# API Documentation

This directory contains documentation for the APIs and services used in the Istanbul Zaim University Campus Information System.

## Service APIs

- [Auth Service](auth-service.md) - Authentication and user management
- [Course Service](course-service.md) - Course management operations
- [Schedule Service](schedule-service.md) - Scheduling and calendar functions
- [User Service](user-service.md) - User profile management
- [Storage Service](storage-service.md) - File storage and management

## Interfaces

The system is built around these core service interfaces:

- **IAuthService** - Authentication operations
- **ICourseService** - Course management 
- **IScheduleService** - Schedule management
- **IUserService** - User profile operations
- **IStorageService** - File storage operations

## Implementations

Each service interface has concrete implementations:

- **Supabase implementations** - Primary backend services using Supabase
- **Mock implementations** - Used for testing
- **Decorator implementations** - Add caching and logging

## Authentication

All API requests (except for login/registration) require authentication:

- JWT tokens issued at login
- All requests must include the token in Authorization header
- Token expiration and refresh mechanisms

## Error Handling

The API follows these error handling conventions:

- HTTP status codes for result status
- Standardized error response format
- Detailed error messages in development mode
- Generic error messages in production

## Rate Limiting

API endpoints have rate limiting to prevent abuse:

- 100 requests per minute for most endpoints
- 10 requests per minute for authentication endpoints
- 30 requests per minute for file upload endpoints 