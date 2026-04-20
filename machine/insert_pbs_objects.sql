-- Makine Bakım Onarım Modülü - pbs_objects kayıtları
-- module_id=31 (Makine Bakım Onarım), kolon adları: object_name, order_no, show_menu

INSERT INTO pbs_objects (full_fuseaction, file_path, object_name, module_id, order_no, is_active, show_menu)
VALUES
('machine.dashboard',               '/machine/display/dashboard.cfm',               'Makine Bakım Dashboard',        31, 60, true, true),
('machine.status_board',            '/machine/display/status_board.cfm',            'Makine Durum Takip Ekranı',     31, 61, true, true),
('machine.save_machine',            '/machine/form/save_machine.cfm',               'Makine Kaydet',                 31, 62, true, false),
('machine.save_maintenance_plan',   '/machine/form/save_maintenance_plan.cfm',      'Bakım Planı Kaydet',            31, 63, true, false),
('machine.save_maintenance_result', '/machine/form/save_maintenance_result.cfm',    'Bakım Sonucu Kaydet',           31, 64, true, false),
('machine.save_fault',              '/machine/form/save_fault.cfm',                 'Arıza Kaydı Oluştur',          31, 65, true, false),
('machine.update_fault_stage',      '/machine/form/update_fault_stage.cfm',         'Arıza Aşaması Güncelle',        31, 66, true, false),
('machine.save_used_material',      '/machine/form/save_used_material.cfm',         'Kullanılan Malzeme Kaydet',     31, 67, true, false),
('machine.delete_used_material',    '/machine/form/delete_used_material.cfm',       'Kullanılan Malzeme Sil',        31, 68, true, false),
('machine.get_used_materials',      '/machine/form/get_used_materials.cfm',         'Kullanılan Malzemeleri Getir',  31, 69, true, false),
('machine.search_products',         '/machine/form/search_products.cfm',            'Ürün Arama (Malzeme)',          31, 70, true, false),
('machine.status_board_report',     '/machine/display/status_board_report.cfm',     'Arıza Bildir (Operatör)',       31, 71, true, true)
ON CONFLICT (full_fuseaction) DO NOTHING;
