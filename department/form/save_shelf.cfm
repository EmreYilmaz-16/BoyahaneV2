<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cfif not structKeyExists(session, "authenticated") or not session.authenticated>
    <cfoutput>{"success":false,"message":"Yetkisiz erişim."}</cfoutput>
    <cfabort>
</cfif>

<cftry>
    <cfset shelfId    = isDefined("form.shelf_id")    and isNumeric(form.shelf_id)    ? val(form.shelf_id)    : 0>
    <cfset locId      = isDefined("form.loc_id")      and isNumeric(form.loc_id)      ? val(form.loc_id)      : 0>
    <cfset shelfCode  = isDefined("form.shelf_code")  ? left(trim(form.shelf_code), 43) : "">
    <cfset placeStatus= isDefined("form.place_status") and isNumeric(form.place_status)? val(form.place_status): 1>
    <cfset shelfType  = isDefined("form.shelf_type")  and isNumeric(form.shelf_type)  ? val(form.shelf_type)  : 0>
    <cfset quantity   = isDefined("form.quantity")    and isNumeric(form.quantity)    ? val(form.quantity)    : 0>
    <cfset detail     = isDefined("form.detail")      ? left(trim(form.detail), 100) : "">
    <cfset startDate  = isDefined("form.start_date")  and len(trim(form.start_date))  ? trim(form.start_date)  : "">
    <cfset finishDate = isDefined("form.finish_date") and len(trim(form.finish_date)) ? trim(form.finish_date) : "">
    <cfset shelfW     = isDefined("form.width")    and isNumeric(form.width)    ? val(form.width)    : 0>
    <cfset shelfH     = isDefined("form.height")   and isNumeric(form.height)   ? val(form.height)   : 0>
    <cfset shelfD     = isDefined("form.depth")    and isNumeric(form.depth)    ? val(form.depth)    : 0>
    <cfset coordX     = isDefined("form.x_coordinate") ? left(trim(form.x_coordinate), 50) : "">
    <cfset coordY     = isDefined("form.y_coordinate") ? left(trim(form.y_coordinate), 50) : "">
    <cfset coordZ     = isDefined("form.z_coordinate") ? left(trim(form.z_coordinate), 50) : "">
    <cfset rowsJson   = isDefined("form.rows") ? form.rows : "[]">

    <cfif not len(shelfCode)>
        <cfoutput>{"success":false,"message":"Raf kodu zorunludur."}</cfoutput>
        <cfabort>
    </cfif>
    <cfif locId lte 0>
        <cfoutput>{"success":false,"message":"Lokasyon seçilmemiş."}</cfoutput>
        <cfabort>
    </cfif>

    <cfset parsedRows = deserializeJSON(rowsJson, false)>

    <cfif shelfId gt 0>
        <!--- RAF GÜNCELLE --->
        <cfquery datasource="boyahane">
            UPDATE product_place SET
                shelf_code    = <cfqueryparam value="#shelfCode#"   cfsqltype="cf_sql_varchar">,
                location_id   = <cfqueryparam value="#locId#"       cfsqltype="cf_sql_integer">,
                place_status  = <cfqueryparam value="#placeStatus#" cfsqltype="cf_sql_integer">,
                shelf_type    = <cfqueryparam value="#shelfType#"   cfsqltype="cf_sql_integer">,
                quantity      = <cfqueryparam value="#quantity#"    cfsqltype="cf_sql_integer">,
                detail        = <cfqueryparam value="#detail#"      cfsqltype="cf_sql_varchar" null="#not len(detail)#">,
                start_date    = <cfqueryparam value="#startDate#"   cfsqltype="cf_sql_timestamp" null="#not len(startDate)#">,
                finish_date   = <cfqueryparam value="#finishDate#"  cfsqltype="cf_sql_timestamp" null="#not len(finishDate)#">,
                width         = <cfqueryparam value="#shelfW#"      cfsqltype="cf_sql_numeric">,
                height        = <cfqueryparam value="#shelfH#"      cfsqltype="cf_sql_numeric">,
                depth         = <cfqueryparam value="#shelfD#"      cfsqltype="cf_sql_numeric">,
                x_coordinate  = <cfqueryparam value="#coordX#"      cfsqltype="cf_sql_varchar" null="#not len(coordX)#">,
                y_coordinate  = <cfqueryparam value="#coordY#"      cfsqltype="cf_sql_varchar" null="#not len(coordY)#">,
                z_coordinate  = <cfqueryparam value="#coordZ#"      cfsqltype="cf_sql_varchar" null="#not len(coordZ)#">,
                update_date   = <cfqueryparam value="#now()#"       cfsqltype="cf_sql_timestamp">,
                update_emp    = <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer">,
                update_emp_ip = <cfqueryparam value="#cgi.remote_addr#" cfsqltype="cf_sql_varchar">
            WHERE product_place_id = <cfqueryparam value="#shelfId#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfset savedShelfId = shelfId>
    <cfelse>
        <!--- RAF EKLE --->
        <cfquery name="insShelf" datasource="boyahane">
            INSERT INTO product_place (
                shelf_code, location_id, place_status, shelf_type, quantity, detail,
                start_date, finish_date, width, height, depth,
                x_coordinate, y_coordinate, z_coordinate,
                record_date, record_emp, record_emp_ip
            ) VALUES (
                <cfqueryparam value="#shelfCode#"   cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#locId#"       cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#placeStatus#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#shelfType#"   cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#quantity#"    cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#detail#"      cfsqltype="cf_sql_varchar" null="#not len(detail)#">,
                <cfqueryparam value="#startDate#"   cfsqltype="cf_sql_timestamp" null="#not len(startDate)#">,
                <cfqueryparam value="#finishDate#"  cfsqltype="cf_sql_timestamp" null="#not len(finishDate)#">,
                <cfqueryparam value="#shelfW#"      cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#shelfH#"      cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#shelfD#"      cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#coordX#"      cfsqltype="cf_sql_varchar" null="#not len(coordX)#">,
                <cfqueryparam value="#coordY#"      cfsqltype="cf_sql_varchar" null="#not len(coordY)#">,
                <cfqueryparam value="#coordZ#"      cfsqltype="cf_sql_varchar" null="#not len(coordZ)#">,
                <cfqueryparam value="#now()#"        cfsqltype="cf_sql_timestamp">,
                <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#cgi.remote_addr#" cfsqltype="cf_sql_varchar">
            ) RETURNING product_place_id
        </cfquery>
        <cfset savedShelfId = insShelf.product_place_id>
    </cfif>

    <!--- SATIR KAYDET: önce sil, sonra toplu ekle --->
    <cfquery datasource="boyahane">
        DELETE FROM product_place_rows
        WHERE product_place_id = <cfqueryparam value="#savedShelfId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfif isArray(parsedRows) and arrayLen(parsedRows) gt 0>
        <cfloop array="#parsedRows#" item="r">
            <cfset rProductId = isNumeric(r.product_id ?: "") ? val(r.product_id) : javaCast("null","")>
            <cfset rStockId   = isNumeric(r.stock_id   ?: "") ? val(r.stock_id)   : javaCast("null","")>
            <cfset rAmount    = isNumeric(r.amount      ?: "") ? val(r.amount)     : 0>
            <cfquery datasource="boyahane">
                INSERT INTO product_place_rows (product_place_id, product_id, stock_id, amount)
                VALUES (
                    <cfqueryparam value="#savedShelfId#" cfsqltype="cf_sql_integer">,
                    <cfif isNumeric(r.product_id ?: "")>
                        <cfqueryparam value="#val(r.product_id)#" cfsqltype="cf_sql_integer">
                    <cfelse>
                        NULL
                    </cfif>,
                    <cfif isNumeric(r.stock_id ?: "")>
                        <cfqueryparam value="#val(r.stock_id)#" cfsqltype="cf_sql_integer">
                    <cfelse>
                        NULL
                    </cfif>,
                    <cfqueryparam value="#rAmount#" cfsqltype="cf_sql_numeric">
                )
            </cfquery>
        </cfloop>
    </cfif>

    <cfoutput>{"success":true,"product_place_id":#savedShelfId#}</cfoutput>

    <cfcatch type="any">
        <cfoutput>{"success":false,"message":#serializeJSON(cfcatch.message)#}</cfoutput>
    </cfcatch>
</cftry>
