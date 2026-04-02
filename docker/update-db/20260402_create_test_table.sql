-- Test tablosu
-- Tarih: 2026-04-02

CREATE TABLE IF NOT EXISTS test_items (
    item_id    SERIAL PRIMARY KEY,
    item_code  VARCHAR(50)   NOT NULL UNIQUE,
    item_name  VARCHAR(200)  NOT NULL,
    quantity   INTEGER       NOT NULL DEFAULT 0,
    unit_price NUMERIC(12,2),
    is_active  BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP     NOT NULL DEFAULT NOW()
);

INSERT INTO test_items (item_code, item_name, quantity, unit_price, is_active) VALUES
    ('TST-001', 'Test Ürün Bir',    100,  25.50, TRUE),
    ('TST-002', 'Test Ürün İki',     50,  99.90, TRUE),
    ('TST-003', 'Test Ürün Üç',      10, 149.99, TRUE),
    ('TST-004', 'Pasif Test Ürün',    0,   0.00, FALSE),
    ('TST-005', 'Test Ürün Beş',    200,  12.75, TRUE)
ON CONFLICT (item_code) DO NOTHING;
