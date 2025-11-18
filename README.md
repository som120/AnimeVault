# 📦 AnimeVault — Flutter Anime Tracking App

AnimeVault is a modern Flutter application inspired by MyAnimeList and AniList.  
It allows users to **search, browse, and track anime**, with **cloud sync using Firebase** and **live data from the AniList GraphQL API**.

---

## 🚀 Features

### 🔍 Anime Search

- Search any anime using AniList API
- Modern, clean UI with poster, rating, and year
- Fast filtering with:
  - Top 100
  - Popular
  - Airing
  - Upcoming
  - Movies

### 🎨 Modern UI

- Custom-designed anime cards
- Beautiful rounded corners and soft shadows
- Clean white backgrounds
- Smooth animations
- Responsive iOS/Android design

### ⭐ Anime Details

- High-quality cover image
- Description
- Genres
- Rating
- Episodes
- Link to AniList page

### ☁️ Firebase Integration

- Firebase Core configured
- Firestore database connected
- Store user watchlist & progress
- Real-time cloud sync (coming soon)

---

## 🏗️ Tech Stack

| Technology                        | Purpose                   |
| --------------------------------- | ------------------------- |
| **Flutter 3**                     | UI & App Development      |
| **Dart**                          | Main Programming Language |
| **AniList GraphQL API**           | Anime Data Source         |
| **Firebase Core**                 | Backend Integration       |
| **Firebase Firestore**            | User Data Storage         |
| **Firebase Auth** _(coming soon)_ | User Login                |

---

## 📁 Project Structure

lib/
├── screens/
│ ├── search_screen.dart
│ ├── anime_detail_screen.dart
│ ├── home_screen.dart
│ ├── profile_screen.dart
│
├── services/
│ ├── anilist_service.dart
│
├── firebase_options.dart
├── main.dart

---

## 🔧 Setup Instructions

### 1️⃣ Install dependencies

flutter pub get

### 2️⃣ Configure Firebase (if needed)

flutterfire configure

### 3️⃣ Run the app

flutter run

---

## 🌐 API Used

### AniList GraphQL API

Documentation: https://anilist.gitbook.io/anilist-apiv2-docs/

---

## 🛠️ Planned Features

- 🔐 Google Sign-in (Firebase Auth)
- ⭐ User ratings
- ❤️ Favorite list
- 📌 Watchlist system (Watching / Completed / Dropped)
- 📊 User statistics
- 🌙 Dark mode
- 🔄 Offline mode
- 🎴 Seasonal anime page
- ↕ Scroll animations & hero effects

---

## 🤝 Contributing

Pull requests are welcome!  
For major changes, open an issue first to discuss your proposal.

---

## 📜 License

MIT License — use freely for learning & development.

---

## 💙 Author

**Somnath**  
Flutter Developer & Anime Enthusiast
