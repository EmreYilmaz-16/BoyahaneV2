-- ship tablosuna return_cat_id kolonu ekle (yoksa) ve NULL kabul edecek şekilde ayarla
ALTER TABLE ship ADD COLUMN IF NOT EXISTS return_cat_id INTEGER;

-- Mevcut NOT NULL kısıtını kaldır (varsa)
ALTER TABLE ship ALTER COLUMN return_cat_id DROP NOT NULL;

-- Mevcut 0 değerlerini NULL'a çevir (FK ihlalini önlemek için)
UPDATE ship SET return_cat_id = NULL WHERE return_cat_id = 0;

-- Bilinen FK constraint isimlerini düşür (varsa), sonra temiz ekle
ALTER TABLE ship DROP CONSTRAINT IF EXISTS ship_return_cat_id_fkey;
ALTER TABLE ship DROP CONSTRAINT IF EXISTS fk_ship_return_cat;

-- FK kısıtını doğru şekilde ekle (ON DELETE SET NULL)
ALTER TABLE ship ADD CONSTRAINT fk_ship_return_cat
    FOREIGN KEY (return_cat_id) REFERENCES return_cats(return_cat_id) ON DELETE SET NULL;
