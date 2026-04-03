-- ================================================
-- PRODUCT_TREE TABLE (Ürün Ağacı/Reçete - BOM)
-- ================================================

CREATE TABLE product_tree (
    product_tree_id SERIAL PRIMARY KEY,
    related_id INTEGER,
    product_id INTEGER,
    hierarchy VARCHAR(100),
    is_tree BOOLEAN DEFAULT false,
    amount NUMERIC(18,6),
    unit_id INTEGER,
    stock_id INTEGER,
    is_configure BOOLEAN,
    is_sevk BOOLEAN DEFAULT false,
    spect_main_id INTEGER,
    line_number INTEGER,
    operation_type_id INTEGER,
    operation_duration VARCHAR(43),
    station_id INTEGER,
    is_phantom BOOLEAN DEFAULT false,
    question_id INTEGER,
    related_product_tree_id INTEGER,
    process_stage INTEGER,
    main_stock_id INTEGER,
    update_emp INTEGER,
    update_ip VARCHAR(50),
    update_date TIMESTAMP WITHOUT TIME ZONE,
    record_emp INTEGER,
    record_date TIMESTAMP WITHOUT TIME ZONE,
    history_date TIMESTAMP WITHOUT TIME ZONE,
    history_emp INTEGER,
    is_free_amount BOOLEAN,
    fire_amount NUMERIC(18,6),
    fire_rate NUMERIC(18,6),
    detail VARCHAR(150),
    product_property INTEGER,
    last_price NUMERIC(18,6),
    supplier_company_id INTEGER,
    alternative_stock_id INTEGER,
    product_sample_id INTEGER,
    product_length INTEGER,
    technical_point INTEGER,
    product_height INTEGER,
    target_price NUMERIC(18,6),
    tree_type INTEGER,
    target_price_currency VARCHAR(10),
    production_code VARCHAR(50),
    product_width INTEGER,
    amount2 NUMERIC(18,6),
    
    -- Foreign Keys
    CONSTRAINT fk_product_tree_product FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE SET NULL,
    CONSTRAINT fk_product_tree_stock FOREIGN KEY (stock_id) REFERENCES stocks(stock_id) ON DELETE SET NULL,
    CONSTRAINT fk_product_tree_unit FOREIGN KEY (unit_id) REFERENCES setup_unit(unit_id) ON DELETE SET NULL,
    CONSTRAINT fk_product_tree_supplier FOREIGN KEY (supplier_company_id) REFERENCES company(company_id) ON DELETE SET NULL
);

-- ================================================
-- İndeksler / Indexes
-- ================================================
CREATE INDEX idx_product_tree_product ON product_tree(product_id);
CREATE INDEX idx_product_tree_stock ON product_tree(stock_id);
CREATE INDEX idx_product_tree_related ON product_tree(related_id);
CREATE INDEX idx_product_tree_hierarchy ON product_tree(hierarchy);
CREATE INDEX idx_product_tree_spect_main ON product_tree(spect_main_id);
CREATE INDEX idx_product_tree_operation ON product_tree(operation_type_id);
CREATE INDEX idx_product_tree_station ON product_tree(station_id);

-- ================================================
-- Açıklamalar / Comments
-- ================================================
COMMENT ON TABLE product_tree IS 'Ürün ağacı/reçete tablosu (BOM - Bill of Materials)';
COMMENT ON COLUMN product_tree.is_tree IS 'Ağaç yapısı var mı?';
COMMENT ON COLUMN product_tree.is_phantom IS 'Hayalet ürün (stoksuz)';
