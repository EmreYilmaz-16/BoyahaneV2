-- PBS (Partner Business Solutions) Menü ve Modül Yapısı Tabloları

-- 1. PBS Solution (Çözümler)
CREATE TABLE IF NOT EXISTS pbs_solution (
    solution_id SERIAL PRIMARY KEY,
    solution_name VARCHAR(255) NOT NULL,
    icon VARCHAR(100),
    show_menu BOOLEAN DEFAULT true,
    order_no INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. PBS Family (Aileler/Kategoriler)
CREATE TABLE IF NOT EXISTS pbs_family (
    family_id SERIAL PRIMARY KEY,
    family_name VARCHAR(255) NOT NULL,
    solution_id INTEGER NOT NULL,
    icon VARCHAR(100),
    show_menu BOOLEAN DEFAULT true,
    order_no INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_family_solution FOREIGN KEY (solution_id) 
        REFERENCES pbs_solution(solution_id) ON DELETE CASCADE
);

-- 3. PBS Module (Modüller)
CREATE TABLE IF NOT EXISTS pbs_module (
    module_id SERIAL PRIMARY KEY,
    module_name VARCHAR(255) NOT NULL,
    family_id INTEGER NOT NULL,
    icon VARCHAR(100),
    show_menu BOOLEAN DEFAULT true,
    order_no INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_module_family FOREIGN KEY (family_id) 
        REFERENCES pbs_family(family_id) ON DELETE CASCADE
);

-- 4. PBS Objects (Nesneler/Sayfalar)
CREATE TABLE IF NOT EXISTS pbs_objects (
    object_id SERIAL PRIMARY KEY,
    object_name VARCHAR(255) NOT NULL,
    module_id INTEGER NOT NULL,
    show_menu BOOLEAN DEFAULT true,
    window_type VARCHAR(20) DEFAULT 'standart' CHECK (window_type IN ('popup', 'ajaxpage', 'standart')),
    full_fuseaction VARCHAR(255),
    file_path VARCHAR(500),
    order_no INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_object_module FOREIGN KEY (module_id) 
        REFERENCES pbs_module(module_id) ON DELETE CASCADE
);

-- Index'ler oluştur (Performance için)
CREATE INDEX IF NOT EXISTS idx_pbs_family_solution ON pbs_family(solution_id);
CREATE INDEX IF NOT EXISTS idx_pbs_module_family ON pbs_module(family_id);
CREATE INDEX IF NOT EXISTS idx_pbs_objects_module ON pbs_objects(module_id);
CREATE INDEX IF NOT EXISTS idx_pbs_objects_fuseaction ON pbs_objects(full_fuseaction);

-- Trigger'lar (updated_at otomatik güncelleme için)
CREATE OR REPLACE FUNCTION update_pbs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_pbs_solution_updated_at ON pbs_solution;
CREATE TRIGGER update_pbs_solution_updated_at
    BEFORE UPDATE ON pbs_solution
    FOR EACH ROW
    EXECUTE FUNCTION update_pbs_updated_at();

DROP TRIGGER IF EXISTS update_pbs_family_updated_at ON pbs_family;
CREATE TRIGGER update_pbs_family_updated_at
    BEFORE UPDATE ON pbs_family
    FOR EACH ROW
    EXECUTE FUNCTION update_pbs_updated_at();

DROP TRIGGER IF EXISTS update_pbs_module_updated_at ON pbs_module;
CREATE TRIGGER update_pbs_module_updated_at
    BEFORE UPDATE ON pbs_module
    FOR EACH ROW
    EXECUTE FUNCTION update_pbs_updated_at();

DROP TRIGGER IF EXISTS update_pbs_objects_updated_at ON pbs_objects;
CREATE TRIGGER update_pbs_objects_updated_at
    BEFORE UPDATE ON pbs_objects
    FOR EACH ROW
    EXECUTE FUNCTION update_pbs_updated_at();

-- Örnek Veriler
-- Solution (Çözüm Kategorileri)
INSERT INTO pbs_solution (solution_name, icon, show_menu, order_no) VALUES
    ('Üretim Yönetimi', 'fa-industry', true, 1),
    ('Stok Yönetimi', 'fa-boxes', true, 2),
    ('Kalite Kontrol', 'fa-check-circle', true, 3),
    ('Raporlama', 'fa-chart-bar', true, 4),
    ('Sistem Yönetimi', 'fa-cog', true, 5)
ON CONFLICT DO NOTHING;

-- Family (Modül Aileleri)
INSERT INTO pbs_family (family_name, solution_id, icon, show_menu, order_no) VALUES
    ('Üretim Planlama', 1, 'fa-calendar-alt', true, 1),
    ('İş Emirleri', 1, 'fa-tasks', true, 2),
    ('Stok Hareketi', 2, 'fa-exchange-alt', true, 1),
    ('Envanter', 2, 'fa-warehouse', true, 2),
    ('Kalite Testleri', 3, 'fa-vial', true, 1),
    ('Performans Raporları', 4, 'fa-chart-line', true, 1),
    ('Kullanıcı Yönetimi', 5, 'fa-users', true, 1)
ON CONFLICT DO NOTHING;

-- Module (Modüller)
INSERT INTO pbs_module (module_name, family_id, icon, show_menu, order_no) VALUES
    ('Üretim Planı', 1, 'fa-clipboard-list', true, 1),
    ('Kapasite Planlama', 1, 'fa-tachometer-alt', true, 2),
    ('İş Emri Girişi', 2, 'fa-plus-square', true, 1),
    ('İş Emri Takibi', 2, 'fa-list-alt', true, 2),
    ('Stok Giriş', 3, 'fa-sign-in-alt', true, 1),
    ('Stok Çıkış', 3, 'fa-sign-out-alt', true, 2),
    ('Sayım', 4, 'fa-calculator', true, 1),
    ('Test Kayıtları', 5, 'fa-file-medical', true, 1),
    ('Günlük Rapor', 6, 'fa-calendar-day', true, 1),
    ('Aylık Rapor', 6, 'fa-calendar-alt', true, 2),
    ('Kullanıcılar', 7, 'fa-user-friends', true, 1)
ON CONFLICT DO NOTHING;

-- Objects (Sayfalar/İşlemler)
INSERT INTO pbs_objects (object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no) VALUES
    ('Yeni Üretim Planı', 1, true, 'ajaxpage', 'production.add_plan', '/modules/production/add_plan.cfm', 1),
    ('Plan Listesi', 1, true, 'standart', 'production.list_plans', '/modules/production/list_plans.cfm', 2),
    ('Kapasite Analizi', 2, true, 'standart', 'production.capacity', '/modules/production/capacity.cfm', 1),
    ('Yeni İş Emri', 3, true, 'popup', 'workorder.add', '/modules/workorder/add.cfm', 1),
    ('İş Emri Listesi', 4, true, 'standart', 'workorder.list', '/modules/workorder/list.cfm', 1),
    ('İş Emri Detay', 4, false, 'ajaxpage', 'workorder.detail', '/modules/workorder/detail.cfm', 2),
    ('Stok Giriş Formu', 5, true, 'popup', 'stock.entry', '/modules/stock/entry.cfm', 1),
    ('Stok Çıkış Formu', 6, true, 'popup', 'stock.exit', '/modules/stock/exit.cfm', 1),
    ('Stok Hareketleri', 6, true, 'standart', 'stock.movements', '/modules/stock/movements.cfm', 2),
    ('Sayım Formu', 7, true, 'standart', 'inventory.count', '/modules/inventory/count.cfm', 1),
    ('Test Giriş', 8, true, 'popup', 'quality.test_entry', '/modules/quality/test_entry.cfm', 1),
    ('Test Sonuçları', 8, true, 'standart', 'quality.test_results', '/modules/quality/test_results.cfm', 2),
    ('Günlük Üretim Raporu', 9, true, 'standart', 'reports.daily_production', '/reports/daily_production.cfm', 1),
    ('Aylık Özet', 10, true, 'standart', 'reports.monthly_summary', '/reports/monthly_summary.cfm', 1),
    ('Kullanıcı Listesi', 11, true, 'standart', 'admin.users', '/admin/users.cfm', 1),
    ('Yeni Kullanıcı', 11, true, 'popup', 'admin.add_user', '/admin/add_user.cfm', 2)
ON CONFLICT DO NOTHING;

-- Log kaydı
DO $$
BEGIN
    RAISE NOTICE 'PBS menü yapısı tabloları başarıyla oluşturuldu!';
    RAISE NOTICE '- pbs_solution: % kayıt', (SELECT COUNT(*) FROM pbs_solution);
    RAISE NOTICE '- pbs_family: % kayıt', (SELECT COUNT(*) FROM pbs_family);
    RAISE NOTICE '- pbs_module: % kayıt', (SELECT COUNT(*) FROM pbs_module);
    RAISE NOTICE '- pbs_objects: % kayıt', (SELECT COUNT(*) FROM pbs_objects);
END $$;
