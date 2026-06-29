-- Add water amount limits to workstations
ALTER TABLE workstations
    ADD COLUMN IF NOT EXISTS min_water_amount NUMERIC(18,6),
    ADD COLUMN IF NOT EXISTS max_water_amount NUMERIC(18,6);

COMMENT ON COLUMN workstations.min_water_amount IS 'Minimum su miktarı';
COMMENT ON COLUMN workstations.max_water_amount IS 'Maximum su miktarı';
