INSERT INTO pbs_objects (object_name, module_id, show_menu, window_type, full_fuseaction, file_path, order_no, is_active)
SELECT 'Hızlı Satış', 24, true, 'standart', 'order.quick_sale', '/order/form/quick_sale.cfm', 1, true
WHERE NOT EXISTS (
    SELECT 1 FROM pbs_objects WHERE full_fuseaction = 'order.quick_sale'
);
