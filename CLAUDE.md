# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Key Project Files

- **CommunityRun_Requirements_Firebase.md**: Complete technical requirements and specifications
- **IMPLEMENTATION_CHECKLIST.md**: Detailed task checklist for tracking development progress
- **CLAUDE.md**: This file - development guidance and project overview

## Project Overview

CommunityRun is a Flutter mobile application for connecting local runners. The app enables users to create, discover, and join running activities in their area using Firebase as the backend.

**Tech Stack:**
- Flutter (Cross-platform mobile development)
- Firebase Suite (Authentication, Firestore, Cloud Messaging, Analytics, Crashlytics, Storage)
- State Management: Provider or Riverpod
- Location Services: GeoFlutterFire2 for geospatial queries
- Maps: Google Maps Flutter

## Development Commands

Since this is a Flutter project, use these standard commands:

### Setup and Dependencies
```bash
flutter pub get                    # Install dependencies
flutter pub upgrade               # Update dependencies
```

### Development
```bash
flutter run                       # Run on connected device/emulator
flutter run --debug              # Debug mode
flutter run --release            # Release mode
flutter hot-reload               # Hot reload (r in terminal)
flutter hot-restart              # Hot restart (R in terminal)
```

### Testing
```bash
flutter test                     # Run unit tests
flutter test --coverage         # Run tests with coverage
flutter integration_test        # Run integration tests
```

### Code Quality
```bash
flutter analyze                  # Static analysis
flutter format .                # Format code
dart fix --apply                # Apply suggested fixes
```

### Build
```bash
flutter build apk              # Build Android APK
flutter build appbundle        # Build Android App Bundle
flutter build ios              # Build iOS app
```

## Project Architecture

### Core Architecture Pattern
- **State Management**: Provider/Riverpod for app state
- **Navigation**: GoRouter for declarative routing
- **Data Layer**: Repository pattern with Firebase services
- **Real-time Updates**: Stream-based UI with Firestore listeners

### Key Directory Structure (When Created)
```
lib/
├── main.dart                    # App entry point
├── models/                      # Data models (Run, UserProfile, Message)
├── services/                    # Firebase services (RunService, AuthService, etc.)
├── providers/                   # State management providers
├── screens/                     # UI screens organized by feature
├── widgets/                     # Reusable UI components
├── utils/                       # Utilities and helpers
└── constants/                   # App constants and configuration
```

### Firebase Collections Schema

**runs collection:**
- Document structure includes creatorId, title, dateTime, startLocation (GeoPoint), participants array
- Uses GeoFlutterFire format for location queries
- Real-time listeners for participant updates

**userProfiles collection:**
- Anonymous Firebase Auth UIDs as document IDs
- Includes running preferences, notification settings, privacy controls
- Optional Strava integration fields

**messages collection:**
- Run-specific group messaging
- Real-time chat functionality with Firestore listeners

### Location-Based Queries
Use GeoFlutterFire2 for efficient geospatial queries:
- Center point + radius searches for nearby runs
- Real-time location updates with proper privacy controls
- Caching for offline capability

## Key Implementation Guidelines

### Authentication
- Primary: Firebase Anonymous Authentication
- Optional: Strava OAuth2 integration
- Persistent user sessions across app restarts

### Security
- Implement Firestore Security Rules as specified in requirements
- Location precision controls (exact vs approximate)
- User verification system for safety

### Real-time Features
- Use StreamBuilder widgets for live UI updates
- Implement proper loading states and error handling
- Optimize listener subscriptions to prevent memory leaks

### Internationalization
- Support Italian (primary) and English
- Use Flutter's intl package for localization
- Proper date/time and distance unit formatting

### Safety Features
- Public meeting point validation
- Emergency contact sharing
- User reporting and blocking functionality
- SOS button integration

## Testing Strategy

### Unit Tests
- Service layer logic (Firebase operations)
- Data model serialization/deserialization
- Utility functions and validators

### Integration Tests
- User flows (onboarding, run creation, joining runs)
- Firebase operations with test database
- Location services and map functionality

### Widget Tests
- UI components with various states
- Form validation and user input handling
- Navigation and routing

## Implementation Progress Tracking

**📋 See IMPLEMENTATION_CHECKLIST.md for detailed progress tracking**

This project uses a comprehensive implementation checklist to track development progress. The checklist is organized by development phases and includes all tasks from the requirements document.

### Development Phases

The project follows a 3-phase development approach:
1. **Phase 1 (Weeks 1-3)**: Basic MVP with core functionality
2. **Phase 2 (Weeks 4-6)**: Enhanced features and communication  
3. **Phase 3 (Weeks 7-9)**: Polish and production readiness

### How to Use the Checklist

1. **Track Progress**: Mark tasks as completed [x], in progress [🔄], or blocked [❌]
2. **Phase Management**: Focus on completing current phase before moving to next
3. **Dependency Awareness**: Some tasks depend on others - check prerequisites
4. **Quality Gates**: Don't skip testing and validation steps
5. **Safety Priority**: Complete all safety features before public launch

When implementing features, follow the detailed task breakdown in the checklist and the milestone structure outlined in the requirements document.

### Current Project Status

**Status**: Pre-development (Project Planning Complete)
- ✅ Requirements analysis completed
- ✅ Implementation plan created
- ⏳ Ready to begin Phase 1: Foundation setup

Next steps: Begin pre-development setup tasks from the checklist.

## Firebase Configuration

### Required Firebase Services
- Authentication (Anonymous + OAuth)
- Cloud Firestore (NoSQL database)
- Cloud Messaging (Push notifications)
- Analytics & Crashlytics (Monitoring)
- Storage (Profile photos)

### Security Rules
Implement the Firestore security rules as specified in the requirements document, ensuring:
- Users can only modify their own profiles
- Run creators control their runs
- Participants can join/leave runs
- Messages are only visible to run participants

## Performance Considerations

- Use pagination for run lists
- Implement image caching for profile photos
- Optimize Firestore queries with proper indexing
- Use offline persistence for core functionality
- Monitor Firebase usage to control costs