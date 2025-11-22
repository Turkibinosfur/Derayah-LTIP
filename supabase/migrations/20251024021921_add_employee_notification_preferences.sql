/*
  # Add Employee Notification Preferences

  1. New Tables
    - `employee_notification_preferences`
      - `id` (uuid, primary key)
      - `employee_id` (uuid, foreign key to employees)
      - `email_notifications` (boolean)
      - `vesting_reminders` (boolean)
      - `document_alerts` (boolean)
      - `price_alerts` (boolean)
      - `tax_reminders` (boolean)
      - `price_alert_threshold` (numeric)
      - `reminder_days_before` (integer)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Security
    - Enable RLS on `employee_notification_preferences` table
    - Add policies for employees to read and update their own preferences
*/

CREATE TABLE IF NOT EXISTS employee_notification_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  email_notifications boolean DEFAULT true,
  vesting_reminders boolean DEFAULT true,
  document_alerts boolean DEFAULT true,
  price_alerts boolean DEFAULT false,
  tax_reminders boolean DEFAULT true,
  price_alert_threshold numeric DEFAULT 0,
  reminder_days_before integer DEFAULT 7,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(employee_id)
);

ALTER TABLE employee_notification_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Employees can read own notification preferences"
  ON employee_notification_preferences FOR SELECT
  TO authenticated
  USING (
    employee_id IN (
      SELECT id FROM employees WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Employees can update own notification preferences"
  ON employee_notification_preferences FOR UPDATE
  TO authenticated
  USING (
    employee_id IN (
      SELECT id FROM employees WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    employee_id IN (
      SELECT id FROM employees WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Employees can insert own notification preferences"
  ON employee_notification_preferences FOR INSERT
  TO authenticated
  WITH CHECK (
    employee_id IN (
      SELECT id FROM employees WHERE user_id = auth.uid()
    )
  );
