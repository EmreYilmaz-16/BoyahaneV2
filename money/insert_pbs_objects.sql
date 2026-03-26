-- =====================================================
-- Money Modülü - pbs_objects Menü Kayıtları
-- =====================================================

INSERT INTO pbs_objects (full_fuseaction, file_path, object_name, object_title, object_type, parent_id, sort_order, is_active, is_menu)
VALUES

-- Para Birimleri
('money.list_money',         '/money/display/list_money.cfm',         'list_money',         'Para Birimleri',    'page', NULL, 10, true, true),
('money.add_money',          '/money/form/add_money.cfm',             'add_money',          'Para Birimi Ekle',  'page', NULL, 11, true, false),
('money.edit_money',         '/money/form/edit_money.cfm',            'edit_money',         'Para Birimi Düzenle','page',NULL, 12, true, false),

-- Kur Geçmişi
('money.list_money_history', '/money/display/list_money_history.cfm', 'list_money_history', 'Kur Geçmişi',       'page', NULL, 20, true, true),

-- TCMB Kur Güncelleme (direkt AJAX endpoint - menüde görünmez)
('money.fetch_tcmb',         '/money/form/fetch_tcmb.cfm',            'fetch_tcmb',         'TCMB Güncelle',     'page', NULL, 21, true, false)

;
