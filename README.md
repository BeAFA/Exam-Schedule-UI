# Exam-Schedule-UI

This repository contains the Flutter front-end for an exam management and timetable system, designed for managing academic schedules, subject classes, exams, and role-based access for students, teachers, and administrators.

## Overview

The application provides a user interface for:

- Login and authentication
- Student, teacher, and admin role-based dashboards
- Exam and subject-class management
- Assigning teachers and invigilators
- Schedule viewing by day/week
- Personal profile management
- Secure storage of tokens and session data

The project currently lives under the `ui/` directory and is built with Flutter/Dart.

## Tech Stack

- Flutter
- Dart
- Material Design UI
- HTTP client for API communication
- `flutter_secure_storage` for secure token storage

## Main Features

### Authentication
- Login screen with role-based access
- Token persistence via secure storage
- API integration for user authentication

### Admin
- Create exams
- Manage subject classes
- Assign teachers and invigilators
- View and organize schedules
- Daily and weekly calendar views

### Teacher
- Teacher dashboard
- Schedule and class-related views

### Student
- Student dashboard
- Personal schedule overview

### Profile
- User profile screen
- Personal information management

## Repository Structure

```text
Exam-Schedule-UI/
├── LICENSE
├── README.md
├── ui/
│   ├── android/
│   ├── ios/
│   ├── lib/
│   │   ├── app/
│   │   │   ├── screen/
│   │   │   │   ├── admin_screen/
│   │   │   │   ├── student_screen/
│   │   │   │   ├── teacher_screen/
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── profile_screen.dart
│   │   │   │   ├── splash_screen.dart
│   │   │   └── router.dart
│   │   ├── core/
│   │   │   ├── models/
│   │   │   └── token_storage.dart
│   │   ├── features/
│   │   │   └── auth/
│   │   ├── main.dart
│   │   └── ...
│   ├── test/
│   ├── pubspec.yaml
│   ├── analysis_options.yaml
│   └── README.md
└── .gitignore
```

## App Architecture

The UI is organized with a modular structure:

- `lib/app`: app-level navigation and screens
- `lib/core`: shared models and storage utilities
- `lib/features`: feature-specific logic such as authentication API integration
- `lib/core/models`: domain entities such as exams, schedules, rooms, subjects, and profiles

## Prerequisites

Before running the project, make sure you have:

- Flutter SDK installed
- Android Studio / VS Code with Flutter extensions
- An emulator or physical device connected

## Getting Started

```bash
cd ui
flutter pub get
flutter run
```

## Notes

This repository is focused on the user interface. It likely depends on a backend or API service for real exam and schedule data. Authentication and data fetching are handled through `http` requests and secure local token storage.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
