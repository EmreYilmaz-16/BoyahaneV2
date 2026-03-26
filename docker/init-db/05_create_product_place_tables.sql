-- PRODUCT_PLACE Tablosu
CREATE TABLE IF NOT EXISTS product_place (
    product_place_id SERIAL PRIMARY KEY,
    shelf_code VARCHAR(43),
    place_status INTEGER,
    product_id INTEGER,
    place_stock_id INTEGER,
    store_id INTEGER,
    location_id INTEGER,
    shelf_type INTEGER,
    quantity INTEGER,
    detail VARCHAR(100),
    start_date TIMESTAMP,
    finish_date TIMESTAMP,
    width NUMERIC(10,2),
    height NUMERIC(10,2),
    depth NUMERIC(10,2),
    x_coordinate VARCHAR(50),
    y_coordinate VARCHAR(50),
    z_coordinate VARCHAR(50),
    record_emp INTEGER,
    record_emp_ip VARCHAR(50),
    record_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_emp INTEGER,
    update_emp_ip VARCHAR(50),
    update_date TIMESTAMP,
    CONSTRAINT fk_product_place_product FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE CASCADE
);

-- PRODUCT_PLACE_ROWS Tablosu
CREATE TABLE IF NOT EXISTS product_place_rows (
    product_place_row_id SERIAL PRIMARY KEY,
    product_place_id INTEGER NOT NULL,
    product_id INTEGER,
    stock_id INTEGER,
    amount NUMERIC(18,4),
    CONSTRAINT fk_place_rows_place FOREIGN KEY (product_place_id) REFERENCES product_place(product_place_id) ON DELETE CASCADE,
    CONSTRAINT fk_place_rows_product FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE SET NULL
);

-- İndeksler
CREATE INDEX idx_product_place_shelf ON product_place(shelf_code);
CREATE INDEX idx_product_place_product ON product_place(product_id);
CREATE INDEX idx_product_place_store ON product_place(store_id);
CREATE INDEX idx_product_place_location ON product_place(location_id);
CREATE INDEX idx_product_place_status ON product_place(place_status);
CREATE INDEX idx_place_rows_place ON product_place_rows(product_place_id);
CREATE INDEX idx_place_rows_product ON product_place_rows(product_id);

-- Yorum satırları
COMMENT ON TABLE product_place IS 'Ürün yerleşim bilgileri - raf konumları';
COMMENT ON TABLE product_place_rows IS 'Ürün yerleşim detay satırları';
COMMENT ON COLUMN product_place.shelf_code IS 'Raf kodu';
COMMENT ON COLUMN product_place.place_status IS 'Yerleşim durumu (0:Pasif, 1:Aktif)';
COMMENT ON COLUMN product_place.shelf_type IS 'Raf tipi';
COMMENT ON COLUMN product_place.quantity IS 'Miktar';
COMMENT ON COLUMN product_place.width IS 'Genişlik (cm)';
COMMENT ON COLUMN product_place.height IS 'Yükseklik (cm)';
COMMENT ON COLUMN product_place.depth IS 'Derinlik (cm)';
COMMENT ON COLUMN product_place_rows.amount IS 'Stok miktarı';
