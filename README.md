# SkillFox

SkillFox is a **mobile platform that connects customers with nearby workers for small jobs and quick services**.  
Customers can search for workers and request services, while workers can register and offer their skills through the platform.

The application is developed as a **Flutter mobile app with Firebase as the backend service**.

---

## Tech Stack

- **Mobile App:** Flutter (Dart)
- **Backend Services:** Firebase
- **Database:** Cloud Firestore
- **Authentication:** Firebase Authentication
- **Storage:** Firebase Storage
- **Version Control:** Git & GitHub

---

## Project Structure

```bash
skillfox/
├── android/
├── ios/
├── web/
├── lib/
│ ├── main.dart
│ ├── firebase_options.dart
│ ├── pages/
│ ├── models/
│ ├── services/
│ └── widgets/
├── test/
├── pubspec.yaml
└── README.md
```

---

## Features

- User registration and login
- Worker registration and profile creation
- Search for workers based on service type
- Send service requests to workers
- View worker details
- Manage service requests

---

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/ItsKalfox/skillfox.git
cd skillfox
```

---

### 2. Install Dependencies

```bash
flutter pub get
```

---

### 3. Run the Application

Connect an Android device or start an emulator and run:

```bash
flutter run
```

---

## Firebase Services Used

- **Firebase Authentication** – user and worker login
- **Cloud Firestore** – storing users, workers, and service requests
- **Firebase Storage** – storing profile images or documents

---

## Branch Strategy

- **main:** stable version
- **dev:** active development
- **feature/name:** new features
- **fix/name:** bug fixes

---

# Versions Used

### Flutter
```
Flutter 3.41.0
Dart 3.11.0
```

### Firebase
```
firebase_core: ^4.5.0
cloud_firestore: ^6.1.3
firebase_auth: ^6.2.0
firebase_storage: ^13.1.0
```

### FlutterFire CLI
```
flutterfire_cli: ^1.3.1
```

### Firebase CLI
```
firebase-tools: ^15.9.0
```
