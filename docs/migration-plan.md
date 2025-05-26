# Documentation Migration Plan

This document outlines the plan for migrating documentation from the current `lib/docs` folder to the new structured documentation system.

## Current Structure

The current documentation is located in `lib/docs/` with no clear organization:

- SQL scripts and database schema information mixed together
- Troubleshooting guides scattered across different files
- No separation between user guides and developer documentation

## New Structure

The new documentation structure is organized as follows:

- `docs/database/` - Database documentation including schema, ERD, etc.
- `docs/backend/` - Backend architecture and Supabase integration
- `docs/frontend/` - UI components, screens, and design guidelines
- `docs/user-guides/` - End-user guides for each role
- `docs/api/` - API documentation and service specifications
- `docs/troubleshooting/` - Common issues and solutions
- `docs/development/` - Development guidelines and practices
- `docs/assets/` - Documentation resources like images

## Migration Steps

### 1. Database Documentation

- [x] Create `docs/database/schema.md` from `lib/docs/database_schema.md`
- [ ] Create `docs/database/erd.md` with visual representation of the database
- [ ] Migrate all SQL scripts to `docs/database/sql/` directory
  - [ ] `database_schema_fix.sql`
  - [ ] `course_rls_policies.sql`
  - [ ] `student_schedule_schema.sql`
  - [ ] `teacher_schedule_schema.sql`
  - [ ] `supabase_rls_profiles.sql`
  - [ ] `supabase_admin_functions.sql`

### 2. Troubleshooting Guides

- [x] Create `docs/troubleshooting/teacher-schedule.md` from `lib/docs/teacher_schedule_troubleshooting.md`
- [ ] Create `docs/troubleshooting/supabase-storage.md` from `lib/docs/supabase_storage_troubleshooting.md`
- [ ] Add additional troubleshooting guides for common issues

### 3. User Guides

- [ ] Create role-based guides:
  - [ ] Student guide
  - [ ] Teacher guide
  - [ ] Supervisor guide
  - [ ] Administrator guide
- [ ] Create feature-based guides:
  - [ ] Profile management from `lib/docs/profile_management.md`
  - [ ] Storage usage from `lib/docs/supabase_storage_implementation.md`

### 4. API Documentation

- [ ] Document auth service API
- [ ] Document course service API
- [ ] Document schedule service API
- [ ] Document user service API

### 5. Development Guidelines

- [ ] Create coding standards document
- [ ] Create contribution guide
- [ ] Document testing procedures

## Timeline

1. Complete initial structure setup - ✅ Done
2. Migrate database documentation - Priority 1
3. Migrate troubleshooting guides - Priority 2
4. Create user guides - Priority 3
5. Develop API documentation - Priority 4
6. Add development guidelines - Priority 5

## Additional Notes

- Keep both documentation systems in sync during migration
- Update README.md links to point to new documentation location
- Review all cross-references between documents
- Update any code comments that reference old documentation paths 