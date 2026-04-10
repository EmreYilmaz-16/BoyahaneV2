-- Makine Bakım Onarım Modülü - pbs_objects kayıtları

INSERT INTO pbs_objects (full_fuseaction, file_path, object_name, object_title, object_type, parent_id, sort_order, is_active, is_menu)
VALUES
('machine.dashboard', '/machine/display/dashboard.cfm', 'dashboard', 'Makine Bakım Dashboard', 'page', NULL, 60, true, true),
('machine.status_board', '/machine/display/status_board.cfm', 'status_board', 'Makine Durum Takip Ekranı', 'page', NULL, 61, true, true),
('machine.save_machine', '/machine/form/save_machine.cfm', 'save_machine', 'Makine Kaydet', 'page', NULL, 62, true, false),
('machine.save_maintenance_plan', '/machine/form/save_maintenance_plan.cfm', 'save_maintenance_plan', 'Bakım Planı Kaydet', 'page', NULL, 63, true, false),
('machine.save_maintenance_result', '/machine/form/save_maintenance_result.cfm', 'save_maintenance_result', 'Bakım Sonucu Kaydet', 'page', NULL, 64, true, false),
('machine.save_fault', '/machine/form/save_fault.cfm', 'save_fault', 'Arıza Kaydı Oluştur', 'page', NULL, 65, true, false),
('machine.update_fault_stage', '/machine/form/update_fault_stage.cfm', 'update_fault_stage', 'Arıza Aşaması Güncelle', 'page', NULL, 66, true, false)
ON CONFLICT (full_fuseaction) DO NOTHING;
