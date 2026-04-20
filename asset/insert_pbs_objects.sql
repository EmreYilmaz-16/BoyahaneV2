-- =====================================================
-- Asset Modülü - pbs_objects Menü Kayıtları
-- module_id = 39 (Varlık Yönetimi)
-- =====================================================
-- DELETE FROM pbs_objects WHERE full_fuseaction LIKE 'asset.%';

INSERT INTO pbs_objects (full_fuseaction, file_path, object_name, module_id, show_menu, order_no, is_active)
VALUES
('asset.list_assets',            '/asset/display/list_assets.cfm',             'Varlık Yönetimi',       39, true,  10, true),
('asset.add_asset',              '/asset/form/add_asset.cfm',                  'Varlık Ekle / Düzenle', 39, false, 11, true),
('asset.save_asset',             '/asset/form/save_asset.cfm',                 'Varlık Kaydet',         39, false, 12, true),
('asset.delete_asset',           '/asset/form/delete_asset.cfm',               'Varlık Sil',            39, false, 13, true),
('asset.list_maintenances',      '/asset/display/list_maintenances.cfm',       'Bakım Kayıtları',       39, true,  14, true),
('asset.save_maintenance',       '/asset/form/save_maintenance.cfm',           'Bakım Kaydet',          39, false, 15, true),
('asset.list_it_licenses',       '/asset/display/list_it_licenses.cfm',        'BT Lisans Yönetimi',    39, true,  16, true),
('asset.save_it_license',        '/asset/form/save_it_license.cfm',            'BT Lisans Kaydet',      39, false, 17, true),
('asset.list_vehicle_operations','/asset/display/list_vehicle_operations.cfm', 'Araç Operasyonları',    39, true,  18, true),
('asset.save_vehicle_fuel',      '/asset/form/save_vehicle_fuel.cfm',          'Araç Yakıt Kaydı',      39, false, 19, true),
('asset.save_vehicle_service',   '/asset/form/save_vehicle_service.cfm',       'Araç Servis Kaydı',     39, false, 20, true),
('asset.save_vehicle_accident',  '/asset/form/save_vehicle_accident.cfm',      'Araç Hasar/Kaza Kaydı', 39, false, 21, true)
ON CONFLICT (full_fuseaction) DO NOTHING;

