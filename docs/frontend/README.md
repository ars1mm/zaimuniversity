# Frontend Documentation

This directory contains documentation for the frontend components of the Istanbul Zaim University Campus Information System.

## Architecture

The Campus Information System follows a screen-based architecture with shared widgets and services. The UI is built with Flutter and follows material design principles with a custom theme.

## Directory Structure

- **[Screens](screens.md)** - Documentation for all application screens
- **[Widgets](widgets.md)** - Reusable UI components
- **[State Management](state-management.md)** - How state is managed across the application
- **[Navigation](navigation.md)** - Navigation system and route management
- **[Theming](theming.md)** - Theme configuration and customization
- **[Assets](assets.md)** - Icons, images, and other assets

## Key Components

### Screens

The application contains several key screens:

- **Login Screen** - Authentication entry point
- **Dashboard** - Main interface for users based on role
- **Course Management** - Creating and managing courses
- **Teacher Schedule** - Calendar view for teacher schedules
- **Profile Management** - User profile settings and information

### Widgets

Common widgets used across the application:

- **CustomAppBar** - Consistent navigation header
- **CourseCard** - Display course information
- **LoadingIndicator** - Standardized loading spinner
- **ErrorDisplay** - Consistent error messaging
- **CustomButton** - Styled buttons following design system

### Services

The frontend interacts with these services:

- **AuthService** - Manages authentication state
- **CourseService** - Handles course operations
- **ScheduleService** - Manages schedule data
- **UserService** - User profile operations
- **StorageService** - File storage operations

## Testing

Frontend testing includes:

- **Widget Tests** - Testing individual UI components
- **Integration Tests** - Testing screen flows
- **Mock Services** - Testing without backend dependencies

## Design Guidelines

The application follows these design principles:

- Consistent color scheme based on university branding
- Responsive layouts for different screen sizes
- Accessible UI elements with proper contrast
- Clear hierarchy and visual organization
- Intuitive navigation patterns 