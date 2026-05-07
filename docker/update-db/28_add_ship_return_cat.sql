-- ship tablosuna iade nedeni kolonu ekle
-- return_cats tablosu zaten docker/init-db/04-create-return-cats.sql ile oluşturulmuş olmalı

ALTER TABLE ship
    ADD COLUMN IF NOT EXISTS return_cat_id INTEGER NULL
        REFERENCES return_cats(return_cat_id);
