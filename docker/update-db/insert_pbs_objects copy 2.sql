-- =====================================================
-- Stock Modülü - pbs_objects Menü Kayıtları
-- =====================================================
-- DELETE FROM pbs_objects WHERE full_fuseaction LIKE 'stock.%';

INSERT INTO pbs_objects (full_fuseaction, file_path, object_name, object_title, object_type, parent_id, sort_order, is_active, is_menu)
VALUES
('stock.list_fis',          '/stock/display/list_fis.cfm',          'list_fis',         'Stok Fişleri',     'page', NULL, 10, true, true),
('stock.add_fis',          '/stock/form/add_fis.cfm',             'add_fis',          'Stok Fiş Ekle',   'page', NULL, 11, true, false),
('stock.list_parti',       '/stock/display/list_parti.cfm',       'list_parti',       'Tüm Partiler',    'page', NULL, 12, true, true),
('stock.list_stock_amounts','/stock/display/list_stock_amounts.cfm','list_stock_amounts','Stok Miktarları','page', NULL, 13, true, true)
ON CONFLICT (full_fuseaction) DO NOTHING;
