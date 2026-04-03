-- ================================================
-- ORDER_TO_SHIP_PRT TABLE (Sipariş-Sevkiyat İlişkisi)
-- ================================================
-- Siparişler ile sevkiyatlar arasındaki ilişkiyi tutar
-- Bir sipariş birden fazla sevkiyata bölünebilir
-- Bir sevkiyat birden fazla siparişi içerebilir
-- ================================================

CREATE TABLE order_to_ship_prt (
    id SERIAL PRIMARY KEY,
    ship_id INTEGER,
    order_id INTEGER,
    period_id INTEGER,
    
    -- Foreign Keys
    CONSTRAINT fk_order_ship_ship FOREIGN KEY (ship_id) REFERENCES ship(ship_id) ON DELETE CASCADE,
    CONSTRAINT fk_order_ship_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
);

-- ================================================
-- İndeksler / Indexes
-- ================================================

CREATE INDEX idx_order_ship_ship ON order_to_ship_prt(ship_id);
CREATE INDEX idx_order_ship_order ON order_to_ship_prt(order_id);
CREATE INDEX idx_order_ship_period ON order_to_ship_prt(period_id);
CREATE INDEX idx_order_ship_combination ON order_to_ship_prt(ship_id, order_id);

-- ================================================
-- Açıklamalar / Comments
-- ================================================

COMMENT ON TABLE order_to_ship_prt IS 'Sipariş ve sevkiyat arasındaki ilişki tablosu (Many-to-Many)';
COMMENT ON COLUMN order_to_ship_prt.id IS 'Birincil anahtar';
COMMENT ON COLUMN order_to_ship_prt.ship_id IS 'Sevkiyat ID (SHIP tablosu)';
COMMENT ON COLUMN order_to_ship_prt.order_id IS 'Sipariş ID (ORDERS tablosu)';
COMMENT ON COLUMN order_to_ship_prt.period_id IS 'Dönem ID (muhasebe dönemi)';
