-- =====================================================
-- Order Modülü - pbs_objects Menü Kayıtları
-- =====================================================
-- DELETE FROM pbs_objects WHERE full_fuseaction LIKE 'order.%';

INSERT INTO pbs_objects (full_fuseaction, file_path, object_name, object_title, object_type, parent_id, sort_order, is_active, is_menu)
VALUES

-- Sipariş Modülü
('order.list_orders',  '/order/display/list_orders.cfm', 'list_orders',  'Siparişler',         'page', NULL, 20, true, true),
('order.quick_sale',   '/order/form/quick_sale.cfm',     'quick_sale',   'Hızlı Satış',        'page', NULL, 20, true, true),
('order.add_order',    '/order/form/add_order.cfm',      'add_order',    'Sipariş Ekle',       'page', NULL, 21, true, true),
('order.edit_order',   '/order/form/add_order.cfm',      'edit_order',   'Sipariş Düzenle',    'page', NULL, 22, true, false),
('order.view_order',   '/order/form/add_order.cfm',      'view_order',   'Sipariş Görüntüle',  'page', NULL, 23, true, false),
('order.save_order',   '/order/form/save_order.cfm',     'save_order',   'Sipariş Kaydet',     'page', NULL, 24, true, false),
('order.delete_order', '/order/form/delete_order.cfm',   'delete_order', 'Sipariş Sil',        'page', NULL, 25, true, false),
('order.cancel_order', '/order/form/delete_order.cfm',   'cancel_order', 'Sipariş İptal',      'page', NULL, 26, true, false)
;
