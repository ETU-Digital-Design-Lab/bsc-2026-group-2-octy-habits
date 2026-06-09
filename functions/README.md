# Octy Habits - Gemini Proxy (Firebase Functions)

Bu klasör, Octy Chat için Gemini entegrasyonunu **API key'i uygulamaya koymadan** yapabilmek için proxy endpoint içerir.
Endpoint Firebase ID Token ile çalışır, sistem prompt'u server tarafında tutar ve kullanıcı başına kota uygular.

## 1) Gereksinimler

- Node.js 20
- Firebase CLI (`npm i -g firebase-tools`)

## 2) Kurulum

```bash
cd functions
npm i
```

## 3) Secret (API Key)

Gemini API key'i Functions secret olarak set edilir:

```bash
firebase functions:secrets:set GEMINI_API_KEY
```

Opsiyonel model adı için deploy/runtime ortamında `GEMINI_MODEL` env var'ı verilebilir.
Verilmezse kod `gemini-2.5-flash` kullanir.

Not: Firebase `functions:config:set` ile verilen `octy.gemini_model` degeri bu kodda okunmaz.

## 4) Deploy

```bash
firebase deploy --only functions
```

Deploy sonrasi endpoint:

- `octyChat`: `https://europe-west1-<PROJECT_ID>.cloudfunctions.net/octyChat`

## 5) Flutter Tarafı

Uygulamayı endpoint ile çalıştır:

```bash
flutter run --dart-define=OCTY_AI_ENDPOINT=https://europe-west1-<PROJECT_ID>.cloudfunctions.net/octyChat
```

Flutter, isteklerde Firebase ID Token'i `Authorization: Bearer <token>` olarak gonderir.
Client sadece kullanıcı mesajı ve kompakt alışkanlık context'i yollar; sistem talimatları server tarafındadır.
