-- orders tablosuna partiye özel tekstil özellikleri eklendi
ALTER TABLE orders ADD COLUMN IF NOT EXISTS gramaj        NUMERIC(10,2);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS en            NUMERIC(10,2);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS kumas_tipi    VARCHAR(200);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS tuse          VARCHAR(200);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS isi           NUMERIC(10,2);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS hiz           NUMERIC(10,2);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS besleme_avans NUMERIC(10,2);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS cekme         VARCHAR(200);
