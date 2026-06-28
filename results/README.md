# Proje Sonuçları (Project Results)

Bu dizin, Octy Habit Tracker projesinin test çıktılarını, model doğrulama raporlarını ve uygulama içi ekran görüntülerini içerir.

---

## 📂 Dizin İçeriği (Directory Contents)

### 1. Ekran Görüntüleri (`/screenshots`)
Uygulamanın ana akışını, yapay zeka asistanı sohbet ekranını ve istatistik panellerini içeren yüksek çözünürlüklü görseller bu klasöre yerleştirilir:
- `01_splash_and_auth.png`: Uygulama karşılama ve kayıt olma arayüzleri.
- `02_home_dashboard.png`: Kullanıcının günlük alışkanlık listesi ve serileri.
- `03_ai_assistant_chat.png`: Gemini API ile entegre edilmiş Octy Asistan sohbet arayüzü.
- `04_stats_and_charts.png`: Alışkanlık tamamlama istatistikleri ve grafik analizler.

### 2. Test Sonuçları (`/test_outputs`)
Projedeki Flutter birim (unit) testlerinin başarıyla çalıştığını gösteren terminal çıktıları ve kapsama (coverage) raporları:
- `unit_tests_report.txt`: `flutter test` komutunun başarı çıktısı.

### 3. Makine Öğrenimi Başarı Metrikleri (`/ml_metrics`)
Logistic Regression modelinin eğitim sonrasında elde edilen doğruluk (accuracy), kesinlik (precision) ve duyarlılık (recall) skorları.
- `confusion_matrix.png`: Modelin tahmin başarısını gösteren karmaşıklık matrisi.
