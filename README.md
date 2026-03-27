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
├── webapp/
├── mobile/
│   ├── android/
│   ├── ios/
│   ├── web/
│   ├── lib/
│   │ ├── main.dart
│   │ ├── firebase_options.dart
│   │ ├── pages/
│   │ ├── models/
│   │ ├── services/
│   │ └── widgets/
│   ├── test/
│   └── pubspec.yaml
├── .gitignore
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

### Other
```
provider: ^6.1.2
google_maps_flutter: ^2.6.1
image_picker: ^1.1.2
shared_preferences: ^2.3.2
google_fonts: ^6.2.1
file_picker: ^8.1.2
mailer: ^6.1.0
permission_handler: ^11.3.1
flutter_svg: ^2.0.10
geolocator: ^14.0.1
image_cropper: ^11.0.0
cached_network_image: ^3.3.1
video_player: ^2.9.1
video_compress: ^3.1.2
flutter_image_compress: ^2.3.0
path_provider: ^2.1.3
fl_chart: ^1.2.0
visibility_detector: ^0.4.0+2
geocoding: ^4.0.0
```