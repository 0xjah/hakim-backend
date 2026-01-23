-- ============================================
-- JORDANIAN GOVERNMENT ENTITIES MIGRATION
-- For HAKIM Complaint Management System
-- ============================================

-- Clear existing seed data (if any)
DELETE FROM categories;
DELETE FROM departments;

-- ============================================
-- MINISTRIES (الوزارات)
-- ============================================

-- وزارة الصحة
INSERT INTO departments (id, name, name_ar, description, email, is_active) VALUES
    (uuid_generate_v4(), 'Ministry of Health', 'وزارة الصحة', 'مسؤولة عن الخدمات الصحية والمستشفيات', 'health@gov.jo', true);

-- وزارة التربية والتعليم
INSERT INTO departments (id, name, name_ar, description, email, is_active) VALUES
    (uuid_generate_v4(), 'Ministry of Education', 'وزارة التربية والتعليم', 'مسؤولة عن التعليم العام والمدارس', 'education@gov.jo', true);

-- وزارة النقل
INSERT INTO departments (id, name, name_ar, description, email, is_active) VALUES
    (uuid_generate_v4(), 'Ministry of Transport', 'وزارة النقل', 'مسؤولة عن النقل والمواصلات', 'transport@gov.jo', true);

-- وزارة المياه والري
INSERT INTO departments (id, name, name_ar, description, email, is_active) VALUES
    (uuid_generate_v4(), 'Ministry of Water and Irrigation', 'وزارة المياه والري', 'مسؤولة عن المياه والصرف الصحي', 'water@gov.jo', true);

-- وزارة الصناعة والتجارة والتموين
INSERT INTO departments (id, name, name_ar, description, email, is_active) VALUES
    (uuid_generate_v4(), 'Ministry of Industry and Trade', 'وزارة الصناعة والتجارة والتموين', 'مسؤولة عن التجارة وحماية المستهلك', 'trade@gov.jo', true);

-- وزارة الداخلية
INSERT INTO departments (id, name, name_ar, description, email, is_active) VALUES
    (uuid_generate_v4(), 'Ministry of Interior', 'وزارة الداخلية', 'مسؤولة عن الأحوال المدنية والجوازات', 'interior@gov.jo', true);

-- وزارة الإدارة المحلية
INSERT INTO departments (id, name, name_ar, description, email, is_active) VALUES
    (uuid_generate_v4(), 'Ministry of Local Administration', 'وزارة الإدارة المحلية', 'مسؤولة عن البلديات والمحافظات', 'local@gov.jo', true);

-- وزارة المالية
INSERT INTO departments (id, name, name_ar, description, email, is_active) VALUES
    (uuid_generate_v4(), 'Ministry of Finance', 'وزارة المالية', 'مسؤولة عن الضرائب والجمارك', 'finance@gov.jo', true);

-- وزارة التنمية الاجتماعية
INSERT INTO departments (id, name, name_ar, description, email, is_active) VALUES
    (uuid_generate_v4(), 'Ministry of Social Development', 'وزارة التنمية الاجتماعية', 'مسؤولة عن الشؤون الاجتماعية والمعونات', 'social@gov.jo', true);

-- وزارة العمل
INSERT INTO departments (id, name, name_ar, description, email, is_active) VALUES
    (uuid_generate_v4(), 'Ministry of Labor', 'وزارة العمل', 'مسؤولة عن شؤون العمال والتوظيف', 'labor@gov.jo', true);

-- وزارة الأشغال العامة والإسكان
INSERT INTO departments (id, name, name_ar, description, email, is_active) VALUES
    (uuid_generate_v4(), 'Ministry of Public Works', 'وزارة الأشغال العامة والإسكان', 'مسؤولة عن الطرق والمباني الحكومية', 'works@gov.jo', true);

-- وزارة الطاقة والثروة المعدنية
INSERT INTO departments (id, name, name_ar, description, email, is_active) VALUES
    (uuid_generate_v4(), 'Ministry of Energy', 'وزارة الطاقة والثروة المعدنية', 'مسؤولة عن الكهرباء والطاقة', 'energy@gov.jo', true);

-- وزارة البيئة
INSERT INTO departments (id, name, name_ar, description, email, is_active) VALUES
    (uuid_generate_v4(), 'Ministry of Environment', 'وزارة البيئة', 'مسؤولة عن الشؤون البيئية', 'environment@gov.jo', true);

-- وزارة الاقتصاد الرقمي والريادة
INSERT INTO departments (id, name, name_ar, description, email, is_active) VALUES
    (uuid_generate_v4(), 'Ministry of Digital Economy', 'وزارة الاقتصاد الرقمي والريادة', 'مسؤولة عن الاتصالات والتحول الرقمي', 'digital@gov.jo', true);

-- ============================================
-- INDEPENDENT AUTHORITIES (هيئات مستقلة)
-- ============================================

-- أمانة عمان الكبرى
INSERT INTO departments (id, name, name_ar, description, email, is_active) VALUES
    (uuid_generate_v4(), 'Greater Amman Municipality', 'أمانة عمان الكبرى', 'مسؤولة عن خدمات العاصمة عمان', 'gam@amman.jo', true);

-- مديرية الأمن العام
INSERT INTO departments (id, name, name_ar, description, email, is_active) VALUES
    (uuid_generate_v4(), 'Public Security Directorate', 'مديرية الأمن العام', 'مسؤولة عن الأمن والسلامة', 'psd@gov.jo', true);

-- هيئة تنظيم قطاع الاتصالات
INSERT INTO departments (id, name, name_ar, description, email, is_active) VALUES
    (uuid_generate_v4(), 'Telecommunications Regulatory Commission', 'هيئة تنظيم قطاع الاتصالات', 'مسؤولة عن الاتصالات والإنترنت', 'trc@gov.jo', true);

-- ============================================
-- CATEGORIES (التصنيفات)
-- ============================================

-- === وزارة الصحة ===
INSERT INTO categories (name, name_ar, department_id, icon, keywords, description) VALUES
    ('Hospital Services', 'خدمات المستشفيات', (SELECT id FROM departments WHERE name = 'Ministry of Health'), 'local_hospital', 
     ARRAY['مستشفى', 'طوارئ', 'علاج', 'أطباء', 'تنويم', 'عيادة', 'hospital', 'emergency', 'doctor', 'clinic'],
     'شكاوى متعلقة بخدمات المستشفيات الحكومية'),
    ('Primary Healthcare', 'الرعاية الصحية الأولية', (SELECT id FROM departments WHERE name = 'Ministry of Health'), 'health_and_safety',
     ARRAY['مركز صحي', 'تطعيم', 'لقاح', 'فحص', 'صحة', 'health center', 'vaccine', 'checkup'],
     'شكاوى متعلقة بالمراكز الصحية'),
    ('Pharmacy and Medicine', 'الأدوية والصيدليات', (SELECT id FROM departments WHERE name = 'Ministry of Health'), 'medication',
     ARRAY['دواء', 'صيدلية', 'علاج', 'نقص أدوية', 'medicine', 'pharmacy', 'drug'],
     'شكاوى متعلقة بالأدوية والصيدليات');

-- === وزارة التربية والتعليم ===
INSERT INTO categories (name, name_ar, department_id, icon, keywords, description) VALUES
    ('School Issues', 'مشاكل المدارس', (SELECT id FROM departments WHERE name = 'Ministry of Education'), 'school',
     ARRAY['مدرسة', 'معلم', 'طالب', 'تعليم', 'صف', 'منهاج', 'school', 'teacher', 'student', 'education'],
     'شكاوى متعلقة بالمدارس والتعليم'),
    ('School Buildings', 'الأبنية المدرسية', (SELECT id FROM departments WHERE name = 'Ministry of Education'), 'business',
     ARRAY['بناء مدرسة', 'صيانة', 'مرافق', 'ملعب', 'building', 'maintenance', 'facilities'],
     'شكاوى متعلقة بالأبنية المدرسية'),
    ('Exams and Results', 'الامتحانات والنتائج', (SELECT id FROM departments WHERE name = 'Ministry of Education'), 'assignment',
     ARRAY['امتحان', 'نتيجة', 'توجيهي', 'علامات', 'exam', 'result', 'tawjihi', 'grades'],
     'شكاوى متعلقة بالامتحانات والنتائج');

-- === وزارة النقل ===
INSERT INTO categories (name, name_ar, department_id, icon, keywords, description) VALUES
    ('Public Transportation', 'النقل العام', (SELECT id FROM departments WHERE name = 'Ministry of Transport'), 'directions_bus',
     ARRAY['باص', 'حافلة', 'نقل عام', 'مواصلات', 'bus', 'public transport', 'commute'],
     'شكاوى متعلقة بالنقل العام'),
    ('Driver Licensing', 'رخص القيادة', (SELECT id FROM departments WHERE name = 'Ministry of Transport'), 'badge',
     ARRAY['رخصة', 'قيادة', 'سواقة', 'فحص', 'license', 'driving', 'test'],
     'شكاوى متعلقة برخص القيادة');

-- === وزارة المياه والري ===
INSERT INTO categories (name, name_ar, department_id, icon, keywords, description) VALUES
    ('Water Supply', 'تزويد المياه', (SELECT id FROM departments WHERE name = 'Ministry of Water and Irrigation'), 'water_drop',
     ARRAY['مياه', 'انقطاع', 'ضخ', 'خزان', 'تزويد', 'water', 'supply', 'cut', 'tank'],
     'شكاوى متعلقة بتزويد المياه'),
    ('Water Leak', 'تسرب مياه', (SELECT id FROM departments WHERE name = 'Ministry of Water and Irrigation'), 'plumbing',
     ARRAY['تسرب', 'تسريب', 'انبوب', 'ماسورة', 'leak', 'pipe', 'broken'],
     'شكاوى متعلقة بتسرب المياه'),
    ('Sewage Issues', 'مشاكل الصرف الصحي', (SELECT id FROM departments WHERE name = 'Ministry of Water and Irrigation'), 'water_damage',
     ARRAY['صرف صحي', 'مجاري', 'طفح', 'رائحة', 'sewage', 'drainage', 'overflow', 'smell'],
     'شكاوى متعلقة بالصرف الصحي');

-- === وزارة الصناعة والتجارة ===
INSERT INTO categories (name, name_ar, department_id, icon, keywords, description) VALUES
    ('Consumer Protection', 'حماية المستهلك', (SELECT id FROM departments WHERE name = 'Ministry of Industry and Trade'), 'verified_user',
     ARRAY['غش', 'احتيال', 'سعر', 'منتج فاسد', 'حماية المستهلك', 'fraud', 'price', 'consumer', 'expired'],
     'شكاوى متعلقة بحماية المستهلك'),
    ('Commercial Violations', 'مخالفات تجارية', (SELECT id FROM departments WHERE name = 'Ministry of Industry and Trade'), 'store',
     ARRAY['محل', 'تجارة', 'مخالفة', 'رخصة تجارية', 'shop', 'business', 'violation', 'license'],
     'شكاوى متعلقة بالمخالفات التجارية');

-- === وزارة الداخلية ===
INSERT INTO categories (name, name_ar, department_id, icon, keywords, description) VALUES
    ('Civil Status', 'الأحوال المدنية', (SELECT id FROM departments WHERE name = 'Ministry of Interior'), 'badge',
     ARRAY['هوية', 'جواز', 'شهادة ميلاد', 'أحوال مدنية', 'id', 'passport', 'birth certificate', 'civil'],
     'شكاوى متعلقة بالأحوال المدنية'),
    ('Passport Services', 'خدمات الجوازات', (SELECT id FROM departments WHERE name = 'Ministry of Interior'), 'card_travel',
     ARRAY['جواز سفر', 'تجديد جواز', 'إصدار جواز', 'passport', 'travel', 'renewal'],
     'شكاوى متعلقة بالجوازات');

-- === وزارة المالية ===
INSERT INTO categories (name, name_ar, department_id, icon, keywords, description) VALUES
    ('Tax Issues', 'الضرائب', (SELECT id FROM departments WHERE name = 'Ministry of Finance'), 'receipt_long',
     ARRAY['ضريبة', 'دخل', 'مبيعات', 'إقرار ضريبي', 'tax', 'income', 'sales', 'return'],
     'شكاوى متعلقة بالضرائب'),
    ('Customs Issues', 'الجمارك', (SELECT id FROM departments WHERE name = 'Ministry of Finance'), 'local_shipping',
     ARRAY['جمارك', 'استيراد', 'تخليص', 'بضائع', 'customs', 'import', 'clearance', 'goods'],
     'شكاوى متعلقة بالجمارك');

-- === وزارة التنمية الاجتماعية ===
INSERT INTO categories (name, name_ar, department_id, icon, keywords, description) VALUES
    ('Social Assistance', 'المعونات الاجتماعية', (SELECT id FROM departments WHERE name = 'Ministry of Social Development'), 'volunteer_activism',
     ARRAY['معونة', 'مساعدة', 'فقير', 'محتاج', 'صندوق المعونة', 'aid', 'assistance', 'help', 'poor'],
     'شكاوى متعلقة بالمعونات الاجتماعية'),
    ('Disability Services', 'خدمات ذوي الإعاقة', (SELECT id FROM departments WHERE name = 'Ministry of Social Development'), 'accessible',
     ARRAY['إعاقة', 'ذوي الاحتياجات', 'كرسي متحرك', 'disability', 'special needs', 'wheelchair'],
     'شكاوى متعلقة بخدمات ذوي الإعاقة');

-- === وزارة العمل ===
INSERT INTO categories (name, name_ar, department_id, icon, keywords, description) VALUES
    ('Labor Violations', 'مخالفات العمل', (SELECT id FROM departments WHERE name = 'Ministry of Labor'), 'work',
     ARRAY['عمل', 'راتب', 'فصل', 'تأخير رواتب', 'حقوق عمالية', 'labor', 'salary', 'dismissal', 'rights'],
     'شكاوى متعلقة بمخالفات العمل'),
    ('Work Permits', 'تصاريح العمل', (SELECT id FROM departments WHERE name = 'Ministry of Labor'), 'badge',
     ARRAY['تصريح عمل', 'وافد', 'عامل', 'work permit', 'foreign worker', 'employee'],
     'شكاوى متعلقة بتصاريح العمل');

-- === وزارة الأشغال العامة ===
INSERT INTO categories (name, name_ar, department_id, icon, keywords, description) VALUES
    ('Road Damage', 'أضرار الطرق', (SELECT id FROM departments WHERE name = 'Ministry of Public Works'), 'warning',
     ARRAY['حفرة', 'طريق', 'شارع', 'رصيف', 'pothole', 'road', 'street', 'pavement', 'damage'],
     'شكاوى متعلقة بأضرار الطرق'),
    ('Government Buildings', 'المباني الحكومية', (SELECT id FROM departments WHERE name = 'Ministry of Public Works'), 'apartment',
     ARRAY['مبنى حكومي', 'صيانة', 'ترميم', 'government building', 'maintenance', 'repair'],
     'شكاوى متعلقة بالمباني الحكومية');

-- === وزارة الطاقة ===
INSERT INTO categories (name, name_ar, department_id, icon, keywords, description) VALUES
    ('Power Outage', 'انقطاع الكهرباء', (SELECT id FROM departments WHERE name = 'Ministry of Energy'), 'flash_off',
     ARRAY['كهرباء', 'انقطاع', 'تيار', 'محول', 'electricity', 'power', 'outage', 'blackout'],
     'شكاوى متعلقة بانقطاع الكهرباء'),
    ('Electricity Bills', 'فواتير الكهرباء', (SELECT id FROM departments WHERE name = 'Ministry of Energy'), 'receipt',
     ARRAY['فاتورة', 'كهرباء', 'استهلاك', 'عداد', 'bill', 'electricity', 'meter', 'consumption'],
     'شكاوى متعلقة بفواتير الكهرباء');

-- === وزارة البيئة ===
INSERT INTO categories (name, name_ar, department_id, icon, keywords, description) VALUES
    ('Pollution', 'التلوث البيئي', (SELECT id FROM departments WHERE name = 'Ministry of Environment'), 'air',
     ARRAY['تلوث', 'بيئة', 'هواء', 'دخان', 'pollution', 'environment', 'air', 'smoke'],
     'شكاوى متعلقة بالتلوث البيئي'),
    ('Waste Management', 'إدارة النفايات', (SELECT id FROM departments WHERE name = 'Ministry of Environment'), 'delete',
     ARRAY['نفايات', 'قمامة', 'مكب', 'تدوير', 'waste', 'garbage', 'landfill', 'recycling'],
     'شكاوى متعلقة بإدارة النفايات');

-- === أمانة عمان الكبرى ===
INSERT INTO categories (name, name_ar, department_id, icon, keywords, description) VALUES
    ('Street Lighting', 'إنارة الشوارع', (SELECT id FROM departments WHERE name = 'Greater Amman Municipality'), 'lightbulb',
     ARRAY['إنارة', 'عمود', 'ظلام', 'شارع', 'lighting', 'lamp', 'street', 'dark'],
     'شكاوى متعلقة بإنارة الشوارع'),
    ('Garbage Collection', 'جمع النفايات', (SELECT id FROM departments WHERE name = 'Greater Amman Municipality'), 'delete_sweep',
     ARRAY['نظافة', 'قمامة', 'زبالة', 'حاوية', 'garbage', 'cleaning', 'trash', 'container'],
     'شكاوى متعلقة بجمع النفايات'),
    ('Parks and Gardens', 'الحدائق والمتنزهات', (SELECT id FROM departments WHERE name = 'Greater Amman Municipality'), 'park',
     ARRAY['حديقة', 'متنزه', 'أشجار', 'ملعب', 'park', 'garden', 'trees', 'playground'],
     'شكاوى متعلقة بالحدائق'),
    ('Building Permits', 'رخص الأبنية', (SELECT id FROM departments WHERE name = 'Greater Amman Municipality'), 'engineering',
     ARRAY['رخصة بناء', 'تنظيم', 'مخالفة بناء', 'building permit', 'zoning', 'violation'],
     'شكاوى متعلقة برخص الأبنية'),
    ('Traffic and Roads', 'السير والطرق', (SELECT id FROM departments WHERE name = 'Greater Amman Municipality'), 'traffic',
     ARRAY['سير', 'إشارة', 'ازدحام', 'موقف', 'traffic', 'signal', 'congestion', 'parking'],
     'شكاوى متعلقة بالسير والطرق');

-- === مديرية الأمن العام ===
INSERT INTO categories (name, name_ar, department_id, icon, keywords, description) VALUES
    ('Traffic Violations', 'مخالفات السير', (SELECT id FROM departments WHERE name = 'Public Security Directorate'), 'directions_car',
     ARRAY['مخالفة سير', 'غرامة', 'سرعة', 'traffic violation', 'fine', 'speeding'],
     'شكاوى متعلقة بمخالفات السير'),
    ('Emergency Services', 'خدمات الطوارئ', (SELECT id FROM departments WHERE name = 'Public Security Directorate'), 'emergency',
     ARRAY['طوارئ', 'نجدة', 'إسعاف', 'دفاع مدني', 'emergency', 'ambulance', 'civil defense'],
     'شكاوى متعلقة بخدمات الطوارئ'),
    ('Security Reports', 'البلاغات الأمنية', (SELECT id FROM departments WHERE name = 'Public Security Directorate'), 'security',
     ARRAY['أمن', 'بلاغ', 'شرطة', 'سرقة', 'security', 'report', 'police', 'theft'],
     'بلاغات أمنية عامة');

-- === هيئة الاتصالات ===
INSERT INTO categories (name, name_ar, department_id, icon, keywords, description) VALUES
    ('Internet Issues', 'مشاكل الإنترنت', (SELECT id FROM departments WHERE name = 'Telecommunications Regulatory Commission'), 'wifi',
     ARRAY['إنترنت', 'اتصال', 'شبكة', 'بطء', 'internet', 'connection', 'network', 'slow'],
     'شكاوى متعلقة بالإنترنت'),
    ('Telecom Services', 'خدمات الاتصالات', (SELECT id FROM departments WHERE name = 'Telecommunications Regulatory Commission'), 'phone',
     ARRAY['هاتف', 'موبايل', 'اتصالات', 'فاتورة', 'phone', 'mobile', 'telecom', 'bill'],
     'شكاوى متعلقة بالاتصالات');

-- ============================================
-- ADD SLA DAYS COLUMN IF NOT EXISTS
-- ============================================

ALTER TABLE categories ADD COLUMN IF NOT EXISTS sla_days INTEGER DEFAULT 14;

-- ============================================
-- SET SLA DAYS FOR CATEGORIES
-- ============================================

UPDATE categories SET sla_days = 3 WHERE name IN ('Power Outage', 'Water Supply', 'Emergency Services');
UPDATE categories SET sla_days = 5 WHERE name IN ('Water Leak', 'Sewage Issues', 'Garbage Collection');
UPDATE categories SET sla_days = 7 WHERE name IN ('Road Damage', 'Street Lighting', 'Pollution');
UPDATE categories SET sla_days = 14 WHERE name NOT IN ('Power Outage', 'Water Supply', 'Emergency Services', 'Water Leak', 'Sewage Issues', 'Garbage Collection', 'Road Damage', 'Street Lighting', 'Pollution');
