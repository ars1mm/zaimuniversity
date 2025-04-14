# Istanbul Zaim University - Campus Information System

## Overview
This application provides a digital Campus Information System for Istanbul Zaim University students and faculty. Built with Flutter, the app enables users to access university resources, course information, and campus services through a clean and intuitive interface.

## Features
- **User Authentication**: Secure login system for students and faculty members
- **Course Management**: View enrolled courses, schedules, and materials
- **Campus Resources**: Access to university news, events, and announcements
- **Student Information**: Personal academic records and profile management
- **Advisor Communication**: Direct contact with academic advisors
- **Cross-Platform Support**: Built with Flutter, the app runs on both Android and iOS
- **Responsive Design**: Optimized for both phone and tablet interfaces

## Project Structure
```
zaimuniversity/
├── lib/
│   ├── main.dart              # Application entry point
│   ├── constants/             # App-wide constants and configuration
│   ├── models/                # Data models and state management
│   ├── screens/               # UI screens and pages
│   ├── services/              # API and backend services
│   ├── utils/                 # Utility functions and helpers
│   └── widgets/               # Reusable UI components
├── android/                   # Android-specific configuration
├── ios/                       # iOS-specific configuration
├── web/                       # Web platform support
└── env/                       # Environment configuration
```

## Development Rules
- **Code Organization**: 
  - Follow the established project structure
  - Place files in appropriate directories based on functionality
  - Maintain separation of concerns (UI, business logic, data access)

- **State Management**:
  - Use the project's chosen state management solution consistently
  - Avoid mixing different state management approaches
  - Keep state changes predictable and trackable

- **Error Handling**:
  - Implement proper error handling for all asynchronous operations
  - Display user-friendly error messages
  - Log errors appropriately for debugging

- **UI/UX Guidelines**:
  - Follow the university's brand guidelines for colors and typography
  - Maintain consistent UI elements across the application
  - Ensure accessibility compliance (contrast, text size, screen readers)

- **Performance**:
  - Optimize images and assets
  - Implement pagination for long lists
  - Minimize unnecessary rebuilds in the widget tree
  - Cache appropriate data to reduce network requests

- **Security**:
  - Never store sensitive information in plain text
  - Implement proper authentication checks for protected routes
  - Validate all user inputs
  - Use secure connection protocols (HTTPS)
  - Follow Supabase security best practices

- **Testing**:
  - Write unit tests for business logic and services
  - Create widget tests for UI components
  - Implement integration tests for critical user flows
  - Maintain test coverage for new features

- **Version Control**:
  - Write clear, descriptive commit messages
  - Create feature branches for new development
  - Review code before merging to main branches
  - Tag important releases

## API Endpoints

### Authentication
- **POST /auth/signup**: Register a new user
  - Parameters: email, password, fullName, studentId
  - Returns: session token, user data
- **POST /auth/login**: Authenticate existing user
  - Parameters: email, password
  - Returns: session token, user data
- **POST /auth/reset-password**: Request password reset
  - Parameters: email
  - Returns: success status
- **GET /auth/user**: Get current authenticated user
  - Headers: Authorization token
  - Returns: user profile data

### Admin Protected Routes
- **GET /admin/dashboard**: Access admin dashboard statistics
  - Headers: Authorization token with admin privileges
  - Returns: system statistics, user counts, activity metrics
- **GET /admin/users**: List all users in the system
  - Headers: Authorization token with admin privileges
  - Parameters: role, status, limit, offset (all optional)
  - Returns: array of user objects with detailed information
- **PUT /admin/users/{id}**: Update user information and privileges
  - Headers: Authorization token with admin privileges
  - Parameters: role, status, permissions
  - Returns: updated user object
- **DELETE /admin/users/{id}**: Remove a user from the system
  - Headers: Authorization token with admin privileges
  - Returns: operation success status
- **POST /admin/teachers**: Create a new teacher account
  - Headers: Authorization token with admin privileges
  - Parameters: email, password, fullName, department, specialization, contactInfo
  - Returns: created teacher object with credentials
- **DELETE /admin/teachers/{id}**: Remove a teacher from the system
  - Headers: Authorization token with admin privileges
  - Parameters: transferCoursesTo (optional, teacher ID to transfer active courses)
  - Returns: operation success status and affected courses

### Course Administration (Admin Only)
- **POST /admin/courses**: Create a new course
  - Headers: Authorization token with admin privileges
  - Parameters: title, description, schedule, capacity, instructorId, departmentId
  - Returns: created course object
- **PUT /admin/courses/{id}**: Update course details
  - Headers: Authorization token with admin privileges
  - Parameters: title, description, schedule, capacity, instructorId, status
  - Returns: updated course object
- **POST /admin/courses/{id}/materials**: Upload course materials (PDF only)
  - Headers: Authorization token with admin privileges
  - Parameters: title, description, file (PDF only, max 20MB)
  - Returns: uploaded material object with download URL
  - Note: Only PDF files are accepted for course materials
- **DELETE /admin/courses/{id}/materials/{materialId}**: Remove course material
  - Headers: Authorization token with admin privileges
  - Returns: operation success status
- **GET /admin/courses/analytics**: Get course enrollment statistics
  - Headers: Authorization token with admin privileges
  - Parameters: departmentId, semester (all optional)
  - Returns: enrollment statistics, completion rates, average grades
- **GET /admin/courses/{id}/students**: List all students enrolled in a specific course
  - Headers: Authorization token with admin privileges
  - Parameters: sortBy, order (all optional)
  - Returns: array of student objects with enrollment details and performance metrics

### Teacher Endpoints
- **GET /teachers/courses**: List all courses taught by the current teacher
  - Headers: Authorization token with teacher privileges
  - Parameters: semester, status (all optional)
  - Returns: array of course objects with enrollment counts
- **POST /teachers/courses**: Create a new course (requires approval)
  - Headers: Authorization token with teacher privileges
  - Parameters: title, description, schedule, capacity, departmentId
  - Returns: created course object with pending status
- **PUT /teachers/courses/{id}**: Update details for a course taught by the teacher
  - Headers: Authorization token with teacher privileges
  - Parameters: title, description, schedule, materials
  - Returns: updated course object
- **POST /teachers/courses/{id}/materials**: Upload course materials (PDF only)
  - Headers: Authorization token with teacher privileges
  - Parameters: title, description, file (PDF only, max 20MB)
  - Returns: uploaded material object with download URL
  - Note: Only PDF files are accepted for course materials
- **DELETE /teachers/courses/{id}/materials/{materialId}**: Remove course material
  - Headers: Authorization token with teacher privileges
  - Returns: operation success status
- **GET /teachers/courses/{id}/students**: List all students in teacher's course
  - Headers: Authorization token with teacher privileges
  - Parameters: sortBy, order (all optional)
  - Returns: array of student objects with grades and participation metrics
- **POST /teachers/courses/{id}/homework**: Create a new homework assignment
  - Headers: Authorization token with teacher privileges
  - Parameters: title, description, dueDate, totalPoints, attachments
  - Returns: created homework object
- **PUT /teachers/courses/{id}/homework/{homeworkId}**: Update a homework assignment
  - Headers: Authorization token with teacher privileges
  - Parameters: title, description, dueDate, totalPoints, attachments
  - Returns: updated homework object
- **DELETE /teachers/courses/{id}/homework/{homeworkId}**: Remove a homework assignment
  - Headers: Authorization token with teacher privileges
  - Returns: operation success status
- **POST /teachers/courses/{id}/homework/{homeworkId}/grades**: Submit grades for a homework assignment
  - Headers: Authorization token with teacher privileges
  - Parameters: grades (array of {studentId, score, feedback})
  - Returns: submission status and summary

### Student Information
- **GET /students/{id}**: Retrieve specific student details
  - Headers: Authorization token with admin or teacher privileges only
  - Access Control: Students can only access their own information
  - Returns: student profile, enrollment status, academic standing
- **GET /students/current**: Get logged-in student information
  - Headers: Authorization token
  - Returns: complete student profile, contact info, enrollment data
- **PUT /students/current**: Update student information
  - Headers: Authorization token
  - Parameters: contactInfo, address, preferences
  - Returns: updated student object
- **GET /students/current/transcripts**: Get student's academic transcripts
  - Headers: Authorization token
  - Parameters: semester (optional)
  - Returns: course grades, GPA, credits earned

### Course Management
- **GET /courses**: List all available courses
  - Parameters: semester, department, searchQuery (all optional)
  - Returns: array of course objects
- **GET /courses/{id}**: Get specific course details
  - Returns: course description, schedule, instructor, capacity
- **GET /students/current/courses**: Get enrolled courses for current student
  - Headers: Authorization token
  - Returns: array of enrolled courses with grades and materials
- **POST /courses/{id}/enroll**: Enroll in a course
  - Headers: Authorization token
  - Returns: enrollment status, updated schedule

### Campus Resources

## Access Role Hierarchy

The system implements a hierarchical access control model with the following roles (from highest to lowest privileges):
1. **Admin**: Complete system access, managing users, courses, and system configuration
2. **Supervisor**: Department-level oversight, approves courses, monitors teacher performance
3. **Teacher**: Course management and student assessment within assigned courses
4. **Student**: Access to personal information, course enrollment, and learning materials

### Supervisor Protected Routes
- **GET /supervisor/dashboard**: Access supervisor dashboard statistics
  - Headers: Authorization token with supervisor privileges
  - Returns: department statistics, teacher metrics, course status
- **GET /supervisor/departments/{id}/teachers**: List teachers in a department
  - Headers: Authorization token with supervisor privileges
  - Parameters: status, specialization (all optional)
  - Returns: array of teacher objects with performance metrics
- **GET /supervisor/departments/{id}/courses**: List courses in a department
  - Headers: Authorization token with supervisor privileges
  - Parameters: status, semester (all optional) 
  - Returns: array of course objects with enrollment and performance data
- **PUT /supervisor/courses/{id}/approve**: Approve a pending course
  - Headers: Authorization token with supervisor privileges
  - Parameters: feedback, modifications (all optional)
  - Returns: updated course object with approved status
- **PUT /supervisor/courses/{id}/reject**: Reject a pending course
  - Headers: Authorization token with supervisor privileges
  - Parameters: reason, feedback (required)
  - Returns: updated course object with rejected status

## User Interface Requirements

### Navigation
- **Drawer Navigation**: 
  - After successful login, a drawer navigation menu appears on the left side of the screen
  - Drawer content is role-specific (different for admin, supervisor, teacher, and student users)
  - Drawer provides access to all role-appropriate features and screens
  - Consistent design with university branding throughout the drawer

### Error Handling
- **Authentication Errors**: 
  - The only authentication error message should be "Wrong email or Password"
  - No detailed error information should be exposed to users for security reasons
- **Form Validation**: 
  - Form fields should have appropriate validation with clear instructions
  - Error states should be visually indicated without exposing system details

## Environment Configuration

All configuration values, especially sensitive ones like API keys and database credentials, must be stored in the `.env` file and loaded using environment variables. This includes:

- Supabase URL and anonymous key
- API endpoints
- Debug settings
- Other configuration parameters

### Using Environment Variables

Always load environment variables instead of hardcoding values:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Load environment variables
await dotenv.load();

// Initialize Supabase with values from environment
await Supabase.initialize(
  url: dotenv.env['SUPABASE_URL']!,
  anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
);
```

### Best Practices

1. Never commit sensitive keys directly in code
2. The `.env` file should be included in `.gitignore` to prevent accidental exposure of credentials
3. Provide a template `.env.example` file with placeholder values for other developers
4. Always validate that environment variables exist before using them
5. Use appropriate error handling for missing environment variables

## Project Grading Criteria

### 1. Functionality (55%)
- **Working Status (40%)**: Application must run without crashes and be free of critical bugs
- **Basic Functions (10%)**: All basic features specific to the project topic (JSON handling, API calls, Supabase integration) must be complete and functional
- **User Interaction (5%)**: All interactive elements (buttons, drawer navigation, app bar) must work smoothly and responsively

### 2. Code Quality and Architecture (20%)
- **Clean Code (10%)**: Code must use meaningful variable names, include appropriate comments, and avoid unnecessary repetition
- **Modularity (10%)**: Code should be properly divided into components (widgets, services, models) and maximize reusability

### 3. User Interface (UI/UX) (10%)
- **Usability (5%)**: UI must be intuitive, easy to learn, and user-friendly
- **Pages (5%)**: All required screens and pages must be complete and functional

### 4. Project Report and Documentation (10%)
- **Documentation Content (5%)**: Project purpose, technical details, and prominent features must be clearly documented
- **Contribution Distribution (5%)**: For team projects, each member's role and contributions must be specified

### 5. Originality and Complexity (5%)
- **Creative Approach (5%)**: Project should present original ideas/solutions beyond a standard implementation

### Extra Points (Optional: +5%)
- Additional points may be awarded for exceptional overall project quality, innovation, or going beyond requirements

## Technical Details
- **Framework**: Flutter
- **Language**: Dart
- **Platform Priority**: Mobile platforms (Android and iOS) should be prioritized over web implementation
- **Backend & Database**: Supabase for backend services, authentication, and database functionality
- **State Management**: [Specify your choice: Provider/Bloc/Riverpod/etc]
- **Authentication**: Secure token-based authentication handled by Supabase Auth
- **Local Storage**: Persistent storage for user preferences and cached data
- **Responsive Design**: Primary focus on mobile screens, with tablet support as secondary priority

## Development Guidelines
- Mobile-first development approach, prioritize Android and iOS functionality
- Focus on native mobile user experiences and platform-specific best practices
- Follow Flutter best practices for code organization and structure
- Use meaningful variable and function names
- Document complex functions and components
- Write unit tests for critical functionality
- Maintain consistent code formatting (using `flutter format`)
- Handle errors gracefully with user-friendly messages

## Database Structure for Supabase

### Recommended Supabase Tables

#### 1. Users
This table will store all user accounts across different roles.
- `id` (UUID, primary key)
- `email` (string, unique)
- `password_hash` (string) - Supabase handles this automatically
- `full_name` (string)
- `role` (enum: 'admin', 'supervisor', 'teacher', 'student')
- `status` (enum: 'active', 'inactive', 'suspended')
- `created_at` (timestamp)
- `updated_at` (timestamp)

#### 2. Students
This table extends the Users table with student-specific information.
- `id` (UUID, primary key, references users.id)
- `student_id` (string, unique)
- `department_id` (UUID, foreign key)
- `address` (string)
- `contact_info` (JSON)
- `enrollment_date` (date)
- `academic_standing` (string)
- `preferences` (JSON)

#### 3. Teachers
This table extends the Users table with teacher-specific information.
- `id` (UUID, primary key, references users.id)
- `department_id` (UUID, foreign key)
- `specialization` (string)
- `contact_info` (JSON)
- `bio` (text)
- `status` (enum: 'active', 'on_leave', 'retired')

#### 4. Departments
This table stores university departments.
- `id` (UUID, primary key)
- `name` (string)
- `description` (text)
- `supervisor_id` (UUID, foreign key to users.id)

#### 5. Courses
This table stores information about university courses.
- `id` (UUID, primary key)
- `title` (string)
- `description` (text)
- `schedule` (JSON)
- `capacity` (integer)
- `instructor_id` (UUID, foreign key to teachers.id)
- `department_id` (UUID, foreign key to departments.id)
- `status` (enum: 'active', 'pending', 'rejected', 'completed', 'cancelled')
- `semester` (string)
- `created_at` (timestamp)
- `updated_at` (timestamp)
- `created_by` (UUID, foreign key to users.id)

#### 6. Course_Enrollments
This junction table tracks which students are enrolled in which courses.
- `id` (UUID, primary key)
- `student_id` (UUID, foreign key to students.id)
- `course_id` (UUID, foreign key to courses.id)
- `enrollment_date` (timestamp)
- `status` (enum: 'active', 'withdrawn', 'completed')
- `final_grade` (float, nullable)

#### 7. Course_Materials
This table stores materials/resources for courses.
- `id` (UUID, primary key)
- `course_id` (UUID, foreign key to courses.id)
- `title` (string)
- `description` (text)
- `file_url` (string)
- `file_type` (string)
- `uploaded_by` (UUID, foreign key to users.id)
- `uploaded_at` (timestamp)

#### 8. Homework_Assignments
This table stores homework assignments for courses.
- `id` (UUID, primary key)
- `course_id` (UUID, foreign key to courses.id)
- `title` (string)
- `description` (text)
- `due_date` (timestamp)
- `total_points` (float)
- `created_by` (UUID, foreign key to teachers.id)
- `created_at` (timestamp)
- `updated_at` (timestamp)

#### 9. Homework_Submissions
This table tracks student submissions for homework.
- `id` (UUID, primary key)
- `homework_id` (UUID, foreign key to homework_assignments.id)
- `student_id` (UUID, foreign key to students.id)
- `submission_url` (string)
- `submitted_at` (timestamp)
- `score` (float, nullable)
- `feedback` (text)
- `graded_by` (UUID, foreign key to teachers.id)
- `graded_at` (timestamp)

#### 10. Transcripts
This table stores student academic records.
- `id` (UUID, primary key)
- `student_id` (UUID, foreign key to students.id)
- `semester` (string)
- `gpa` (float)
- `credits_earned` (integer)
- `academic_standing` (string)
- `generated_at` (timestamp)

#### 11. Course_Approvals
This table tracks the course approval process by supervisors.
- `id` (UUID, primary key)
- `course_id` (UUID, foreign key to courses.id)
- `supervisor_id` (UUID, foreign key to users.id with role='supervisor')
- `status` (enum: 'approved', 'rejected', 'pending')
- `feedback` (text)
- `reviewed_at` (timestamp)

### Database Relationships
1. One-to-one relationship between Users and Students/Teachers
2. One-to-many relationship between Departments and Users (supervisors)
3. One-to-many relationship between Departments and Courses
4. One-to-many relationship between Teachers and Courses
5. Many-to-many relationship between Students and Courses (via Course_Enrollments)
6. One-to-many relationship between Courses and Course_Materials
7. One-to-many relationship between Courses and Homework_Assignments
8. One-to-many relationship between Homework_Assignments and Homework_Submissions
9. One-to-many relationship between Students and Transcripts
