# 🌫️ PM2.5 Prediction App

**PM2.5 Prediction App** is an intelligent air quality prediction system that combines **Computer Vision** and **Machine Learning** to estimate PM2.5 concentrations from real-time traffic data. Instead of relying solely on conventional air quality sensors, the application utilizes CCTV footage to analyze traffic conditions as an indicator of particulate matter emissions.

The system employs **YOLO (You Only Look Once)** to detect, classify, and count different types of vehicles, including **cars, trucks, and motorcycles**, from video streams or recorded CCTV footage. The detected vehicle counts and classifications are then processed as input features for a Machine Learning model, which predicts the concentration of **PM2.5 (Particulate Matter ≤ 2.5 μm)** at the observed location.

By integrating object detection with predictive analytics, the application provides an efficient and scalable approach to estimating air pollution levels in areas where dedicated air quality monitoring stations are limited. The system is designed to support smart city initiatives, environmental monitoring, and data-driven decision-making by delivering fast, automated, and real-time PM2.5 predictions based on traffic activity.

### Key Features

* 🚗 Real-time vehicle detection and classification using **YOLO**.
* 📹 Traffic analysis from CCTV video streams or recorded footage.
* 🚙 Detection of multiple vehicle categories, including cars, trucks, and motorcycles.
* 🤖 PM2.5 concentration prediction using a Machine Learning model.
* 📊 Real-time visualization of traffic statistics and prediction results.
* 🌍 Scalable solution for traffic-based air quality monitoring.
