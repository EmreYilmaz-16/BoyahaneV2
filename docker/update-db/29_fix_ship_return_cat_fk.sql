-- ACIL DUZELTME: return_cat_id FK constraint'i NULL kabul edecek sekilde yeniden kur
-- Hata: "insert or update on table ship violates foreign key constraint ship_return_cat_id_fkey"
-- Neden: 0 degeri return_cats tablosunda yok; secilmediginde NULL gonderilmeli

-- 1) Mevcut 0 degerlerini NULL'a cevir
UPDATE ship SET return_cat_id = NULL WHERE return_cat_id = 0;

-- 2) Otomatik olusturulmus constraint'i duser
ALTER TABLE ship DROP CONSTRAINT IF EXISTS ship_return_cat_id_fkey;

-- 3) Eski adli constraint'i duser (onceki migration varsa)
ALTER TABLE ship DROP CONSTRAINT IF EXISTS fk_ship_return_cat;

-- 4) Temiz olarak ON DELETE SET NULL ile yeniden ekle
ALTER TABLE ship ADD CONSTRAINT fk_ship_return_cat
    FOREIGN KEY (return_cat_id) REFERENCES return_cats(return_cat_id) ON DELETE SET NULL;
