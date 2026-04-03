-- =====================================================
-- Colors Modülü — PostgreSQL tablo ve pbs_objects
-- Sırasıyla çalıştırın
-- =====================================================

-- 1. color_info tablosu (renk metadatası)
CREATE TABLE IF NOT EXISTS color_info (
    color_id       SERIAL PRIMARY KEY,
    stock_id       INTEGER NOT NULL,          -- stocks.stock_id (renk stoğu)
    company_id     INTEGER,                   -- company.company_id (müşteri)
    product_id     INTEGER,                   -- product.product_id (ilgili kumaş ürünü)
    color_code     VARCHAR(100),              -- Renk Kodu
    color_name     VARCHAR(255),              -- Renk Adı
    kartela_no     VARCHAR(100),              -- Kartela No
    kartela_date   DATE,                      -- Kartela Tarihi
    renk_tonu      SMALLINT,                  -- Renk Tonu (1-6)
    boya_derecesi  VARCHAR(50),               -- Boya Derecesi
    flote          NUMERIC(10,4) DEFAULT 0,   -- Flote
    is_ready       BOOLEAN       DEFAULT FALSE,
    information    TEXT,                      -- Açıklama
    record_date    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    update_date    TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS uix_color_info_stock ON color_info (stock_id);
CREATE INDEX IF NOT EXISTS idx_color_info_company  ON color_info (company_id);
CREATE INDEX IF NOT EXISTS idx_color_info_product  ON color_info (product_id);