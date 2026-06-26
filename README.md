# Zara Traders

A full-featured inventory management and e-commerce Flutter application with Firebase backend. Built for businesses that need admin and shopkeeper role-based dashboards, product management, barcode scanning, and real-time support chat.

## Features

### Authentication
- Email/password signup and login
- Google sign-in
- Email OTP password reset flow
- Rate-limit handling with cooldown timer
- Smart Firestore user migration on signup

### Admin Dashboard
- Product management (CRUD with image search via Pixabay)
- Category and brand management
- Supplier and customer management
- Warehouse and unit management
- User role management
- Database control with seed data (personal care categories)
- Order tracking
- Messages and support chat

### Shopkeeper Dashboard
- Inventory overview
- Store management
- Order placement
- Help and support chat

### UI/UX
- Dark and light theme support (persisted with SharedPreferences)
- Animated transitions and splash effects (InkSparkle)
- Responsive design for mobile, web, and desktop
- Barcode/QR code scanning with `mobile_scanner`
- Auto image search for products (Pixabay API)

### Backend
- Firebase Authentication (email/password, Google)
- Cloud Firestore (real-time database)
- Firebase Security Rules with role-based access
- OTP service integration (`otp-service-beta.vercel.app`)

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x |
| Language | Dart |
| Auth | Firebase Auth |
| Database | Cloud Firestore |
| State | Provider |
| Theme | SharedPreferences |
| Scanning | mobile_scanner 7.x |
| Charts | fl_chart |
| Maps | Google Maps Flutter |
| HTTP | http 1.2.x |
| Image | Pixabay API |

## Project Structure

```
lib/
  data/           # Static data (products)
  models/         # Data models (Product, User, Brand, Category, etc.)
  screens/
    admin/        # Admin dashboard and CRUD screens
    auth/         # Login, signup, forgot password
    shopkeeper/   # Shopkeeper dashboard screens
    barcode_scanner_screen.dart
    cart_screen.dart
    home_screen.dart
    order_form_screen.dart
    search_screen.dart
  services/       # Firebase services (auth, admin, product, support)
  theme/          # App theme and theme provider
  utils/          # Helpers (phone utils, messenger)
  widgets/        # Reusable widgets (product card, animations)
```

## Getting Started

### Prerequisites
- Flutter SDK 3.x
- Dart SDK
- Firebase project with Authentication and Firestore enabled
- Android Studio / VS Code

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/Panker199/zaratraders.git
   cd zaratraders
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Enable **Email/Password** and **Google** sign-in methods
   - Add your Android app with package name `com.company.zaratraders`
   - Download `google-services.json` and place it in `android/app/`

4. Run the app:
   ```bash
   flutter run
   ```

### Build

```bash
# Android APK
flutter build apk --release

# Web
flutter build web

# Windows
flutter build windows
```

## Firebase Security Rules

The app uses role-based Firestore security rules:
- **Users collection**: Readable by any authenticated user (for signup migration), writable only by the document owner
- **Products/Categories/Brands**: Readable by authenticated users, writable by admin only
- **Messages**: Readable/writable by conversation participants

## License

This project is private and proprietary.
