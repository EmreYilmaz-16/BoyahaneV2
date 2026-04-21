-- =====================================================
-- Kalite Kontrol Modülü - pbs_module ve pbs_objects Kayıtları
-- =====================================================
-- Önce mevcut kayıtları temizlemek için (gerekirse):
-- DELETE FROM pbs_objects WHERE full_fuseaction LIKE 'quality.%';

-- 1) Modülü ekle (Üretim family altında, family_id=18)
INSERT INTO pbs_module (module_name, family_id, show_menu, order_no, is_active)
VALUES ('Kalite Kontrol', 18, true, 110, true)
ON CONFLICT DO NOTHING;

-- 2) Eklenen modülün ID'sini bul ve objeleri ekle
DO $$
DECLARE
    v_module_id INTEGER;
BEGIN
    SELECT module_id INTO v_module_id
    FROM pbs_module
    WHERE module_name = 'Kalite Kontrol' AND family_id = 18
    ORDER BY module_id DESC
    LIMIT 1;

    INSERT INTO pbs_objects (full_fuseaction, file_path, object_name, module_id, order_no, is_active, show_menu)
    VALUES
        -- KK Parametreleri (menüde görünür)
        ('quality.list_qc_parameters',   '/quality/display/list_qc_parameters.cfm',  'KK Parametreleri',          v_module_id, 110, true, true),
        ('quality.add_qc_parameter',     '/quality/form/add_qc_parameter.cfm',        'KK Parametre Ekle/Düzenle', v_module_id, 111, true, false),
        ('quality.save_qc_parameter',    '/quality/form/save_qc_parameter.cfm',       'KK Parametre Kaydet',       v_module_id, 112, true, false),
        ('quality.delete_qc_parameter',  '/quality/form/delete_qc_parameter.cfm',     'KK Parametre Sil',          v_module_id, 113, true, false),
        -- Hata Tipleri (menüde görünür)
        ('quality.list_qc_defect_types', '/quality/display/list_qc_defect_types.cfm', 'KK Hata Tipleri',           v_module_id, 114, true, true),
        ('quality.add_qc_defect_type',   '/quality/form/add_qc_defect_type.cfm',      'Hata Tipi Ekle/Düzenle',    v_module_id, 115, true, false),
        ('quality.save_qc_defect_type',  '/quality/form/save_qc_defect_type.cfm',     'Hata Tipi Kaydet',          v_module_id, 116, true, false),
        ('quality.delete_qc_defect_type','/quality/form/delete_qc_defect_type.cfm',   'Hata Tipi Sil',             v_module_id, 117, true, false),
        -- KK Planları (menüde görünür)
        ('quality.list_qc_plans',        '/quality/display/list_qc_plans.cfm',        'KK Planları',               v_module_id, 118, true, true),
        ('quality.add_qc_plan',          '/quality/form/add_qc_plan.cfm',             'KK Planı Ekle/Düzenle',     v_module_id, 119, true, false),
        ('quality.save_qc_plan',         '/quality/form/save_qc_plan.cfm',            'KK Planı Kaydet',           v_module_id, 120, true, false),
        ('quality.delete_qc_plan',       '/quality/form/delete_qc_plan.cfm',          'KK Planı Sil',              v_module_id, 121, true, false),
        -- KK Muayeneleri (menüde görünür)
        ('quality.list_qc_inspections',  '/quality/display/list_qc_inspections.cfm',  'KK Muayeneleri',            v_module_id, 122, true, true),
        ('quality.add_qc_inspection',    '/quality/form/add_qc_inspection.cfm',       'Muayene Başlat/Düzenle',    v_module_id, 123, true, false),
        ('quality.save_qc_inspection',   '/quality/form/save_qc_inspection.cfm',      'Muayene Kaydet',            v_module_id, 124, true, false),
        ('quality.delete_qc_inspection', '/quality/form/delete_qc_inspection.cfm',    'Muayene Sil',               v_module_id, 125, true, false),
        ('quality.view_qc_inspection',   '/quality/display/view_qc_inspection.cfm',   'Muayene Detayı',            v_module_id, 126, true, false),
        -- AJAX Endpoint (menüde görünmez)
        ('quality.get_plan_params',      '/quality/form/get_plan_params.cfm',         'KK Plan Parametreleri JSON', v_module_id, 127, true, false)
    ON CONFLICT (full_fuseaction) DO NOTHING;
END $$;

