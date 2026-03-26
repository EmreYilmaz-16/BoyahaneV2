-- =====================================================
-- Production Modülü - pbs_objects Menü Kayıtları
-- =====================================================
-- Önce mevcut kayıtları temizlemek için (gerekirse):
-- DELETE FROM pbs_objects WHERE full_fuseaction LIKE 'production.%';

INSERT INTO pbs_objects (full_fuseaction, file_path, object_name, object_title, object_type, parent_id, sort_order, is_active, is_menu)
VALUES
-- Operasyon Tipleri
('production.list_operation_types', '/production/display/list_operation_types.cfm', 'list_operation_types', 'Operasyon Tipleri',         'page', NULL, 10, true, true),
('production.add_operation_type',   '/production/form/add_operation_type.cfm',       'add_operation_type',   'Yeni Operasyon Tipi',        'page', NULL, 11, true, false),
('production.save_operation_type',  '/production/form/save_operation_type.cfm',       'save_operation_type',  'Operasyon Tipi Kaydet',      'page', NULL, 12, true, false),
('production.delete_operation_type','/production/form/delete_operation_type.cfm',     'delete_operation_type','Operasyon Tipi Sil',         'page', NULL, 13, true, false),

-- İş İstasyonları
('production.list_workstations',    '/production/display/list_workstations.cfm',      'list_workstations',    'İş İstasyonları',            'page', NULL, 20, true, true),
('production.add_workstation',      '/production/form/add_workstation.cfm',            'add_workstation',      'Yeni İş İstasyonu',          'page', NULL, 21, true, false),
('production.save_workstation',     '/production/form/save_workstation.cfm',           'save_workstation',     'İstasyon Kaydet',            'page', NULL, 22, true, false),
('production.delete_workstation',   '/production/form/delete_workstation.cfm',         'delete_workstation',   'İstasyon Sil',               'page', NULL, 23, true, false),

-- İstasyon-Ürün İlişkisi (AJAX uç noktaları, menüde görünmez)
('production.save_ws_product',      '/production/form/save_ws_product.cfm',            'save_ws_product',      'İstasyon Ürün Kaydet',       'page', NULL, 30, true, false),
('production.delete_ws_product',    '/production/form/delete_ws_product.cfm',          'delete_ws_product',    'İstasyon Ürün Sil',          'page', NULL, 31, true, false)
;

-- =====================================================
-- Modül kaydı yoksa önce pbs_module'e ekle:
-- =====================================================
-- INSERT INTO pbs_module (module_name, family_id, icon, show_menu, order_no)
-- VALUES ('Üretim', <family_id>, 'fa-industry', true, 5)
-- RETURNING module_id;
--
-- Ardından yukarıdaki INSERT'lere module_id'yi parent_id olarak ekleyin
-- veya doğrudan sisteminizin yönlendirme mekanizmasına göre ayarlayın.
