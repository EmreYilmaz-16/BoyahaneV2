CREATE TABLE IF NOT EXISTS ship_rolls (
    ship_roll_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    roll_no INTEGER NOT NULL,
    roll_barcode VARCHAR(100) NOT NULL,
    weight NUMERIC(18,6),
    meter NUMERIC(18,6),
    note VARCHAR(500),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_ship_rolls_order_roll_no UNIQUE (order_id, roll_no),
    CONSTRAINT uq_ship_rolls_barcode UNIQUE (roll_barcode)
);

CREATE INDEX IF NOT EXISTS idx_ship_rolls_order ON ship_rolls(order_id);

COMMENT ON TABLE ship_rolls IS 'Siparişe bağlı top kayıtları ve barkodları';
COMMENT ON COLUMN ship_rolls.roll_no IS 'Aynı sipariş içinde 1’den başlayarak artan top sıra numarası';
COMMENT ON COLUMN ship_rolls.roll_barcode IS 'SR-{order_id}-{roll_no} formatında benzersiz top barkodu';
