-- ============================================
-- HAKIM DUMMY DATA
-- For Testing and Development
-- ============================================

-- Note: This script assumes the departments and categories from 004_jordan_government_entities.sql are already inserted.
-- Run this AFTER the schema and government entities migrations.

-- ============================================
-- TEMPORARY USERS FOR TESTING
-- In production, users are created via Supabase Auth
-- ============================================

-- First, create test users in auth.users (required for foreign key constraint)
-- These are dummy users for development/testing only

INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, created_at, updated_at, confirmation_token, recovery_token, email_change_token_new, email_change)
VALUES
    ('a1111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'ahmad.khalil@gmail.com', crypt('Test123!', gen_salt('bf')), NOW(), NOW(), NOW(), '', '', '', ''),
    ('a2222222-2222-2222-2222-222222222222', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'fatima.hassan@gmail.com', crypt('Test123!', gen_salt('bf')), NOW(), NOW(), NOW(), '', '', '', ''),
    ('a3333333-3333-3333-3333-333333333333', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'mohammad.ali@yahoo.com', crypt('Test123!', gen_salt('bf')), NOW(), NOW(), NOW(), '', '', '', ''),
    ('a4444444-4444-4444-4444-444444444444', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'sara.omar@hotmail.com', crypt('Test123!', gen_salt('bf')), NOW(), NOW(), NOW(), '', '', '', ''),
    ('a5555555-5555-5555-5555-555555555555', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'khaled.ahmad@gmail.com', crypt('Test123!', gen_salt('bf')), NOW(), NOW(), NOW(), '', '', '', ''),
    ('b1111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'admin@hakim.gov.jo', crypt('Admin123!', gen_salt('bf')), NOW(), NOW(), NOW(), '', '', '', ''),
    ('b2222222-2222-2222-2222-222222222222', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'admin2@hakim.gov.jo', crypt('Admin123!', gen_salt('bf')), NOW(), NOW(), NOW(), '', '', '', ''),
    ('c1111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'employee.water@hakim.gov.jo', crypt('Emp123!', gen_salt('bf')), NOW(), NOW(), NOW(), '', '', '', ''),
    ('c2222222-2222-2222-2222-222222222222', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'employee.health@hakim.gov.jo', crypt('Emp123!', gen_salt('bf')), NOW(), NOW(), NOW(), '', '', '', ''),
    ('c3333333-3333-3333-3333-333333333333', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'employee.amman@hakim.gov.jo', crypt('Emp123!', gen_salt('bf')), NOW(), NOW(), NOW(), '', '', '', ''),
    ('d1111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'superadmin@hakim.gov.jo', crypt('Super123!', gen_salt('bf')), NOW(), NOW(), NOW(), '', '', '', '')
ON CONFLICT (id) DO NOTHING;

-- Also insert into auth.identities (required by Supabase)
INSERT INTO auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
VALUES
    ('a1111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'ahmad.khalil@gmail.com', '{"sub": "a1111111-1111-1111-1111-111111111111", "email": "ahmad.khalil@gmail.com"}', 'email', NOW(), NOW(), NOW()),
    ('a2222222-2222-2222-2222-222222222222', 'a2222222-2222-2222-2222-222222222222', 'fatima.hassan@gmail.com', '{"sub": "a2222222-2222-2222-2222-222222222222", "email": "fatima.hassan@gmail.com"}', 'email', NOW(), NOW(), NOW()),
    ('a3333333-3333-3333-3333-333333333333', 'a3333333-3333-3333-3333-333333333333', 'mohammad.ali@yahoo.com', '{"sub": "a3333333-3333-3333-3333-333333333333", "email": "mohammad.ali@yahoo.com"}', 'email', NOW(), NOW(), NOW()),
    ('a4444444-4444-4444-4444-444444444444', 'a4444444-4444-4444-4444-444444444444', 'sara.omar@hotmail.com', '{"sub": "a4444444-4444-4444-4444-444444444444", "email": "sara.omar@hotmail.com"}', 'email', NOW(), NOW(), NOW()),
    ('a5555555-5555-5555-5555-555555555555', 'a5555555-5555-5555-5555-555555555555', 'khaled.ahmad@gmail.com', '{"sub": "a5555555-5555-5555-5555-555555555555", "email": "khaled.ahmad@gmail.com"}', 'email', NOW(), NOW(), NOW()),
    ('b1111111-1111-1111-1111-111111111111', 'b1111111-1111-1111-1111-111111111111', 'admin@hakim.gov.jo', '{"sub": "b1111111-1111-1111-1111-111111111111", "email": "admin@hakim.gov.jo"}', 'email', NOW(), NOW(), NOW()),
    ('b2222222-2222-2222-2222-222222222222', 'b2222222-2222-2222-2222-222222222222', 'admin2@hakim.gov.jo', '{"sub": "b2222222-2222-2222-2222-222222222222", "email": "admin2@hakim.gov.jo"}', 'email', NOW(), NOW(), NOW()),
    ('c1111111-1111-1111-1111-111111111111', 'c1111111-1111-1111-1111-111111111111', 'employee.water@hakim.gov.jo', '{"sub": "c1111111-1111-1111-1111-111111111111", "email": "employee.water@hakim.gov.jo"}', 'email', NOW(), NOW(), NOW()),
    ('c2222222-2222-2222-2222-222222222222', 'c2222222-2222-2222-2222-222222222222', 'employee.health@hakim.gov.jo', '{"sub": "c2222222-2222-2222-2222-222222222222", "email": "employee.health@hakim.gov.jo"}', 'email', NOW(), NOW(), NOW()),
    ('c3333333-3333-3333-3333-333333333333', 'c3333333-3333-3333-3333-333333333333', 'employee.amman@hakim.gov.jo', '{"sub": "c3333333-3333-3333-3333-333333333333", "email": "employee.amman@hakim.gov.jo"}', 'email', NOW(), NOW(), NOW()),
    ('d1111111-1111-1111-1111-111111111111', 'd1111111-1111-1111-1111-111111111111', 'superadmin@hakim.gov.jo', '{"sub": "d1111111-1111-1111-1111-111111111111", "email": "superadmin@hakim.gov.jo"}', 'email', NOW(), NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

DO $$
DECLARE
    citizen_1_id UUID := 'a1111111-1111-1111-1111-111111111111';
    citizen_2_id UUID := 'a2222222-2222-2222-2222-222222222222';
    citizen_3_id UUID := 'a3333333-3333-3333-3333-333333333333';
    citizen_4_id UUID := 'a4444444-4444-4444-4444-444444444444';
    citizen_5_id UUID := 'a5555555-5555-5555-5555-555555555555';
    admin_1_id UUID := 'b1111111-1111-1111-1111-111111111111';
    admin_2_id UUID := 'b2222222-2222-2222-2222-222222222222';
    employee_1_id UUID := 'c1111111-1111-1111-1111-111111111111';
    employee_2_id UUID := 'c2222222-2222-2222-2222-222222222222';
    employee_3_id UUID := 'c3333333-3333-3333-3333-333333333333';
    super_admin_id UUID := 'd1111111-1111-1111-1111-111111111111';
    
    -- Department IDs (will be fetched)
    health_dept_id UUID;
    water_dept_id UUID;
    transport_dept_id UUID;
    education_dept_id UUID;
    interior_dept_id UUID;
    amman_dept_id UUID;
    energy_dept_id UUID;
    env_dept_id UUID;
    labor_dept_id UUID;
    works_dept_id UUID;
    
    -- Category IDs (will be fetched)
    hospital_cat_id UUID;
    water_supply_cat_id UUID;
    water_leak_cat_id UUID;
    sewage_cat_id UUID;
    public_transport_cat_id UUID;
    school_cat_id UUID;
    civil_status_cat_id UUID;
    street_lighting_cat_id UUID;
    garbage_cat_id UUID;
    power_outage_cat_id UUID;
    road_damage_cat_id UUID;
    labor_violations_cat_id UUID;
    pollution_cat_id UUID;
    
    -- Complaint IDs
    complaint_1_id UUID;
    complaint_2_id UUID;
    complaint_3_id UUID;
    complaint_4_id UUID;
    complaint_5_id UUID;
    complaint_6_id UUID;
    complaint_7_id UUID;
    complaint_8_id UUID;
    complaint_9_id UUID;
    complaint_10_id UUID;
    complaint_11_id UUID;
    complaint_12_id UUID;
    complaint_13_id UUID;
    complaint_14_id UUID;
    complaint_15_id UUID;
BEGIN
    -- Get Department IDs
    SELECT id INTO health_dept_id FROM departments WHERE name = 'Ministry of Health' LIMIT 1;
    SELECT id INTO water_dept_id FROM departments WHERE name = 'Ministry of Water and Irrigation' LIMIT 1;
    SELECT id INTO transport_dept_id FROM departments WHERE name = 'Ministry of Transport' LIMIT 1;
    SELECT id INTO education_dept_id FROM departments WHERE name = 'Ministry of Education' LIMIT 1;
    SELECT id INTO interior_dept_id FROM departments WHERE name = 'Ministry of Interior' LIMIT 1;
    SELECT id INTO amman_dept_id FROM departments WHERE name = 'Greater Amman Municipality' LIMIT 1;
    SELECT id INTO energy_dept_id FROM departments WHERE name = 'Ministry of Energy' LIMIT 1;
    SELECT id INTO env_dept_id FROM departments WHERE name = 'Ministry of Environment' LIMIT 1;
    SELECT id INTO labor_dept_id FROM departments WHERE name = 'Ministry of Labor' LIMIT 1;
    SELECT id INTO works_dept_id FROM departments WHERE name = 'Ministry of Public Works' LIMIT 1;
    
    -- Get Category IDs
    SELECT id INTO hospital_cat_id FROM categories WHERE name = 'Hospital Services' LIMIT 1;
    SELECT id INTO water_supply_cat_id FROM categories WHERE name = 'Water Supply' LIMIT 1;
    SELECT id INTO water_leak_cat_id FROM categories WHERE name = 'Water Leak' LIMIT 1;
    SELECT id INTO sewage_cat_id FROM categories WHERE name = 'Sewage Issues' LIMIT 1;
    SELECT id INTO public_transport_cat_id FROM categories WHERE name = 'Public Transportation' LIMIT 1;
    SELECT id INTO school_cat_id FROM categories WHERE name = 'School Issues' LIMIT 1;
    SELECT id INTO civil_status_cat_id FROM categories WHERE name = 'Civil Status' LIMIT 1;
    SELECT id INTO street_lighting_cat_id FROM categories WHERE name = 'Street Lighting' LIMIT 1;
    SELECT id INTO garbage_cat_id FROM categories WHERE name = 'Garbage Collection' LIMIT 1;
    SELECT id INTO power_outage_cat_id FROM categories WHERE name = 'Power Outage' LIMIT 1;
    SELECT id INTO road_damage_cat_id FROM categories WHERE name = 'Road Damage' LIMIT 1;
    SELECT id INTO labor_violations_cat_id FROM categories WHERE name = 'Labor Violations' LIMIT 1;
    SELECT id INTO pollution_cat_id FROM categories WHERE name = 'Pollution' LIMIT 1;

    -- ============================================
    -- INSERT PROFILES (Test Users)
    -- ============================================
    
    -- Citizens
    INSERT INTO profiles (id, email, full_name, phone, national_id, role, language, notifications_enabled) VALUES
        (citizen_1_id, 'ahmad.khalil@gmail.com', 'أحمد خليل', '+962791234567', '9871234567', 'citizen', 'ar', true),
        (citizen_2_id, 'fatima.hassan@gmail.com', 'فاطمة حسن', '+962792345678', '9882345678', 'citizen', 'ar', true),
        (citizen_3_id, 'mohammad.ali@yahoo.com', 'محمد علي', '+962793456789', '9893456789', 'citizen', 'ar', true),
        (citizen_4_id, 'sara.omar@hotmail.com', 'سارة عمر', '+962794567890', '9904567890', 'citizen', 'en', true),
        (citizen_5_id, 'khaled.ahmad@gmail.com', 'خالد أحمد', '+962795678901', '9915678901', 'citizen', 'ar', false)
    ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name;
    
    -- Employees (assigned to departments)
    INSERT INTO profiles (id, email, full_name, phone, national_id, role, department_id, language, notifications_enabled) VALUES
        (employee_1_id, 'employee.water@hakim.gov.jo', 'يوسف الماء', '+962796789012', '9926789012', 'employee', water_dept_id, 'ar', true),
        (employee_2_id, 'employee.health@hakim.gov.jo', 'نور الصحة', '+962797890123', '9937890123', 'employee', health_dept_id, 'ar', true),
        (employee_3_id, 'employee.amman@hakim.gov.jo', 'عمار عمان', '+962798901234', '9948901234', 'employee', amman_dept_id, 'ar', true)
    ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name;
    
    -- Admins
    INSERT INTO profiles (id, email, full_name, phone, national_id, role, language, notifications_enabled) VALUES
        (admin_1_id, 'admin@hakim.gov.jo', 'مدير النظام', '+962799012345', '9959012345', 'admin', 'ar', true),
        (admin_2_id, 'admin2@hakim.gov.jo', 'مدير ثاني', '+962780123456', '9960123456', 'admin', 'en', true)
    ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name;
    
    -- Super Admin
    INSERT INTO profiles (id, email, full_name, phone, national_id, role, language, notifications_enabled) VALUES
        (super_admin_id, 'superadmin@hakim.gov.jo', 'المدير العام', '+962781234567', '9971234567', 'super_admin', 'ar', true)
    ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name;

    -- ============================================
    -- INSERT COMPLAINTS (Various Statuses)
    -- ============================================
    
    -- Generate UUIDs for complaints
    complaint_1_id := uuid_generate_v4();
    complaint_2_id := uuid_generate_v4();
    complaint_3_id := uuid_generate_v4();
    complaint_4_id := uuid_generate_v4();
    complaint_5_id := uuid_generate_v4();
    complaint_6_id := uuid_generate_v4();
    complaint_7_id := uuid_generate_v4();
    complaint_8_id := uuid_generate_v4();
    complaint_9_id := uuid_generate_v4();
    complaint_10_id := uuid_generate_v4();
    complaint_11_id := uuid_generate_v4();
    complaint_12_id := uuid_generate_v4();
    complaint_13_id := uuid_generate_v4();
    complaint_14_id := uuid_generate_v4();
    complaint_15_id := uuid_generate_v4();

    -- Complaint 1: Water leak - Resolved
    INSERT INTO complaints (id, tracking_number, user_id, category_id, department_id, assigned_to, title, description, 
        latitude, longitude, address, status, priority, ai_category, ai_category_confidence, ai_priority, ai_tags,
        sla_deadline, resolved_at, created_at) VALUES
        (complaint_1_id, 'HKM-20260115-0001', citizen_1_id, water_leak_cat_id, water_dept_id, employee_1_id,
         'تسرب مياه كبير في شارع الجامعة', 
         'يوجد تسرب مياه كبير منذ أسبوع في شارع الجامعة قرب مسجد الحسين. المياه تتدفق بشكل مستمر وتسبب أضرار للشارع والمحلات المجاورة.',
         31.9539, 35.9106, 'شارع الجامعة، قرب مسجد الحسين، عمان',
         'resolved', 'high', 'Water Leak', 0.9500, 'high', ARRAY['تسرب', 'مياه', 'شارع', 'أضرار'],
         NOW() + INTERVAL '5 days', NOW() - INTERVAL '2 days', NOW() - INTERVAL '10 days');
    
    -- Complaint 2: Hospital complaint - In Progress
    INSERT INTO complaints (id, tracking_number, user_id, category_id, department_id, assigned_to, title, description,
        latitude, longitude, address, status, priority, ai_category, ai_category_confidence, ai_priority, ai_tags,
        sla_deadline, created_at) VALUES
        (complaint_2_id, 'HKM-20260118-0002', citizen_2_id, hospital_cat_id, health_dept_id, employee_2_id,
         'انتظار طويل في طوارئ مستشفى البشير',
         'انتظرت في قسم الطوارئ لأكثر من 6 ساعات دون أن يتم فحصي. كان هناك نقص واضح في الكادر الطبي والتمريضي.',
         31.9856, 35.8789, 'مستشفى البشير، عمان',
         'in_progress', 'high', 'Hospital Services', 0.9200, 'high', ARRAY['طوارئ', 'انتظار', 'مستشفى', 'كادر'],
         NOW() + INTERVAL '7 days', NOW() - INTERVAL '5 days');
    
    -- Complaint 3: Street lighting - Submitted (New)
    INSERT INTO complaints (id, tracking_number, user_id, category_id, department_id, title, description,
        latitude, longitude, address, status, priority, ai_category, ai_category_confidence, ai_priority, ai_tags,
        sla_deadline, created_at) VALUES
        (complaint_3_id, 'HKM-20260123-0003', citizen_3_id, street_lighting_cat_id, amman_dept_id,
         'أعمدة إنارة مطفأة في حي نزال',
         'جميع أعمدة الإنارة في شارع الملك عبدالله الثاني في حي نزال مطفأة منذ أسبوعين مما يجعل الشارع مظلماً تماماً ويشكل خطراً على السكان.',
         31.9345, 35.9234, 'شارع الملك عبدالله الثاني، حي نزال، عمان',
         'submitted', 'medium', 'Street Lighting', 0.9700, 'medium', ARRAY['إنارة', 'ظلام', 'أعمدة', 'خطر'],
         NOW() + INTERVAL '14 days', NOW() - INTERVAL '1 day');
    
    -- Complaint 4: Garbage collection - In Review
    INSERT INTO complaints (id, tracking_number, user_id, category_id, department_id, title, description,
        latitude, longitude, address, status, priority, ai_category, ai_category_confidence, ai_priority, ai_tags,
        sla_deadline, created_at) VALUES
        (complaint_4_id, 'HKM-20260120-0004', citizen_1_id, garbage_cat_id, amman_dept_id,
         'عدم جمع النفايات منذ أسبوع',
         'لم يتم جمع النفايات من حاويات الحي منذ أكثر من أسبوع. الحاويات ممتلئة والقمامة منتشرة في الشارع وتسبب روائح كريهة.',
         31.9678, 35.8956, 'حي الرابية، عمان',
         'in_review', 'high', 'Garbage Collection', 0.9800, 'high', ARRAY['قمامة', 'نفايات', 'حاويات', 'روائح'],
         NOW() + INTERVAL '5 days', NOW() - INTERVAL '4 days');
    
    -- Complaint 5: Power outage - Critical, Assigned
    INSERT INTO complaints (id, tracking_number, user_id, category_id, department_id, assigned_to, title, description,
        latitude, longitude, address, status, priority, ai_category, ai_category_confidence, ai_priority, ai_tags,
        sla_deadline, created_at) VALUES
        (complaint_5_id, 'HKM-20260122-0005', citizen_4_id, power_outage_cat_id, energy_dept_id, NULL,
         'انقطاع متكرر للكهرباء في منطقة صويلح',
         'يحدث انقطاع متكرر للكهرباء يومياً لمدة 4-5 ساعات مما يؤثر على العمل والدراسة. المحول الرئيسي يبدو معطلاً.',
         32.0234, 35.8567, 'منطقة صويلح، عمان',
         'assigned', 'critical', 'Power Outage', 0.9600, 'critical', ARRAY['كهرباء', 'انقطاع', 'محول', 'صيانة'],
         NOW() + INTERVAL '3 days', NOW() - INTERVAL '2 days');
    
    -- Complaint 6: Road damage - In Progress
    INSERT INTO complaints (id, tracking_number, user_id, category_id, department_id, title, description,
        latitude, longitude, address, status, priority, ai_category, ai_category_confidence, ai_priority, ai_tags,
        sla_deadline, created_at) VALUES
        (complaint_6_id, 'HKM-20260110-0006', citizen_5_id, road_damage_cat_id, works_dept_id,
         'حفرة كبيرة وخطيرة في شارع المدينة المنورة',
         'توجد حفرة كبيرة جداً في وسط الشارع تشكل خطراً على السيارات. تسببت في حادث سير الأسبوع الماضي.',
         31.9456, 35.9012, 'شارع المدينة المنورة، عمان',
         'in_progress', 'critical', 'Road Damage', 0.9400, 'critical', ARRAY['حفرة', 'طريق', 'خطر', 'حادث'],
         NOW() + INTERVAL '7 days', NOW() - INTERVAL '14 days');
    
    -- Complaint 7: School issue - Closed
    INSERT INTO complaints (id, tracking_number, user_id, category_id, department_id, title, description,
        latitude, longitude, address, status, priority, ai_category, ai_category_confidence, ai_priority, ai_tags,
        sla_deadline, resolved_at, closed_at, created_at) VALUES
        (complaint_7_id, 'HKM-20260105-0007', citizen_2_id, school_cat_id, education_dept_id,
         'نقص في المعلمين في مدرسة الأمير حسن',
         'يوجد نقص حاد في معلمي الرياضيات والعلوم مما يؤثر على تحصيل الطلاب.',
         31.9123, 35.9345, 'مدرسة الأمير حسن، عمان',
         'closed', 'medium', 'School Issues', 0.8800, 'medium', ARRAY['مدرسة', 'معلمين', 'نقص', 'تعليم'],
         NOW() - INTERVAL '5 days', NOW() - INTERVAL '10 days', NOW() - INTERVAL '5 days', NOW() - INTERVAL '20 days');
    
    -- Complaint 8: Sewage issue - Submitted
    INSERT INTO complaints (id, tracking_number, user_id, category_id, department_id, title, description,
        latitude, longitude, address, status, priority, ai_category, ai_category_confidence, ai_priority, ai_tags,
        sla_deadline, created_at) VALUES
        (complaint_8_id, 'HKM-20260124-0008', citizen_3_id, sewage_cat_id, water_dept_id,
         'طفح مجاري في شارع وادي صقرة',
         'يوجد طفح مجاري منذ 3 أيام يسبب روائح كريهة جداً ويهدد الصحة العامة. الوضع خطير ويحتاج تدخل عاجل.',
         31.9567, 35.9123, 'شارع وادي صقرة، عمان',
         'submitted', 'critical', 'Sewage Issues', 0.9300, 'critical', ARRAY['مجاري', 'طفح', 'روائح', 'صحة'],
         NOW() + INTERVAL '5 days', NOW());
    
    -- Complaint 9: Public transport - In Review
    INSERT INTO complaints (id, tracking_number, user_id, category_id, department_id, title, description,
        latitude, longitude, address, status, priority, ai_category, ai_category_confidence, ai_priority, ai_tags,
        sla_deadline, created_at) VALUES
        (complaint_9_id, 'HKM-20260119-0009', citizen_4_id, public_transport_cat_id, transport_dept_id,
         'عدم التزام الباصات بالمواعيد',
         'باصات خط 35 لا تلتزم بأي مواعيد وتأتي متأخرة دائماً بساعة أو أكثر مما يسبب تأخر الموظفين والطلاب.',
         31.9789, 35.8678, 'محطة المحطة الشمالية، عمان',
         'in_review', 'medium', 'Public Transportation', 0.8700, 'medium', ARRAY['باص', 'مواعيد', 'تأخير', 'نقل'],
         NOW() + INTERVAL '14 days', NOW() - INTERVAL '5 days');
    
    -- Complaint 10: Labor violations - Rejected
    INSERT INTO complaints (id, tracking_number, user_id, category_id, department_id, title, description,
        latitude, longitude, address, status, priority, ai_category, ai_category_confidence, ai_priority, ai_tags,
        sla_deadline, closed_at, created_at) VALUES
        (complaint_10_id, 'HKM-20260108-0010', citizen_1_id, labor_violations_cat_id, labor_dept_id,
         'تأخير صرف الرواتب',
         'الشركة تؤخر صرف الرواتب لأكثر من شهرين.',
         31.9234, 35.9234, 'منطقة البيادر، عمان',
         'rejected', 'high', 'Labor Violations', 0.7500, 'high', ARRAY['رواتب', 'تأخير', 'عمل'],
         NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days', NOW() - INTERVAL '16 days');
    
    -- Complaint 11: Water supply - Assigned
    INSERT INTO complaints (id, tracking_number, user_id, category_id, department_id, assigned_to, title, description,
        latitude, longitude, address, status, priority, ai_category, ai_category_confidence, ai_priority, ai_tags,
        sla_deadline, created_at) VALUES
        (complaint_11_id, 'HKM-20260121-0011', citizen_5_id, water_supply_cat_id, water_dept_id, employee_1_id,
         'انقطاع المياه المتكرر في جبل النصر',
         'المياه تنقطع بشكل يومي لأكثر من 12 ساعة رغم أن جدول التوزيع يقول عكس ذلك.',
         31.9901, 35.8901, 'جبل النصر، عمان',
         'assigned', 'high', 'Water Supply', 0.9100, 'high', ARRAY['مياه', 'انقطاع', 'توزيع'],
         NOW() + INTERVAL '3 days', NOW() - INTERVAL '3 days');
    
    -- Complaint 12: Civil status - Resolved
    INSERT INTO complaints (id, tracking_number, user_id, category_id, department_id, title, description,
        latitude, longitude, address, status, priority, ai_category, ai_category_confidence, ai_priority, ai_tags,
        sla_deadline, resolved_at, created_at) VALUES
        (complaint_12_id, 'HKM-20260112-0012', citizen_2_id, civil_status_cat_id, interior_dept_id,
         'تأخير في إصدار شهادة ميلاد',
         'تقدمت بطلب شهادة ميلاد لمولودي منذ شهر ولم أستلمها حتى الآن رغم الوعود المتكررة.',
         31.9567, 35.9456, 'دائرة الأحوال المدنية، عمان',
         'resolved', 'medium', 'Civil Status', 0.8900, 'medium', ARRAY['شهادة', 'ميلاد', 'تأخير', 'أحوال مدنية'],
         NOW() - INTERVAL '3 days', NOW() - INTERVAL '5 days', NOW() - INTERVAL '18 days');
    
    -- Complaint 13: Pollution - Submitted
    INSERT INTO complaints (id, tracking_number, user_id, category_id, department_id, title, description,
        latitude, longitude, address, status, priority, ai_category, ai_category_confidence, ai_priority, ai_tags,
        sla_deadline, created_at) VALUES
        (complaint_13_id, 'HKM-20260124-0013', citizen_3_id, pollution_cat_id, env_dept_id,
         'دخان كثيف من مصنع في سحاب',
         'يصدر مصنع الإسمنت دخان أسود كثيف يومياً يؤثر على صحة سكان المنطقة ويسبب أمراض تنفسية.',
         31.8567, 35.9678, 'منطقة سحاب الصناعية، عمان',
         'submitted', 'high', 'Pollution', 0.9200, 'high', ARRAY['تلوث', 'دخان', 'مصنع', 'صحة'],
         NOW() + INTERVAL '7 days', NOW());
    
    -- Complaint 14: Garbage - Resolved
    INSERT INTO complaints (id, tracking_number, user_id, category_id, department_id, assigned_to, title, description,
        latitude, longitude, address, status, priority, ai_category, ai_category_confidence, ai_priority, ai_tags,
        sla_deadline, resolved_at, created_at) VALUES
        (complaint_14_id, 'HKM-20260107-0014', citizen_4_id, garbage_cat_id, amman_dept_id, employee_3_id,
         'تراكم النفايات قرب مدرسة',
         'تتراكم النفايات بشكل خطير قرب مدرسة البنات الثانوية مما يشكل خطراً صحياً على الطالبات.',
         31.9234, 35.8789, 'قرب مدرسة البنات الثانوية، عمان',
         'resolved', 'high', 'Garbage Collection', 0.9600, 'high', ARRAY['نفايات', 'مدرسة', 'خطر', 'صحة'],
         NOW() - INTERVAL '10 days', NOW() - INTERVAL '12 days', NOW() - INTERVAL '17 days');
    
    -- Complaint 15: Street lighting - In Progress with escalation
    INSERT INTO complaints (id, tracking_number, user_id, category_id, department_id, assigned_to, title, description,
        latitude, longitude, address, status, priority, ai_category, ai_category_confidence, ai_priority, ai_tags,
        sla_deadline, escalation_level, is_escalated, created_at) VALUES
        (complaint_15_id, 'HKM-20260101-0015', citizen_5_id, street_lighting_cat_id, amman_dept_id, employee_3_id,
         'عطل في إنارة نفق الصحافة',
         'إنارة نفق الصحافة معطلة منذ 3 أسابيع مما يشكل خطراً كبيراً على سائقي السيارات.',
         31.9456, 35.8901, 'نفق الصحافة، عمان',
         'in_progress', 'critical', 'Street Lighting', 0.9500, 'critical', ARRAY['إنارة', 'نفق', 'خطر', 'سيارات'],
         NOW() - INTERVAL '7 days', 2, true, NOW() - INTERVAL '21 days');

    -- ============================================
    -- INSERT ATTACHMENTS
    -- ============================================
    
    INSERT INTO attachments (complaint_id, file_url, file_name, file_type, file_size, mime_type, ai_labels) VALUES
        (complaint_1_id, 'https://storage.hakim.gov.jo/attachments/water_leak_1.jpg', 'water_leak_1.jpg', 'image', 245000, 'image/jpeg', ARRAY['water', 'leak', 'street', 'damage']),
        (complaint_1_id, 'https://storage.hakim.gov.jo/attachments/water_leak_2.jpg', 'water_leak_2.jpg', 'image', 312000, 'image/jpeg', ARRAY['water', 'flooding', 'road']),
        (complaint_3_id, 'https://storage.hakim.gov.jo/attachments/dark_street.jpg', 'dark_street.jpg', 'image', 198000, 'image/jpeg', ARRAY['dark', 'street', 'night', 'danger']),
        (complaint_4_id, 'https://storage.hakim.gov.jo/attachments/garbage_1.jpg', 'garbage_1.jpg', 'image', 456000, 'image/jpeg', ARRAY['garbage', 'trash', 'container', 'overflow']),
        (complaint_5_id, 'https://storage.hakim.gov.jo/attachments/power_issue.jpg', 'power_issue.jpg', 'image', 234000, 'image/jpeg', ARRAY['electricity', 'transformer', 'damage']),
        (complaint_6_id, 'https://storage.hakim.gov.jo/attachments/pothole_1.jpg', 'pothole_1.jpg', 'image', 567000, 'image/jpeg', ARRAY['pothole', 'road', 'danger', 'big']),
        (complaint_6_id, 'https://storage.hakim.gov.jo/attachments/pothole_2.jpg', 'pothole_2.jpg', 'image', 423000, 'image/jpeg', ARRAY['pothole', 'road', 'car']),
        (complaint_8_id, 'https://storage.hakim.gov.jo/attachments/sewage_overflow.jpg', 'sewage_overflow.jpg', 'image', 345000, 'image/jpeg', ARRAY['sewage', 'overflow', 'street']),
        (complaint_8_id, 'https://storage.hakim.gov.jo/attachments/sewage_audio.mp3', 'sewage_audio.mp3', 'voice', 1234000, 'audio/mpeg', NULL),
        (complaint_13_id, 'https://storage.hakim.gov.jo/attachments/factory_smoke.jpg', 'factory_smoke.jpg', 'image', 678000, 'image/jpeg', ARRAY['smoke', 'pollution', 'factory', 'black']),
        (complaint_15_id, 'https://storage.hakim.gov.jo/attachments/tunnel_dark.jpg', 'tunnel_dark.jpg', 'image', 234000, 'image/jpeg', ARRAY['tunnel', 'dark', 'danger', 'road']);

    -- ============================================
    -- INSERT STATUS HISTORY
    -- ============================================
    
    -- Complaint 1 history (Resolved)
    INSERT INTO status_history (complaint_id, old_status, new_status, changed_by, notes, created_at) VALUES
        (complaint_1_id, NULL, 'submitted', NULL, 'تم تقديم الشكوى', NOW() - INTERVAL '10 days'),
        (complaint_1_id, 'submitted', 'in_review', admin_1_id, 'جاري مراجعة الشكوى', NOW() - INTERVAL '9 days'),
        (complaint_1_id, 'in_review', 'assigned', admin_1_id, 'تم تحويل الشكوى لقسم المياه', NOW() - INTERVAL '8 days'),
        (complaint_1_id, 'assigned', 'in_progress', employee_1_id, 'تم البدء بالإصلاح', NOW() - INTERVAL '5 days'),
        (complaint_1_id, 'in_progress', 'resolved', employee_1_id, 'تم إصلاح التسرب بالكامل', NOW() - INTERVAL '2 days');
    
    -- Complaint 2 history (In Progress)
    INSERT INTO status_history (complaint_id, old_status, new_status, changed_by, notes, created_at) VALUES
        (complaint_2_id, NULL, 'submitted', NULL, 'تم تقديم الشكوى', NOW() - INTERVAL '5 days'),
        (complaint_2_id, 'submitted', 'in_review', admin_1_id, 'جاري مراجعة الشكوى', NOW() - INTERVAL '4 days'),
        (complaint_2_id, 'in_review', 'assigned', admin_1_id, 'تم تحويل الشكوى لوزارة الصحة', NOW() - INTERVAL '3 days'),
        (complaint_2_id, 'assigned', 'in_progress', employee_2_id, 'جاري التحقيق في الموضوع', NOW() - INTERVAL '2 days');
    
    -- Complaint 7 history (Closed)
    INSERT INTO status_history (complaint_id, old_status, new_status, changed_by, notes, created_at) VALUES
        (complaint_7_id, NULL, 'submitted', NULL, 'تم تقديم الشكوى', NOW() - INTERVAL '20 days'),
        (complaint_7_id, 'submitted', 'in_review', admin_1_id, 'جاري مراجعة الشكوى', NOW() - INTERVAL '18 days'),
        (complaint_7_id, 'in_review', 'in_progress', admin_1_id, 'تم التواصل مع المدرسة', NOW() - INTERVAL '15 days'),
        (complaint_7_id, 'in_progress', 'resolved', admin_2_id, 'تم تعيين معلمين جدد', NOW() - INTERVAL '10 days'),
        (complaint_7_id, 'resolved', 'closed', admin_1_id, 'تم إغلاق الشكوى بعد التأكد من الحل', NOW() - INTERVAL '5 days');
    
    -- Complaint 10 history (Rejected)
    INSERT INTO status_history (complaint_id, old_status, new_status, changed_by, notes, created_at) VALUES
        (complaint_10_id, NULL, 'submitted', NULL, 'تم تقديم الشكوى', NOW() - INTERVAL '16 days'),
        (complaint_10_id, 'submitted', 'in_review', admin_1_id, 'جاري مراجعة الشكوى', NOW() - INTERVAL '12 days'),
        (complaint_10_id, 'in_review', 'rejected', admin_1_id, 'الشكوى من اختصاص المحاكم العمالية وليس الوزارة', NOW() - INTERVAL '7 days');

    -- ============================================
    -- INSERT FEEDBACK
    -- ============================================
    
    INSERT INTO feedback (complaint_id, user_id, rating, comment, response, responded_by, responded_at, created_at) VALUES
        (complaint_1_id, citizen_1_id, 5, 'خدمة ممتازة وسريعة. شكراً لكم!', 'شكراً لملاحظاتكم القيمة. نسعد بخدمتكم دائماً.', admin_1_id, NOW() - INTERVAL '1 day', NOW() - INTERVAL '2 days'),
        (complaint_7_id, citizen_2_id, 4, 'تم حل المشكلة لكن استغرق وقتاً طويلاً', 'نعتذر عن التأخير ونعمل على تحسين سرعة الاستجابة.', admin_2_id, NOW() - INTERVAL '3 days', NOW() - INTERVAL '4 days'),
        (complaint_12_id, citizen_2_id, 3, 'الخدمة جيدة لكن يمكن تحسينها', NULL, NULL, NULL, NOW() - INTERVAL '4 days'),
        (complaint_14_id, citizen_4_id, 5, 'استجابة سريعة ورائعة!', 'سعداء بخدمتكم!', employee_3_id, NOW() - INTERVAL '11 days', NOW() - INTERVAL '12 days');

    -- ============================================
    -- INSERT NOTIFICATIONS
    -- ============================================
    
    INSERT INTO notifications (user_id, complaint_id, title, title_ar, body, body_ar, type, is_read, created_at) VALUES
        -- Notifications for citizen_1
        (citizen_1_id, complaint_1_id, 'Complaint Resolved', 'تم حل الشكوى', 'Your water leak complaint has been resolved.', 'تم حل شكوى تسرب المياه الخاصة بك.', 'status_update', true, NOW() - INTERVAL '2 days'),
        (citizen_1_id, complaint_4_id, 'Complaint Under Review', 'الشكوى قيد المراجعة', 'Your garbage complaint is being reviewed.', 'شكوى النفايات الخاصة بك قيد المراجعة.', 'status_update', true, NOW() - INTERVAL '3 days'),
        
        -- Notifications for citizen_2
        (citizen_2_id, complaint_2_id, 'Complaint In Progress', 'الشكوى قيد التنفيذ', 'Your hospital complaint is being processed.', 'شكوى المستشفى الخاصة بك قيد التنفيذ.', 'status_update', true, NOW() - INTERVAL '2 days'),
        (citizen_2_id, complaint_7_id, 'Complaint Closed', 'تم إغلاق الشكوى', 'Your school complaint has been closed.', 'تم إغلاق شكوى المدرسة الخاصة بك.', 'status_update', true, NOW() - INTERVAL '5 days'),
        
        -- Notifications for citizen_3
        (citizen_3_id, complaint_3_id, 'Complaint Submitted', 'تم تقديم الشكوى', 'Your street lighting complaint has been submitted.', 'تم تقديم شكوى إنارة الشوارع الخاصة بك.', 'status_update', false, NOW() - INTERVAL '1 day'),
        (citizen_3_id, complaint_8_id, 'Complaint Submitted', 'تم تقديم الشكوى', 'Your sewage complaint has been submitted.', 'تم تقديم شكوى الصرف الصحي الخاصة بك.', 'status_update', false, NOW()),
        
        -- Notifications for citizen_4
        (citizen_4_id, complaint_5_id, 'Complaint Assigned', 'تم تعيين الشكوى', 'Your power outage complaint has been assigned.', 'تم تعيين شكوى انقطاع الكهرباء الخاصة بك.', 'status_update', false, NOW() - INTERVAL '1 day'),
        (citizen_4_id, complaint_14_id, 'Feedback Response', 'رد على التقييم', 'The team responded to your feedback.', 'رد الفريق على تقييمك.', 'feedback_response', true, NOW() - INTERVAL '11 days'),
        
        -- Notifications for citizen_5
        (citizen_5_id, complaint_11_id, 'Complaint Assigned', 'تم تعيين الشكوى', 'Your water supply complaint has been assigned.', 'تم تعيين شكوى تزويد المياه الخاصة بك.', 'status_update', false, NOW() - INTERVAL '2 days'),
        (citizen_5_id, complaint_15_id, 'Complaint Escalated', 'تم تصعيد الشكوى', 'Your lighting complaint has been escalated to management.', 'تم تصعيد شكوى الإنارة للإدارة.', 'escalation', false, NOW() - INTERVAL '7 days'),
        
        -- Employee notifications
        (employee_1_id, complaint_1_id, 'New Assignment', 'مهمة جديدة', 'You have been assigned a water leak complaint.', 'تم تعيينك لشكوى تسرب مياه.', 'assignment', true, NOW() - INTERVAL '8 days'),
        (employee_1_id, complaint_11_id, 'New Assignment', 'مهمة جديدة', 'You have been assigned a water supply complaint.', 'تم تعيينك لشكوى تزويد مياه.', 'assignment', false, NOW() - INTERVAL '2 days'),
        (employee_2_id, complaint_2_id, 'New Assignment', 'مهمة جديدة', 'You have been assigned a hospital complaint.', 'تم تعيينك لشكوى مستشفى.', 'assignment', true, NOW() - INTERVAL '3 days'),
        (employee_3_id, complaint_15_id, 'Urgent Assignment', 'مهمة عاجلة', 'Escalated complaint requires immediate attention.', 'شكوى مصعدة تتطلب اهتماماً فورياً.', 'assignment', false, NOW() - INTERVAL '7 days');

END $$;

-- ============================================
-- SUMMARY STATISTICS
-- ============================================

-- View to check dummy data counts
DO $$
BEGIN
    RAISE NOTICE '=== DUMMY DATA SUMMARY ===';
    RAISE NOTICE 'Profiles: %', (SELECT COUNT(*) FROM profiles);
    RAISE NOTICE 'Complaints: %', (SELECT COUNT(*) FROM complaints);
    RAISE NOTICE 'Attachments: %', (SELECT COUNT(*) FROM attachments);
    RAISE NOTICE 'Status History: %', (SELECT COUNT(*) FROM status_history);
    RAISE NOTICE 'Feedback: %', (SELECT COUNT(*) FROM feedback);
    RAISE NOTICE 'Notifications: %', (SELECT COUNT(*) FROM notifications);
    RAISE NOTICE 'Departments: %', (SELECT COUNT(*) FROM departments);
    RAISE NOTICE 'Categories: %', (SELECT COUNT(*) FROM categories);
END $$;
