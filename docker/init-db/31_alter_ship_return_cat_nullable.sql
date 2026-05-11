-- ship tablosuna return_cat_id kolonu ekle (yoksa) ve NULL kabul edecek şekilde ayarla
ALTER TABLE ship ADD COLUMN IF NOT EXISTS return_cat_id INTEGER;

-- Mevcut NOT NULL kısıtını kaldır (varsa)
ALTER TABLE ship ALTER COLUMN return_cat_id DROP NOT NULL;

-- FK kısıtı yoksa ekle
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints tc
        JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
        WHERE tc.table_name = 'ship' AND ccu.column_name = 'return_cat_id'
          AND tc.constraint_type = 'FOREIGN KEY'
    ) THEN
        ALTER TABLE ship ADD CONSTRAINT fk_ship_return_cat
            FOREIGN KEY (return_cat_id) REFERENCES return_cats(return_cat_id) ON DELETE SET NULL;
    END IF;
END $$;
