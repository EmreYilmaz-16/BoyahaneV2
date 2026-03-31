-- ================================================
-- PRODUCTION FUNCTIONS (Üretim Stored Procedure'leri)
-- SQL Server Stored Procedures → PostgreSQL Functions
-- ================================================

-- ================================================
-- PRODUCTION_ORDERS_CASH TABLE (Üretim Emri Nakit)
-- ADD_PRODUCTION_ORDER_CASH procedure tarafından kullanılıyor
-- ================================================
CREATE TABLE IF NOT EXISTS production_orders_cash (
    cash_id    SERIAL PRIMARY KEY,
    start_date TIMESTAMP WITHOUT TIME ZONE,
    finish_date TIMESTAMP WITHOUT TIME ZONE,
    station_id INTEGER,
    CONSTRAINT fk_prod_orders_cash_station FOREIGN KEY (station_id)
        REFERENCES workstations(station_id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_prod_orders_cash_station ON production_orders_cash(station_id);
COMMENT ON TABLE production_orders_cash IS 'Üretim emri nakit/maliyet periyotları';

-- ================================================
-- FUNCTION: add_production_operation
-- Yeni üretim operasyonu ekler
-- ================================================
CREATE OR REPLACE FUNCTION add_production_operation(
    _p_order_id        INTEGER,
    _station_id        INTEGER,
    _o_minute          NUMERIC(18,6),
    _operation_type_id INTEGER,
    _amount            NUMERIC(18,6),
    _record_emp        INTEGER,
    _record_date       TIMESTAMP WITHOUT TIME ZONE,
    _record_ip         VARCHAR(50),
    _stage             INTEGER
) RETURNS INTEGER AS $$
DECLARE
    _new_id INTEGER;
BEGIN
    INSERT INTO production_operation (
        p_order_id, station_id, o_minute, operation_type_id, amount,
        record_emp, record_date, record_ip, stage
    ) VALUES (
        _p_order_id, _station_id, _o_minute, _operation_type_id, _amount,
        _record_emp, _record_date, _record_ip, _stage
    ) RETURNING p_operation_id INTO _new_id;
    RETURN _new_id;
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- FUNCTION: add_production_order
-- Yeni üretim emri ekler
-- ================================================
CREATE OR REPLACE FUNCTION add_production_order(
    _po_related_id        INTEGER,
    _stock_id             INTEGER,
    _quantity             NUMERIC(18,6),
    _quantity_2           INTEGER,
    _unit_2               VARCHAR(50),
    _start_date           TIMESTAMP WITHOUT TIME ZONE,
    _finish_date          TIMESTAMP WITHOUT TIME ZONE,
    _record_emp           INTEGER,
    _record_date          TIMESTAMP WITHOUT TIME ZONE,
    _record_ip            VARCHAR(50),
    _status               INTEGER,
    _project_id           INTEGER,
    _p_order_no           VARCHAR(50),
    _detail               VARCHAR(2000),
    _prod_order_stage     INTEGER,
    _station_id           INTEGER,
    _spect_var_id         INTEGER,
    _spect_var_name       VARCHAR(500),
    _is_stock_reserved    BOOLEAN,
    _is_demontaj          BOOLEAN,
    _lot_no               VARCHAR(100),
    _production_level     VARCHAR(50),
    _spec_main_id         INTEGER,
    _is_stage             INTEGER,
    _wrk_row_id           VARCHAR(40),
    _demand_no            VARCHAR(50),
    _exit_dep_id          INTEGER,
    _exit_loc_id          INTEGER,
    _production_dep_id    INTEGER,
    _production_loc_id    INTEGER,
    _work_id              INTEGER,
    _wrk_row_relation_id  VARCHAR(50)
) RETURNS INTEGER AS $$
DECLARE
    _new_id INTEGER;
BEGIN
    INSERT INTO production_orders (
        po_related_id, stock_id, quantity, quantity_2, unit_2,
        start_date, finish_date, record_emp, record_date, record_ip,
        status, project_id, p_order_no, detail, prod_order_stage,
        station_id, spect_var_id, spect_var_name, is_stock_reserved,
        is_demontaj, lot_no, production_level, spec_main_id, is_stage,
        wrk_row_id, demand_no, exit_dep_id, exit_loc_id,
        production_dep_id, production_loc_id, work_id, wrk_row_relation_id
    ) VALUES (
        _po_related_id, _stock_id, _quantity, _quantity_2, _unit_2,
        _start_date, _finish_date, _record_emp, _record_date, _record_ip,
        _status, _project_id, _p_order_no, _detail, _prod_order_stage,
        _station_id, _spect_var_id, _spect_var_name, _is_stock_reserved,
        _is_demontaj, _lot_no, _production_level, _spec_main_id, _is_stage,
        _wrk_row_id, _demand_no, _exit_dep_id, _exit_loc_id,
        _production_dep_id, _production_loc_id, _work_id, _wrk_row_relation_id
    ) RETURNING p_order_id INTO _new_id;
    RETURN _new_id;
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- FUNCTION: add_production_order_cash
-- Nakit/maliyet periyodu ekler
-- ================================================
CREATE OR REPLACE FUNCTION add_production_order_cash(
    _start_date  TIMESTAMP WITHOUT TIME ZONE,
    _finish_date TIMESTAMP WITHOUT TIME ZONE,
    _station_id  INTEGER
) RETURNS INTEGER AS $$
DECLARE
    _new_id INTEGER;
BEGIN
    INSERT INTO production_orders_cash (start_date, finish_date, station_id)
    VALUES (_start_date, _finish_date, _station_id)
    RETURNING cash_id INTO _new_id;
    RETURN _new_id;
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- FUNCTION: add_production_order_result
-- Üretim emri sonucu ekler
-- ================================================
CREATE OR REPLACE FUNCTION add_production_order_result(
    _p_order_id            INTEGER,
    _process_id            INTEGER,
    _start_date            TIMESTAMP WITHOUT TIME ZONE,
    _finish_date           TIMESTAMP WITHOUT TIME ZONE,
    _exit_dep_id           INTEGER,
    _exit_loc_id           INTEGER,
    _station_id            INTEGER,
    _production_order_no   VARCHAR(43),
    _result_no             VARCHAR(43),
    _enter_dep_id          INTEGER,
    _enter_loc_id          INTEGER,
    _order_no              VARCHAR(250),
    _reference_no          VARCHAR(500),
    _position_id           INTEGER,
    _record_emp            INTEGER,
    _record_date           TIMESTAMP WITHOUT TIME ZONE,
    _record_ip             VARCHAR(50),
    _lot_no                VARCHAR(100),
    _production_dep_id     INTEGER,
    _production_loc_id     INTEGER,
    _prod_ord_result_stage INTEGER,
    _is_stock_fis          BOOLEAN,
    _wrk_row_id            VARCHAR(40),
    _expiration_date       TIMESTAMP WITHOUT TIME ZONE
) RETURNS INTEGER AS $$
DECLARE
    _new_id INTEGER;
BEGIN
    INSERT INTO production_order_results (
        p_order_id, process_id, start_date, finish_date,
        exit_dep_id, exit_loc_id, station_id, production_order_no,
        result_no, enter_dep_id, enter_loc_id, order_no,
        reference_no, position_id, record_emp, record_date, record_ip,
        lot_no, production_dep_id, production_loc_id,
        prod_ord_result_stage, is_stock_fis, wrk_row_id, expiration_date
    ) VALUES (
        _p_order_id, _process_id, _start_date, _finish_date,
        _exit_dep_id, _exit_loc_id, _station_id, _production_order_no,
        _result_no, _enter_dep_id, _enter_loc_id, _order_no,
        _reference_no, _position_id, _record_emp, _record_date, _record_ip,
        _lot_no, _production_dep_id, _production_loc_id,
        _prod_ord_result_stage, _is_stock_fis, _wrk_row_id, _expiration_date
    ) RETURNING pr_order_id INTO _new_id;
    RETURN _new_id;
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- FUNCTION: add_production_order_results_row
-- Üretim sonuç satırı ekler (maliyet/ağaç tipi)
-- ================================================
CREATE OR REPLACE FUNCTION add_production_order_results_row(
    _tree_type                    VARCHAR(43),
    _type                         INTEGER,
    _pr_order_id                  INTEGER,
    _barcode                      VARCHAR(43),
    _stock_id                     INTEGER,
    _product_id                   INTEGER,
    _amount                       NUMERIC(18,6),
    _amount2                      NUMERIC(18,6),
    _unit_id                      INTEGER,
    _unit2                        VARCHAR(50),
    _name_product                 VARCHAR(500),
    _unit_name                    VARCHAR(65),
    _spect_id                     INTEGER,
    _spec_main_id                 INTEGER,
    _spect_name                   VARCHAR(500),
    _cost_id                      INTEGER,
    _kdv_price                    NUMERIC(18,6),
    _purchase_net_system          NUMERIC(18,6),
    _purchase_net_system_money    VARCHAR(43),
    _purchase_extra_cost_system   NUMERIC(18,6),
    _purchase_net_system_total    NUMERIC(18,6),
    _purchase_net                 NUMERIC(18,6),
    _purchase_net_money           VARCHAR(43),
    _purchase_net_2               NUMERIC(18,6),
    _purchase_extra_cost_system_2 NUMERIC(18,6),
    _purchase_net_money_2         VARCHAR(43),
    _purchase_extra_cost          NUMERIC(18,6),
    _purchase_net_total           NUMERIC(18,6),
    _product_name2                VARCHAR(500),
    _fire_amount                  NUMERIC(18,6),
    _is_free_amount               BOOLEAN,
    _wrk_row_id                   VARCHAR(50),
    _wrk_row_relation_id          VARCHAR(50),
    _width                        NUMERIC(18,6),
    _height                       NUMERIC(18,6),
    _length                       NUMERIC(18,6),
    _specific_weight              NUMERIC(18,6),
    _weight                       NUMERIC(18,6),
    _work_id                      INTEGER,
    _work_head                    VARCHAR(50)
) RETURNS INTEGER AS $$
DECLARE
    _new_id INTEGER;
BEGIN
    INSERT INTO production_order_results_row (
        tree_type, type, pr_order_id, barcode, stock_id, product_id,
        amount, amount2, unit_id, unit2, name_product, unit_name,
        spect_id, spec_main_id, spect_name, cost_id, kdv_price,
        purchase_net_system, purchase_net_system_money, purchase_extra_cost_system,
        purchase_net_system_total, purchase_net, purchase_net_money,
        purchase_net_2, purchase_extra_cost_system_2, purchase_net_money_2,
        purchase_extra_cost, purchase_net_total, product_name2, fire_amount,
        is_free_amount, wrk_row_id, wrk_row_relation_id,
        width, height, length, specific_weight, weight, work_id, work_head
    ) VALUES (
        _tree_type, _type, _pr_order_id, _barcode, _stock_id, _product_id,
        _amount, _amount2, _unit_id, _unit2, _name_product, _unit_name,
        _spect_id, _spec_main_id, _spect_name, _cost_id, _kdv_price,
        _purchase_net_system, _purchase_net_system_money, _purchase_extra_cost_system,
        _purchase_net_system_total, _purchase_net, _purchase_net_money,
        _purchase_net_2, _purchase_extra_cost_system_2, _purchase_net_money_2,
        _purchase_extra_cost, _purchase_net_total, _product_name2, _fire_amount,
        _is_free_amount, _wrk_row_id, _wrk_row_relation_id,
        _width, _height, _length, _specific_weight, _weight, _work_id, _work_head
    ) RETURNING pr_order_row_id INTO _new_id;
    RETURN _new_id;
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- FUNCTION: add_production_order_results_row_o
-- Üretim sonuç satırı ekler (operasyon tipi - lot/seri no ile)
-- ================================================
CREATE OR REPLACE FUNCTION add_production_order_results_row_o(
    _type                         INTEGER,
    _pr_order_id                  INTEGER,
    _barcode                      VARCHAR(43),
    _stock_id                     INTEGER,
    _product_id                   INTEGER,
    _lot_no                       VARCHAR(100),
    _amount                       NUMERIC(18,6),
    _amount2                      NUMERIC(18,6),
    _unit_id                      INTEGER,
    _unit2                        VARCHAR(50),
    _serial_no                    VARCHAR(50),
    _name_product                 VARCHAR(500),
    _unit_name                    VARCHAR(65),
    _is_sevkiyat                  BOOLEAN,
    _spect_id                     INTEGER,
    _spec_main_id                 INTEGER,
    _spect_name                   VARCHAR(500),
    _cost_id                      INTEGER,
    _kdv_price                    NUMERIC(18,6),
    _purchase_net_system          NUMERIC(18,6),
    _purchase_net_system_money    VARCHAR(43),
    _purchase_extra_cost_system   NUMERIC(18,6),
    _purchase_net_system_total    NUMERIC(18,6),
    _purchase_net                 NUMERIC(18,6),
    _purchase_net_money           VARCHAR(43),
    _purchase_net_2               NUMERIC(18,6),
    _purchase_extra_cost_system_2 NUMERIC(18,6),
    _purchase_net_money_2         VARCHAR(43),
    _purchase_extra_cost          NUMERIC(18,6),
    _purchase_net_total           NUMERIC(18,6),
    _product_name2                VARCHAR(500),
    _wrk_row_id                   VARCHAR(50),
    _wrk_row_relation_id          VARCHAR(50),
    _line_number                  INTEGER,
    _is_manual_cost               BOOLEAN,
    _expiration_date              TIMESTAMP WITHOUT TIME ZONE,
    _width                        NUMERIC(18,6),
    _height                       NUMERIC(18,6),
    _length                       NUMERIC(18,6)
) RETURNS INTEGER AS $$
DECLARE
    _new_id INTEGER;
BEGIN
    INSERT INTO production_order_results_row (
        type, pr_order_id, barcode, stock_id, product_id, lot_no,
        amount, amount2, unit_id, unit2, serial_no, name_product, unit_name,
        is_sevkiyat, spect_id, spec_main_id, spect_name, cost_id, kdv_price,
        purchase_net_system, purchase_net_system_money, purchase_extra_cost_system,
        purchase_net_system_total, purchase_net, purchase_net_money,
        purchase_net_2, purchase_extra_cost_system_2, purchase_net_money_2,
        purchase_extra_cost, purchase_net_total, product_name2,
        wrk_row_id, wrk_row_relation_id, line_number, is_manual_cost,
        expiration_date, width, height, length
    ) VALUES (
        _type, _pr_order_id, _barcode, _stock_id, _product_id, _lot_no,
        _amount, _amount2, _unit_id, _unit2, _serial_no, _name_product, _unit_name,
        _is_sevkiyat, _spect_id, _spec_main_id, _spect_name, _cost_id, _kdv_price,
        _purchase_net_system, _purchase_net_system_money, _purchase_extra_cost_system,
        _purchase_net_system_total, _purchase_net, _purchase_net_money,
        _purchase_net_2, _purchase_extra_cost_system_2, _purchase_net_money_2,
        _purchase_extra_cost, _purchase_net_total, _product_name2,
        _wrk_row_id, _wrk_row_relation_id, _line_number, _is_manual_cost,
        _expiration_date, _width, _height, _length
    ) RETURNING pr_order_row_id INTO _new_id;
    RETURN _new_id;
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- FUNCTION: add_production_order_results_row_s
-- Üretim sonuç satırı ekler (spect/varyant kaynaklı)
-- ================================================
CREATE OR REPLACE FUNCTION add_production_order_results_row_s(
    _tree_type                    VARCHAR(43),
    _type                         INTEGER,
    _pr_order_id                  INTEGER,
    _barcode                      VARCHAR(43),
    _stock_id                     INTEGER,
    _product_id                   INTEGER,
    _lot_no                       VARCHAR(100),
    _amount                       NUMERIC(18,6),
    _amount2                      NUMERIC(18,6),
    _unit_id                      INTEGER,
    _unit2                        VARCHAR(50),
    _serial_no                    VARCHAR(50),
    _name_product                 VARCHAR(500),
    _unit_name                    VARCHAR(65),
    _is_sevkiyat                  BOOLEAN,
    _spect_id                     INTEGER,
    _spec_main_id                 INTEGER,
    _spect_name                   VARCHAR(500),
    _cost_id                      INTEGER,
    _kdv_price                    NUMERIC(18,6),
    _purchase_net_system          NUMERIC(18,6),
    _purchase_net_system_money    VARCHAR(43),
    _purchase_extra_cost_system   NUMERIC(18,6),
    _purchase_net_system_total    NUMERIC(18,6),
    _purchase_net                 NUMERIC(18,6),
    _purchase_net_money           VARCHAR(43),
    _purchase_net_2               NUMERIC(18,6),
    _purchase_extra_cost_system_2 NUMERIC(18,6),
    _purchase_net_money_2         VARCHAR(43),
    _purchase_extra_cost          NUMERIC(18,6),
    _purchase_net_total           NUMERIC(18,6),
    _product_name2                VARCHAR(500),
    _is_from_spect                BOOLEAN,
    _is_free_amount               BOOLEAN,
    _wrk_row_id                   VARCHAR(50),
    _wrk_row_relation_id          VARCHAR(50),
    _line_number                  INTEGER,
    _is_manual_cost               BOOLEAN,
    _expiration_date              TIMESTAMP WITHOUT TIME ZONE,
    _width                        NUMERIC(18,6),
    _height                       NUMERIC(18,6),
    _length                       NUMERIC(18,6)
) RETURNS INTEGER AS $$
DECLARE
    _new_id INTEGER;
BEGIN
    INSERT INTO production_order_results_row (
        tree_type, type, pr_order_id, barcode, stock_id, product_id, lot_no,
        amount, amount2, unit_id, unit2, serial_no, name_product, unit_name,
        is_sevkiyat, spect_id, spec_main_id, spect_name, cost_id, kdv_price,
        purchase_net_system, purchase_net_system_money, purchase_extra_cost_system,
        purchase_net_system_total, purchase_net, purchase_net_money,
        purchase_net_2, purchase_extra_cost_system_2, purchase_net_money_2,
        purchase_extra_cost, purchase_net_total, product_name2,
        is_from_spect, is_free_amount, wrk_row_id, wrk_row_relation_id,
        line_number, is_manual_cost, expiration_date, width, height, length
    ) VALUES (
        _tree_type, _type, _pr_order_id, _barcode, _stock_id, _product_id, _lot_no,
        _amount, _amount2, _unit_id, _unit2, _serial_no, _name_product, _unit_name,
        _is_sevkiyat, _spect_id, _spec_main_id, _spect_name, _cost_id, _kdv_price,
        _purchase_net_system, _purchase_net_system_money, _purchase_extra_cost_system,
        _purchase_net_system_total, _purchase_net, _purchase_net_money,
        _purchase_net_2, _purchase_extra_cost_system_2, _purchase_net_money_2,
        _purchase_extra_cost, _purchase_net_total, _product_name2,
        _is_from_spect, _is_free_amount, _wrk_row_id, _wrk_row_relation_id,
        _line_number, _is_manual_cost, _expiration_date, _width, _height, _length
    ) RETURNING pr_order_row_id INTO _new_id;
    RETURN _new_id;
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- FUNCTION: add_production_orders_row
-- Üretim emri - sipariş satırı ilişkisi ekler
-- ================================================
CREATE OR REPLACE FUNCTION add_production_orders_row(
    _production_order_id INTEGER,
    _order_id            INTEGER,
    _order_row_id        INTEGER,
    _type                INTEGER
) RETURNS INTEGER AS $$
DECLARE
    _new_id INTEGER;
BEGIN
    INSERT INTO production_orders_row (
        production_order_id, order_id, order_row_id, type
    ) VALUES (
        _production_order_id, _order_id, _order_row_id, _type
    ) RETURNING production_order_row_id INTO _new_id;
    RETURN _new_id;
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- FUNCTION: add_production_orders_stocks
-- Üretim emri hammadde/stok kalemi ekler
-- ================================================
CREATE OR REPLACE FUNCTION add_production_orders_stocks(
    _p_order_id        INTEGER,
    _product_id        INTEGER,
    _stock_id          INTEGER,
    _spect_main_id     INTEGER,
    _amount            NUMERIC(18,6),
    _type              INTEGER,
    _product_unit_id   INTEGER,
    _record_emp        INTEGER,
    _record_date       TIMESTAMP WITHOUT TIME ZONE,
    _record_ip         VARCHAR(50),
    _is_phantom        BOOLEAN,
    _is_sevk           BOOLEAN,
    _is_property       INTEGER,
    _is_free_amount    BOOLEAN,
    _fire_amount       NUMERIC(18,6),
    _fire_rate         NUMERIC(18,6),
    _spect_main_row_id INTEGER,
    _is_flag           BOOLEAN,
    _wrk_row_id        VARCHAR(40),
    _line_number       INTEGER,
    _prtotm_detail     VARCHAR(150) DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    _new_id INTEGER;
BEGIN
    INSERT INTO production_orders_stocks (
        p_order_id, product_id, stock_id, spect_main_id, amount,
        type, product_unit_id, record_emp, record_date, record_ip,
        is_phantom, is_sevk, is_property, is_free_amount,
        fire_amount, fire_rate, spect_main_row_id, is_flag,
        wrk_row_id, line_number, prtotm_detail
    ) VALUES (
        _p_order_id, _product_id, _stock_id, _spect_main_id, _amount,
        _type, _product_unit_id, _record_emp, _record_date, _record_ip,
        _is_phantom, _is_sevk, _is_property, _is_free_amount,
        _fire_amount, _fire_rate, _spect_main_row_id, _is_flag,
        _wrk_row_id, _line_number, _prtotm_detail
    ) RETURNING por_stock_id INTO _new_id;
    RETURN _new_id;
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- Açıklamalar / Comments
-- ================================================
COMMENT ON FUNCTION add_production_operation IS 'Üretim operasyonu ekler, p_operation_id döndürür';
COMMENT ON FUNCTION add_production_order IS 'Üretim emri ekler, p_order_id döndürür';
COMMENT ON FUNCTION add_production_order_cash IS 'Üretim emri nakit periyodu ekler, cash_id döndürür';
COMMENT ON FUNCTION add_production_order_result IS 'Üretim emri sonucu ekler, pr_order_id döndürür';
COMMENT ON FUNCTION add_production_order_results_row IS 'Üretim sonuç satırı ekler (maliyet/ağaç tipi), pr_order_row_id döndürür';
COMMENT ON FUNCTION add_production_order_results_row_o IS 'Üretim sonuç satırı ekler (lot/seri no ile), pr_order_row_id döndürür';
COMMENT ON FUNCTION add_production_order_results_row_s IS 'Üretim sonuç satırı ekler (spect kaynaklı), pr_order_row_id döndürür';
COMMENT ON FUNCTION add_production_orders_row IS 'Üretim emri-sipariş satır ilişkisi ekler, production_order_row_id döndürür';
COMMENT ON FUNCTION add_production_orders_stocks IS 'Üretim emri hammadde kalemi ekler, por_stock_id döndürür';
