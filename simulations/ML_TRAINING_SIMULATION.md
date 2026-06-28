# 🤖 Makine Öğrenimi Eğitim Simülasyonu (ML Training & Simulation)

> [📄 PDF Sürümünü İndir](ML_TRAINING_SIMULATION.pdf)

Bu dizin, Octy Habit Tracker uygulamasının arkasında çalışan **Motivasyon Düşüşü Tahmin Modeli**'nin (Logistic Regression) eğitim, test ve simülasyon süreçlerini içerir.

Model, kullanıcının geçmiş alışkanlık tamamlama sıklığı, serileri (streaks) ve uygulama içi davranış etkinlikleri (events) verilerini analiz ederek, önümüzdeki günlerde alışkanlıklarını aksatma olasılığını hesaplar.

---

## 🚀 Simülasyonu ve Model Eğitimini Çalıştırma Adımları

Model eğitimi, Python 3 ortamında scikit-learn kütüphanesi kullanılarak yerel olarak (çevrimdışı) gerçekleştirilir.

### 1. Gerekli Python Bağımlılıklarının Kurulması
Öncelikle projenin ML araçlarının bulunduğu `src/tools/ml/` altındaki bağımlılıkları kurmak için bir sanal ortam oluşturun:

```bash
# Sanal ortam oluşturma ve aktifleştirme
python -m venv .venv
# Windows için:
.venv\Scripts\activate
# macOS/Linux için:
source .venv/bin/activate

# Gerekli paketlerin kurulması
pip install -r src/tools/ml/requirements.txt
```

### 2. Simülasyon Verisinin Sağlanması
Modeli eğitmek için 3 temel Firestore koleksiyonunun dışa aktarılmış JSON formatına ihtiyaç duyulur. Örnek/simülasyon verileri oluşturabilir ya da test cihazınızdan Firestore verilerini indirebilirsiniz:
- `habits.json` (Kullanıcının alışkanlık listesi)
- `habit_logs.json` (Alışkanlıkların geçmiş günlerdeki tamamlanma kayıtları)
- `events.json` (Uygulama açma, tamamlama saati vb. loglar)

*Not: Simülasyon amaçlı hızlı test için rastgele veri üreten bir mock scripti hazırlayabilir veya mevcut test verilerinizi kullanabilirsiniz.*

### 3. Özellik Çıkarımı (Feature Engineering) ve Veri Seti Oluşturma
Ham JSON verilerini makine öğrenimi modelinin işleyebileceği bir CSV dosyasına dönüştürmek için aşağıdaki komutu çalıştırın:

```bash
python src/tools/ml/build_dataset.py \
  --events src/tools/ml/events.json \
  --habit-logs src/tools/ml/habit_logs.json \
  --habits src/tools/ml/habits.json \
  --out simulations/dataset.csv \
  --days 60
```
Bu script, son 60 günü geriye doğru tarayarak her gün için şu özellikleri hesaplar ve `simulations/dataset.csv` dosyasına kaydeder:
- `streak`: Güncel alışkanlık serisi.
- `completion_rate`: Son 7 gündeki tamamlama oranı.
- `avg_completion_hour`: Alışkanlıkların genelde günün hangi saatinde tamamlandığı.
- `motivation_drop_label` (Hedef Değişken - Label): Alışkanlığın sonraki gün aksatılıp aksatılmadığı (0 veya 1).

### 4. Modeli Eğitme ve Flutter Uygulamasına Gönderme
Oluşturulan veri seti (`dataset.csv`) üzerinde Logistic Regression modelini eğitip, model katsayılarını Flutter uygulamasının okuyabileceği JSON dosyasına dönüştürmek için:

```bash
python src/tools/ml/train_logreg.py \
  --csv simulations/dataset.csv \
  --out src/assets/ml/model.json
```

Bu komut başarıyla tamamlandığında, eğitilen modelin ağırlıkları (weights/coefficients) ve sapma (intercept) değerleri [src/assets/ml/model.json](file:///c:/Bitirme%20projesi/octy_habitsfinal/octy_habits-final/src/assets/ml/model.json) dosyasına otomatik olarak kaydedilir. Flutter uygulaması bu katsayıları yükleyerek cihaz üzerinde (on-device) anlık tahminler yapabilir.
