## Zaim University Campus Information System

### Overview

This application provides a digital Campus Information System for Istanbul Zaim University students and faculty. Built with Flutter, the app enables users to access university resources, course information, and campus services through a clean and intuitive interface.

### Features

- **User Authentication**: Secure login system for students and faculty members
- **Course Management**: View enrolled courses, schedules, and materials
- **Campus Resources**: Access to university news, events, and announcements
- **Student Information**: Personal academic records and profile management
- **Advisor Communication**: Direct contact with academic advisors
- **Teacher Schedule**: Interactive calendar view for faculty to manage their teaching schedules (with RLS policy fix)
- **Cross-Platform Support**: Built with Flutter, the app runs on both Android and iOS
- **Responsive Design**: Optimized for both phone and tablet interfaces

### Installation

To set up the project locally, follow these steps:

1. Clone the repository:
    ```bash
    git clone https://github.com/ars1mm/zaimuniversity.git
    ```
2. Navigate to the project directory:
    ```bash
    cd zaimuniversity
    ```
3. Install dependencies:
    ```bash
    flutter pub get
    ```
4. Run the app:
    ```bash
    flutter run
    ```

### Running with an Emulator

To run the project using an Android or iOS emulator from the terminal, follow these steps:

#### Prerequisites
- Android SDK with emulator images installed (for Android)
- Xcode with simulator installed (for iOS, macOS only)
- Flutter SDK properly set up in your PATH

#### Installing Emulators

##### Android Emulator Installation

1. **Install Android Studio**
   - Download and install [Android Studio](https://developer.android.com/studio)
   - During installation, ensure the "Android Virtual Device" option is selected

2. **Create a Virtual Device**
   - Open Android Studio
   - Go to Tools > AVD Manager (or click the AVD Manager icon in the toolbar)
   - Click "Create Virtual Device"
   - Select a device definition (e.g., Pixel 6)
   - Select a system image (preferably the latest stable Android version)
   - Complete the setup with default settings or customize as needed
   - Click "Finish"

3. **Verify Installation**
   - From the terminal/PowerShell, run:
     ```powershell
     flutter emulators
     ```
   - You should see your newly created emulator in the list

##### iOS Simulator Installation (macOS only)

1. **Install Xcode**
   - Download Xcode from the Mac App Store
   - Open Xcode and accept the license agreement
   - Install additional components when prompted

2. **Create iOS Simulator**
   - Open Xcode
   - Go to Xcode > Open Developer Tool > Simulator
   - In Simulator, go to File > New Simulator
   - Configure the simulator with your desired device and iOS version
   - Click "Create"

3. **Verify Installation**
   - From the terminal, run:
     ```bash
     xcrun simctl list
     ```
   - You should see your newly created simulator in the list

#### Steps to Run on Emulator

1. **List available emulators**
    ```powershell
    flutter emulators
    ```

2. **Launch a specific emulator**
    ```powershell
    flutter emulators --launch <emulator_id>
    ```
    Replace `<emulator_id>` with the ID of your desired emulator from step 1.

3. **Run the application on the launched emulator**
    ```powershell
    flutter run
    ```

#### Running on a Specific Device/Emulator
If you have multiple devices connected or emulators running:

1. **List available devices**
    ```powershell
    flutter devices
    ```
    This will show output similar to:
    ```
    3 connected devices:

    Pixel 6 Pro (mobile) • emulator-5554 • android-x64 • Android 13 (API 33)
    Chrome (web)         • chrome        • web-javascript • Google Chrome 113.0.5672.93
    Edge (web)           • edge          • web-javascript • Microsoft Edge 113.0.1774.35
    ```

2. **Identify the device ID**
    The device ID is the second value in each row. For example:
    - `emulator-5554` for the Pixel 6 Pro emulator
    - `chrome` for Chrome browser
    - `edge` for Edge browser
    - For physical devices, it will usually show a serial number

3. **Run on a specific device**
    ```powershell
    flutter run -d <device_id>
    ```
    Replace `<device_id>` with the ID identified in step 2.
    
    Example:
    ```powershell
    flutter run -d emulator-5554
    ```

#### Additional Flags
- For faster development builds:
    ```powershell
    flutter run --debug
    ```
- For performance testing:
    ```powershell
    flutter run --profile
    ```
- For release version:
    ```powershell
    flutter run --release
    ```

### Testing

To run the tests, use the following command:
```bash
flutter test
```
## Environment variables for zaimuniversity app
### Environment Variables

To configure the application, create a `.env` file in the project root with the following variables:

```
# API endpoints
API_URL=your_api_url_here

# Supabase configuration
SUPABASE_URL=your_supabase_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here
SUPABASE_STORAGE_URL=your_supabase_storage_url_here

# Supabase configuration
SUPABASE_URL=YOUR_SUPABASE_URL_HERE
SUPABASE_ANON_KEY=your_supabase_anon_key_here

# Other configuration
APP_DEBUG=true
```

> **Note**: Never commit sensitive keys to public repositories. The above values are placeholders and should be replaced with your actual configuration values.
### Troubleshooting

If you encounter any issues, consider the following steps:

- Ensure you have the latest version of Flutter installed
- Check the project's dependencies in `pubspec.yaml` and update them if necessary
- Review the error logs for specific details and search for solutions in the [Flutter Documentation](https://flutter.dev/docs)
- For Supabase storage-related issues (particularly the "admin_ensure_bucket_exists" error), see our [Storage Troubleshooting Guide](lib/docs/supabase_storage_troubleshooting.md)

For further assistance, feel free to open an issue in the repository.

### Developer Resources

The following troubleshooting guides are available for common issues:

- **Supabase Storage Issues**: See [Supabase Storage Troubleshooting](lib/docs/supabase_storage_troubleshooting.md) for solutions to storage-related problems.
- **Teacher Schedule Issues**: See [Teacher Schedule Troubleshooting](lib/docs/teacher_schedule_troubleshooting.md) for solutions to schedule-related problems.

For additional documentation, check the complete guides in the [docs directory](lib/docs/).

### Architecture

The application follows a clean architecture pattern:

- **Presentation Layer**: Contains UI components (screens and widgets)
- **Business Logic Layer**: Handles the application's business rules
- **Data Layer**: Manages data access and persistence

### Folder Structure

```
lib/
├── main.dart           # Entry point with login screen
├── screens/            # Application screens (dashboard, courses, profile, etc.)
├── widgets/            # Reusable UI components
├── models/             # Data models
├── services/           # Business logic and API services
├── utils/              # Utility functions and helpers
└── constants/          # App-wide constants
```

### Contributors

This project was developed by Istanbul Zaim University Computer Science students as part of the Mobile Applications course:

- **Arsim Ajvazi,Vladyslav Shaposhnikov**: UI/UX Design & Frontend Development
- **Arsim Ajvazi**: Backend Integration & Authentication
- **Vladyslav Shaposhnikov**: Testing & Documentation

### Contributing

We welcome contributions to the Zaim University Campus Information System! To ensure a smooth collaboration experience, please follow these guidelines:

#### Branching Strategy

1. **Main Branch**: The `main` branch contains the stable production version of the application. Direct commits to this branch are not allowed.

2. **Feature Branches**: For each new feature, bug fix, or improvement:
   - Create a new branch from `main` with a descriptive name following the pattern:
     - `feature/feature-name` for new features
     - `bugfix/issue-description` for bug fixes
     - `improvement/description` for improvements
   - Example: `feature/course-calendar-integration` or `bugfix/login-validation`

3. **One Change, One Branch**: Each change, regardless of size, should be isolated in its own branch.

#### Issue Tracking

1. **Create an Issue First**: Before starting work on any change:
   - Open an issue in the repository describing the proposed change
   - Include the purpose, implementation details, and expected outcomes
   - Add relevant labels (enhancement, bug, documentation, etc.)

2. **Discussion**: Use the issue comments to discuss the proposed changes with team members before implementation.

3. **Implementation**: After reaching consensus in the issue discussion:
   - Reference the issue number in your branch name when possible
   - Example: `feature/42-course-calendar-integration` for issue #42

#### Pull Request Process

1. Once your changes are ready:
   - Ensure tests pass locally
   - Update documentation if necessary
   - Submit a pull request from your feature branch to `main`
   - Reference the issue number in the PR description

2. Code Review:
   - At least one team member must approve the PR before merging
   - Address any feedback or requested changes

By following these guidelines, we maintain a clean, organized codebase and ensure that all changes are properly discussed, documented, and reviewed.

### License

This project is licensed under a strict Proprietary License that grants usage rights EXCLUSIVELY to the original contributors (Arsim Ajvazi and Vladyslav Shaposhnikov).

**IMPORTANT NOTICE:** Istanbul Zaim University is EXPRESSLY PROHIBITED from using, copying, modifying, distributing, or creating derivative works from this software under any circumstances. This prohibition extends to all departments, faculties, staff, and affiliates of the university. This project was created solely for educational demonstration purposes as part of coursework and cannot be appropriated by the university for any official or unofficial use.

This is not an open-source project. Any unauthorized use may be subject to legal action. See the `LICENSE` file for complete details.

### Acknowledgements

Special thanks to the Faculty of Computer Science at Istanbul Zaim University for their guidance and support throughout the development of this application.

### Recent Updates

#### May 14, 2025
- **Fixed Teacher Schedule SQL Error**: Corrected the RLS policies in the teacher schedule schema that were referencing a non-existent column `user_id`. The policies now correctly reference the `id` column in the users table.
- **Fixed Teacher Profile Query**: Fixed the teacher schedule service to use `id` instead of `user_id` when querying for teacher profiles, matching the actual database structure.
- **Updated Troubleshooting Documentation**: Enhanced the teacher schedule troubleshooting guide with information about column reference errors and their solutions.
