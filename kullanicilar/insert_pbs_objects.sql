-- =====================================================
-- Kullanıcılar Modülü - pbs_module ve pbs_objects Kayıtları
-- module_id=32 (Kullanıcı Yönetimi, family_id=16 Sistem Yönetimi)
-- =====================================================

-- 1) Modülü ekle (zaten varsa atla)
INSERT INTO pbs_module (module_name, family_id, show_menu, order_no, is_active)
VALUES ('Kullanıcı Yönetimi', 16, true, 70, true)
ON CONFLICT DO NOTHING;

-- 2) Eklenen modülün ID'sini bul ve objeleri ekle
DO $$
DECLARE
    v_module_id INTEGER;
BEGIN
    SELECT module_id INTO v_module_id
    FROM pbs_module
    WHERE module_name = 'Kullanıcı Yönetimi' AND family_id = 16
    ORDER BY module_id DESC
    LIMIT 1;

    INSERT INTO pbs_objects (full_fuseaction, file_path, object_name, module_id, order_no, is_active, show_menu)
    VALUES
        ('kullanicilar.list_users',          '/kullanicilar/display/list_users.cfm',        'Kullanıcı Yönetimi',          v_module_id, 70, true, true),
        ('kullanicilar.save_user',           '/kullanicilar/form/save_user.cfm',             'Kullanıcı Kaydet',            v_module_id, 71, true, false),
        ('kullanicilar.delete_user',         '/kullanicilar/form/delete_user.cfm',           'Kullanıcı Sil',               v_module_id, 72, true, false),
        ('kullanicilar.fuseaction_deny',     '/kullanicilar/display/fuseaction_deny.cfm',    'Fuseaction Kısıtlamaları',    v_module_id, 73, true, true),
        ('kullanicilar.save_fuseaction_deny','/kullanicilar/form/save_fuseaction_deny.cfm',  'Fuseaction Kısıtlama Kaydet', v_module_id, 74, true, false)
    ON CONFLICT (full_fuseaction) DO NOTHING;
END $$;

