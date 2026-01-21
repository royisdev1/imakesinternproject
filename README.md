🍔 Food App (Flutter + Firebase)

A full-featured Food Ordering & Delivery Application built with Flutter, Firebase, and GetX.
The app supports multiple user roles, real-time order management, push notifications, and map-based delivery tracking. try it link: foodieroy.vercel.app

🚀 Features
🔐 Authentication

User Login & Signup

Firebase Authentication

Auto login check using CheckUserLogin

👥 Multi-Role System

Customer

Hotel Owner

Delivery Partner

Each role is redirected to its respective dashboard automatically.

🛒 Order Management

Place food orders

Order status tracking

Role-based order views

Real-time updates using Firebase

🔔 Push Notifications

Firebase Cloud Messaging (FCM)

Order status notifications

Delivery updates

Platform-safe initialization (disabled for Web)

🗺️ Map Integration

Live order delivery tracking

Location-based delivery flow

Google Maps integration (for delivery partners & customers)

🎨 UI & Navigation

Clean Material UI

Custom color theme (Red & Orange)

GetX navigation & routing

Responsive layouts

🧠 App Flow (High Level)
App Start
   ↓
Firebase Initialization
   ↓
Notification Initialization (Mobile only)
   ↓
CheckUserLogin
   ↓
Role Detection
   ↓
Navigate to:
   • Customer Home
   • Hotel Owner Home
   • Delivery Partner Home

🧱 Tech Stack
Technology	Usage
Flutter	Frontend framework
Firebase Core	App initialization
Firebase Auth	Authentication
Firebase Cloud Messaging	Push notifications
GetX	State management & routing
Google Maps API	Delivery tracking
Dart	Programming language
📁 Project Structure
lib/
 ├── auth/
 │   └── chackUserLgin.dart
 ├── auth_ui/
 │   ├── loginScreen.dart
 │   └── signupScreen.dart
 ├── screen/
 │   ├── homeScreen.dart
 │   ├── hotelownwerHome.dart
 │   ├── deliveryHome.dart
 │   ├── profile_page.dart
 │   ├── edit_profile_screen.dart
 │   └── settings.dart
 |   |__ foodDetails.dart
 |   |__ hotels.dart
 |   |__ Myfooditems.dart
 |   |__ Myorderpage.dart 
 |   |__ offerfoodDetail.dart
 |   |__ payment_page.dart
 |   |__ tableBookin.dart
 |   |__ Table_count.dart
 |   |__ editFooditem.dart
 ├── utils/
 │   └── notifications.dart
 ├── firebase_options.dart
 └── main.dart

⚙️ Setup Instructions
1️⃣ Clone the Repository
git clone https://github.com/your-username/food-app.git
cd food-app

2️⃣ Install Dependencies
flutter pub get

3️⃣ Firebase Setup

Create a Firebase project

Enable Authentication

Enable Cloud Messaging

Download:

google-services.json (Android)

GoogleService-Info.plist (iOS)

Configure using flutterfire configure

4️⃣ Run the App
flutter run

🌐 Supported Platforms

✅ Android

✅ iOS

✅ Web 

🔐 Environment Notes

Notifications are initialized only for mobile platforms

Firebase is safely initialized using platform-specific options

📌 Future Enhancements

Admin panel

Payment gateway integration

Order analytics

Ratings & reviews

Dark mode

👨‍💻 Developer

Royis Abraham
📧 Email: royisdev1@gmail.com

🔗 GitHub: https://github.com/royism

🔗 LinkedIn: https://linkedin.com/in/royis-abraham-m-b5a019280

📄 License

This project is licensed under the MIT License.
