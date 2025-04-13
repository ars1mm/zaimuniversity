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
    git clone https://github.com/your-repo/zaimuniversity.git
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

### Troubleshooting

If you encounter any issues, consider the following steps:

- Ensure you have the latest version of Flutter installed
- Check the project's dependencies in `pubspec.yaml` and update them if necessary
- Review the error logs for specific details and search for solutions in the [Flutter Documentation](https://flutter.dev/docs)
- For university-specific login issues, contact the IT department at [it@izu.edu.tr](mailto:it@izu.edu.tr)

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

### License

This project is licensed under the MIT License. See the `LICENSE` file for more details.

### Acknowledgements

Special thanks to the Faculty of Computer Science at Istanbul Zaim University for their guidance and support throughout the development of this application.
