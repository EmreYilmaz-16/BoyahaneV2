-- =====================================================
-- Papers Modülü - pbs_objects Menü Kayıtları
-- =====================================================
-- DELETE FROM pbs_objects WHERE full_fuseaction LIKE 'papers.%';

INSERT INTO pbs_objects (full_fuseaction, file_path, object_name, object_title, object_type, parent_id, sort_order, is_active, is_menu)
VALUES
('papers.list_papers',  '/papers/display/list_papers.cfm', 'list_papers',  'Belge Numaraları', 'page', NULL, 10, true, true),
('papers.save_papers',  '/papers/form/save_papers.cfm',    'save_papers',  'Belge No Kaydet',  'page', NULL, 11, true, false)
;

-- Minimal versiyon:
-- INSERT INTO pbs_objects (full_fuseaction, file_path)
-- VALUES
-- ('papers.list_papers', '/papers/display/list_papers.cfm'),
-- ('papers.save_papers', '/papers/form/save_papers.cfm');
