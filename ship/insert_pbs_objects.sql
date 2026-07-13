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
('ship.update_order_row_stock', '/ship/form/update_order_row_stock.cfm',     'update_order_row_stock', 'Sipariş Satırı Stok Güncelle','page', NULL, 18, true, false),
('ship.detail_parti',          '/ship/display/detail_parti.cfm',            'detail_parti',           'Parti Detay',               'page', NULL, 19, true, false),
('ship.giris_fis_panel',       '/ship/display/giris_fis_panel.cfm',         'giris_fis_panel',        'Giriş Fişi Paneli',         'page', NULL, 20, true, true),
('ship.add_ship_rolls',        '/ship/form/add_ship_rolls.cfm',             'add_ship_rolls',         'Sarım Topları',            'page', NULL, 21, true, false),
('ship.save_ship_rolls',       '/ship/form/save_ship_rolls.cfm',            'save_ship_rolls',        'Sarım Topları Kaydet',     'page', NULL, 22, true, false),
('ship.get_parti_by_barcode',  '/ship/form/get_parti_by_barcode.cfm',       'get_parti_by_barcode',   'Barkoddan Parti Getir',    'page', NULL, 23, true, false),
('ship.operator_roll_scan',    '/ship/form/operator_roll_scan.cfm',         'operator_roll_scan',     'Operatör Ekranı',          'page', NULL, 24, true, true),
('ship.operator_roll_entry',   '/ship/form/operator_roll_entry.cfm',        'operator_roll_entry',    'Operatör Sarım Girişi',    'page', NULL, 25, true, false),
('ship.save_operator_roll',    '/ship/form/save_operator_roll.cfm',         'save_operator_roll',     'Operatör Top Kaydet',      'page', NULL, 26, true, false),
('ship.dispatch_roll_scan',    '/ship/form/dispatch_roll_scan.cfm',         'dispatch_roll_scan',     'Top Barkod Sevkiyat',      'page', NULL, 27, true, true),
('ship.get_roll_by_barcode',   '/ship/form/get_roll_by_barcode.cfm',        'get_roll_by_barcode',    'Top Barkoddan Getir',      'page', NULL, 28, true, false),
('ship.save_dispatch_rolls',   '/ship/form/save_dispatch_rolls.cfm',        'save_dispatch_rolls',    'Topları Sevk Et',          'page', NULL, 29, true, false),
('ship.parti_paket_toplari',   '/ship/display/parti_paket_toplari.cfm',     'parti_paket_toplari',    'Parti Paket Topları',      'page', NULL, 30, true, true)
;

-- Minimal (full_fuseaction + file_path yeterli ise):
-- INSERT INTO pbs_objects (full_fuseaction, file_path)
-- VALUES
-- ('ship.list_ship',   '/ship/display/list_ship.cfm'),
-- ('ship.add_ship',    '/ship/form/add_ship.cfm'),
-- ('ship.save_ship',   '/ship/form/save_ship.cfm'),
-- ('ship.delete_ship', '/ship/form/delete_ship.cfm');
