-- Parti Güncelle fuseaction kaydı (ship.edit_parti)
INSERT INTO pbs_objects (object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active)
SELECT 'Parti Güncelle', 12, false, 'standart', 'ship.edit_parti', '/ship/form/edit_parti.cfm', 0, true
WHERE NOT EXISTS (SELECT 1 FROM pbs_objects WHERE full_fuseaction = 'ship.edit_parti');
