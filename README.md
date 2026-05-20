
# Asset Management App

An RFID-based mobile application developed using Flutter and Firebase for efficient asset tracking and management within organizations. This system helps users and administrators manage assets digitally with features like RFID scanning, asset requests, issue reporting, notifications, and admin controls.

## Features


 User Features
- User Registration & Login 
- RFID Asset Scanning 
- Asset Search 
- Asset Request Submission 
- Report Missing/Damaged Assets 
- Notifications for Asset Updates
- User Profile Management

Admin Features
- Secure Admin Login 
- Admin Dashboard 
- Add / Update / Delete Assets 
- Manage Users 
- Approve or Reject Asset Requests 
- Issue Assets to Users 
- Asset Tracking & Monitoring 
- Admin Profile Management




## Tech Stack

| Technology                     | Purpose                         |
| ------------------------------ | ------------------------------- |
| Flutter                        | Frontend Mobile App Development |
| Dart                           | Programming Language            |
| Firebase Authentication        | User Authentication             |
| Cloud Firestore                | Database Management             |
| Firebase Cloud Messaging (FCM) | Push Notifications              |
| RFID Technology                | Asset Identification & Tracking |


##  System Architecture
The application follows a client-server architecture:

- Frontend: Flutter Mobile Application 
- Backend Services: Firebase 
- Database: Cloud Firestore 
- Notifications: Firebase Cloud Messaging 
- RFID Integration: RFID Reader / Scanner

## Installation

Make sure you have installed:

- Flutter SDK 
- Dart SDK 
- Android Studio / VS Code 
- Android Emulator or Physical Device 

## Setup Instructions

### 1. Install Flutter SDK

Download Flutter from the official website

```bash
  https://flutter.dev/docs/get-started/install/windows
```

After installation, verify Flutter is installed correctly

### 2. Install Dependencies

```bash
  flutter pub get
```

### 3. Configure Firebase

- Create a Firebase project 
- Enable: 
	- Authentication 
    - Cloud Firestore 
	- Firebase Cloud Messaging 
- Download: 
	- google-services.json (Android) 
	- GoogleService-Info.plist (iOS) 
- Place them in the appropriate directories 

### 4. Run the Application

```bash
  flutter run
```

## Project Structure

```bash
  lib/
│
├── screens/
│   ├── login_screen.dart
│   ├── splash_screen.dart
│   ├── rfid_scan_screen.dart
│
├── services/
│   ├── notification_service.dart
│
├── firebase_options.dart
├── main.dart
│
assets/
│
pubspec.yaml
```
