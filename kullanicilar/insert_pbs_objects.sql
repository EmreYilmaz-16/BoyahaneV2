-- =====================================================
-- Kullanıcılar Modülü - pbs_objects Menü Kayıtları
-- =====================================================

INSERT INTO pbs_objects (full_fuseaction, file_path, object_name, object_title, object_type, parent_id, sort_order, is_active, is_menu)
VALUES
('kullanicilar.list_users',  '/kullanicilar/display/list_users.cfm',  'list_users',  'Kullanıcı Yönetimi', 'page', NULL, 70, true, true),
('kullanicilar.save_user',   '/kullanicilar/form/save_user.cfm',      'save_user',   'Kullanıcı Kaydet',   'page', NULL, 71, true, false),
('kullanicilar.delete_user', '/kullanicilar/form/delete_user.cfm',    'delete_user', 'Kullanıcı Sil',      'page', NULL, 72, true, false)
ON CONFLICT (full_fuseaction) DO NOTHING;
