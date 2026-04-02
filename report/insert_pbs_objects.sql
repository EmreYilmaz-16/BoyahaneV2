-- =====================================================
-- Report Modülü - pbs_objects Menü Kayıtları
-- =====================================================
-- DELETE FROM pbs_objects WHERE full_fuseaction LIKE 'report.%';

INSERT INTO pbs_objects (full_fuseaction, file_path, object_name, object_title, object_type, parent_id, sort_order, is_active, is_menu)
VALUES

-- Raporlar (menüde görünür)
('report.list_reports',        '/report/display/list_reports.cfm',        'list_reports',        'Raporlar',              'page', NULL, 10, true, true),
('report.detail_view_report',  '/report/display/detail_view_report.cfm',  'detail_view_report',  'Rapor Görüntüle',       'page', NULL, 11, true, false),

-- Rapor yönetimi - backend (menüde görünmez)
('report.add_report',          '/report/form/add_report.cfm',             'add_report',          'Rapor Ekle / Düzenle',  'page', NULL, 12, true, false),
('report.save_report',         '/report/form/save_report.cfm',            'save_report',         'Rapor Kaydet',          'page', NULL, 13, true, false),
('report.delete_report',       '/report/form/delete_report.cfm',          'delete_report',       'Rapor Sil',             'page', NULL, 14, true, false)
;
