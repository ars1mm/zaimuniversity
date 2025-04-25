## Zaim University Campus Information System

### Overview

This application provides a digital Campus Information System for Istanbul Zaim University students and faculty. Built with Flutter, the app enables users to access university resources, course information, and campus services through a clean and intuitive interface.

### Features

- **User Authentication**: Secure login system for students and faculty members
- **Course Management**: View enrolled courses, schedules, and materials
- **Campus Resources**: Access to university news, events, and announcements
- **Student Information**: Personal academic records and profile management
- **Advisor Communication**: Direct contact with academic advisors
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

For further assistance, feel free to open an issue in the repository.

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
