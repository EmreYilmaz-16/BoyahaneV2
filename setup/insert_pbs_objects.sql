-- =====================================================
-- Setup Modülü — Yazdırma Şablonları pbs kayıtları
-- =====================================================
-- Çalıştırmadan önce:
--   Sistem Yönetimi solution altında uygun bir family bulunmalı.
--   family_id'yi aşağıdaki DO bloğu dinamik olarak saptar.
-- =====================================================
-- DELETE FROM pbs_objects WHERE full_fuseaction LIKE 'setup.%print%';

DO $$
DECLARE
    v_solution_id  INTEGER;
    v_family_id    INTEGER;
    v_module_id    INTEGER;
BEGIN
    -- Sistem Yönetimi solution bul (yoksa oluştur)
    SELECT solution_id INTO v_solution_id
    FROM pbs_solution
    WHERE solution_name = 'Sistem Yönetimi'
    ORDER BY solution_id LIMIT 1;

    IF v_solution_id IS NULL THEN
        INSERT INTO pbs_solution (solution_name, icon, show_menu, order_no)
        VALUES ('Sistem Yönetimi', 'fa-cog', true, 99)
        RETURNING solution_id INTO v_solution_id;
    END IF;

    -- Ayarlar family bul/oluştur
    SELECT family_id INTO v_family_id
    FROM pbs_family
    WHERE family_name = 'Ayarlar' AND solution_id = v_solution_id
    ORDER BY family_id LIMIT 1;

    IF v_family_id IS NULL THEN
        INSERT INTO pbs_family (family_name, solution_id, icon, show_menu, order_no)
        VALUES ('Ayarlar', v_solution_id, 'fa-sliders-h', true, 10)
        RETURNING family_id INTO v_family_id;
    END IF;

    -- Yazdırma Şablonları modülü bul/oluştur
    SELECT module_id INTO v_module_id
    FROM pbs_module
    WHERE module_name = 'Yazdırma Şablonları' AND family_id = v_family_id
    ORDER BY module_id LIMIT 1;

    IF v_module_id IS NULL THEN
        INSERT INTO pbs_module (module_name, family_id, icon, show_menu, order_no)
        VALUES ('Yazdırma Şablonları', v_family_id, 'fa-print', true, 20)
        RETURNING module_id INTO v_module_id;
    END IF;

    -- Sayfa kayıtları
    INSERT INTO pbs_objects (full_fuseaction, file_path, object_name, module_id, order_no, is_active, show_menu, window_type)
    VALUES
        ('setup.list_print_templates',  '/setup/display/list_print_templates.cfm', 'Yazdırma Şablonları', v_module_id, 10, true, true,  'standart'),
        ('setup.add_print_template',    '/setup/form/add_print_template.cfm',      'Şablon Ekle/Düzenle', v_module_id, 11, true, false, 'standart'),
        ('setup.save_print_template',   '/setup/form/save_print_template.cfm',     'Şablon Kaydet',       v_module_id, 12, true, false, 'standart'),
        ('setup.delete_print_template', '/setup/form/delete_print_template.cfm',   'Şablon Sil',          v_module_id, 13, true, false, 'standart'),
        ('setup.print_document',        '/setup/display/print_document.cfm',       'Belge Yazdır',        v_module_id, 14, true, false, 'standart')
    ON CONFLICT (full_fuseaction) DO UPDATE SET
        file_path    = EXCLUDED.file_path,
        object_name  = EXCLUDED.object_name,
        order_no     = EXCLUDED.order_no,
        window_type  = EXCLUDED.window_type,
        is_active    = EXCLUDED.is_active;

    RAISE NOTICE 'Yazdırma Şablonları modülü kaydedildi. module_id=%', v_module_id;
END $$;
