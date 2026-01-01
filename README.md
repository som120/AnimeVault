# 📦 AniFlux — Flutter Anime Tracking App

AniFlux is a modern **Flutter-based anime tracking application** inspired by **MyAnimeList** and **AniList**.  
It allows users to **search, browse, and track anime**, with **cloud sync using Firebase** and **live data from the AniList GraphQL API**.

---

## 🚀 Features

### 🔍 Anime Search
- Search anime using **AniList GraphQL API**
- Clean and modern UI
- Displays poster, rating, release year
- Fast filters:
  - Top 100
  - Popular
  - Airing
  - Upcoming
  - Movies

### 🎨 Modern UI
- Custom anime cards
- Rounded corners & soft shadows
- Smooth animations
- Clean white theme
- Fully responsive for **Android & iOS**

### ⭐ Anime Details
- High-quality cover image
- Description & synopsis
- Genres
- Rating & episode count
- Direct link to AniList page

### ☁️ Firebase Integration
- Firebase Core configured
- Firestore database connected
- Store user watchlist & progress
- Real-time cloud sync *(coming soon)*

---

## 🏗️ Tech Stack

| Technology | Purpose |
|-----------|--------|
| **Flutter 3** | Cross-platform UI |
| **Dart** | Programming language |
| **AniList GraphQL API** | Anime data source |
| **Firebase Core** | Backend services |
| **Cloud Firestore** | User data storage |
| **Firebase Auth** *(coming soon)* | Authentication |

---

## 📁 Project Structure

lib/
├── screens/
│ ├── search_screen.dart
│ ├── anime_detail_screen.dart
│ ├── home_screen.dart
│ └── profile_screen.dart
│
├── services/
│ └── anilist_service.dart
│
├── firebase_options.dart
└── main.dart

---

## 🔧 Setup Instructions

### 1️⃣ Clone the repository
```bash
git clone https://github.com/<your-username>/AniFlux.git
cd AniFlux

flutter pub get

flutterfire configure

flutter run

```
---

🌐 API Used
AniList GraphQL API

---
## 📖 Documentation:
https://anilist.gitbook.io/anilist-apiv2-docs/

🛠️ Planned Features

🔐 Google Sign-In (Firebase Auth)

⭐ User ratings

❤️ Favorites list

📌 Watchlist system (Watching / Completed / Dropped)

📊 User statistics

🌙 Dark mode

🔄 Offline support

🎴 Seasonal anime page

✨ Hero animations & advanced transitions

---
## 🤝 Contributing

Contributions are welcome!
Please open an issue first to discuss major changes.

Steps:

Fork the repository

Create a new branch

Commit your changes

Open a pull request

---
## 📜 License

MIT License — free to use for learning and development.

---
## 💙 Author

Somnath
Flutter Developer & Anime Enthusiast

