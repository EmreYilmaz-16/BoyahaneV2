-- =====================================================
-- Product Modülü - pbs_objects Menü Kayıtları
-- =====================================================
-- DELETE FROM pbs_objects WHERE full_fuseaction LIKE 'product.%';

INSERT INTO pbs_objects (full_fuseaction, file_path, object_name, object_title, object_type, parent_id, sort_order, is_active, is_menu)
VALUES

-- Ürün Kategorileri (menüde görünür)
('product.list_product_cat',     '/product/display/list_product_cat.cfm',     'list_product_cat',     'Ürün Kategorileri',       'page', NULL, 10, true, true),
('product.view_product_cat',     '/product/display/view_product_cat.cfm',     'view_product_cat',     'Kategori Detayı',         'page', NULL, 11, true, false),
('product.add_product_cat',      '/product/form/add_product_cat.cfm',         'add_product_cat',      'Kategori Ekle',           'page', NULL, 12, true, false),
('product.edit_product_cat',     '/product/form/edit_product_cat.cfm',        'edit_product_cat',     'Kategori Düzenle',        'page', NULL, 13, true, false),
('product.delete_product_cat',   '/product/form/delete_product_cat.cfm',      'delete_product_cat',   'Kategori Sil',            'page', NULL, 14, true, false),

-- Ürün Markaları
('product.list_product_brands',  '/product/display/list_product_brands.cfm',  'list_product_brands',  'Ürün Markaları',          'page', NULL, 20, true, true),
('product.add_product_brand',    '/product/form/add_product_brand.cfm',       'add_product_brand',    'Marka Ekle',              'page', NULL, 21, true, false),
('product.add_product_brand_popup','/product/form/add_product_brand_popup.cfm','add_product_brand_popup','Marka Ekle (Popup)',   'page', NULL, 22, true, false),
('product.edit_product_brand',   '/product/form/edit_product_brand.cfm',      'edit_product_brand',   'Marka Düzenle',           'page', NULL, 23, true, false),
('product.delete_product_brand', '/product/form/delete_product_brand.cfm',    'delete_product_brand', 'Marka Sil',               'page', NULL, 24, true, false),

-- Ürünler
('product.list_product',         '/product/display/list_product.cfm',         'list_product',         'Ürünler',                 'page', NULL, 30, true, true),
('product.add_product',          '/product/form/add_product.cfm',             'add_product',          'Ürün Ekle',               'page', NULL, 31, true, false),
('product.edit_product',         '/product/form/edit_product.cfm',            'edit_product',         'Ürün Düzenle',            'page', NULL, 32, true, false),
('product.delete_product',       '/product/form/delete_product.cfm',          'delete_product',       'Ürün Sil',                'page', NULL, 33, true, false),

-- Ürün Ağacı (Reçete)
('product.list_product_trees',   '/product/display/list_product_trees.cfm',   'list_product_trees',   'Ürün Ağacı',              'page', NULL, 40, true, true),
('product.view_product_tree',    '/product/display/view_product_tree.cfm',    'view_product_tree',    'Ürün Ağacı Detayı',       'page', NULL, 41, true, false),
('product.view_product_tree_ajax','/product/display/view_product_tree_ajax.cfm','view_product_tree_ajax','Ürün Ağacı AJAX',      'page', NULL, 42, true, false),
('product.show_product_tree',    '/product/form/show_product_tree.cfm',       'show_product_tree',    'Ürün Ağacı Göster',       'page', NULL, 43, true, false),
('product.save_product_tree_row','/product/form/save_product_tree_row.cfm',   'save_product_tree_row','Ürün Ağacı Satır Kaydet', 'page', NULL, 44, true, false),
('product.delete_product_tree_row','/product/form/delete_product_tree_row.cfm','delete_product_tree_row','Ürün Ağacı Satır Sil', 'page', NULL, 45, true, false)
;
