# Octy: AI-Powered Habit Tracker 🚀 (Group 2)

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org)
[![Scikit-Learn](https://img.shields.io/badge/scikit--learn-F7931E?style=for-the-badge&logo=scikit-learn&logoColor=white)](https://scikit-learn.org)

Bu proje, **bsc-2026-group-2-ai-powered-habbit-tracker** kapsamında geliştirilmiş, kullanıcıların alışkanlıklarını takip etmelerini kolaylaştıran ve yapay zeka ile kişiselleştirilmiş motivasyon destekleri sunan mobil tabanlı bir alışkanlık takip (Habit Tracker) uygulamasıdır.

---

## 📂 Depo Yapısı (Repository Structure)

Proje deposu aşağıdaki şekilde yapılandırılmıştır:

```
├── README.md                 # Proje genel açıklaması ve kurulum kılavuzu
├── report.pdf                # Proje Raporu
├── src/                      # Kaynak Kodlar (Flutter mobil uygulaması & Firebase Functions)
│   ├── lib/                  # Flutter uygulama kaynak kodları
│   ├── assets/               # Görsel varlıklar ve yerel makine öğrenimi modelleri
│   ├── functions/            # Firebase Cloud Functions
│   ├── test/                 # Birim ve entegrasyon testleri
│   └── tools/                # Çevrimdışı ML veri seti ve model eğitim araçları
├── docs/                     # Sistem tasarımı, veritabanı şeması ve mimari belgeler
├── simulations/              # Makine öğrenimi eğitim simülasyonları
├── results/                  # Test çıktıları ve ML sonuçları
└── presentation/             # Proje sunum slaytları ve video linkleri
```

---

## ✨ Temel Özellikler (Key Features)

1. **Yapay Zeka Destekli Alışkanlık Asistanı:**
   - Gemini API entegrasyonu sayesinde kullanıcıya özel, dinamik motivasyon tavsiyeleri sunar.
   - Kullanıcının alışkanlık geçmişini analiz ederek akıllı içgörüler (insights) oluşturur.

2. **Gelişmiş Alışkanlık ve Seri (Streak) Takibi:**
   - Günlük, haftalık veya özel periyotlarda alışkanlıklar oluşturma.
   - Alışkanlıkların tamamlanma durumlarını interaktif takvim ve grafiklerle izleme.

3. **Makine Öğrenimi Tabanlı Motivasyon Düşüşü Tahmini:**
   - Firestore'dan dışa aktarılan kullanıcı verileriyle eğitilen bir **Logistic Regression (Scikit-Learn)** modeli içerir.
   - Kullanıcının önümüzdeki günlerde alışkanlık tamamlama motivasyonunun düşüp düşmeyeceğini tahmin eder ve risk analizine göre önceden uyarı sistemi devreye girer.

4. **Gelişmiş İstatistikler ve Grafikler:**
   - Haftalık ve aylık bazda alışkanlık tamamlama oranları, en uzun seriler ve genel performans analizleri.

---

## 🛠️ Kurulum ve Çalıştırma (Installation & Setup)

### 1. Flutter Uygulamasını Çalıştırma

Gerekli tüm kodlar [src/](file:///c:/Bitirme%20projesi/octy_habitsfinal/octy_habits-final/src) klasöründedir.

```bash
# src klasörüne gidin
cd src

# Bağımlılıkları yükleyin
flutter pub get
```

#### Yapay Zeka / ML Modunu Aktifleştirerek Çalıştırma:
Uygulama yerleşik bir mantıksal risk analiz motoruna sahiptir. Ancak eğitilmiş Logistic Regression modelini devreye sokmak isterseniz uygulamayı şu parametreyle başlatmalısınız:

```bash
flutter run --dart-define=OCTY_USE_ML=true
```

### 2. Çevrimdışı Makine Öğrenimi (ML) Boru Hattı

Uygulamanın kullandığı ML modeli çevrimdışı olarak Scikit-Learn ile eğitilmektedir. Ayrıntılı çalıştırma adımları [simulations/](file:///c:/Bitirme%20projesi/octy_habitsfinal/octy_habits-final/simulations) altındaki dokümanlarda yer almaktadır:

```bash
# Python sanal ortamını kurun
python -m venv .venv
source .venv/bin/activate  # Windows için: .venv\Scripts\activate
pip install -r src/tools/ml/requirements.txt

# Veri setini oluşturun
python src/tools/ml/build_dataset.py --events events.json --habit-logs habit_logs.json --habits habits.json --out dataset.csv --days 60

# Modeli eğitin ve Flutter varlıklarına kaydedin
python src/tools/ml/train_logreg.py --csv dataset.csv --out src/assets/ml/model.json
```

---

## 👥 Proje Ekibi
- **Yunus Emre Yılmaz**
- **Emirhan Çelen**

