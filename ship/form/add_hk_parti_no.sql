-- ship tablosuna hk_parti_no kolonu ekle
ALTER TABLE ship ADD COLUMN IF NOT EXISTS hk_parti_no VARCHAR(200);

-- general_papers tablosuna giris_fis kolonları ekle
ALTER TABLE general_papers ADD COLUMN IF NOT EXISTS giris_fis_no VARCHAR(50);
ALTER TABLE general_papers ADD COLUMN IF NOT EXISTS giris_fis_number INTEGER;
