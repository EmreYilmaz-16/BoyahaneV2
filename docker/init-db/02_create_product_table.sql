-- PRODUCT tablosu - PostgreSQL formatında
CREATE TABLE IF NOT EXISTS product (
    product_id SERIAL PRIMARY KEY,
    product_status BOOLEAN NOT NULL DEFAULT false,
    product_code VARCHAR(500),
    company_id INTEGER,
    product_catid INTEGER NOT NULL,
    barcod VARCHAR(50),
    product_name VARCHAR(500),
    product_detail VARCHAR(500),
    product_detail2 VARCHAR(500),
    tax DOUBLE PRECISION NOT NULL DEFAULT 0,
    tax_purchase DOUBLE PRECISION,
    is_production BOOLEAN,
    shelf_life VARCHAR(300),
    is_sales BOOLEAN,
    is_purchase BOOLEAN,
    manufact_code VARCHAR(100),
    is_prototype BOOLEAN,
    is_internet BOOLEAN,
    is_terazi BOOLEAN,
    brand_id INTEGER,
    is_serial_no BOOLEAN,
    is_zero_stock BOOLEAN,
    otv DOUBLE PRECISION,
    is_karma BOOLEAN,
    product_code_2 VARCHAR(150),
    short_code VARCHAR(150),
    is_extranet BOOLEAN,
    is_karma_sevk BOOLEAN,
    record_branch_id INTEGER,
    record_member INTEGER,
    record_date TIMESTAMP,
    update_date TIMESTAMP,
    update_emp INTEGER,
    update_par INTEGER,
    update_ip VARCHAR(50),
    user_friendly_url VARCHAR(250),
    package_control_type INTEGER,
    is_limited_stock BOOLEAN,
    short_code_id INTEGER,
    is_commission BOOLEAN,
    customs_recipe_code VARCHAR(500),
    is_gift_card BOOLEAN,
    gift_valid_day INTEGER,
    is_quality BOOLEAN,
    quality_start_date TIMESTAMP,
    is_lot_no BOOLEAN,
    otv_amount DOUBLE PRECISION,
    oiv DOUBLE PRECISION,
    bsmv DOUBLE PRECISION,
    project_id INTEGER,
    otv_type INTEGER,
    product_keyword VARCHAR(500)
);

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_product_code ON product(product_code);
CREATE INDEX IF NOT EXISTS idx_product_name ON product(product_name);
CREATE INDEX IF NOT EXISTS idx_barcod ON product(barcod);
CREATE INDEX IF NOT EXISTS idx_company_id ON product(company_id);
CREATE INDEX IF NOT EXISTS idx_product_catid ON product(product_catid);
CREATE INDEX IF NOT EXISTS idx_brand_id ON product(brand_id);

-- Yorum ekle
COMMENT ON TABLE product IS 'Ürün bilgilerini tutan ana tablo';
