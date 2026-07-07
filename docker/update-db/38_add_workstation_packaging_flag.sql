ALTER TABLE workstations ADD COLUMN IF NOT EXISTS is_packaging BOOLEAN DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_workstations_is_packaging ON workstations(is_packaging);

COMMENT ON COLUMN workstations.is_packaging IS 'Paketleme metrikleri için tek kaynak: TRUE olan iş istasyonları paketleme istasyonudur.';
