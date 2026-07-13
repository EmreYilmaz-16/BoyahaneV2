-- Parti paketlenen toplar sorgu ekranı
INSERT INTO pbs_objects (object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active)
SELECT 'Parti Paket Topları', 12, true, 'standart', 'ship.parti_paket_toplari', '/ship/display/parti_paket_toplari.cfm', 30, true
WHERE NOT EXISTS (SELECT 1 FROM pbs_objects WHERE full_fuseaction = 'ship.parti_paket_toplari');
