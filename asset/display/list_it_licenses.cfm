<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getLicenses" datasource="boyahane">
    SELECT l.license_id,
           l.software_name,
           l.vendor_name,
           l.expiry_date,
           l.total_seat,
           l.used_seat,
           l.compliance_status,
           am.asset_name
    FROM it_software_licenses l
    LEFT JOIN asset_master am ON am.asset_id = l.asset_id
    ORDER BY l.license_id DESC
</cfquery>

<div class="container-fluid py-3">
    <h3>BT Lisans Yönetimi</h3>
    <div class="table-responsive">
        <table class="table table-sm table-striped">
            <thead>
                <tr>
                    <th>#</th>
                    <th>Yazılım</th>
                    <th>Varlık</th>
                    <th>Tedarikçi</th>
                    <th>Bitiş Tarihi</th>
                    <th>Kullanım</th>
                    <th>Uyumluluk</th>
                </tr>
            </thead>
            <tbody>
                <cfoutput query="getLicenses">
                    <tr>
                        <td>#license_id#</td>
                        <td>#encodeForHTML(software_name)#</td>
                        <td>#encodeForHTML(asset_name ?: "-")#</td>
                        <td>#encodeForHTML(vendor_name ?: "-")#</td>
                        <td>#isDate(expiry_date) ? dateFormat(expiry_date, "dd.mm.yyyy") : "-"#</td>
                        <td>#used_seat# / #total_seat#</td>
                        <td>#encodeForHTML(compliance_status)#</td>
                    </tr>
                </cfoutput>
            </tbody>
        </table>
    </div>
</div>
