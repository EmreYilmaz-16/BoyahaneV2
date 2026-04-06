DO $$
DECLARE
    v_solution_id  INTEGER;
    v_family_id    INTEGER;
    v_module_id    INTEGER;
BEGIN
    SELECT solution_id INTO v_solution_id
    FROM pbs_solution
    WHERE solution_name = 'Sistem Yönetimi'
    ORDER BY solution_id LIMIT 1;

    IF v_solution_id IS NULL THEN
        INSERT INTO pbs_solution (solution_name, icon, show_menu, order_no)
        VALUES ('Sistem Yönetimi', 'fa-cog', true, 99)
        RETURNING solution_id INTO v_solution_id;
    END IF;

    SELECT family_id INTO v_family_id
    FROM pbs_family
    WHERE family_name = 'Ayarlar' AND solution_id = v_solution_id
    ORDER BY family_id LIMIT 1;

    IF v_family_id IS NULL THEN
        INSERT INTO pbs_family (family_name, solution_id, icon, show_menu, order_no)
        VALUES ('Ayarlar', v_solution_id, 'fa-sliders-h', true, 10)
        RETURNING family_id INTO v_family_id;
    END IF;

    SELECT module_id INTO v_module_id
    FROM pbs_module
    WHERE module_name = 'Yazdırma Şablonları' AND family_id = v_family_id
    ORDER BY module_id LIMIT 1;

    IF v_module_id IS NULL THEN
        INSERT INTO pbs_module (module_name, family_id, icon, show_menu, order_no)
        VALUES ('Yazdırma Şablonları', v_family_id, 'fa-print', true, 20)
        RETURNING module_id INTO v_module_id;
    END IF;

    INSERT INTO pbs_objects (full_fuseaction, file_path, object_name, module_id, order_no, is_active, show_menu, window_type)
    VALUES
        ('setup.module_permissions', '/setup/display/module_permissions.cfm', 'Modül Yetkilendirme', v_module_id, 30, true, true, 'standart'),
        ('setup.get_user_module_permissions', '/setup/form/get_user_module_permissions.cfm', 'Modül Yetki Liste (JSON)', v_module_id, 31, true, false, 'ajaxpage'),
        ('setup.save_user_module_permission', '/setup/form/save_user_module_permission.cfm', 'Modül Yetki Kaydet (JSON)', v_module_id, 32, true, false, 'ajaxpage')
    ON CONFLICT (full_fuseaction) DO UPDATE SET
        file_path = EXCLUDED.file_path,
        object_name = EXCLUDED.object_name,
        module_id = EXCLUDED.module_id,
        order_no = EXCLUDED.order_no,
        is_active = EXCLUDED.is_active,
        show_menu = EXCLUDED.show_menu,
        window_type = EXCLUDED.window_type;
END $$;
