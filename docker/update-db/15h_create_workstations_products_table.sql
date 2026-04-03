-- ================================================
-- WORKSTATIONS_PRODUCTS TABLE (İstasyon-Ürün İlişkisi)
-- ================================================
-- Bağımlılık: workstations (15b) ve operation_types (15a) önce oluşturulmalıdır
-- ================================================

CREATE TABLE workstations_products (
    ws_p_id SERIAL PRIMARY KEY,
    ws_id INTEGER,
    stock_id INTEGER,
    capacity NUMERIC(18,6),
    production_time NUMERIC(18,6),
    production_time_type NUMERIC(18,6),
    setup_time NUMERIC(18,6),
    min_product_amount NUMERIC(18,6),
    production_type BOOLEAN,
    process VARCHAR(250),
    main_stock_id INTEGER,
    operation_type_id INTEGER,
    record_emp INTEGER,
    record_ip VARCHAR(50),
    record_date TIMESTAMP WITHOUT TIME ZONE,
    asset_id INTEGER,
    
    -- Foreign Keys
    CONSTRAINT fk_ws_products_ws FOREIGN KEY (ws_id) REFERENCES workstations(station_id) ON DELETE CASCADE,
    CONSTRAINT fk_ws_products_stock FOREIGN KEY (stock_id) REFERENCES stocks(stock_id) ON DELETE SET NULL,
    CONSTRAINT fk_ws_products_operation FOREIGN KEY (operation_type_id) REFERENCES operation_types(operation_type_id) ON DELETE SET NULL
);

-- ================================================
-- İndeksler / Indexes
-- ================================================
CREATE INDEX idx_ws_products_ws ON workstations_products(ws_id);
CREATE INDEX idx_ws_products_stock ON workstations_products(stock_id);
CREATE INDEX idx_ws_products_operation ON workstations_products(operation_type_id);

-- ================================================
-- Açıklamalar / Comments
-- ================================================
COMMENT ON TABLE workstations_products IS 'İstasyon-ürün ilişki tablosu';
COMMENT ON COLUMN workstations_products.production_time IS 'Üretim süresi';
