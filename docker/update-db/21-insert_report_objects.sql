-- =====================================================
-- Report Modülü - pbs_module ve pbs_objects Kayıtları
-- =====================================================

-- 1) Modülü ekle (Sistem Yönetimi family altında, family_id=16)
INSERT INTO pbs_module (module_name, family_id, show_menu, order_no, is_active)
VALUES ('Raporlar', 16, true, 10, true);

-- 2) Eklenen modülün ID'sini bul ve objeleri ekle
DO $$
DECLARE
    v_module_id INTEGER;
BEGIN
    SELECT module_id INTO v_module_id
    FROM pbs_module
    WHERE module_name = 'Raporlar' AND family_id = 16
    ORDER BY module_id DESC
    LIMIT 1;

    INSERT INTO pbs_objects (full_fuseaction, file_path, object_name, module_id, order_no, is_active, show_menu)
    VALUES
        ('report.list_reports',       '/report/display/list_reports.cfm',       'Raporlar',             v_module_id, 10, true, true),
        ('report.detail_view_report', '/report/display/detail_view_report.cfm', 'Rapor Görüntüle',      v_module_id, 11, true, false),
        ('report.add_report',         '/report/form/add_report.cfm',            'Rapor Ekle / Düzenle', v_module_id, 12, true, false),
        ('report.save_report',        '/report/form/save_report.cfm',           'Rapor Kaydet',         v_module_id, 13, true, false),
        ('report.delete_report',      '/report/form/delete_report.cfm',         'Rapor Sil',            v_module_id, 14, true, false);
END $$;
