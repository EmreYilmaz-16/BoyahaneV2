-- =====================================================
-- Makine Bakım Onarım Modülü - pbs_module ve pbs_objects Kayıtları
-- =====================================================

-- 1) Modülü ekle (Üretim family altında, family_id=18)
INSERT INTO pbs_module (module_name, family_id, show_menu, order_no, is_active)
VALUES ('Makine Bakım Onarım', 18, true, 60, true)
ON CONFLICT DO NOTHING;

-- 2) Eklenen modülün ID'sini bul ve objeleri ekle
DO $$
DECLARE
    v_module_id INTEGER;
BEGIN
    SELECT module_id INTO v_module_id
    FROM pbs_module
    WHERE module_name = 'Makine Bakım Onarım' AND family_id = 18
    ORDER BY module_id DESC
    LIMIT 1;

    INSERT INTO pbs_objects (full_fuseaction, file_path, object_name, module_id, order_no, is_active, show_menu)
    VALUES
        ('machine.dashboard',               '/machine/display/dashboard.cfm',            'Makine Bakım Dashboard',    v_module_id, 60, true, true),
        ('machine.status_board',            '/machine/display/status_board.cfm',         'Makine Durum Takip Ekranı', v_module_id, 61, true, true),
        ('machine.save_machine',            '/machine/form/save_machine.cfm',            'Makine Kaydet',             v_module_id, 62, true, false),
        ('machine.save_maintenance_plan',   '/machine/form/save_maintenance_plan.cfm',   'Bakım Planı Kaydet',        v_module_id, 63, true, false),
        ('machine.save_maintenance_result', '/machine/form/save_maintenance_result.cfm', 'Bakım Sonucu Kaydet',       v_module_id, 64, true, false),
        ('machine.save_fault',              '/machine/form/save_fault.cfm',              'Arıza Kaydı Oluştur',       v_module_id, 65, true, false),
        ('machine.update_fault_stage',      '/machine/form/update_fault_stage.cfm',      'Arıza Aşaması Güncelle',    v_module_id, 66, true, false)
    ON CONFLICT (full_fuseaction) DO NOTHING;
END $$;
