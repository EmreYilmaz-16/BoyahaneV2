-- Sistem Parametreleri yönetim ekranı pbs_objects kaydı
INSERT INTO pbs_objects (object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active)
SELECT 'Sistem Parametreleri', 12, true, 'standart', 'setup.list_params', '/setup/display/list_params.cfm', 95, true
WHERE NOT EXISTS (SELECT 1 FROM pbs_objects WHERE full_fuseaction = 'setup.list_params');

INSERT INTO pbs_objects (object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active)
SELECT 'Parametre Kaydet', 12, false, 'ajaxpage', 'setup.save_param', '/setup/form/save_param.cfm', 96, true
WHERE NOT EXISTS (SELECT 1 FROM pbs_objects WHERE full_fuseaction = 'setup.save_param');

INSERT INTO pbs_objects (object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active)
SELECT 'Parametre Sil', 12, false, 'ajaxpage', 'setup.delete_param', '/setup/form/delete_param.cfm', 97, true
WHERE NOT EXISTS (SELECT 1 FROM pbs_objects WHERE full_fuseaction = 'setup.delete_param');
