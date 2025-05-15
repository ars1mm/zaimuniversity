-- Run the password hash fix function to update the column type
SELECT fix_password_hash_type();
NOTIFY system, 'Password hash type fix has been applied';
