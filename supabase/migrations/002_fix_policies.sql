-- Fix RLS Policies Migration
-- Run this in Supabase SQL Editor to fix duplicate policies

-- ============================================
-- DROP ALL EXISTING POLICIES (Clean Slate)
-- ============================================

-- Profiles policies
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "profiles_select_own" ON profiles;
DROP POLICY IF EXISTS "profiles_insert_own" ON profiles;
DROP POLICY IF EXISTS "profiles_update_own" ON profiles;

-- Complaints policies
DROP POLICY IF EXISTS "Users can view their own complaints" ON complaints;
DROP POLICY IF EXISTS "Users can create complaints" ON complaints;
DROP POLICY IF EXISTS "Admins can view all complaints" ON complaints;
DROP POLICY IF EXISTS "Admins can update complaints" ON complaints;
DROP POLICY IF EXISTS "Users can update their own complaints" ON complaints;

-- Attachments policies
DROP POLICY IF EXISTS "Users can view attachments of their complaints" ON attachments;
DROP POLICY IF EXISTS "Users can add attachments to their complaints" ON attachments;
DROP POLICY IF EXISTS "Users can view attachments for their complaints" ON attachments;
DROP POLICY IF EXISTS "Users can insert attachments for their complaints" ON attachments;

-- Status history policies
DROP POLICY IF EXISTS "Users can view status history for their complaints" ON status_history;

-- Notifications policies
DROP POLICY IF EXISTS "Users can view their own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON notifications;

-- Departments & Categories policies
DROP POLICY IF EXISTS "Departments are viewable by everyone" ON departments;
DROP POLICY IF EXISTS "Categories are viewable by everyone" ON categories;

-- ============================================
-- DROP OLD HELPER FUNCTION IF EXISTS
-- ============================================
DROP FUNCTION IF EXISTS role_check();

-- ============================================
-- CREATE HELPER FUNCTION
-- ============================================
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS TEXT AS $$
BEGIN
    RETURN COALESCE(
        (SELECT role::TEXT FROM profiles WHERE id = auth.uid()),
        'citizen'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================
-- ENABLE RLS ON ALL TABLES
-- ============================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PROFILES POLICIES
-- ============================================

-- Allow users to read their own profile
CREATE POLICY "profiles_select_own"
ON profiles FOR SELECT
USING (auth.uid() = id);

-- Allow staff to read all profiles
CREATE POLICY "profiles_select_staff"
ON profiles FOR SELECT
USING (get_user_role() IN ('admin', 'super_admin', 'employee'));

-- CRITICAL: Allow new users to insert their own profile (for signup trigger)
CREATE POLICY "profiles_insert_own"
ON profiles FOR INSERT
WITH CHECK (auth.uid() = id);

-- Allow users to update their own profile
CREATE POLICY "profiles_update_own"
ON profiles FOR UPDATE
USING (auth.uid() = id);

-- ============================================
-- DEPARTMENTS POLICIES (Public Read)
-- ============================================
CREATE POLICY "departments_select_all"
ON departments FOR SELECT
USING (true);

CREATE POLICY "departments_manage_admin"
ON departments FOR ALL
USING (get_user_role() IN ('admin', 'super_admin'));

-- ============================================
-- CATEGORIES POLICIES (Public Read)
-- ============================================
CREATE POLICY "categories_select_all"
ON categories FOR SELECT
USING (true);

CREATE POLICY "categories_manage_admin"
ON categories FOR ALL
USING (get_user_role() IN ('admin', 'super_admin'));

-- ============================================
-- COMPLAINTS POLICIES
-- ============================================

-- Users can view their own complaints
CREATE POLICY "complaints_select_own"
ON complaints FOR SELECT
USING (user_id = auth.uid());

-- Staff can view all complaints
CREATE POLICY "complaints_select_staff"
ON complaints FOR SELECT
USING (get_user_role() IN ('admin', 'super_admin', 'employee'));

-- Users can create their own complaints
CREATE POLICY "complaints_insert_own"
ON complaints FOR INSERT
WITH CHECK (user_id = auth.uid());

-- Users can update their own complaints (limited fields)
CREATE POLICY "complaints_update_own"
ON complaints FOR UPDATE
USING (user_id = auth.uid());

-- Staff can update all complaints
CREATE POLICY "complaints_update_staff"
ON complaints FOR UPDATE
USING (get_user_role() IN ('admin', 'super_admin', 'employee'));

-- ============================================
-- ATTACHMENTS POLICIES
-- ============================================

-- Users can view attachments of their complaints
CREATE POLICY "attachments_select_own"
ON attachments FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM complaints 
        WHERE complaints.id = attachments.complaint_id 
        AND complaints.user_id = auth.uid()
    )
);

-- Staff can view all attachments
CREATE POLICY "attachments_select_staff"
ON attachments FOR SELECT
USING (get_user_role() IN ('admin', 'super_admin', 'employee'));

-- Users can add attachments to their complaints
CREATE POLICY "attachments_insert_own"
ON attachments FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM complaints 
        WHERE complaints.id = complaint_id 
        AND complaints.user_id = auth.uid()
    )
);

-- ============================================
-- STATUS HISTORY POLICIES
-- ============================================

-- Users can view status history of their complaints
CREATE POLICY "status_history_select_own"
ON status_history FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM complaints 
        WHERE complaints.id = status_history.complaint_id 
        AND complaints.user_id = auth.uid()
    )
);

-- Staff can view all status history
CREATE POLICY "status_history_select_staff"
ON status_history FOR SELECT
USING (get_user_role() IN ('admin', 'super_admin', 'employee'));

-- Staff can insert status history
CREATE POLICY "status_history_insert_staff"
ON status_history FOR INSERT
WITH CHECK (get_user_role() IN ('admin', 'super_admin', 'employee'));

-- ============================================
-- FEEDBACK POLICIES
-- ============================================

-- Users can view their own feedback
CREATE POLICY "feedback_select_own"
ON feedback FOR SELECT
USING (user_id = auth.uid());

-- Staff can view all feedback
CREATE POLICY "feedback_select_staff"
ON feedback FOR SELECT
USING (get_user_role() IN ('admin', 'super_admin', 'employee'));

-- Users can insert feedback for their complaints
CREATE POLICY "feedback_insert_own"
ON feedback FOR INSERT
WITH CHECK (user_id = auth.uid());

-- ============================================
-- NOTIFICATIONS POLICIES
-- ============================================

-- Users can view their own notifications
CREATE POLICY "notifications_select_own"
ON notifications FOR SELECT
USING (user_id = auth.uid());

-- Users can update their own notifications (mark as read)
CREATE POLICY "notifications_update_own"
ON notifications FOR UPDATE
USING (user_id = auth.uid());

-- System/staff can insert notifications
CREATE POLICY "notifications_insert_system"
ON notifications FOR INSERT
WITH CHECK (true);

-- ============================================
-- FIX THE TRIGGER FUNCTION
-- ============================================

-- Recreate the trigger function with proper error handling
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (id, email, full_name, phone)
    VALUES (
        NEW.id, 
        NEW.email, 
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        NEW.raw_user_meta_data->>'phone'
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    -- Log error but don't fail the user creation
    RAISE WARNING 'Failed to create profile for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ensure trigger exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ============================================
-- GRANT PERMISSIONS
-- ============================================

-- Grant usage on schema
GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- Grant select on public tables
GRANT SELECT ON departments TO anon, authenticated;
GRANT SELECT ON categories TO anon, authenticated;

-- Grant full access to authenticated users on their tables
GRANT ALL ON profiles TO authenticated;
GRANT ALL ON complaints TO authenticated;
GRANT ALL ON attachments TO authenticated;
GRANT ALL ON status_history TO authenticated;
GRANT ALL ON feedback TO authenticated;
GRANT ALL ON notifications TO authenticated;

-- Grant sequence usage
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- ============================================
-- CREATE PROFILES FOR EXISTING USERS
-- ============================================
-- This creates profiles for any auth.users that don't have a profile yet
-- (e.g., users created through the Supabase dashboard)

INSERT INTO profiles (id, email, full_name)
SELECT 
    u.id,
    u.email,
    COALESCE(u.raw_user_meta_data->>'full_name', split_part(u.email, '@', 1))
FROM auth.users u
LEFT JOIN profiles p ON p.id = u.id
WHERE p.id IS NULL
ON CONFLICT (id) DO NOTHING;
