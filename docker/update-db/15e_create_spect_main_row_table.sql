-- ================================================
-- SPECT_MAIN_ROW TABLE (Ana Varyant Satırları)
-- ================================================
-- Bağımlılık: spect_main tablosu önce oluşturulmalıdır (15c)
-- ================================================

CREATE TABLE spect_main_row (
    spect_main_row_id SERIAL PRIMARY KEY,
    spect_main_id INTEGER,
    product_id INTEGER,
    stock_id INTEGER,
    amount NUMERIC(18,6),
    property_id INTEGER,
    variation_id INTEGER,
    total_min NUMERIC(18,6),
    total_max NUMERIC(18,6),
    product_name VARCHAR(500),
    is_property INTEGER,
    is_configure BOOLEAN,
    is_sevk BOOLEAN,
    total_value NUMERIC(18,6),
    tolerance INTEGER,
    product_space NUMERIC(18,6),
    product_display NUMERIC(18,6),
    product_rate NUMERIC(18,6),
    product_list_price NUMERIC(18,6),
    calculate_type INTEGER,
    related_main_spect_id INTEGER,
    related_main_spect_name VARCHAR(150),
    line_number INTEGER,
    dimension NUMERIC(18,6),
    configurator_variation_id INTEGER,
    is_phantom BOOLEAN DEFAULT false,
    related_tree_id INTEGER,
    operation_type_id INTEGER,
    question_id INTEGER,
    station_id INTEGER,
    is_free_amount BOOLEAN,
    fire_amount NUMERIC(18,6),
    fire_rate NUMERIC(18,6),
    detail VARCHAR(150),
    is_quality_type BOOLEAN,
    quality_type_id INTEGER,
    quality_standart_value NUMERIC(18,6),
    quality_measure NUMERIC(18,6),
    quality_tolerance NUMERIC(18,6),
    
    -- Foreign Keys
    CONSTRAINT fk_spect_main_row_main FOREIGN KEY (spect_main_id) REFERENCES spect_main(spect_main_id) ON DELETE CASCADE,
    CONSTRAINT fk_spect_main_row_product FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE SET NULL,
    CONSTRAINT fk_spect_main_row_stock FOREIGN KEY (stock_id) REFERENCES stocks(stock_id) ON DELETE SET NULL
);

-- ================================================
-- İndeksler / Indexes
-- ================================================
CREATE INDEX idx_spect_main_row_main ON spect_main_row(spect_main_id);
CREATE INDEX idx_spect_main_row_product ON spect_main_row(product_id);
CREATE INDEX idx_spect_main_row_stock ON spect_main_row(stock_id);

-- ================================================
-- Açıklamalar / Comments
-- ================================================
COMMENT ON TABLE spect_main_row IS 'Ana varyant şablon satırları';
