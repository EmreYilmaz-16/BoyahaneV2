-- ================================================
-- SETUP_PROD_PAUSE_TYPE — Üretim Duruş Tipleri
-- SETUP_PROD_PAUSE     — Üretim Duruş Kayıtları
-- ================================================

-- ================================================
-- SETUP_PROD_PAUSE_TYPE
-- ================================================
CREATE TABLE setup_prod_pause_type (
    prod_pause_type_id   SERIAL PRIMARY KEY,
    prod_pause_type      VARCHAR(100),
    prod_pause_type_code VARCHAR(50),
    is_active            BOOLEAN DEFAULT true,
    prod_pause_cat_id    INTEGER,
    pause_detail         VARCHAR(200),
    file_name            VARCHAR(100),
    product_catid        INTEGER,
    record_date          TIMESTAMP WITHOUT TIME ZONE,
    record_emp           INTEGER,
    record_ip            VARCHAR(50),
    update_date          TIMESTAMP WITHOUT TIME ZONE,
    update_emp           INTEGER,
    update_ip            VARCHAR(50)
);

CREATE INDEX idx_pause_type_active ON setup_prod_pause_type(is_active);
CREATE INDEX idx_pause_type_cat    ON setup_prod_pause_type(prod_pause_cat_id);

COMMENT ON TABLE setup_prod_pause_type IS 'Üretim duruş tipleri (arıza, mola, bakım vs.)';

-- ================================================
-- SETUP_PROD_PAUSE
-- ================================================
CREATE TABLE setup_prod_pause (
    prod_pause_id         SERIAL PRIMARY KEY,
    prod_pause_type_id    INTEGER,
    prod_duration         INTEGER,           -- dakika
    prod_detail           VARCHAR(250),
    is_working_time       BOOLEAN DEFAULT false,
    pr_order_id           INTEGER,
    action_date           TIMESTAMP WITHOUT TIME ZONE,
    record_date           TIMESTAMP WITHOUT TIME ZONE,
    record_emp            INTEGER,
    record_ip             VARCHAR(50),
    update_date           TIMESTAMP WITHOUT TIME ZONE,
    update_emp            INTEGER,
    update_ip             VARCHAR(50),
    operation_id          INTEGER,
    employee_id           INTEGER,
    station_id            INTEGER,
    p_order_id            INTEGER,
    operation_result_id   INTEGER,
    duration_start_date   TIMESTAMP WITHOUT TIME ZONE,
    duration_finish_date  TIMESTAMP WITHOUT TIME ZONE,

    CONSTRAINT fk_prod_pause_type    FOREIGN KEY (prod_pause_type_id)  REFERENCES setup_prod_pause_type(prod_pause_type_id) ON DELETE SET NULL,
    CONSTRAINT fk_prod_pause_result  FOREIGN KEY (pr_order_id)         REFERENCES production_order_results(pr_order_id)     ON DELETE CASCADE,
    CONSTRAINT fk_prod_pause_order   FOREIGN KEY (p_order_id)          REFERENCES production_orders(p_order_id)             ON DELETE CASCADE,
    CONSTRAINT fk_prod_pause_op      FOREIGN KEY (operation_id)        REFERENCES production_operation(p_operation_id)      ON DELETE SET NULL,
    CONSTRAINT fk_prod_pause_station FOREIGN KEY (station_id)          REFERENCES workstations(station_id)                  ON DELETE SET NULL,
    CONSTRAINT fk_prod_pause_op_res  FOREIGN KEY (operation_result_id) REFERENCES production_operation_result(operation_result_id) ON DELETE SET NULL
);

CREATE INDEX idx_prod_pause_order     ON setup_prod_pause(p_order_id);
CREATE INDEX idx_prod_pause_pr_order  ON setup_prod_pause(pr_order_id);
CREATE INDEX idx_prod_pause_type      ON setup_prod_pause(prod_pause_type_id);
CREATE INDEX idx_prod_pause_station   ON setup_prod_pause(station_id);
CREATE INDEX idx_prod_pause_employee  ON setup_prod_pause(employee_id);
CREATE INDEX idx_prod_pause_action    ON setup_prod_pause(action_date);

COMMENT ON TABLE  setup_prod_pause IS 'Üretim sürecinde gerçekleşen duruşların kaydı';
COMMENT ON COLUMN setup_prod_pause.prod_duration    IS 'Duruş süresi (dakika)';
COMMENT ON COLUMN setup_prod_pause.is_working_time  IS 'Çalışma süresine sayılır mı?';
