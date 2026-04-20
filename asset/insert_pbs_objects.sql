-- =====================================================
-- Asset Modülü - pbs_objects Menü Kayıtları
-- =====================================================
-- DELETE FROM pbs_objects WHERE full_fuseaction LIKE 'asset.%';

INSERT INTO pbs_objects (full_fuseaction, file_path, object_name, object_title, object_type, parent_id, sort_order, is_active, is_menu)
VALUES
('asset.list_assets',            '/asset/display/list_assets.cfm',            'list_assets',            'Varlık Yönetimi',                  'page', NULL, 10, true, true),
('asset.add_asset',              '/asset/form/add_asset.cfm',                 'add_asset',              'Varlık Ekle / Düzenle',             'page', NULL, 11, true, false),
('asset.save_asset',             '/asset/form/save_asset.cfm',                'save_asset',             'Varlık Kaydet',                     'page', NULL, 12, true, false),
('asset.delete_asset',           '/asset/form/delete_asset.cfm',              'delete_asset',           'Varlık Sil',                        'page', NULL, 13, true, false),
('asset.list_maintenances',      '/asset/display/list_maintenances.cfm',      'list_maintenances',      'Bakım Kayıtları',                   'page', NULL, 14, true, true),
('asset.save_maintenance',       '/asset/form/save_maintenance.cfm',          'save_maintenance',       'Bakım Kaydet',                      'page', NULL, 15, true, false),
('asset.list_it_licenses',       '/asset/display/list_it_licenses.cfm',       'list_it_licenses',       'BT Lisans Yönetimi',                'page', NULL, 16, true, true),
('asset.save_it_license',        '/asset/form/save_it_license.cfm',           'save_it_license',        'BT Lisans Kaydet',                  'page', NULL, 17, true, false),
('asset.list_vehicle_operations','/asset/display/list_vehicle_operations.cfm', 'list_vehicle_operations','Araç Operasyonları',                'page', NULL, 18, true, true),
('asset.save_vehicle_fuel',      '/asset/form/save_vehicle_fuel.cfm',         'save_vehicle_fuel',      'Araç Yakıt Kaydı',                  'page', NULL, 19, true, false),
('asset.save_vehicle_service',   '/asset/form/save_vehicle_service.cfm',      'save_vehicle_service',   'Araç Servis Kaydı',                 'page', NULL, 20, true, false),
('asset.save_vehicle_accident',  '/asset/form/save_vehicle_accident.cfm',     'save_vehicle_accident',  'Araç Hasar/Kaza Kaydı',             'page', NULL, 21, true, false)
;
