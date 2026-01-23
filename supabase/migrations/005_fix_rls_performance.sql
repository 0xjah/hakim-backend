-- Migration: Fix RLS Performance Issues
-- Fixes: auth_rls_initplan, multiple_permissive_policies, unindexed_foreign_keys

-- ============================================================================
-- PART 1: Add missing indexes for foreign keys
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_categories_department_id ON categories(department_id);
CREATE INDEX IF NOT EXISTS idx_complaints_assigned_to ON complaints(assigned_to);
CREATE INDEX IF NOT EXISTS idx_complaints_category_id ON complaints(category_id);
CREATE INDEX IF NOT EXISTS idx_feedback_responded_by ON feedback(responded_by);
CREATE INDEX IF NOT EXISTS idx_feedback_user_id ON feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_complaint_id ON notifications(complaint_id);
CREATE INDEX IF NOT EXISTS idx_profiles_department_id ON profiles(department_id);
CREATE INDEX IF NOT EXISTS idx_status_history_changed_by ON status_history(changed_by);

-- ============================================================================
-- PART 2: Fix complaints table RLS policies
-- Drop existing policies and create optimized combined ones
-- ============================================================================

-- Drop existing complaints policies
DROP POLICY IF EXISTS complaints_select_own ON complaints;
DROP POLICY IF EXISTS complaints_select_staff ON complaints;
DROP POLICY IF EXISTS complaints_insert_own ON complaints;
DROP POLICY IF EXISTS complaints_update_own ON complaints;
DROP POLICY IF EXISTS complaints_update_staff ON complaints;

-- Create optimized combined SELECT policy for complaints
CREATE POLICY complaints_select_policy ON complaints
    FOR SELECT
    USING (
        user_id = (SELECT auth.uid())
        OR EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.role IN ('admin', 'super_admin', 'employee')
        )
    );

-- Create optimized INSERT policy for complaints
CREATE POLICY complaints_insert_policy ON complaints
    FOR INSERT
    WITH CHECK (user_id = (SELECT auth.uid()));

-- Create optimized combined UPDATE policy for complaints
CREATE POLICY complaints_update_policy ON complaints
    FOR UPDATE
    USING (
        user_id = (SELECT auth.uid())
        OR EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.role IN ('admin', 'super_admin', 'employee')
        )
    );

-- ============================================================================
-- PART 3: Fix attachments table RLS policies
-- ============================================================================

-- Drop existing attachments policies
DROP POLICY IF EXISTS attachments_select_own ON attachments;
DROP POLICY IF EXISTS attachments_select_staff ON attachments;
DROP POLICY IF EXISTS attachments_insert_own ON attachments;

-- Create optimized combined SELECT policy for attachments
CREATE POLICY attachments_select_policy ON attachments
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM complaints 
            WHERE complaints.id = attachments.complaint_id 
            AND complaints.user_id = (SELECT auth.uid())
        )
        OR EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.role IN ('admin', 'super_admin', 'employee')
        )
    );

-- Create optimized INSERT policy for attachments
CREATE POLICY attachments_insert_policy ON attachments
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM complaints 
            WHERE complaints.id = attachments.complaint_id 
            AND complaints.user_id = (SELECT auth.uid())
        )
    );

-- ============================================================================
-- PART 4: Fix profiles table RLS policies
-- ============================================================================

-- Drop existing profiles policies
DROP POLICY IF EXISTS profiles_select_own ON profiles;
DROP POLICY IF EXISTS profiles_select_staff ON profiles;
DROP POLICY IF EXISTS profiles_insert_own ON profiles;
DROP POLICY IF EXISTS profiles_update_own ON profiles;

-- Create optimized combined SELECT policy for profiles
CREATE POLICY profiles_select_policy ON profiles
    FOR SELECT
    USING (
        id = (SELECT auth.uid())
        OR EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = (SELECT auth.uid()) 
            AND p.role IN ('admin', 'super_admin', 'employee')
        )
    );

-- Create optimized INSERT policy for profiles
CREATE POLICY profiles_insert_policy ON profiles
    FOR INSERT
    WITH CHECK (id = (SELECT auth.uid()));

-- Create optimized UPDATE policy for profiles
CREATE POLICY profiles_update_policy ON profiles
    FOR UPDATE
    USING (id = (SELECT auth.uid()));

-- ============================================================================
-- PART 5: Fix status_history table RLS policies
-- ============================================================================

-- Drop existing status_history policies
DROP POLICY IF EXISTS status_history_select_own ON status_history;
DROP POLICY IF EXISTS status_history_select_staff ON status_history;

-- Create optimized combined SELECT policy for status_history
CREATE POLICY status_history_select_policy ON status_history
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM complaints 
            WHERE complaints.id = status_history.complaint_id 
            AND complaints.user_id = (SELECT auth.uid())
        )
        OR EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.role IN ('admin', 'super_admin', 'employee')
        )
    );

-- ============================================================================
-- PART 6: Fix feedback table RLS policies
-- ============================================================================

-- Drop existing feedback policies
DROP POLICY IF EXISTS feedback_select_own ON feedback;
DROP POLICY IF EXISTS feedback_select_staff ON feedback;
DROP POLICY IF EXISTS feedback_insert_own ON feedback;

-- Create optimized combined SELECT policy for feedback
CREATE POLICY feedback_select_policy ON feedback
    FOR SELECT
    USING (
        user_id = (SELECT auth.uid())
        OR EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.role IN ('admin', 'super_admin', 'employee')
        )
    );

-- Create optimized INSERT policy for feedback
CREATE POLICY feedback_insert_policy ON feedback
    FOR INSERT
    WITH CHECK (user_id = (SELECT auth.uid()));

-- ============================================================================
-- PART 7: Fix notifications table RLS policies
-- ============================================================================

-- Drop existing notifications policies
DROP POLICY IF EXISTS notifications_select_own ON notifications;
DROP POLICY IF EXISTS notifications_update_own ON notifications;

-- Create optimized SELECT policy for notifications
CREATE POLICY notifications_select_policy ON notifications
    FOR SELECT
    USING (user_id = (SELECT auth.uid()));

-- Create optimized UPDATE policy for notifications
CREATE POLICY notifications_update_policy ON notifications
    FOR UPDATE
    USING (user_id = (SELECT auth.uid()));

-- ============================================================================
-- PART 8: Fix departments table RLS policies
-- ============================================================================

-- Drop existing departments policies
DROP POLICY IF EXISTS departments_select_all ON departments;
DROP POLICY IF EXISTS departments_manage_admin ON departments;

-- Create single SELECT policy for departments (public read)
CREATE POLICY departments_select_policy ON departments
    FOR SELECT
    USING (true);

-- Create admin-only management policies for departments
CREATE POLICY departments_insert_policy ON departments
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.role = 'admin'
        )
    );

CREATE POLICY departments_update_policy ON departments
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.role = 'admin'
        )
    );

CREATE POLICY departments_delete_policy ON departments
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.role = 'admin'
        )
    );

-- ============================================================================
-- PART 9: Fix categories table RLS policies
-- ============================================================================

-- Drop existing categories policies
DROP POLICY IF EXISTS categories_select_all ON categories;
DROP POLICY IF EXISTS categories_manage_admin ON categories;

-- Create single SELECT policy for categories (public read)
CREATE POLICY categories_select_policy ON categories
    FOR SELECT
    USING (true);

-- Create admin-only management policies for categories
CREATE POLICY categories_insert_policy ON categories
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.role = 'admin'
        )
    );

CREATE POLICY categories_update_policy ON categories
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.role = 'admin'
        )
    );

CREATE POLICY categories_delete_policy ON categories
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = (SELECT auth.uid()) 
            AND profiles.role = 'admin'
        )
    );

-- ============================================================================
-- PART 10: Optional - Remove unused indexes (commented out for safety)
-- Uncomment if you want to remove these indexes
-- ============================================================================

-- DROP INDEX IF EXISTS idx_complaints_status;
-- DROP INDEX IF EXISTS idx_complaints_priority;
-- DROP INDEX IF EXISTS idx_complaints_tracking_number;
-- DROP INDEX IF EXISTS idx_complaints_location;
-- DROP INDEX IF EXISTS idx_feedback_complaint_id;
-- DROP INDEX IF EXISTS idx_notifications_user_id;
-- DROP INDEX IF EXISTS idx_notifications_unread;
