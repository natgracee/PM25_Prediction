# 🌫️ PM2.5 Prediction App

Aplikasi berbasis Machine Learning untuk memprediksi konsentrasi PM2.5 berdasarkan data kualitas udara dan parameter meteorologi. Aplikasi ini membantu pengguna dalam menganalisis tingkat polusi udara serta memberikan prediksi secara cepat melalui antarmuka yang sederhana.

## ✨ Fitur

- Prediksi kadar PM2.5 menggunakan model Machine Learning.
- Input data melalui form interaktif.
- Menampilkan hasil prediksi secara real-time.
- Visualisasi data dan hasil prediksi.
- Mudah digunakan dan dikembangkan.

## 🛠️ Teknologi

- Python
- Streamlit / Flask *(sesuaikan)*
- Scikit-learn
- Pandas
- NumPy
- Matplotlib / Plotly *(opsional)*

## 📂 Struktur Proyek

```
├── data/              # Dataset
├── model/             # Model Machine Learning
├── notebooks/         # Eksperimen dan eksplorasi data
├── app.py             # Aplikasi utama
├── requirements.txt   # Dependency
└── README.md
```

## 🚀 Instalasi

1. Clone repository

```bash
git clone https://github.com/username/pm25-prediction-app.git
cd pm25-prediction-app
```

2. Install dependency

```bash
pip install -r requirements.txt
```

3. Jalankan aplikasi

```bash
streamlit run app.py
```

atau

```bash
python app.py
```

## 📊 Cara Kerja

1. Pengguna memasukkan parameter kualitas udara dan cuaca.
2. Data diproses melalui model Machine Learning yang telah dilatih.
3. Model menghasilkan prediksi konsentrasi PM2.5.
4. Hasil ditampilkan pada aplikasi beserta visualisasinya.

## 📈 Model Machine Learning

Model yang digunakan dapat berupa:

- Random Forest
- XGBoost
- Gradient Boosting
- Linear Regression
- atau model terbaik berdasarkan evaluasi

## 📋 Evaluasi

Model dievaluasi menggunakan beberapa metrik, seperti:

- Mean Absolute Error (MAE)
- Mean Squared Error (MSE)
- Root Mean Squared Error (RMSE)
- R² Score

## 📄 Lisensi

Project ini menggunakan lisensi MIT.

## 👨‍💻 Author

Nama Anda
