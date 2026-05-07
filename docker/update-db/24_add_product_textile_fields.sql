-- Ürün tablosuna tekstil/kumaş alanları ekleme
ALTER TABLE product
    ADD COLUMN IF NOT EXISTS en               DOUBLE PRECISION NULL,
    ADD COLUMN IF NOT EXISTS tuse             VARCHAR(200)     NULL,
    ADD COLUMN IF NOT EXISTS cekme            VARCHAR(200)     NULL,
    ADD COLUMN IF NOT EXISTS isi              DOUBLE PRECISION NULL,
    ADD COLUMN IF NOT EXISTS hiz              DOUBLE PRECISION NULL,
    ADD COLUMN IF NOT EXISTS gramaj           DOUBLE PRECISION NULL,
    ADD COLUMN IF NOT EXISTS besleme_avans    DOUBLE PRECISION NULL,
    ADD COLUMN IF NOT EXISTS kumas_tipi       VARCHAR(200)     NULL,
    ADD COLUMN IF NOT EXISTS kullanilan_kimyassal INTEGER      NULL;
