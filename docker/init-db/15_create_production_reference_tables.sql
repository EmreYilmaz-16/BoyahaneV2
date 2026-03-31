-- ================================================
-- PRODUCTION REFERENCE TABLES (Üretim referans tabloları)
-- 16_create_production_tables.sql dosyasındaki foreign key bağımlılıkları
-- ================================================

-- WORKSTATIONS (İş istasyonları / makineler)
CREATE TABLE IF NOT EXISTS workstations (
    station_id SERIAL PRIMARY KEY,
    station_name VARCHAR(255) NOT NULL,
    station_code VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    record_date TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_workstations_active ON workstations(is_active);

-- SPECT_MAIN (Varyant ana tanımları)
CREATE TABLE IF NOT EXISTS spect_main (
    spect_main_id SERIAL PRIMARY KEY,
    spect_main_name VARCHAR(255),
    record_date TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- SPECTS (Varyant alt tanımları)
CREATE TABLE IF NOT EXISTS spects (
    spect_var_id SERIAL PRIMARY KEY,
    spect_main_id INTEGER,
    spect_var_name VARCHAR(255),
    record_date TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_spects_main FOREIGN KEY (spect_main_id)
        REFERENCES spect_main(spect_main_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_spects_main ON spects(spect_main_id);

-- OPERATION_TYPES (Operasyon tipleri)
CREATE TABLE IF NOT EXISTS operation_types (
    operation_type_id SERIAL PRIMARY KEY,
    operation_type_name VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    record_date TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_operation_types_active ON operation_types(is_active);
