<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cftry>
    <cfset shipId = isDefined("url.ship_id") AND isNumeric(url.ship_id) ? val(url.ship_id) : 0>
    <cfif shipId lte 0>
        <cfoutput>{"success":false,"message":"ship_id gerekli"}</cfoutput>
        <cfabort>
    </cfif>

    <cfquery name="getShip" datasource="boyahane">
        SELECT s.ship_id, s.ship_number, s.ref_no, s.ship_detail, s.ship_status,
               s.hk_metre, s.hk_kg, s.hk_top_adedi, s.hk_h_gramaj, s.hk_gr_mtul,
               s.hk_ucretli, s.hk_ham_boyali, s.hk_parti_no,
               s.record_date, s.is_ship_iptal,
               COALESCE(c.nickname, c.fullname, '') AS company_name,
               c.company_id,
               COALESCE((
                   SELECT p.product_name || ' — ' || st.stock_code
                   FROM ship_row sr
                   LEFT JOIN stocks st ON sr.stock_id = st.stock_id
                   LEFT JOIN product p ON st.product_id = p.product_id
                   WHERE sr.ship_id = s.ship_id
                   ORDER BY sr.ship_row_id LIMIT 1
               ), '') AS urun_adi,
               COALESCE((
                   SELECT SUM(orw.quantity)
                   FROM orders o
                   JOIN order_row orw ON o.order_id = orw.order_id
                   WHERE o.ref_ship_id = s.ship_id
                     AND orw.product_id = (
                         SELECT sr2.product_id FROM ship_row sr2
                         WHERE sr2.ship_id = s.ship_id
                         ORDER BY sr2.ship_row_id LIMIT 1
                     )
               ), 0) AS parti_metre
        FROM ship s
        LEFT JOIN company c ON s.company_id = c.company_id
        WHERE s.ship_id = <cfqueryparam value="#shipId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfif NOT getShip.recordCount>
        <cfoutput>{"success":false,"message":"Kayıt bulunamadı"}</cfoutput>
        <cfabort>
    </cfif>

    <cfset d = {
        "ship_id":      val(getShip.ship_id),
        "ship_number":  getShip.ship_number  ?: "",
        "ref_no":       getShip.ref_no       ?: "",
        "ship_detail":  getShip.ship_detail  ?: "",
        "company_id":   val(getShip.company_id),
        "company_name": getShip.company_name ?: "",
        "urun_adi":     getShip.urun_adi     ?: "",
        "hk_metre":     isNumeric(getShip.hk_metre)     ? val(getShip.hk_metre)     : 0,
        "hk_kg":        isNumeric(getShip.hk_kg)        ? val(getShip.hk_kg)        : 0,
        "hk_top_adedi": isNumeric(getShip.hk_top_adedi) ? val(getShip.hk_top_adedi) : 0,
        "hk_h_gramaj":  isNumeric(getShip.hk_h_gramaj)  ? val(getShip.hk_h_gramaj)  : 0,
        "hk_gr_mtul":   isNumeric(getShip.hk_gr_mtul)   ? val(getShip.hk_gr_mtul)   : 0,
        "hk_ucretli":   (getShip.hk_ucretli   EQ true OR getShip.hk_ucretli   EQ "true" OR getShip.hk_ucretli   EQ "YES"),
        "hk_ham_boyali":(getShip.hk_ham_boyali EQ true OR getShip.hk_ham_boyali EQ "true" OR getShip.hk_ham_boyali EQ "YES"),
        "hk_parti_no":  getShip.hk_parti_no ?: "",
        "parti_metre":  isNumeric(getShip.parti_metre) ? val(getShip.parti_metre) : 0,
        "record_date":  isDate(getShip.record_date) ? dateFormat(getShip.record_date, "dd/mm/yyyy") : "",
        "is_ship_iptal":(getShip.is_ship_iptal EQ true OR getShip.is_ship_iptal EQ "true" OR getShip.is_ship_iptal EQ "YES")
    }>

    <cfoutput>{"success":true,"data":#serializeJSON(d)#}</cfoutput>

    <cfcatch type="any">
        <cfoutput>{"success":false,"message":#serializeJSON(cfcatch.message)#}</cfoutput>
    </cfcatch>
</cftry>
