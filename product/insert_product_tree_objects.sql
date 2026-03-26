-- =====================================================
-- Ürün Ağacı (BOM) Modülü - pbs_objects Menü Kayıtları
-- =====================================================
-- Çalıştırmadan önce product modülünün parent_id değerini kontrol ediniz.
-- is_menu = true olanlar sol menüde görünür.
-- =====================================================

INSERT INTO pbs_objects
    (full_fuseaction, file_path, object_name, object_title, object_type, parent_id, sort_order, is_active, is_menu)
VALUES
    -- Ürün Ağacı Listesi (menüde görünür)
    ('product.list_product_trees',
     '/product/display/list_product_trees.cfm',
     'list_product_trees',
     'Ürün Ağaçları (BOM)',
     'page', NULL, 50, true, true),

    -- Ürün Ağacı Görüntüleme / Düzenleme (menüde görünmez, liste sayfasından açılır)
    ('product.view_product_tree',
     '/product/display/view_product_tree.cfm',
     'view_product_tree',
     'Ürün Ağacı Görüntüle',
     'page', NULL, 51, true, false),

    -- AJAX: Satır kaydet
    ('product.save_product_tree_row',
     '/product/form/save_product_tree_row.cfm',
     'save_product_tree_row',
     'Ürün Ağacı Satır Kaydet',
     'page', NULL, 52, true, false),

    -- AJAX: Satır sil
    ('product.delete_product_tree_row',
     '/product/form/delete_product_tree_row.cfm',
     'delete_product_tree_row',
     'Ürün Ağacı Satır Sil',
     'page', NULL, 53, true, false)
;

-- =====================================================
-- NOT: Eğer product modülü pbs_module'de kayıtlıysa;
-- parent_id = (SELECT module_id FROM pbs_module WHERE module_name = 'Ürün')
-- ile güncelleyebilirsiniz. Örnek:
--
-- UPDATE pbs_objects
-- SET parent_id = (SELECT module_id FROM pbs_module WHERE module_name = 'Ürün' LIMIT 1)
-- WHERE full_fuseaction IN (
--     'product.list_product_trees',
--     'product.view_product_tree',
--     'product.save_product_tree_row',
--     'product.delete_product_tree_row'
-- );
-- =====================================================
