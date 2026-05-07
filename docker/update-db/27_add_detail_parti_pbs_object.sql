-- =====================================================
-- Parti Detay sayfası için pbs_objects kaydı
-- =====================================================

INSERT INTO pbs_objects (full_fuseaction, file_path, object_name, object_title, object_type, parent_id, sort_order, is_active, show_menu)
VALUES (
    'ship.detail_parti',
    '/ship/display/detail_parti.cfm',
    'detail_parti',
    'Parti Detay',
    'page',
    NULL,
    19,
    true,
    false
)
ON CONFLICT (full_fuseaction) DO NOTHING;
