<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cfif not structKeyExists(session, "authenticated") or not session.authenticated>
    <cfoutput>{"success":false,"message":"Yetkisiz erişim."}</cfoutput>
    <cfabort>
</cfif>

<cftry>
    <!--- Parametreleri al --->
    <cfset fisId            = isDefined("form.fis_id") and isNumeric(form.fis_id) ? val(form.fis_id) : 0>
    <cfset fisType          = isDefined("form.fis_type")    and isNumeric(form.fis_type)    ? val(form.fis_type)    : 1>
    <cfset fisNumber        = isDefined("form.fis_number")    ? trim(form.fis_number)    : "">
    <cfset fisDateStr       = isDefined("form.fis_date")      ? trim(form.fis_date)      : "">
    <cfset deliverDateStr   = isDefined("form.deliver_date")  ? trim(form.deliver_date)  : "">
    <cfset refNo            = isDefined("form.ref_no")        ? trim(form.ref_no)        : "">
    <cfset fisDetail        = isDefined("form.fis_detail")    ? trim(form.fis_detail)    : "">
    <cfset isProduction     = isDefined("form.is_production")    and val(form.is_production)    eq 1>
    <cfset isStockTransfer  = isDefined("form.is_stock_transfer") and val(form.is_stock_transfer) eq 1 ? 1 : 0>
    <cfset locationInId     = isDefined("form.location_in_id")  and isNumeric(form.location_in_id)  ? val(form.location_in_id)  : 0>
    <cfset locationOutId    = isDefined("form.location_out_id") and isNumeric(form.location_out_id) ? val(form.location_out_id) : 0>
    <cfset rowsJson         = isDefined("form.rows") ? form.rows : "[]">

    <!--- Güvenlik: fisNumber uzunluk sınırı --->
    <cfif len(fisNumber) gt 50><cfset fisNumber = left(fisNumber, 50)></cfif>
    <cfif len(refNo)     gt 2000><cfset refNo   = left(refNo, 2000)></cfif>

    <!--- Tarih doğrulama --->
    <cfif len(fisDateStr) and isDate(fisDateStr)>
        <cfset fisDateParam = parseDateTime(fisDateStr)>
        <cfset hasFisDate = true>
    <cfelse>
        <cfset fisDateParam = now()>
        <cfset hasFisDate = true>
    </cfif>

    <cfset hasDeliverDate = len(deliverDateStr) and isDate(deliverDateStr)>
    <cfif hasDeliverDate>
        <cfset deliverDateParam = parseDateTime(deliverDateStr)>
    </cfif>

    <!--- Satırları parse et --->
    <cfset rowsData = deserializeJSON(rowsJson)>

    <!--- Lokasyon → Departman ID lookup --->
    <cfset deptIn  = 0>
    <cfset deptOut = 0>
    <cfif locationInId gt 0>
        <cfquery name="getLocIn" datasource="boyahane">
            SELECT department_id FROM stocks_location
            WHERE id = <cfqueryparam value="#locationInId#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfif getLocIn.recordCount><cfset deptIn = val(getLocIn.department_id ?: 0)></cfif>
    </cfif>
    <cfif locationOutId gt 0>
        <cfquery name="getLocOut" datasource="boyahane">
            SELECT department_id FROM stocks_location
            WHERE id = <cfqueryparam value="#locationOutId#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfif getLocOut.recordCount><cfset deptOut = val(getLocOut.department_id ?: 0)></cfif>
    </cfif>

    <cfif fisId gt 0>
        <!--- ── GÜNCELLEME ── --->
        <cfquery datasource="boyahane">
            UPDATE stock_fis SET
                fis_type          = <cfqueryparam value="#fisType#"         cfsqltype="cf_sql_integer">,
                fis_number        = <cfqueryparam value="#fisNumber#"       cfsqltype="cf_sql_varchar" null="#not len(fisNumber)#">,
                fis_date          = <cfqueryparam value="#fisDateParam#"    cfsqltype="cf_sql_timestamp">,
                deliver_date      = <cfif hasDeliverDate><cfqueryparam value="#deliverDateParam#" cfsqltype="cf_sql_timestamp"><cfelse>NULL</cfif>,
                ref_no            = <cfqueryparam value="#refNo#"           cfsqltype="cf_sql_varchar" null="#not len(refNo)#">,
                fis_detail        = <cfqueryparam value="#fisDetail#"       cfsqltype="cf_sql_longvarchar" null="#not len(fisDetail)#">,
                is_production     = <cfqueryparam value="#isProduction#"    cfsqltype="cf_sql_bit">,
                is_stock_transfer = <cfqueryparam value="#isStockTransfer#" cfsqltype="cf_sql_integer">,
                location_in       = <cfqueryparam value="#locationInId#"    cfsqltype="cf_sql_integer" null="#locationInId eq 0#">,
                location_out      = <cfqueryparam value="#locationOutId#"   cfsqltype="cf_sql_integer" null="#locationOutId eq 0#">,
                update_date       = <cfqueryparam value="#now()#"           cfsqltype="cf_sql_timestamp">,
                update_emp        = <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer">,
                update_ip         = <cfqueryparam value="#cgi.remote_addr#" cfsqltype="cf_sql_varchar">
            WHERE fis_id = <cfqueryparam value="#fisId#" cfsqltype="cf_sql_integer">
        </cfquery>

        <!--- Mevcut satırları sil, yeniden ekle --->
        <cfquery datasource="boyahane">
            DELETE FROM stock_fis_row WHERE fis_id = <cfqueryparam value="#fisId#" cfsqltype="cf_sql_integer">
        </cfquery>
        <!--- Stok hareket satırlarını da sil --->
        <cfquery datasource="boyahane">
            DELETE FROM stocks_row WHERE upd_id = <cfqueryparam value="#fisId#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfset newFisId = fisId>
    <cfelse>
        <!--- ── YENİ FİŞ: Belge numarasını atomik olarak üret ── --->
        <!---
            UPDATE ... RETURNING PostgreSQL'de satır kilidiyle atomiktir.
            İki eşzamanlı istek asla aynı numarayı alamaz:
            ikinci istek birinci commit edilene kadar satır kilidinde bekler.
        --->
        <cfquery name="getAutoFisNo" datasource="boyahane">
            UPDATE general_papers
               SET stock_fis_number = COALESCE(stock_fis_number, 0) + 1
             WHERE zone_type = 0
             RETURNING stock_fis_no,
                       stock_fis_number,
                       COALESCE(stock_fis_no, 'SF') || '-' ||
                           LPAD(stock_fis_number::text, 5, '0') AS generated_no
        </cfquery>
        <cfif getAutoFisNo.recordCount>
            <cfset fisNumber = getAutoFisNo.generated_no>
        <cfelse>
            <!--- general_papers satırı yoksa oluştur ve tekrar dene --->
            <cfquery datasource="boyahane">
                INSERT INTO general_papers (zone_type, stock_fis_no, stock_fis_number)
                VALUES (0, 'SF', 1)
                ON CONFLICT DO NOTHING
            </cfquery>
            <cfquery name="getAutoFisNo2" datasource="boyahane">
                UPDATE general_papers
                   SET stock_fis_number = COALESCE(stock_fis_number, 0) + 1
                 WHERE zone_type = 0
                 RETURNING COALESCE(stock_fis_no, 'SF') || '-' ||
                               LPAD(stock_fis_number::text, 5, '0') AS generated_no
            </cfquery>
            <cfif getAutoFisNo2.recordCount>
                <cfset fisNumber = getAutoFisNo2.generated_no>
            <cfelse>
                <cfset fisNumber = 'SF-' & dateFormat(now(),'yyyymmdd') & '-' & randRange(1000,9999)>
            </cfif>
        </cfif>

        <!--- ── YENİ FİŞ ── --->
        <cfquery datasource="boyahane">
            INSERT INTO stock_fis (
                fis_type, fis_number, fis_date, deliver_date,
                ref_no, fis_detail, is_production, is_stock_transfer,
                location_in, location_out,
                record_date, record_emp, record_ip
            ) VALUES (
                <cfqueryparam value="#fisType#"         cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#fisNumber#"       cfsqltype="cf_sql_varchar" null="#not len(fisNumber)#">,
                <cfqueryparam value="#fisDateParam#"    cfsqltype="cf_sql_timestamp">,
                <cfif hasDeliverDate><cfqueryparam value="#deliverDateParam#" cfsqltype="cf_sql_timestamp"><cfelse>NULL</cfif>,
                <cfqueryparam value="#refNo#"           cfsqltype="cf_sql_varchar" null="#not len(refNo)#">,
                <cfqueryparam value="#fisDetail#"       cfsqltype="cf_sql_longvarchar" null="#not len(fisDetail)#">,
                <cfqueryparam value="#isProduction#"    cfsqltype="cf_sql_bit">,
                <cfqueryparam value="#isStockTransfer#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#locationInId#"    cfsqltype="cf_sql_integer" null="#locationInId eq 0#">,
                <cfqueryparam value="#locationOutId#"   cfsqltype="cf_sql_integer" null="#locationOutId eq 0#">,
                <cfqueryparam value="#now()#"           cfsqltype="cf_sql_timestamp">,
                <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#cgi.remote_addr#" cfsqltype="cf_sql_varchar">
            )
        </cfquery>
        <cfquery name="getNewFisId" datasource="boyahane">
            SELECT lastval() AS fis_id
        </cfquery>
        <cfset newFisId = getNewFisId.fis_id>
    </cfif>

    <!--- ── Satırları Ekle ── --->
    <cfif isArray(rowsData) and arrayLen(rowsData)>
        <cfloop array="#rowsData#" item="row">
            <cfset rowStockId = isNumeric(row.stock_id ?: 0) ? val(row.stock_id) : 0>
            <cfset rowAmount  = isNumeric(row.amount   ?: 0) ? val(row.amount)   : 0>
            <cfset rowTotal   = isNumeric(row.total    ?: 0) ? val(row.total)    : 0>
            <cfset rowUnit    = left(row.unit   ?: "", 43)>
            <cfset rowLot     = left(row.lot_no ?: "", 100)>
            <cfset rowShelf   = isNumeric(row.shelf_number    ?: 0) ? val(row.shelf_number)    : 0>
            <cfset rowToShelf = isNumeric(row.to_shelf_number ?: 0) ? val(row.to_shelf_number) : 0>
            <cfset rowDetail  = left(row.detail_info_extra ?: "", 500)>

            <cfif rowStockId gt 0>
                <cfquery datasource="boyahane">
                    INSERT INTO stock_fis_row (
                        fis_id, stock_id, amount, unit, lot_no,
                        shelf_number, to_shelf_number, total, net_total,
                        detail_info_extra
                    ) VALUES (
                        <cfqueryparam value="#newFisId#"   cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#rowStockId#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#rowAmount#"  cfsqltype="cf_sql_double">,
                        <cfqueryparam value="#rowUnit#"    cfsqltype="cf_sql_varchar" null="#not len(rowUnit)#">,
                        <cfqueryparam value="#rowLot#"     cfsqltype="cf_sql_varchar" null="#not len(rowLot)#">,
                        <cfqueryparam value="#rowShelf#"   cfsqltype="cf_sql_integer" null="#rowShelf eq 0#">,
                        <cfqueryparam value="#rowToShelf#" cfsqltype="cf_sql_integer" null="#rowToShelf eq 0#">,
                        <cfqueryparam value="#rowTotal#"   cfsqltype="cf_sql_double">,
                        <cfqueryparam value="#rowTotal#"   cfsqltype="cf_sql_double">,
                        <cfqueryparam value="#rowDetail#"  cfsqltype="cf_sql_varchar" null="#not len(rowDetail)#">
                    )
                </cfquery>

                <!--- Stok'un product_id'sini al --->
                <cfquery name="getStockProd" datasource="boyahane">
                    SELECT product_id FROM stocks
                    WHERE stock_id = <cfqueryparam value="#rowStockId#" cfsqltype="cf_sql_integer">
                </cfquery>
                <cfset rowProductId = getStockProd.recordCount ? val(getStockProd.product_id ?: 0) : 0>

                <!--- STOCKS_ROW: fiş tipine göre stok hareketi --->
                <cfif fisType eq 1 or fisType eq 4>
                    <!--- Giriş / Sayım: bir satır, STOCK_IN --->
                    <cfquery datasource="boyahane">
                        INSERT INTO stocks_row (
                            stock_id, product_id, upd_id, process_type,
                            stock_in, stock_out, store, store_location,
                            process_date, lot_no, shelf_number, deliver_date
                        ) VALUES (
                            <cfqueryparam value="#rowStockId#"   cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#rowProductId#" cfsqltype="cf_sql_integer" null="#rowProductId eq 0#">,
                            <cfqueryparam value="#newFisId#"     cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#fisType#"      cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#rowAmount#"    cfsqltype="cf_sql_double">,
                            0,
                            <cfqueryparam value="#deptIn#"       cfsqltype="cf_sql_integer" null="#deptIn eq 0#">,
                            <cfqueryparam value="#locationInId#" cfsqltype="cf_sql_integer" null="#locationInId eq 0#">,
                            <cfqueryparam value="#fisDateParam#" cfsqltype="cf_sql_timestamp">,
                            <cfqueryparam value="#rowLot#"       cfsqltype="cf_sql_varchar"  null="#not len(rowLot)#">,
                            <cfqueryparam value="#rowShelf#"     cfsqltype="cf_sql_integer"  null="#rowShelf eq 0#">,
                            <cfif hasDeliverDate><cfqueryparam value="#deliverDateParam#" cfsqltype="cf_sql_timestamp"><cfelse>NULL</cfif>
                        )
                    </cfquery>
                <cfelseif fisType eq 2>
                    <!--- Çıkış: bir satır, STOCK_OUT --->
                    <cfquery datasource="boyahane">
                        INSERT INTO stocks_row (
                            stock_id, product_id, upd_id, process_type,
                            stock_in, stock_out, store, store_location,
                            process_date, lot_no, shelf_number, deliver_date
                        ) VALUES (
                            <cfqueryparam value="#rowStockId#"    cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#rowProductId#"  cfsqltype="cf_sql_integer" null="#rowProductId eq 0#">,
                            <cfqueryparam value="#newFisId#"      cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#fisType#"       cfsqltype="cf_sql_integer">,
                            0,
                            <cfqueryparam value="#rowAmount#"     cfsqltype="cf_sql_double">,
                            <cfqueryparam value="#deptOut#"       cfsqltype="cf_sql_integer" null="#deptOut eq 0#">,
                            <cfqueryparam value="#locationOutId#" cfsqltype="cf_sql_integer" null="#locationOutId eq 0#">,
                            <cfqueryparam value="#fisDateParam#"  cfsqltype="cf_sql_timestamp">,
                            <cfqueryparam value="#rowLot#"        cfsqltype="cf_sql_varchar"  null="#not len(rowLot)#">,
                            <cfqueryparam value="#rowToShelf#"    cfsqltype="cf_sql_integer"  null="#rowToShelf eq 0#">,
                            <cfif hasDeliverDate><cfqueryparam value="#deliverDateParam#" cfsqltype="cf_sql_timestamp"><cfelse>NULL</cfif>
                        )
                    </cfquery>
                <cfelseif fisType eq 3>
                    <!--- Transfer: çıkış satırı --->
                    <cfquery datasource="boyahane">
                        INSERT INTO stocks_row (
                            stock_id, product_id, upd_id, process_type,
                            stock_in, stock_out, store, store_location,
                            process_date, lot_no, shelf_number, deliver_date
                        ) VALUES (
                            <cfqueryparam value="#rowStockId#"    cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#rowProductId#"  cfsqltype="cf_sql_integer" null="#rowProductId eq 0#">,
                            <cfqueryparam value="#newFisId#"      cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#fisType#"       cfsqltype="cf_sql_integer">,
                            0,
                            <cfqueryparam value="#rowAmount#"     cfsqltype="cf_sql_double">,
                            <cfqueryparam value="#deptOut#"       cfsqltype="cf_sql_integer" null="#deptOut eq 0#">,
                            <cfqueryparam value="#locationOutId#" cfsqltype="cf_sql_integer" null="#locationOutId eq 0#">,
                            <cfqueryparam value="#fisDateParam#"  cfsqltype="cf_sql_timestamp">,
                            <cfqueryparam value="#rowLot#"        cfsqltype="cf_sql_varchar"  null="#not len(rowLot)#">,
                            <cfqueryparam value="#rowToShelf#"    cfsqltype="cf_sql_integer"  null="#rowToShelf eq 0#">,
                            <cfif hasDeliverDate><cfqueryparam value="#deliverDateParam#" cfsqltype="cf_sql_timestamp"><cfelse>NULL</cfif>
                        )
                    </cfquery>
                    <!--- Transfer: giriş satırı --->
                    <cfquery datasource="boyahane">
                        INSERT INTO stocks_row (
                            stock_id, product_id, upd_id, process_type,
                            stock_in, stock_out, store, store_location,
                            process_date, lot_no, shelf_number, deliver_date
                        ) VALUES (
                            <cfqueryparam value="#rowStockId#"   cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#rowProductId#" cfsqltype="cf_sql_integer" null="#rowProductId eq 0#">,
                            <cfqueryparam value="#newFisId#"     cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#fisType#"      cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#rowAmount#"    cfsqltype="cf_sql_double">,
                            0,
                            <cfqueryparam value="#deptIn#"       cfsqltype="cf_sql_integer" null="#deptIn eq 0#">,
                            <cfqueryparam value="#locationInId#" cfsqltype="cf_sql_integer" null="#locationInId eq 0#">,
                            <cfqueryparam value="#fisDateParam#" cfsqltype="cf_sql_timestamp">,
                            <cfqueryparam value="#rowLot#"       cfsqltype="cf_sql_varchar"  null="#not len(rowLot)#">,
                            <cfqueryparam value="#rowShelf#"     cfsqltype="cf_sql_integer"  null="#rowShelf eq 0#">,
                            <cfif hasDeliverDate><cfqueryparam value="#deliverDateParam#" cfsqltype="cf_sql_timestamp"><cfelse>NULL</cfif>
                        )
                    </cfquery>
                </cfif>
            </cfif>
        </cfloop>
    </cfif>

    <cfoutput>{"success":true,"fis_id":#newFisId#}</cfoutput>

    <cfcatch type="any">
        <cfoutput>{"success":false,"message":#serializeJSON(cfcatch.message)#}</cfoutput>
    </cfcatch>
</cftry>
