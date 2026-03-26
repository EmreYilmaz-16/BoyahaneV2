-- =====================================================
-- Company Modülü - pbs_objects Menü Kayıtları
-- =====================================================
-- Çalıştırmadan önce pbs_objects tablonuzda hangi kolonlar
-- var olduğunu kontrol edin. Eksik kolon varsa ALTER TABLE ekleyin.
-- =====================================================

-- Önce mevcut kayıtları temizle (isteğe bağlı)
-- DELETE FROM pbs_objects WHERE full_fuseaction LIKE 'company.%';

-- Ana menü grubu (varsa üst menü id'sini ayarlayın)
-- Aşağıdaki parent_id değerini kendi menü ağacınıza göre güncelleyin

INSERT INTO pbs_objects (full_fuseaction, file_path, object_name, object_title, object_type, parent_id, sort_order, is_active, is_menu)
VALUES
-- Firma Kategorileri
('company.list_company_cat',   '/company/display/list_company_cat.cfm',  'list_company_cat',   'Firma Kategorileri',    'page',  NULL, 10, true, true),
('company.add_company_cat',    '/company/form/add_company_cat.cfm',      'add_company_cat',    'Kategori Ekle',         'page',  NULL, 11, true, false),
('company.edit_company_cat',   '/company/form/edit_company_cat.cfm',     'edit_company_cat',   'Kategori Düzenle',      'page',  NULL, 12, true, false),

-- Firma Listesi
('company.list_company',       '/company/display/list_company.cfm',      'list_company',       'Firmalar',              'page',  NULL, 20, true, true),
('company.add_company',        '/company/form/add_company.cfm',          'add_company',        'Firma Ekle',            'page',  NULL, 21, true, false),
('company.edit_company',       '/company/form/edit_company.cfm',         'edit_company',       'Firma Düzenle',         'page',  NULL, 22, true, false),

-- Sevkiyat Yöntemleri
('company.list_ship_method',   '/company/display/list_ship_method.cfm',  'list_ship_method',   'Sevkiyat Yöntemleri',   'page',  NULL, 30, true, true),
('company.add_ship_method',    '/company/form/add_ship_method.cfm',      'add_ship_method',    'Sevkiyat Ekle',         'page',  NULL, 31, true, false),
('company.edit_ship_method',   '/company/form/edit_ship_method.cfm',     'edit_ship_method',   'Sevkiyat Düzenle',      'page',  NULL, 32, true, false),

-- Ödeme Yöntemleri
('company.list_paymethod',     '/company/display/list_paymethod.cfm',    'list_paymethod',     'Ödeme Yöntemleri',      'page',  NULL, 40, true, true),
('company.add_paymethod',      '/company/form/add_paymethod.cfm',        'add_paymethod',      'Ödeme Yöntemi Ekle',    'page',  NULL, 41, true, false),
('company.edit_paymethod',     '/company/form/edit_paymethod.cfm',       'edit_paymethod',     'Ödeme Yöntemi Düzenle', 'page',  NULL, 42, true, false),

-- Kredi & Risk Limitleri
('company.list_company_credit','/company/display/list_company_credit.cfm','list_company_credit','Kredi & Risk Limitleri','page',  NULL, 50, true, true),
('company.add_company_credit', '/company/form/add_company_credit.cfm',   'add_company_credit', 'Kredi Kaydı Ekle',      'page',  NULL, 51, true, false),
('company.edit_company_credit','/company/form/edit_company_credit.cfm',  'edit_company_credit','Kredi Kaydı Düzenle',   'page',  NULL, 52, true, false)
;

-- NOT: parent_id, sort_order ve is_menu kolonları tablonuzda yoksa aşağıdaki minimal versiyonu kullanın:
-- INSERT INTO pbs_objects (full_fuseaction, file_path)
-- VALUES
-- ('company.list_company_cat', '/company/display/list_company_cat.cfm'),
-- ('company.add_company_cat',  '/company/form/add_company_cat.cfm'),
-- ('company.edit_company_cat', '/company/form/edit_company_cat.cfm'),
-- ('company.list_company',     '/company/display/list_company.cfm'),
-- ('company.add_company',      '/company/form/add_company.cfm'),
-- ('company.edit_company',     '/company/form/edit_company.cfm');
