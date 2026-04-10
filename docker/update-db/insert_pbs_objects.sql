-- =====================================================
-- Kullanıcılar Modülü - pbs_objects Menü Kayıtları
-- module_id=32 (Kullanıcı Yönetimi, family_id=16 Sistem Yönetimi)
-- =====================================================

INSERT INTO pbs_objects (full_fuseaction, file_path, object_name, module_id, order_no, is_active, show_menu)
VALUES
('kullanicilar.list_users',  '/kullanicilar/display/list_users.cfm', 'Kullanıcı Yönetimi', 32, 70, true, true),
('kullanicilar.save_user',   '/kullanicilar/form/save_user.cfm',     'Kullanıcı Kaydet',   32, 71, true, false),
('kullanicilar.delete_user', '/kullanicilar/form/delete_user.cfm',   'Kullanıcı Sil',      32, 72, true, false)
ON CONFLICT (full_fuseaction) DO NOTHING;
