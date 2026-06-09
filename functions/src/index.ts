import { onRequest } from 'firebase-functions/v2/https';
import * as logger from 'firebase-functions/logger';
import * as admin from 'firebase-admin';
import {
  GoogleGenerativeAI,
  HarmBlockThreshold,
  HarmCategory,
} from '@google/generative-ai';

admin.initializeApp();

type OctyChatRequest = {
  message?: unknown;
  context?: unknown;
};

const SYSTEM_PROMPT = [
  'Sen Octy adlı Türkçe konuşan kısa, sıcak ve pratik bir alışkanlık koçusun.',
  'Yanıtların 2-4 kısa cümle olsun.',
  'Her zaman tek bir net sonraki adım öner.',
  'Tıbbi, hukuki veya finansal tavsiye verme.',
  'Kullanıcı kriz, kendine zarar veya acil sağlık riski anlatırsa profesyonel destek ve acil yardım öner.',
].join(' ');

const RATE_LIMIT_WINDOW_MS = 10 * 60 * 1000;
const RATE_LIMIT_MAX_REQUESTS = 25;

function pickString(v: unknown, maxLen: number): string {
  if (typeof v !== 'string') return '';
  const s = v.trim();
  return s.length > maxLen ? s.slice(0, maxLen) : s;
}

function buildPrompt(args: {
  message: string;
  contextJson: string;
}): string {
  const parts = <string[]>[];
  parts.push(`SYSTEM:\n${SYSTEM_PROMPT}`);
  parts.push(`CONTEXT(JSON):\n${args.contextJson}`);
  parts.push(`USER:\n${args.message}`);
  return parts.join('\n\n');
}

async function isRateLimited(uid: string): Promise<boolean> {
  const now = Date.now();
  const ref = admin.firestore().collection('ai_rate_limits').doc(uid);

  return admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.exists ? snap.data() ?? {} : {};
    const resetAt = typeof data.resetAtMillis === 'number' ?
      data.resetAtMillis :
      now + RATE_LIMIT_WINDOW_MS;
    const count = resetAt <= now ?
      1 :
      ((typeof data.count === 'number' ? data.count : 0) + 1);
    const nextResetAt = resetAt <= now ? now + RATE_LIMIT_WINDOW_MS : resetAt;

    tx.set(ref, {
      count,
      resetAtMillis: nextResetAt,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    return count > RATE_LIMIT_MAX_REQUESTS;
  });
}

export const octyChat = onRequest(
    {
      region: 'europe-west1',
      cors: true,
      invoker: 'public',
      secrets: ['GEMINI_API_KEY'],
      timeoutSeconds: 30,
    },
    async (req, res) => {
      try {
        if (req.method !== 'POST') {
          res.status(405).json({ error: 'method_not_allowed' });
          return;
        }

        const authHeader = req.get('Authorization') ?? '';
        const m = authHeader.match(/^Bearer\s+(.+)$/i);
        if (!m) {
          res.status(401).json({ error: 'unauthenticated' });
          return;
        }

        let uid = 'unknown';
        try {
          const decoded = await admin.auth().verifyIdToken(m[1]);
          uid = decoded.uid;
        } catch (e) {
          res.status(401).json({ error: 'unauthenticated' });
          return;
        }

        if (await isRateLimited(uid)) {
          res.status(429).json({ error: 'rate_limited' });
          return;
        }

        const body = (req.body ?? {}) as OctyChatRequest;
        const message = pickString(body.message, 1000);

        if (!message) {
          res.status(400).json({ error: 'missing_message' });
          return;
        }

        // Context is optional; keep it bounded.
        let contextJson = '{}';
        try {
          const raw = JSON.stringify(body.context ?? {});
          contextJson = raw.length > 8000 ? raw.slice(0, 8000) : raw;
        } catch (_) {
          contextJson = '{}';
        }

        const apiKey = process.env.GEMINI_API_KEY;
        if (!apiKey) {
          res.status(500).json({ error: 'missing_gemini_api_key' });
          return;
        }

        const modelName = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
        const genAI = new GoogleGenerativeAI(apiKey);
        const model = genAI.getGenerativeModel({
          model: modelName,
          generationConfig: {
            maxOutputTokens: 360,
            temperature: 0.6,
          },
          safetySettings: [
            {
              category: HarmCategory.HARM_CATEGORY_HARASSMENT,
              threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
            },
            {
              category: HarmCategory.HARM_CATEGORY_HATE_SPEECH,
              threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
            },
            {
              category: HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT,
              threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
            },
            {
              category: HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
              threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
            },
          ],
        });

        const prompt = buildPrompt({ message, contextJson });

        const startedAt = Date.now();
        const result = await model.generateContent(prompt);
        const reply = (result.response.text() ?? '').trim();

        // Best-effort log (don’t fail the request if Firestore is unavailable).
        void admin
            .firestore()
            .collection('users')
            .doc(uid)
            .collection('ai_events')
            .add({
              type: 'chat',
              model: modelName,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              latencyMs: Date.now() - startedAt,
            })
            .catch((err) => logger.warn('ai_events write failed', err));

        if (!reply) {
          res.status(200).json({
            reply: 'Şu an yanıt üretemedim. Biraz daha kısa yazar mısın?',
          });
          return;
        }

        res.status(200).json({ reply });
    } catch (err) {
      logger.error('octyChat failed', err);
      res.status(500).json({ error: 'internal' });
    }
  },
);
