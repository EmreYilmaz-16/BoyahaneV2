-- =====================================================
-- Kalite Kontrol Modülü - Tablo Oluşturma Scripti
-- boyahane veritabanı / PostgreSQL
-- =====================================================

-- ─────────────────────────────────────────────────────
-- 1. qc_parameters — Kalite Kontrol Parametreleri
--    (ölçülecek kriterler: boyut, renk, mukavemet vs.)
-- ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS qc_parameters (
    qc_param_id     SERIAL          PRIMARY KEY,
    param_code      VARCHAR(50)     NOT NULL UNIQUE,
    param_name      VARCHAR(200)    NOT NULL,
    param_type      SMALLINT        NOT NULL DEFAULT 1,
        -- 1=Sayısal(min-max), 2=Geçti/Kaldı, 3=Metin
    unit_name       VARCHAR(50),
    min_value       NUMERIC(18,4),
    max_value       NUMERIC(18,4),
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    sort_order      INTEGER         NOT NULL DEFAULT 0,
    detail          TEXT,
    record_emp      INTEGER,
    record_date     TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_ip       VARCHAR(50)
);

COMMENT ON TABLE  qc_parameters IS 'Kalite kontrol test/ölçüm parametreleri';
COMMENT ON COLUMN qc_parameters.param_type IS '1=Sayısal, 2=Geçti/Kaldı, 3=Metin';

-- ─────────────────────────────────────────────────────
-- 2. qc_defect_types — Hata / Kusur Tipleri
-- ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS qc_defect_types (
    defect_type_id  SERIAL          PRIMARY KEY,
    defect_code     VARCHAR(50)     NOT NULL UNIQUE,
    defect_name     VARCHAR(200)    NOT NULL,
    severity        SMALLINT        NOT NULL DEFAULT 2,
        -- 1=Hafif, 2=Orta, 3=Ciddi, 4=Kritik
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    sort_order      INTEGER         NOT NULL DEFAULT 0,
    detail          TEXT,
    record_date     TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_ip       VARCHAR(50)
);

COMMENT ON TABLE  qc_defect_types IS 'Kalite kontrol hata/kusur tip tanımları';
COMMENT ON COLUMN qc_defect_types.severity IS '1=Hafif, 2=Orta, 3=Ciddi, 4=Kritik';

-- ─────────────────────────────────────────────────────
-- 3. qc_plans — Kalite Kontrol Planları
--    (hangi ürün için hangi kontrol tipi uygulanacak)
-- ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS qc_plans (
    qc_plan_id      SERIAL          PRIMARY KEY,
    plan_code       VARCHAR(50)     NOT NULL UNIQUE,
    plan_name       VARCHAR(200)    NOT NULL,
    product_id      INTEGER         REFERENCES product(product_id) ON DELETE SET NULL,
    control_type    SMALLINT        NOT NULL DEFAULT 1,
        -- 1=Giriş Kontrol, 2=Operasyon Kontrol, 3=Final/Çıkış Kontrol
    sample_method   SMALLINT        NOT NULL DEFAULT 1,
        -- 1=Sabit Miktar, 2=Yüzde, 3=Tümü
    sample_value    NUMERIC(18,4),  -- miktar ya da yüzde
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    detail          TEXT,
    record_emp      INTEGER,
    record_date     TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_ip       VARCHAR(50)
);

COMMENT ON TABLE  qc_plans IS 'Kalite kontrol planları (ürün bazlı)';
COMMENT ON COLUMN qc_plans.control_type IS '1=Giriş, 2=Operasyon, 3=Final/Çıkış';
COMMENT ON COLUMN qc_plans.sample_method IS '1=Sabit Miktar, 2=Yüzde, 3=Tümü';

-- ─────────────────────────────────────────────────────
-- 4. qc_plan_items — Plan Kalemleri
--    (plan içinde kontrol edilecek parametreler)
-- ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS qc_plan_items (
    qc_plan_item_id SERIAL          PRIMARY KEY,
    qc_plan_id      INTEGER         NOT NULL REFERENCES qc_plans(qc_plan_id) ON DELETE CASCADE,
    qc_param_id     INTEGER         NOT NULL REFERENCES qc_parameters(qc_param_id) ON DELETE CASCADE,
    is_required     BOOLEAN         NOT NULL DEFAULT TRUE,
    min_override    NUMERIC(18,4),  -- plan bazlı min değer (parametre default'unu ezer)
    max_override    NUMERIC(18,4),  -- plan bazlı max değer
    sort_order      INTEGER         NOT NULL DEFAULT 0,
    UNIQUE (qc_plan_id, qc_param_id)
);

-- ─────────────────────────────────────────────────────
-- 5. qc_inspections — Kalite Kontrol Muayene İşlemleri
--    Giriş, Operasyon veya Final kontrolü başlık tablosu
-- ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS qc_inspections (
    qc_inspection_id    SERIAL          PRIMARY KEY,
    inspection_no       VARCHAR(50)     NOT NULL,
    inspection_type     SMALLINT        NOT NULL DEFAULT 1,
        -- 1=Giriş Kontrol, 2=Operasyon Kontrol, 3=Final/Çıkış Kontrol
    -- Referans bağlantısı (sadece biri dolu olacak)
    ship_id             INTEGER         REFERENCES ship(ship_id) ON DELETE SET NULL,
    p_order_id          INTEGER         REFERENCES production_orders(p_order_id) ON DELETE SET NULL,
    -- Ürün / Stok
    product_id          INTEGER         REFERENCES product(product_id) ON DELETE SET NULL,
    stock_id            INTEGER         REFERENCES stocks(stock_id) ON DELETE SET NULL,
    qc_plan_id          INTEGER         REFERENCES qc_plans(qc_plan_id) ON DELETE SET NULL,
    lot_no              VARCHAR(100),
    quantity            NUMERIC(18,4)   NOT NULL DEFAULT 0,
    sample_quantity     NUMERIC(18,4)   NOT NULL DEFAULT 0,
    inspection_date     TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    inspector_name      VARCHAR(200),
    -- Sonuç: 1=Kabul, 2=Koşullu Kabul, 3=Ret
    result              SMALLINT        NOT NULL DEFAULT 1,
    notes               TEXT,
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,
    record_emp          INTEGER,
    record_date         TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_ip           VARCHAR(50)
);

COMMENT ON TABLE  qc_inspections IS 'Kalite kontrol muayene işlemleri (giriş/operasyon/final)';
COMMENT ON COLUMN qc_inspections.inspection_type IS '1=Giriş Kontrol, 2=Operasyon Kontrol, 3=Final/Çıkış Kontrol';
COMMENT ON COLUMN qc_inspections.result IS '1=Kabul, 2=Koşullu Kabul, 3=Ret';

-- ─────────────────────────────────────────────────────
-- 6. qc_inspection_results — Parametre Ölçüm Sonuçları
-- ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS qc_inspection_results (
    qc_result_id        SERIAL          PRIMARY KEY,
    qc_inspection_id    INTEGER         NOT NULL REFERENCES qc_inspections(qc_inspection_id) ON DELETE CASCADE,
    qc_param_id         INTEGER         NOT NULL REFERENCES qc_parameters(qc_param_id) ON DELETE CASCADE,
    measured_value      NUMERIC(18,4),
    text_result         VARCHAR(500),
    is_pass             BOOLEAN         NOT NULL DEFAULT TRUE,
    notes               VARCHAR(500)
);

-- ─────────────────────────────────────────────────────
-- 7. qc_inspection_defects — Tespit Edilen Hatalar
-- ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS qc_inspection_defects (
    qc_defect_id        SERIAL          PRIMARY KEY,
    qc_inspection_id    INTEGER         NOT NULL REFERENCES qc_inspections(qc_inspection_id) ON DELETE CASCADE,
    defect_type_id      INTEGER         NOT NULL REFERENCES qc_defect_types(defect_type_id) ON DELETE CASCADE,
    defect_count        INTEGER         NOT NULL DEFAULT 1,
    defect_location     VARCHAR(200),
    notes               VARCHAR(500)
);

-- ─────────────────────────────────────────────────────
-- İndeksler
-- ─────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_qc_plans_product   ON qc_plans(product_id);
CREATE INDEX IF NOT EXISTS idx_qc_plan_items_plan ON qc_plan_items(qc_plan_id);
CREATE INDEX IF NOT EXISTS idx_qc_insp_type       ON qc_inspections(inspection_type);
CREATE INDEX IF NOT EXISTS idx_qc_insp_ship       ON qc_inspections(ship_id);
CREATE INDEX IF NOT EXISTS idx_qc_insp_porder     ON qc_inspections(p_order_id);
CREATE INDEX IF NOT EXISTS idx_qc_insp_product    ON qc_inspections(product_id);
CREATE INDEX IF NOT EXISTS idx_qc_insp_date       ON qc_inspections(inspection_date);
CREATE INDEX IF NOT EXISTS idx_qc_res_insp        ON qc_inspection_results(qc_inspection_id);
CREATE INDEX IF NOT EXISTS idx_qc_def_insp        ON qc_inspection_defects(qc_inspection_id);

-- ─────────────────────────────────────────────────────
-- Örnek Parametre Tanımları (boyahane / tekstil)
-- ─────────────────────────────────────────────────────
INSERT INTO qc_parameters (param_code, param_name, param_type, unit_name, min_value, max_value, sort_order) VALUES
    ('RENK_FARKI',   'Renk Farkı (Delta E)',        1, 'ΔE',     NULL, 1.00,   10),
    ('KOPMA_MUK',    'Kopma Mukavemeti',             1, 'N',      100,  NULL,   20),
    ('UZAMA',        'Uzama Yüzdesi',                1, '%',      10.0, 50.0,   30),
    ('GRAMAJ',       'Gramaj',                       1, 'g/m²',   NULL, NULL,   40),
    ('EN',           'Kumaş Eni',                    1, 'cm',     NULL, NULL,   50),
    ('BOYAMA_ESIT',  'Boyama Eşitliği',              2, NULL,     NULL, NULL,   60),
    ('SOLMA',        'Solma Haslığı',                1, 'Nota',   3.0,  5.0,    70),
    ('YIKAMA_HASL',  'Yıkama Haslığı',               1, 'Nota',   3.0,  5.0,    80),
    ('GORSEL_KON',   'Görsel Kontrol',               2, NULL,     NULL, NULL,   90),
    ('MIKTAR_KON',   'Miktar Kontrolü',              2, NULL,     NULL, NULL,   100)
ON CONFLICT (param_code) DO NOTHING;

-- Örnek Hata Tipleri
INSERT INTO qc_defect_types (defect_code, defect_name, severity, sort_order) VALUES
    ('RENK_FARK',    'Renk Farkı',               3, 10),
    ('BOYAMA_HAT',   'Boyama Hatası',             3, 20),
    ('YIRTIK',       'Yırtık / Delik',            4, 30),
    ('LEKE',         'Leke',                      2, 40),
    ('DIKIS_HAT',    'Dikiş Hatası',              2, 50),
    ('GRAMAJ_FARK',  'Gramaj Sapması',            2, 60),
    ('EN_FARK',      'En Sapması',                2, 70),
    ('BUKUSME',      'Büküşme / Çekme',           2, 80),
    ('ETIKET_HAT',   'Etiket Hatası',             1, 90),
    ('AMBALAJ_HAT',  'Ambalaj Hatası',            1, 100)
ON CONFLICT (defect_code) DO NOTHING;
