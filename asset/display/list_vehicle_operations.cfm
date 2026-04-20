<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getFuel" datasource="boyahane">
    SELECT f.fuel_log_id,
           f.asset_id,
           am.asset_name,
           f.fuel_date,
           f.odometer_km,
           f.liters,
           f.amount
    FROM vehicle_fuel_logs f
    INNER JOIN asset_master am ON am.asset_id = f.asset_id
    ORDER BY f.fuel_log_id DESC
    LIMIT 100
</cfquery>

<cfquery name="getService" datasource="boyahane">
    SELECT s.service_id,
           s.asset_id,
           am.asset_name,
           s.service_type,
           s.service_date,
           s.total_cost
    FROM vehicle_service_logs s
    INNER JOIN asset_master am ON am.asset_id = s.asset_id
    ORDER BY s.service_id DESC
    LIMIT 100
</cfquery>

<div class="container-fluid py-3">
    <h3>Araç Operasyonları</h3>

    <h5 class="mt-4">Yakıt Kayıtları</h5>
    <div class="table-responsive mb-4">
        <table class="table table-sm table-striped">
            <thead><tr><th>#</th><th>Araç</th><th>Tarih</th><th>KM</th><th>Litre</th><th>Tutar</th></tr></thead>
            <tbody>
                <cfoutput query="getFuel">
                    <tr>
                        <td>#fuel_log_id#</td>
                        <td>#encodeForHTML(asset_name)#</td>
                        <td>#dateFormat(fuel_date,"dd.mm.yyyy")#</td>
                        <td>#numberFormat(odometer_km ?: 0, "9,999,999.9")#</td>
                        <td>#numberFormat(liters ?: 0, "9,999,999.999")#</td>
                        <td>#numberFormat(amount ?: 0, "9,999,999.99")#</td>
                    </tr>
                </cfoutput>
            </tbody>
        </table>
    </div>

    <h5>Servis Kayıtları</h5>
    <div class="table-responsive">
        <table class="table table-sm table-striped">
            <thead><tr><th>#</th><th>Araç</th><th>Tip</th><th>Tarih</th><th>Tutar</th></tr></thead>
            <tbody>
                <cfoutput query="getService">
                    <tr>
                        <td>#service_id#</td>
                        <td>#encodeForHTML(asset_name)#</td>
                        <td>#encodeForHTML(service_type)#</td>
                        <td>#dateFormat(service_date,"dd.mm.yyyy")#</td>
                        <td>#numberFormat(total_cost ?: 0, "9,999,999.99")#</td>
                    </tr>
                </cfoutput>
            </tbody>
        </table>
    </div>
</div>
