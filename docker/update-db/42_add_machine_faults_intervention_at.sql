ALTER TABLE machine_faults
    ADD COLUMN IF NOT EXISTS intervention_at TIMESTAMP;
