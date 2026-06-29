-- Üretim planlama sırasında reçete hesabında kullanılacak plan su miktarı
ALTER TABLE production_orders
    ADD COLUMN IF NOT EXISTS plan_water_amount NUMERIC(18,6) DEFAULT 0;

COMMENT ON COLUMN production_orders.plan_water_amount IS 'Reçete plan çıktısında kimyasal hesapları için kullanılan plan su miktarı';

INSERT INTO pbs_objects (full_fuseaction, file_path, object_name, object_title, object_type, parent_id, sort_order, is_active, is_menu)
VALUES ('production.print_recipe', '/production/display/print_recipe.cfm', 'print_recipe', 'Üretim Reçete Yazdır', 'page', NULL, 52, true, false)
ON CONFLICT (full_fuseaction) DO NOTHING;
