-- Hakim Database Schema for Supabase
-- Run this in the Supabase SQL Editor

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ============================================
-- ENUMS
-- ============================================

CREATE TYPE user_role AS ENUM ('citizen', 'employee', 'admin', 'super_admin');
CREATE TYPE complaint_status AS ENUM ('submitted', 'in_review', 'assigned', 'in_progress', 'resolved', 'closed', 'rejected');
CREATE TYPE complaint_priority AS ENUM ('low', 'medium', 'high', 'critical');
CREATE TYPE attachment_type AS ENUM ('image', 'voice', 'document');

-- ============================================
-- DEPARTMENTS TABLE
-- ============================================

CREATE TABLE departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    name_ar VARCHAR(100) NOT NULL,
    description TEXT,
    email VARCHAR(255),
    phone VARCHAR(20),
    manager_id UUID,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- CATEGORIES TABLE
-- ============================================

CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
    name VARCHAR(100) NOT NULL,
    name_ar VARCHAR(100) NOT NULL,
    description TEXT,
    icon VARCHAR(50),
    keywords TEXT[], -- Array of keywords for AI classification
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- PROFILES TABLE (extends Supabase auth.users)
-- ============================================

CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(100),
    phone VARCHAR(20),
    national_id VARCHAR(20),
    avatar_url TEXT,
    role user_role DEFAULT 'citizen',
    department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
    language VARCHAR(5) DEFAULT 'ar',
    notifications_enabled BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- COMPLAINTS TABLE
-- ============================================

CREATE TABLE complaints (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tracking_number VARCHAR(20) UNIQUE NOT NULL,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
    assigned_to UUID REFERENCES profiles(id) ON DELETE SET NULL,
    
    -- Content
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    
    -- Location
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    address TEXT,
    location GEOGRAPHY(POINT, 4326), -- PostGIS point
    
    -- Status & Priority
    status complaint_status DEFAULT 'submitted',
    priority complaint_priority DEFAULT 'medium',
    
    -- AI Analysis Results
    ai_category VARCHAR(100),
    ai_category_confidence DECIMAL(5, 4),
    ai_priority VARCHAR(20),
    ai_tags TEXT[],
    
    -- SLA & Escalation
    sla_deadline TIMESTAMP WITH TIME ZONE,
    escalation_level INTEGER DEFAULT 0,
    is_escalated BOOLEAN DEFAULT false,
    
    -- Timestamps
    resolved_at TIMESTAMP WITH TIME ZONE,
    closed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Generate tracking number trigger
CREATE OR REPLACE FUNCTION generate_tracking_number()
RETURNS TRIGGER AS $$
BEGIN
    NEW.tracking_number := 'HKM-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_tracking_number
    BEFORE INSERT ON complaints
    FOR EACH ROW
    EXECUTE FUNCTION generate_tracking_number();

-- ============================================
-- ATTACHMENTS TABLE
-- ============================================

CREATE TABLE attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    complaint_id UUID NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
    file_url TEXT NOT NULL,
    file_name VARCHAR(255),
    file_type attachment_type NOT NULL,
    file_size INTEGER,
    mime_type VARCHAR(100),
    ai_labels TEXT[],
    ai_description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- STATUS HISTORY TABLE
-- ============================================

CREATE TABLE status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    complaint_id UUID NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
    old_status complaint_status,
    new_status complaint_status NOT NULL,
    changed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    notes TEXT,
    is_system_generated BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- FEEDBACK TABLE
-- ============================================

CREATE TABLE feedback (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    complaint_id UUID NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    response TEXT, -- Admin response to feedback
    responded_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    responded_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- NOTIFICATIONS TABLE
-- ============================================

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    complaint_id UUID REFERENCES complaints(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    title_ar VARCHAR(255),
    body TEXT NOT NULL,
    body_ar TEXT,
    type VARCHAR(50) NOT NULL,
    is_read BOOLEAN DEFAULT false,
    data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX idx_complaints_user_id ON complaints(user_id);
CREATE INDEX idx_complaints_department_id ON complaints(department_id);
CREATE INDEX idx_complaints_status ON complaints(status);
CREATE INDEX idx_complaints_priority ON complaints(priority);
CREATE INDEX idx_complaints_created_at ON complaints(created_at DESC);
CREATE INDEX idx_complaints_tracking_number ON complaints(tracking_number);
CREATE INDEX idx_complaints_location ON complaints USING GIST(location);

CREATE INDEX idx_attachments_complaint_id ON attachments(complaint_id);
CREATE INDEX idx_status_history_complaint_id ON status_history(complaint_id);
CREATE INDEX idx_feedback_complaint_id ON feedback(complaint_id);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id) WHERE is_read = false;

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view their own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles" ON profiles
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'employee'))
    );

-- Complaints policies
CREATE POLICY "Users can view their own complaints" ON complaints
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can create complaints" ON complaints
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can view all complaints" ON complaints
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'employee'))
    );

CREATE POLICY "Admins can update complaints" ON complaints
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'employee'))
    );

-- Attachments policies
CREATE POLICY "Users can view attachments of their complaints" ON attachments
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM complaints WHERE complaints.id = attachments.complaint_id AND complaints.user_id = auth.uid())
    );

CREATE POLICY "Users can add attachments to their complaints" ON attachments
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM complaints WHERE complaints.id = attachments.complaint_id AND complaints.user_id = auth.uid())
    );

-- Notifications policies
CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can update their own notifications" ON notifications
    FOR UPDATE USING (user_id = auth.uid());

-- ============================================
-- FUNCTIONS
-- ============================================

-- Update timestamp function
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to tables
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_complaints_updated_at BEFORE UPDATE ON complaints
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_departments_updated_at BEFORE UPDATE ON departments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Log status changes
CREATE OR REPLACE FUNCTION log_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO status_history (complaint_id, old_status, new_status, is_system_generated)
        VALUES (NEW.id, OLD.status, NEW.status, true);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER log_complaint_status_change AFTER UPDATE ON complaints
    FOR EACH ROW EXECUTE FUNCTION log_status_change();

-- Create profile on user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (id, email, full_name, phone)
    VALUES (
        NEW.id, 
        NEW.email, 
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
        NEW.raw_user_meta_data->>'phone'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ============================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaint_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Public profiles are viewable by everyone"
ON profiles FOR SELECT
USING (true);

CREATE POLICY "Users can insert their own profile"
ON profiles FOR INSERT
WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
ON profiles FOR UPDATE
USING (auth.uid() = id);

-- Departments policies (public read)
CREATE POLICY "Departments are viewable by everyone"
ON departments FOR SELECT
USING (true);

-- Categories policies (public read)
CREATE POLICY "Categories are viewable by everyone"
ON categories FOR SELECT
USING (true);

-- Complaints policies
CREATE POLICY "Users can view their own complaints"
ON complaints FOR SELECT
USING (auth.uid() = user_id OR role_check() IN ('admin', 'super_admin', 'employee'));

CREATE POLICY "Users can create complaints"
ON complaints FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own complaints"
ON complaints FOR UPDATE
USING (auth.uid() = user_id OR role_check() IN ('admin', 'super_admin', 'employee'));

-- Helper function for role check
CREATE OR REPLACE FUNCTION role_check()
RETURNS user_role AS $$
BEGIN
    RETURN (SELECT role FROM profiles WHERE id = auth.uid());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Attachments policies
CREATE POLICY "Users can view attachments for their complaints"
ON attachments FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM complaints 
        WHERE complaints.id = attachments.complaint_id 
        AND (complaints.user_id = auth.uid() OR role_check() IN ('admin', 'super_admin', 'employee'))
    )
);

CREATE POLICY "Users can insert attachments for their complaints"
ON attachments FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM complaints 
        WHERE complaints.id = complaint_id 
        AND complaints.user_id = auth.uid()
    )
);

-- Status history policies
CREATE POLICY "Users can view status history for their complaints"
ON status_history FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM complaints 
        WHERE complaints.id = status_history.complaint_id 
        AND (complaints.user_id = auth.uid() OR role_check() IN ('admin', 'super_admin', 'employee'))
    )
);

-- Notifications policies
CREATE POLICY "Users can view their own notifications"
ON notifications FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications"
ON notifications FOR UPDATE
USING (auth.uid() = user_id);

-- ============================================
-- SEED DATA
-- ============================================

-- Insert default departments
INSERT INTO departments (name, name_ar, email) VALUES
    ('Water Authority', 'هيئة المياه', 'water@hakim.gov'),
    ('Electricity Authority', 'هيئة الكهرباء', 'electricity@hakim.gov'),
    ('Roads Department', 'إدارة الطرق', 'roads@hakim.gov'),
    ('Sanitation Department', 'إدارة النظافة', 'sanitation@hakim.gov'),
    ('Municipal Services', 'الخدمات البلدية', 'municipal@hakim.gov');

-- Insert default categories
INSERT INTO categories (name, name_ar, department_id, icon, keywords) VALUES
    ('Water Leak', 'تسرب مياه', (SELECT id FROM departments WHERE name = 'Water Authority'), 'water_drop', ARRAY['تسرب', 'مياه', 'صرف', 'leak', 'water', 'sewage', 'pipe']),
    ('Power Outage', 'انقطاع الكهرباء', (SELECT id FROM departments WHERE name = 'Electricity Authority'), 'flash_off', ARRAY['كهرباء', 'انقطاع', 'أعمدة', 'power', 'outage', 'electricity', 'wires']),
    ('Pothole', 'حفرة بالطريق', (SELECT id FROM departments WHERE name = 'Roads Department'), 'warning', ARRAY['حفرة', 'طريق', 'رصيف', 'pothole', 'road', 'pavement', 'damage']),
    ('Garbage Collection', 'جمع النفايات', (SELECT id FROM departments WHERE name = 'Sanitation Department'), 'delete', ARRAY['نظافة', 'قمامة', 'garbage', 'cleaning', 'waste', 'trash']),
    ('Street Lighting', 'إنارة الشوارع', (SELECT id FROM departments WHERE name = 'Municipal Services'), 'lightbulb', ARRAY['إنارة', 'عمود', 'lighting', 'lamp', 'street', 'dark']),
    ('Park Maintenance', 'صيانة الحدائق', (SELECT id FROM departments WHERE name = 'Municipal Services'), 'park', ARRAY['حديقة', 'أشجار', 'park', 'garden', 'trees', 'maintenance']);
