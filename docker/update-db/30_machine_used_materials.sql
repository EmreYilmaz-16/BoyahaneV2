-- ================================================================
-- MACHINE USED MATERIALS TABLE
-- Bakım ve arıza sonrası kullanılan malzemeleri tutar.
-- Ürünler product tablosundan seçilir.
-- ================================================================

CREATE TABLE IF NOT EXISTS machine_used_materials (
    material_id   SERIAL       PRIMARY KEY,
    source_type   VARCHAR(20)  NOT NULL,            -- 'fault' | 'maintenance'
    source_id     INTEGER      NOT NULL,             -- fault_id veya maintenance_log_id
    product_id    INTEGER,                           -- FK to product (nullable: manuel giriş de mümkün)
    product_name  VARCHAR(500) NOT NULL,
    product_code  VARCHAR(150),
    quantity      NUMERIC(12,3) NOT NULL DEFAULT 1,
    unit          VARCHAR(50)  NOT NULL DEFAULT 'adet', -- adet, litre, kg, metre, kutu, paket, rulo
    note          VARCHAR(1000),
    record_date   TIMESTAMP    NOT NULL DEFAULT NOW(),
    record_emp    INTEGER,

    CONSTRAINT chk_um_source_type CHECK (source_type IN ('fault','maintenance'))
);

CREATE INDEX IF NOT EXISTS idx_um_source      ON machine_used_materials (source_type, source_id);
CREATE INDEX IF NOT EXISTS idx_um_product_id  ON machine_used_materials (product_id);
