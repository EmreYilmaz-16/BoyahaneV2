-- =====================================================
-- Production Modülü - pbs_objects Menü Kayıtları
-- =====================================================
-- Önce mevcut kayıtları temizlemek için (gerekirse):
-- DELETE FROM pbs_objects WHERE full_fuseaction LIKE 'production.%';

INSERT INTO pbs_objects (full_fuseaction, file_path, object_name, object_title, object_type, parent_id, sort_order, is_active, is_menu)
VALUES

-- -- Üretim Emirleri (menüde görünür)
-- ('production.list_production_orders',  '/production/display/list_production_orders.cfm',  'list_production_orders',  'Üretim Emirleri',        'page', NULL, 40, true, true),
-- ('production.add_production_order',    '/production/form/add_production_order.cfm',        'add_production_order',    'Yeni Üretim Emri',       'page', NULL, 41, true, false),
-- ('production.view_production_order',   '/production/display/view_production_order.cfm',    'view_production_order',   'Üretim Emri Detayı',     'page', NULL, 42, true, false),

-- -- Üretim Emirleri — backend (menüde görünmez)
-- ('production.save_production_order',   '/production/form/save_production_order.cfm',       'save_production_order',   'Üretim Emri Kaydet',     'page', NULL, 43, true, false),
-- ('production.delete_production_order', '/production/form/delete_production_order.cfm',     'delete_production_order', 'Üretim Emri Sil',        'page', NULL, 44, true, false),
-- ('production.update_production_status','/production/form/update_production_status.cfm',    'update_production_status','Üretim Emri Durum Güncelle','page',NULL,45, true, false),
-- ('production.finalize_production_order','/production/form/finalize_production_order.cfm',  'finalize_production_order','Üretim Emri Sonuçlandır','page', NULL, 46, true, false),
-- ('production.save_production_stock',   '/production/form/save_production_stock.cfm',       'save_production_stock',   'Hammadde Tüketim Güncelle','page',NULL,47, true, false),

-- -- MES — Üretim Takip Ekranı (menüde görünür)
-- ('production.mes',                     '/production/display/mes.cfm',                      'mes',                     'MES Üretim Takip',         'page', NULL, 48, true, true),

-- -- MES — backend (menüde görünmez)
-- ('production.save_production_pause',      '/production/form/save_production_pause.cfm',         'save_production_pause',      'Duruş Kaydet',                    'page', NULL, 49, true, false),
('production.send_order_to_production',  '/production/form/send_order_to_production.cfm',      'send_order_to_production',   'Siparişten Üretim Emri Oluştur',  'page', NULL, 50, true, false),
('production.daily_dashboard',           '/production/display/daily_dashboard.cfm',             'daily_dashboard',            'Günlük Üretim Özeti',             'page', NULL, 51, true, true),
('production.print_recipe',              '/production/display/print_recipe.cfm',                 'print_recipe',               'Üretim Reçete Yazdır',            'page', NULL, 52, true, false),
('production.merge_production_orders','/production/form/merge_production_orders.cfm',       'merge_production_orders',    'Üretim Emri Birleştir',           'page', NULL, 53, true, false),
('production.list_productcategory_workstationgroup_relation', '/production/display/list_productcategory_workstationgroup_relation.cfm', 'list_productcategory_workstationgroup_relation', 'Kategori - İş İstasyonu Eşleştirmeleri', 'page', NULL, 54, true, true),
('production.add_productcategory_workstationgroup_relation', '/production/form/add_productcategory_workstationgroup_relation.cfm', 'add_productcategory_workstationgroup_relation', 'Kategori - İş İstasyonu Eşleştirme Ekle', 'page', NULL, 55, true, false),
('production.save_productcategory_workstationgroup_relation', '/production/form/save_productcategory_workstationgroup_relation.cfm', 'save_productcategory_workstationgroup_relation', 'Kategori - İş İstasyonu Eşleştirme Kaydet', 'page', NULL, 56, true, false),
('production.delete_productcategory_workstationgroup_relation', '/production/form/delete_productcategory_workstationgroup_relation.cfm', 'delete_productcategory_workstationgroup_relation', 'Kategori - İş İstasyonu Eşleştirme Sil', 'page', NULL, 57, true, false)
ON CONFLICT (full_fuseaction) DO NOTHING;

-- =====================================================
-- Modül kaydı yoksa önce pbs_module'e ekle:
-- =====================================================
-- INSERT INTO pbs_module (module_name, family_id, icon, show_menu, order_no)
-- VALUES ('Üretim', <family_id>, 'fa-industry', true, 5)
-- RETURNING module_id;
--
-- Ardından yukarıdaki INSERT'lere module_id'yi parent_id olarak ekleyin
-- veya doğrudan sisteminizin yönlendirme mekanizmasına göre ayarlayın.
