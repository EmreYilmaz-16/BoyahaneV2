-- =====================================================
-- Stock Modülü - pbs_module ve pbs_objects Kayıtları
-- =====================================================
-- DELETE FROM pbs_objects WHERE full_fuseaction LIKE 'stock.%';

-- 1) Modülü ekle (Stok İşlemleri family altında, family_id=14)
INSERT INTO pbs_module (module_name, family_id, show_menu, order_no, is_active)
VALUES ('Stok Fişi', 14, true, 10, true)
ON CONFLICT DO NOTHING;

-- 2) Eklenen modülün ID'sini bul ve objeleri ekle
DO $$
DECLARE
    v_module_id INTEGER;
BEGIN
    SELECT module_id INTO v_module_id
    FROM pbs_module
    WHERE module_name = 'Stok Fişi' AND family_id = 14
    ORDER BY module_id DESC
    LIMIT 1;

    INSERT INTO pbs_objects (full_fuseaction, file_path, object_name, module_id, order_no, is_active, show_menu)
    VALUES
        ('stock.list_fis',           '/stock/display/list_fis.cfm',           'Stok Fişleri',    v_module_id, 10, true, true),
        ('stock.add_fis',            '/stock/form/add_fis.cfm',               'Stok Fiş Ekle',   v_module_id, 11, true, false),
        ('stock.list_parti',         '/stock/display/list_parti.cfm',         'Tüm Partiler',    v_module_id, 12, true, true),
        ('stock.list_stock_amounts', '/stock/display/list_stock_amounts.cfm', 'Stok Miktarları', v_module_id, 13, true, true)
    ON CONFLICT (full_fuseaction) DO NOTHING;
END $$;

