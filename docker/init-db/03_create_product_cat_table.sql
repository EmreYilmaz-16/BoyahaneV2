-- PRODUCT_CAT tablosu - PostgreSQL formatında
CREATE TABLE IF NOT EXISTS product_cat (
    product_catid SERIAL PRIMARY KEY,
    hierarchy VARCHAR(50),
    product_cat VARCHAR(150) NOT NULL,
    detail VARCHAR(150),
    record_date TIMESTAMP,
    record_emp INTEGER,
    record_emp_ip VARCHAR(50),
    update_date TIMESTAMP,
    update_emp INTEGER,
    update_emp_ip VARCHAR(50)
);

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_product_cat_hierarchy ON product_cat(hierarchy);
CREATE INDEX IF NOT EXISTS idx_product_cat_name ON product_cat(product_cat);

-- Yorum ekle
COMMENT ON TABLE product_cat IS 'Ürün kategorilerini tutan tablo';
