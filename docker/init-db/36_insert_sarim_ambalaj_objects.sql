-- Sarım Şekilleri ve Ambalaj Tipleri yönetim ekranları
INSERT INTO pbs_objects (object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active)
SELECT 'Sarım & Ambalaj Tipleri', 12, true, 'standart', 'setup.list_sarim_ambalaj', '/setup/display/list_sarim_ambalaj.cfm', 90, true
WHERE NOT EXISTS (SELECT 1 FROM pbs_objects WHERE full_fuseaction = 'setup.list_sarim_ambalaj');

INSERT INTO pbs_objects (object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active)
SELECT 'Sarım & Ambalaj Kaydet', 12, false, 'ajaxpage', 'setup.save_sarim_ambalaj', '/setup/form/save_sarim_ambalaj.cfm', 91, true
WHERE NOT EXISTS (SELECT 1 FROM pbs_objects WHERE full_fuseaction = 'setup.save_sarim_ambalaj');

INSERT INTO pbs_objects (object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active)
SELECT 'Sarım & Ambalaj Sil', 12, false, 'ajaxpage', 'setup.delete_sarim_ambalaj', '/setup/form/delete_sarim_ambalaj.cfm', 92, true
WHERE NOT EXISTS (SELECT 1 FROM pbs_objects WHERE full_fuseaction = 'setup.delete_sarim_ambalaj');
