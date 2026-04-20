<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getMaintenances" datasource="boyahane">
    SELECT m.maintenance_id,
           m.asset_id,
           am.asset_name,
           m.maintenance_type,
           m.planned_date,
           m.start_date,
           m.end_date,
           m.total_cost,
           m.maintenance_status
    FROM asset_maintenance m
    INNER JOIN asset_master am ON am.asset_id = m.asset_id
    ORDER BY m.maintenance_id DESC
</cfquery>

<div class="container-fluid py-3">
    <h3>Varlık Bakım Yönetimi</h3>
    <p class="text-muted">Fiziki varlıklar dahil tüm varlıkların bakım kayıtları.</p>

    <div class="table-responsive">
        <table class="table table-striped table-sm">
            <thead>
                <tr>
                    <th>#</th>
                    <th>Varlık</th>
                    <th>Tip</th>
                    <th>Plan</th>
                    <th>Başlangıç</th>
                    <th>Bitiş</th>
                    <th>Durum</th>
                    <th class="text-end">Toplam Maliyet</th>
                </tr>
            </thead>
            <tbody>
                <cfoutput query="getMaintenances">
                    <tr>
                        <td>#maintenance_id#</td>
                        <td>#encodeForHTML(asset_name)#</td>
                        <td>#encodeForHTML(maintenance_type)#</td>
                        <td>#isDate(planned_date) ? dateFormat(planned_date, "dd.mm.yyyy") : "-"#</td>
                        <td>#isDate(start_date) ? dateFormat(start_date, "dd.mm.yyyy") : "-"#</td>
                        <td>#isDate(end_date) ? dateFormat(end_date, "dd.mm.yyyy") : "-"#</td>
                        <td>#encodeForHTML(maintenance_status)#</td>
                        <td class="text-end">#numberFormat(total_cost ?: 0, "9,999,999.99")#</td>
                    </tr>
                </cfoutput>
            </tbody>
        </table>
    </div>
</div>
