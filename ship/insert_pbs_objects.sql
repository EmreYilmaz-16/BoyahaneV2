-- =====================================================
-- Ship Modülü - pbs_objects Menü Kayıtları
-- =====================================================
-- DELETE FROM pbs_objects WHERE full_fuseaction LIKE 'ship.%';

INSERT INTO pbs_objects (full_fuseaction, file_path, object_name, object_title, object_type, parent_id, sort_order, is_active, is_menu)
VALUES

-- İrsaliye / Sevkiyat Modülü
('ship.list_ship',    '/ship/display/list_ship.cfm',   'list_ship',    'İrsaliyeler',        'page', NULL, 10, true, true),
('ship.add_ship',     '/ship/form/add_ship.cfm',       'add_ship',     'İrsaliye Ekle',      'page', NULL, 11, true, true),
('ship.save_ship',    '/ship/form/save_ship.cfm',      'save_ship',    'İrsaliye Kaydet',    'page', NULL, 12, true, false),
('ship.delete_ship',    '/ship/form/delete_ship.cfm',    'delete_ship',    'İrsaliye Sil',            'page', NULL, 13, true, false),
('ship.add_giris_fis',  '/ship/form/add_giris_fis.cfm',  'add_giris_fis',  'Ham Kumaş Giriş İrs.',    'page', NULL, 14, true, true),
('ship.add_parti',      '/ship/form/add_parti.cfm',      'add_parti',      'Parti Oluştur',           'page', NULL, 15, true, false),
('ship.list_partiler',          '/ship/display/list_partiler.cfm',           'list_partiler',          'Parti Listesi',              'page', NULL, 16, true, false),
('ship.list_giris_fis',         '/ship/display/list_giris_fis.cfm',          'list_giris_fis',         'Ham Kumaş Girişleri',        'page', NULL, 17, true, true),
('ship.update_order_row_stock', '/ship/form/update_order_row_stock.cfm',     'update_order_row_stock', 'Sipariş Satırı Stok Güncelle','page', NULL, 18, true, false)
;

-- Minimal (full_fuseaction + file_path yeterli ise):
-- INSERT INTO pbs_objects (full_fuseaction, file_path)
-- VALUES
-- ('ship.list_ship',   '/ship/display/list_ship.cfm'),
-- ('ship.add_ship',    '/ship/form/add_ship.cfm'),
-- ('ship.save_ship',   '/ship/form/save_ship.cfm'),
-- ('ship.delete_ship', '/ship/form/delete_ship.cfm');
