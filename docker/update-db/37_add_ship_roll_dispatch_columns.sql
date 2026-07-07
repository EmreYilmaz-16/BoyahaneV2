-- Sevkiyat aşamasında top barkodlarının okutulup sevk edilmesi için alanlar
ALTER TABLE ship_roll ADD COLUMN IF NOT EXISTS dispatch_ship_id INTEGER;
ALTER TABLE ship_roll ADD COLUMN IF NOT EXISTS dispatch_date TIMESTAMP;
ALTER TABLE ship_roll ADD COLUMN IF NOT EXISTS dispatch_emp INTEGER;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_ship_roll_dispatch_ship'
    ) THEN
        ALTER TABLE ship_roll
            ADD CONSTRAINT fk_ship_roll_dispatch_ship
            FOREIGN KEY (dispatch_ship_id) REFERENCES ship(ship_id) ON DELETE SET NULL;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_ship_roll_dispatch_ship ON ship_roll(dispatch_ship_id);
CREATE INDEX IF NOT EXISTS idx_ship_roll_dispatch_date ON ship_roll(dispatch_date);

COMMENT ON COLUMN ship_roll.dispatch_ship_id IS 'Topun sevk edildiği irsaliye/sevkiyat ID';
COMMENT ON COLUMN ship_roll.dispatch_date IS 'Topun sevk okutma tarihi';
COMMENT ON COLUMN ship_roll.dispatch_emp IS 'Topu sevk okutan personel';
