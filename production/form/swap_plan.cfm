<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<!--- Planlı iki üretim emrinin makine ve zaman bilgilerini karşılıklı değiştirir. --->
<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.source_p_order_id" default="0">
    <cfparam name="form.target_p_order_id" default="0">

    <cfset sourceId = isNumeric(form.source_p_order_id) AND val(form.source_p_order_id) gt 0 ? val(form.source_p_order_id) : 0>
    <cfset targetId = isNumeric(form.target_p_order_id) AND val(form.target_p_order_id) gt 0 ? val(form.target_p_order_id) : 0>

    <cfif sourceId eq 0 OR targetId eq 0 OR sourceId eq targetId>
        <cfset response.message = "Yer değiştirme için iki farklı planlı emir seçin.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfquery name="qOrders" datasource="boyahane">
        SELECT p_order_id, station_id, start_date, finish_date, status
        FROM production_orders
        WHERE p_order_id IN (
            <cfqueryparam value="#sourceId#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#targetId#" cfsqltype="cf_sql_integer">
        )
          AND station_id IS NOT NULL
          AND start_date IS NOT NULL
          AND finish_date IS NOT NULL
          AND status IN (1, 2, 5)
    </cfquery>

    <cfif qOrders.recordCount neq 2>
        <cfset response.message = "Yer değiştirme sadece planlı emirler arasında yapılabilir.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfloop query="qOrders">
        <cfif val(qOrders.p_order_id) eq sourceId>
            <cfset sourceStation = qOrders.station_id>
            <cfset sourceStart = qOrders.start_date>
            <cfset sourceFinish = qOrders.finish_date>
        <cfelse>
            <cfset targetStation = qOrders.station_id>
            <cfset targetStart = qOrders.start_date>
            <cfset targetFinish = qOrders.finish_date>
        </cfif>
    </cfloop>

    <cftransaction>
        <cfquery datasource="boyahane">
            UPDATE production_orders
            SET station_id = <cfqueryparam value="#targetStation#" cfsqltype="cf_sql_integer">,
                start_date = <cfqueryparam value="#createODBCDateTime(targetStart)#" cfsqltype="cf_sql_timestamp">,
                finish_date = <cfqueryparam value="#createODBCDateTime(targetFinish)#" cfsqltype="cf_sql_timestamp">,
                update_date = CURRENT_TIMESTAMP
            WHERE p_order_id = <cfqueryparam value="#sourceId#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfquery datasource="boyahane">
            UPDATE production_orders
            SET station_id = <cfqueryparam value="#sourceStation#" cfsqltype="cf_sql_integer">,
                start_date = <cfqueryparam value="#createODBCDateTime(sourceStart)#" cfsqltype="cf_sql_timestamp">,
                finish_date = <cfqueryparam value="#createODBCDateTime(sourceFinish)#" cfsqltype="cf_sql_timestamp">,
                update_date = CURRENT_TIMESTAMP
            WHERE p_order_id = <cfqueryparam value="#targetId#" cfsqltype="cf_sql_integer">
        </cfquery>
    </cftransaction>

    <cfset response.success = true>
    <cfset response.message = "Emirlerin makine ve saatleri yer değiştirildi.">

<cfcatch type="any">
    <cfset response.message = "Sunucu hatası: " & htmlEditFormat(cfcatch.message)>
</cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
