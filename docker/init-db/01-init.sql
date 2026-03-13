-- Initial database setup for Boyahane application
-- This script runs automatically when PostgreSQL container starts

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Log initialization
DO $$
BEGIN
    RAISE NOTICE 'Boyahane database initialized successfully!';
END $$;

-- Example: Create a test table
CREATE TABLE IF NOT EXISTS test_connection (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    message VARCHAR(255)
);

INSERT INTO test_connection (message) VALUES ('Database connection test successful!');

-- Your custom tables will go here
-- Example structure:
/*
CREATE TABLE IF NOT EXISTS siparisler (
    id SERIAL PRIMARY KEY,
    siparis_no VARCHAR(50) UNIQUE NOT NULL,
    urun_adi VARCHAR(255) NOT NULL,
    miktar INTEGER NOT NULL,
    durum VARCHAR(50) DEFAULT 'Beklemede',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS uretim (
    id SERIAL PRIMARY KEY,
    siparis_id INTEGER REFERENCES siparisler(id),
    uretilen_miktar INTEGER NOT NULL,
    uretim_tarihi DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
*/
