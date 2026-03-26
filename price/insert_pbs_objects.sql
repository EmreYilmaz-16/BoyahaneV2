-- =====================================================
-- Price Modülü - pbs_objects Menü Kayıtları
-- =====================================================
-- DELETE FROM pbs_objects WHERE full_fuseaction LIKE 'price.%';

INSERT INTO pbs_objects (full_fuseaction, file_path, object_name, object_title, object_type, parent_id, sort_order, is_active, is_menu)
VALUES

-- Fiyat Kategorileri (Liste yönetimi)
('price.list_price_cat',   '/price/display/list_price_cat.cfm', 'list_price_cat',   'Fiyat Listeleri',          'page', NULL, 30, true, true),
('price.add_price_cat',    '/price/form/add_price_cat.cfm',     'add_price_cat',    'Fiyat Listesi Ekle',       'page', NULL, 31, true, true),
('price.edit_price_cat',   '/price/form/add_price_cat.cfm',     'edit_price_cat',   'Fiyat Listesi Düzenle',    'page', NULL, 32, true, false),
('price.save_price_cat',   '/price/form/save_price_cat.cfm',    'save_price_cat',   'Fiyat Listesi Kaydet',     'page', NULL, 33, true, false),
('price.delete_price_cat', '/price/form/delete_price_cat.cfm',  'delete_price_cat', 'Fiyat Listesi Sil',        'page', NULL, 34, true, false),

-- Fiyat Kalemleri (Listedeki ürün fiyatları)
('price.list_price',        '/price/display/list_price.cfm',     'list_price',       'Fiyat Kalemleri',          'page', NULL, 35, true, false),
('price.save_price_row',    '/price/form/save_price_row.cfm',    'save_price_row',   'Fiyat Satırı Kaydet',      'page', NULL, 36, true, false),
('price.delete_price_row',  '/price/form/delete_price_row.cfm',  'delete_price_row', 'Fiyat Satırı Sil',         'page', NULL, 37, true, false),
('price.bulk_price_change', '/price/form/bulk_price_change.cfm', 'bulk_price_change','Toplu Fiyat Güncelleme',   'page', NULL, 38, true, false),
('price.get_prices',        '/price/form/get_prices.cfm',        'get_prices',       'Fiyatları Getir (JSON)',   'page', NULL, 39, true, false)
;
