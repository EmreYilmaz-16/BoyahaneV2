-- =====================================================
-- Üretim Planlama Sayfası — pbs_objects Menü Kayıtları
-- =====================================================

-- Mevcut yanlış kayıtları temizle (window_type=ajaxpage loadAssets=false yapar)
DELETE FROM pbs_objects WHERE full_fuseaction IN (
    'production.production_planning',
    'production.save_plan',
    'production.unplan_order'
);

INSERT INTO pbs_objects (full_fuseaction, file_path, object_name, object_title, object_type, parent_id, sort_order, is_active, show_menu, window_type)
VALUES
    -- Planlama sayfası (menüde görünür, normal sayfa — assets yüklenir)
    ('production.production_planning',
     '/production/display/production_planning.cfm',
     'production_planning',
     'Üretim Planlama',
     'page', NULL, 55, true, true, 'page'),

    -- Planla backend (menüde görünmez)
    ('production.save_plan',
     '/production/form/save_plan.cfm',
     'save_plan',
     'Üretim Planla',
     'page', NULL, 56, true, false, 'page'),

    -- Plandan kaldır backend (menüde görünmez)
    ('production.unplan_order',
     '/production/form/unplan_order.cfm',
     'unplan_order',
     'Emirden Plan Kaldır',
     'page', NULL, 57, true, false, 'page');
