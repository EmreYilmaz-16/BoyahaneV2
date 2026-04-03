-- ================================================
-- SPECTS_ROW TABLE (Varyant Satırları)
-- ================================================
-- Bağımlılık: spects tablosu önce oluşturulmalıdır (15f)
-- ================================================

CREATE TABLE spects_row (
    spect_row_id SERIAL PRIMARY KEY,
    spect_id INTEGER,
    product_id INTEGER,
    stock_id INTEGER,
    amount_value NUMERIC(18,6),
    total_value NUMERIC(18,6),
    money_currency VARCHAR(43),
    property_id INTEGER,
    variation_id INTEGER,
    total_min NUMERIC(18,6),
    total_max NUMERIC(18,6),
    product_name VARCHAR(500),
    is_property INTEGER,
    is_configure BOOLEAN,
    diff_price NUMERIC(18,6),
    product_cost NUMERIC(18,6),
    product_cost_money VARCHAR(43),
    product_cost_id INTEGER,
    is_sevk BOOLEAN DEFAULT false,
    tolerance INTEGER,
    related_spect_id INTEGER,
    shelf_number VARCHAR(43),
    product_manufact_code VARCHAR(100),
    product_space NUMERIC(18,6),
    product_display NUMERIC(18,6),
    product_rate NUMERIC(18,6),
    product_list_price NUMERIC(18,6),
    line_number INTEGER,
    configurator_variation_id INTEGER,
    dimension NUMERIC(18,6),
    related_tree_id INTEGER,
    operation_type_id INTEGER,
    is_quality_type BOOLEAN,
    quality_type_id INTEGER,
    quality_standart_value NUMERIC(18,6),
    quality_measure NUMERIC(18,6),
    quality_tolerance NUMERIC(18,6),
    fire_amount NUMERIC(18,6),
    product_height NUMERIC(18,6),
    product_thickness NUMERIC(18,6),
    tree_type INTEGER,
    product_size NUMERIC(18,6),
    product_width NUMERIC(18,6),
    
    -- Foreign Keys
    CONSTRAINT fk_spects_row_spect FOREIGN KEY (spect_id) REFERENCES spects(spect_var_id) ON DELETE CASCADE,
    CONSTRAINT fk_spects_row_product FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE SET NULL,
    CONSTRAINT fk_spects_row_stock FOREIGN KEY (stock_id) REFERENCES stocks(stock_id) ON DELETE SET NULL
);

-- ================================================
-- İndeksler / Indexes
-- ================================================
CREATE INDEX idx_spects_row_spect ON spects_row(spect_id);
CREATE INDEX idx_spects_row_product ON spects_row(product_id);
CREATE INDEX idx_spects_row_stock ON spects_row(stock_id);

-- ================================================
-- Açıklamalar / Comments
-- ================================================
COMMENT ON TABLE spects_row IS 'Varyant detay satırları';
