-- Users Table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT auth.uid(),
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash TEXT,
  phone VARCHAR(20),
  role VARCHAR(20) NOT NULL CHECK (role IN ('admin', 'user')),
  name VARCHAR(255),
  profile_image TEXT,
  email_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  last_login TIMESTAMP,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Quizzes Table
CREATE TABLE quizzes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  category VARCHAR(100) NOT NULL,
  total_questions INTEGER NOT NULL,
  duration_seconds INTEGER NOT NULL,
  -- Legacy (kept for backward compatibility)
  price DECIMAL(10, 2),
  is_paid BOOLEAN DEFAULT FALSE,
  -- New: Points system
  points_cost INTEGER NOT NULL DEFAULT 0,
  total_marks INTEGER NOT NULL DEFAULT 0,
  status VARCHAR(20) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
  difficulty INTEGER CHECK (difficulty >= 1 AND difficulty <= 5),
  thumbnail_url TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  published_at TIMESTAMP,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Questions Table
CREATE TABLE questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_id UUID NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
  question_text TEXT NOT NULL,
  question_number INTEGER NOT NULL,
  marks INTEGER NOT NULL DEFAULT 1,
  time_limit_seconds INTEGER NOT NULL DEFAULT 60,
  image_url TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Answers Table
CREATE TABLE answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  answer_text TEXT NOT NULL,
  answer_number INTEGER NOT NULL,
  is_correct BOOLEAN NOT NULL DEFAULT FALSE,
  explanation TEXT,
  image_url TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- User Answers (Quiz Responses)
CREATE TABLE user_answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  quiz_id UUID NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  selected_answer_id UUID REFERENCES answers(id) ON DELETE SET NULL,
  is_correct BOOLEAN NOT NULL,
  time_spent_seconds INTEGER DEFAULT 0,
  answered_at TIMESTAMP DEFAULT NOW()
);

-- Quiz Results (Quiz Attempt Summary)
CREATE TABLE quiz_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  quiz_id UUID NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
  total_questions INTEGER NOT NULL,
  correct_answers INTEGER NOT NULL,
  marks_obtained INTEGER NOT NULL,
  total_marks INTEGER NOT NULL,
  accuracy DECIMAL(5, 2) NOT NULL,
  time_taken_seconds INTEGER NOT NULL,
  max_time_seconds INTEGER NOT NULL,
  question_results JSONB NOT NULL DEFAULT '[]',
  attempted_at TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- User Points
CREATE TABLE user_points (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  daily_points INTEGER DEFAULT 0,
  weekly_points INTEGER DEFAULT 0,
  total_points INTEGER DEFAULT 0,
  last_updated TIMESTAMP DEFAULT NOW()
);

-- Payments Table
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  quiz_id UUID REFERENCES quizzes(id) ON DELETE SET NULL,
  amount DECIMAL(10, 2) NOT NULL,
  payment_method VARCHAR(50) NOT NULL CHECK (payment_method IN ('upi', 'card', 'wallet', 'net_banking')),
  status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed')),
  transaction_id VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Subscriptions Table
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plan VARCHAR(20) NOT NULL CHECK (plan IN ('daily', 'weekly', 'monthly', 'yearly')),
  amount DECIMAL(10, 2) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  payment_id UUID REFERENCES payments(id) ON DELETE SET NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Agreements Table
CREATE TABLE agreements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  document_url TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP
);

-- User Agreements (Acceptance Tracking)
CREATE TABLE user_agreements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  agreement_id UUID NOT NULL REFERENCES agreements(id) ON DELETE CASCADE,
  accepted BOOLEAN NOT NULL DEFAULT FALSE,
  accepted_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, agreement_id)
);

-- Create Indexes for Performance
CREATE INDEX idx_quizzes_admin_id ON quizzes(admin_id);
CREATE INDEX idx_quizzes_status ON quizzes(status);
CREATE INDEX idx_questions_quiz_id ON questions(quiz_id);
CREATE INDEX idx_answers_question_id ON answers(question_id);
CREATE INDEX idx_user_answers_user_id ON user_answers(user_id);
CREATE INDEX idx_user_answers_quiz_id ON user_answers(quiz_id);
CREATE INDEX idx_quiz_results_user_id ON quiz_results(user_id);
CREATE INDEX idx_quiz_results_quiz_id ON quiz_results(quiz_id);
CREATE INDEX idx_quiz_results_user_quiz ON quiz_results(user_id, quiz_id);
CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_is_active ON subscriptions(is_active);
CREATE INDEX idx_user_agreements_user_id ON user_agreements(user_id);

-- Row Level Security (RLS) Policies

-- Users Table RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile" 
  ON users FOR SELECT
  USING (auth.uid() = id);


-- Quizzes Table RLS
ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage own quizzes"
  ON quizzes FOR ALL
  USING (admin_id = auth.uid() AND EXISTS (
    SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'
  ))
  WITH CHECK (admin_id = auth.uid());

CREATE POLICY "Users can view published quizzes"
  ON quizzes FOR SELECT
  USING (status = 'published' OR admin_id = auth.uid());

-- Questions Table RLS
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage quiz questions"
  ON questions FOR ALL
  USING (EXISTS (
    SELECT 1 FROM quizzes WHERE id = quiz_id AND admin_id = auth.uid()
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM quizzes WHERE id = quiz_id AND admin_id = auth.uid()
  ));

CREATE POLICY "Users can view published quiz questions"
  ON questions FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM quizzes WHERE id = quiz_id AND status = 'published'
  ));

-- Answers Table RLS
ALTER TABLE answers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage answers"
  ON answers FOR ALL
  USING (EXISTS (
    SELECT 1 FROM questions q
    JOIN quizzes qu ON q.quiz_id = qu.id
    WHERE q.id = question_id AND qu.admin_id = auth.uid()
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM questions q
    JOIN quizzes qu ON q.quiz_id = qu.id
    WHERE q.id = question_id AND qu.admin_id = auth.uid()
  ));

CREATE POLICY "Users can view answers of published quizzes"
  ON answers FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM questions q
    JOIN quizzes qu ON q.quiz_id = qu.id
    WHERE q.id = question_id AND qu.status = 'published'
  ));

-- User Answers Table RLS
ALTER TABLE user_answers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own answers"
  ON user_answers FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Quiz Results Table RLS
ALTER TABLE quiz_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own quiz results"
  ON quiz_results FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can create own quiz results"
  ON quiz_results FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own quiz results"
  ON quiz_results FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can view all quiz results"
  ON quiz_results FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'
  ));

-- User Points Table RLS
ALTER TABLE user_points ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own points"
  ON user_points FOR SELECT
  USING (user_id = auth.uid());

-- Payments Table RLS
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own payments"
  ON payments FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Admins can view all payments"
  ON payments FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'
  ));

-- Subscriptions Table RLS
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own subscriptions"
  ON subscriptions FOR SELECT
  USING (user_id = auth.uid());

-- Agreements Table RLS
ALTER TABLE agreements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can view active agreements"
  ON agreements FOR SELECT
  USING (is_active = TRUE);

CREATE POLICY "Admins can manage agreements"
  ON agreements FOR ALL
  USING (EXISTS (
    SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'
  ));

-- User Agreements Table RLS
ALTER TABLE user_agreements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own agreement acceptances"
  ON user_agreements FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Enable pgcrypto for hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Store email OTPs for login verification
CREATE TABLE IF NOT EXISTS email_otps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  otp_hash TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  used BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_email_otps_user_id ON email_otps(user_id);
CREATE INDEX IF NOT EXISTS idx_email_otps_expires_at ON email_otps(expires_at);

-- RPC: create application user (stores hashed password)
CREATE OR REPLACE FUNCTION rpc_create_app_user(p_email TEXT, p_password_hash TEXT, p_role TEXT DEFAULT 'user')
RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_exists UUID;
  v_id UUID;
BEGIN
  SELECT id INTO v_exists FROM users WHERE email = p_email;
  IF v_exists IS NOT NULL THEN
    RAISE EXCEPTION 'user_exists';
  END IF;
  INSERT INTO users(id, email, password_hash, role, created_at, updated_at)
  VALUES (gen_random_uuid(), p_email, p_password_hash, p_role, NOW(), NOW())
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$;

-- RPC: generate an OTP for given email (returns plaintext OTP so the caller can send it via email)
-- NOTE: In production, call this function from a trusted server/Edge Function and send the OTP via SMTP/SendGrid.
CREATE OR REPLACE FUNCTION rpc_generate_email_otp(p_email TEXT)
RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_user_id UUID;
  v_otp TEXT;
  v_otp_hash TEXT;
BEGIN
  SELECT id INTO v_user_id FROM users WHERE email = p_email;
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'user_not_found';
  END IF;
  v_otp := lpad((floor(random() * 900000)::int + 100000)::text, 6, '0');
  v_otp_hash := crypt(v_otp, gen_salt('bf'));
  INSERT INTO email_otps(id, user_id, otp_hash, expires_at, used, created_at)
  VALUES (gen_random_uuid(), v_user_id, v_otp_hash, NOW() + INTERVAL '10 minutes', FALSE, NOW());
  RETURN v_otp;
END;
$$;

-- RPC: verify OTP for an email. Returns boolean indicating success.
CREATE OR REPLACE FUNCTION rpc_verify_email_otp(p_email TEXT, p_otp TEXT)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_user_id UUID;
  v_rec RECORD;
BEGIN
  SELECT id INTO v_user_id FROM users WHERE email = p_email;
  IF v_user_id IS NULL THEN
    RETURN FALSE;
  END IF;
  SELECT * INTO v_rec FROM email_otps
  WHERE user_id = v_user_id AND used = FALSE AND expires_at >= NOW()
  ORDER BY created_at DESC LIMIT 1;
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;
  IF crypt(p_otp, v_rec.otp_hash) = v_rec.otp_hash THEN
    UPDATE email_otps SET used = TRUE WHERE id = v_rec.id;
    RETURN TRUE;
  END IF;
  RETURN FALSE;
END;
$$;

-- NOTE: Email delivery should be implemented by an Edge Function or server-side worker that calls
-- `rpc_generate_email_otp(email)` to create an OTP, then sends the returned OTP to the user's email.
-- The mobile client should call the Edge Function to request an OTP, then call `rpc_verify_email_otp` to verify.

