--Tables:

--1-Users Table:
Create table users(
 userId serial primary key,
 username varchar(100) not null,
 email varchar(100) UNIQUE,
 password_hash text
);

--2-Sessions:
 CREATE TABLE sessions (
  sid VARCHAR NOT NULL PRIMARY KEY,                  -- Session ID
  sess JSONB NOT NULL,                               -- Session data (stored as JSONB)
  expire TIMESTAMP NOT NULL                        -- Expiration time of the session
);


--3- User Plans Table (Stores the plan metadata)
CREATE TABLE IF NOT EXISTS user_plans (
    plan_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(userid) ON DELETE CASCADE,
    plan_name VARCHAR(100) DEFAULT 'My Workout Plan',
    goal VARCHAR(100),
    duration_weeks INTEGER,
    deadline TIMESTAMP,
    current_weight NUMERIC(5, 2),
    goal_weight NUMERIC(5, 2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

--4- Plan Exercises Table (Stores the specific exercises for each plan)
-- This links back to the plan_id and stores details like duration and days.
CREATE TABLE IF NOT EXISTS plan_exercises (
    exercise_id SERIAL PRIMARY KEY,
    plan_id INTEGER REFERENCES user_plans(plan_id) ON DELETE CASCADE,
    category VARCHAR(50),      -- e.g., 'Cardio', 'Yoga'
    exercise_name VARCHAR(100), -- e.g., 'Running', 'Downward Dog'
    duration VARCHAR(50),      -- e.g., '30 mins'
    days TEXT[],               -- Array of strings, e.g., {'Mon', 'Wed', 'Fri'}
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
--update the users tables:
ALTER TABLE users 
  ADD COLUMN gender VARCHAR(10) CHECK (gender IN ('male', 'female')),
  ADD COLUMN birthdate DATE,
  ADD COLUMN weight NUMERIC(5, 2), -- Supports decimals like 75.5 kg
  ADD COLUMN height NUMERIC(5, 2); -- Supports decimals like 180.5 cm

 -- This makes your Login query (WHERE username = ...) much faster
CREATE INDEX idx_users_username ON users(username); 
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_gender_check;

--update the user-plans table:
ALTER TABLE user_plans 
  ADD COLUMN goal VARCHAR(100),
  ADD COLUMN duration_weeks INTEGER,
  ADD COLUMN deadline TIMESTAMP,
  ADD COLUMN current_weight NUMERIC(5, 2),
  ADD COLUMN goal_weight NUMERIC(5, 2);

--5- exercise_completions (Tracks progress)

CREATE TABLE IF NOT EXISTS exercise_completions (
    completion_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(userid) ON DELETE CASCADE,
    plan_id INTEGER REFERENCES user_plans(plan_id) ON DELETE CASCADE,
    exercise_name VARCHAR(100),
    completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Ensure schema updates are applied if tables already exist
ALTER TABLE user_plans ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
ALTER TABLE exercise_completions ADD COLUMN IF NOT EXISTS exercise_id INTEGER REFERENCES plan_exercises(exercise_id) ON DELETE CASCADE;



--update the table users
ALTER TABLE users 
DROP CONSTRAINT users_gender_check;
