-- Price and Pricing Tables for PostgreSQL

-- PRICE_CAT Table (Fiyat kategorileri - liste, perakende, toptan vb.)
CREATE TABLE IF NOT EXISTS price_cat (
    price_catid SERIAL PRIMARY KEY,
    price_cat_status BOOLEAN NOT NULL DEFAULT true,
    guest BOOLEAN,
    company_cat VARCHAR(500),
    consumer_cat VARCHAR(500),
    branch VARCHAR(500),
    price_cat VARCHAR(100) NOT NULL,
    discount NUMERIC(10,2),
    is_kdv BOOLEAN,
    target_margin VARCHAR(50),
    target_margin_id INTEGER,
    margin NUMERIC(10,2),
    startdate TIMESTAMP,
    finishdate TIMESTAMP,
    valid_date TIMESTAMP,
    valid_emp INTEGER,
    money_id INTEGER DEFAULT 1,
    rounding INTEGER,
    number_of_installment INTEGER,
    avg_due_day INTEGER,
    due_diff_value NUMERIC(18,6),
    paymethod INTEGER,
    early_payment NUMERIC(10,2),
    target_due_date TIMESTAMP,
    is_calc_productcat BOOLEAN,
    is_sales INTEGER,
    is_purchase INTEGER,
    position_cat TEXT,
    record_emp INTEGER,
    record_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    record_ip VARCHAR(50),
    update_emp INTEGER,
    update_date TIMESTAMP,
    update_ip VARCHAR(50),
    CONSTRAINT fk_price_cat_money FOREIGN KEY (money_id) REFERENCES setup_money(money_id)
);

-- PRICE Table (Ürün fiyatları)
CREATE TABLE IF NOT EXISTS price (
    price_id SERIAL PRIMARY KEY,
    price_catid INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    stock_id INTEGER,
    spect_var_id INTEGER,
    finishdate TIMESTAMP,
    startdate TIMESTAMP NOT NULL,
    price NUMERIC(18,6) NOT NULL,
    price_kdv NUMERIC(18,6) NOT NULL,
    is_kdv BOOLEAN NOT NULL,
    rounding INTEGER,
    unit INTEGER NOT NULL,
    money VARCHAR(43) NOT NULL,
    catalog_id INTEGER,
    price_discount NUMERIC(10,2) NOT NULL,
    record_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    record_emp INTEGER,
    record_ip VARCHAR(50),
    process_stage INTEGER,
    CONSTRAINT fk_price_cat FOREIGN KEY (price_catid) REFERENCES price_cat(price_catid) ON DELETE CASCADE,
    CONSTRAINT fk_price_product FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE CASCADE,
    CONSTRAINT fk_price_stock FOREIGN KEY (stock_id) REFERENCES stocks(stock_id) ON DELETE CASCADE
);

-- PRICE_HISTORY Table (Fiyat değişiklik geçmişi)
CREATE TABLE IF NOT EXISTS price_history (
    price_history_id SERIAL PRIMARY KEY,
    price_catid INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    stock_id INTEGER,
    spect_var_id INTEGER,
    finishdate TIMESTAMP,
    startdate TIMESTAMP NOT NULL,
    price NUMERIC(18,6) NOT NULL,
    is_kdv BOOLEAN NOT NULL,
    price_kdv NUMERIC(18,6) NOT NULL,
    price_discount NUMERIC(10,2) NOT NULL,
    unit INTEGER NOT NULL,
    money VARCHAR(43) NOT NULL,
    catalog_id INTEGER,
    record_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    record_emp INTEGER,
    record_ip VARCHAR(50),
    CONSTRAINT fk_price_history_cat FOREIGN KEY (price_catid) REFERENCES price_cat(price_catid) ON DELETE CASCADE,
    CONSTRAINT fk_price_history_product FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE CASCADE
);

-- PRICE_CAT_EXCEPTIONS Table (Fiyat istisnaları - özel müşteri/ürün fiyatları)
CREATE TABLE IF NOT EXISTS price_cat_exceptions (
    price_cat_exception_id SERIAL PRIMARY KEY,
    is_general BOOLEAN,
    company_id INTEGER,
    product_catid INTEGER,
    consumer_id INTEGER,
    brand_id INTEGER,
    product_id INTEGER,
    price_catid INTEGER,
    discount_rate NUMERIC(10,2),
    companycat_id INTEGER,
    supplier_id INTEGER,
    act_type INTEGER DEFAULT 1,
    is_default BOOLEAN DEFAULT false,
    purchase_sales INTEGER,
    discount_rate_2 NUMERIC(10,2),
    discount_rate_3 NUMERIC(10,2),
    discount_rate_4 NUMERIC(10,2),
    discount_rate_5 NUMERIC(10,2),
    payment_type_id INTEGER,
    short_code_id INTEGER,
    contract_id INTEGER,
    price NUMERIC(18,6),
    price_money VARCHAR(43),
    record_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    record_emp INTEGER,
    record_ip VARCHAR(50),
    update_date TIMESTAMP,
    update_emp INTEGER,
    update_ip VARCHAR(50),
    CONSTRAINT fk_exception_company FOREIGN KEY (company_id) REFERENCES company(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_exception_price_cat FOREIGN KEY (price_catid) REFERENCES price_cat(price_catid) ON DELETE CASCADE,
    CONSTRAINT fk_exception_product FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE CASCADE,
    CONSTRAINT fk_exception_brand FOREIGN KEY (brand_id) REFERENCES product_brands(brand_id) ON DELETE CASCADE
);

-- İndeksler
CREATE INDEX idx_price_cat_status ON price_cat(price_cat_status);
CREATE INDEX idx_price_cat_valid ON price_cat(valid_date);
CREATE INDEX idx_price_cat_money ON price_cat(money_id);

CREATE INDEX idx_price_catid ON price(price_catid);
CREATE INDEX idx_price_product ON price(product_id);
CREATE INDEX idx_price_stock ON price(stock_id);
CREATE INDEX idx_price_dates ON price(startdate, finishdate);
CREATE INDEX idx_price_money ON price(money);

CREATE INDEX idx_price_history_cat ON price_history(price_catid);
CREATE INDEX idx_price_history_product ON price_history(product_id);
CREATE INDEX idx_price_history_dates ON price_history(startdate, finishdate);

CREATE INDEX idx_exception_company ON price_cat_exceptions(company_id);
CREATE INDEX idx_exception_product ON price_cat_exceptions(product_id);
CREATE INDEX idx_exception_cat ON price_cat_exceptions(price_catid);
CREATE INDEX idx_exception_brand ON price_cat_exceptions(brand_id);
CREATE INDEX idx_exception_type ON price_cat_exceptions(act_type);

-- Yorum satırları
COMMENT ON TABLE price_cat IS 'Fiyat kategorileri (Liste, Perakende, Toptan, vb.)';
COMMENT ON TABLE price IS 'Ürün fiyat tanımları';
COMMENT ON TABLE price_history IS 'Fiyat değişiklik geçmişi';
COMMENT ON TABLE price_cat_exceptions IS 'Özel fiyat istisnaları (müşteri/ürün bazlı)';

COMMENT ON COLUMN price_cat.price_cat IS 'Fiyat kategori adı';
COMMENT ON COLUMN price_cat.is_kdv IS 'KDV dahil mi?';
COMMENT ON COLUMN price_cat.margin IS 'Hedef kar marjı (%)';
COMMENT ON COLUMN price_cat.is_sales IS 'Satış fiyatı mı?';
COMMENT ON COLUMN price_cat.is_purchase IS 'Alış fiyatı mı?';

COMMENT ON COLUMN price.price IS 'Fiyat (KDV hariç)';
COMMENT ON COLUMN price.price_kdv IS 'Fiyat (KDV dahil)';
COMMENT ON COLUMN price.is_kdv IS 'KDV dahil mi?';
COMMENT ON COLUMN price.price_discount IS 'İskonto oranı (%)';
COMMENT ON COLUMN price.startdate IS 'Geçerlilik başlangıç tarihi';
COMMENT ON COLUMN price.finishdate IS 'Geçerlilik bitiş tarihi';

COMMENT ON COLUMN price_cat_exceptions.is_general IS 'Genel istisna mı?';
COMMENT ON COLUMN price_cat_exceptions.discount_rate IS 'İskonto 1 (%)';
COMMENT ON COLUMN price_cat_exceptions.discount_rate_2 IS 'İskonto 2 (%)';
COMMENT ON COLUMN price_cat_exceptions.purchase_sales IS 'Alış/Satış (1:Satış, 0:Alış)';

-- Örnek fiyat kategorileri
INSERT INTO price_cat (price_cat, price_cat_status, is_kdv, margin, is_sales, is_purchase) VALUES
('Liste Fiyatı', true, true, 30.00, 1, 0),
('Perakende', true, true, 25.00, 1, 0),
('Toptan', true, true, 15.00, 1, 0),
('Bayi', true, true, 10.00, 1, 0),
('Alış Fiyatı', true, false, 0.00, 0, 1)
ON CONFLICT DO NOTHING;
