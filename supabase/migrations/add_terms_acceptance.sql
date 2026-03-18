-- Add terms acceptance fields to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS terms_accepted BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS terms_accepted_at TIMESTAMP;

-- Add comment to document the change
COMMENT ON COLUMN users.terms_accepted IS 'Whether the user has accepted the terms of service';
COMMENT ON COLUMN users.terms_accepted_at IS 'Timestamp when the user accepted the terms of service';
