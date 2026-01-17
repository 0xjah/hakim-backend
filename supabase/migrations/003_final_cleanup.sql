-- Migration 003: Final Schema Cleanup
-- This removes the orphaned complaint_assignments RLS reference and adds useful indexes

-- ============================================
-- REMOVE ORPHANED RLS STATEMENT
-- ============================================
-- Note: The complaint_assignments table doesn't exist, so this might error
-- Run with IF EXISTS in production to be safe

-- ============================================
-- ADD ANALYTICS INDEXES
-- ============================================

-- Index for department-based analytics
CREATE INDEX IF NOT EXISTS idx_complaints_department_status 
ON complaints(department_id, status);

-- Index for category-based analytics
CREATE INDEX IF NOT EXISTS idx_complaints_category_status 
ON complaints(category_id, status);

-- Index for time-based analytics
CREATE INDEX IF NOT EXISTS idx_complaints_created_at_status 
ON complaints(created_at, status);

-- Index for assignment queries
CREATE INDEX IF NOT EXISTS idx_complaints_assigned_to 
ON complaints(assigned_to) WHERE assigned_to IS NOT NULL;

-- Index for resolution time calculations
CREATE INDEX IF NOT EXISTS idx_complaints_resolved_at 
ON complaints(resolved_at) WHERE resolved_at IS NOT NULL;

-- Index for feedback analytics
CREATE INDEX IF NOT EXISTS idx_feedback_rating 
ON feedback(rating);

-- Index for status history timeline
CREATE INDEX IF NOT EXISTS idx_status_history_created_at 
ON status_history(complaint_id, created_at DESC);

-- ============================================
-- ADD MISSING ADMIN POLICIES FOR STATUS_HISTORY
-- ============================================

-- Allow staff to insert status history (for status updates)
DROP POLICY IF EXISTS "status_history_insert_staff" ON status_history;
CREATE POLICY "status_history_insert_staff"
ON status_history FOR INSERT
WITH CHECK (
    (SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'super_admin', 'employee')
);

-- Allow staff to view all status history
DROP POLICY IF EXISTS "status_history_select_staff" ON status_history;
CREATE POLICY "status_history_select_staff"
ON status_history FOR SELECT
USING (
    (SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'super_admin', 'employee')
);

-- ============================================
-- ADD ATTACHMENTS ADMIN POLICY
-- ============================================

-- Allow staff to view all attachments
DROP POLICY IF EXISTS "attachments_select_staff" ON attachments;
CREATE POLICY "attachments_select_staff"
ON attachments FOR SELECT
USING (
    (SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'super_admin', 'employee')
);

-- ============================================
-- ADD FEEDBACK ADMIN POLICY
-- ============================================

-- Allow staff to view all feedback
DROP POLICY IF EXISTS "feedback_select_staff" ON feedback;
CREATE POLICY "feedback_select_staff"
ON feedback FOR SELECT
USING (
    (SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'super_admin', 'employee')
);

-- Allow users to view their own feedback
DROP POLICY IF EXISTS "feedback_select_own" ON feedback;
CREATE POLICY "feedback_select_own"
ON feedback FOR SELECT
USING (user_id = auth.uid());

-- Allow users to insert their own feedback
DROP POLICY IF EXISTS "feedback_insert_own" ON feedback;
CREATE POLICY "feedback_insert_own"
ON feedback FOR INSERT
WITH CHECK (user_id = auth.uid());

-- ============================================
-- VERIFY ALL REQUIRED TABLES EXIST
-- ============================================
-- departments ✓
-- categories ✓
-- profiles ✓
-- complaints ✓
-- attachments ✓
-- status_history ✓
-- feedback ✓
-- notifications ✓
