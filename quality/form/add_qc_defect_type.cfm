<cfprocessingdirective pageEncoding="utf-8">

<cfparam name="url.defect_type_id" default="0">
<cfset editMode  = isNumeric(url.defect_type_id) AND val(url.defect_type_id) gt 0>
<cfset currentId = editMode ? val(url.defect_type_id) : 0>

<cfif editMode>
    <cfquery name="getRec" datasource="boyahane">
        SELECT * FROM qc_defect_types
        WHERE defect_type_id = <cfqueryparam value="#currentId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif NOT getRec.recordCount>
        <cflocation url="index.cfm?fuseaction=quality.list_qc_defect_types" addtoken="false">
    </cfif>
<cfelse>
    <cfset getRec = { defect_type_id:0, defect_code:"", defect_name:"", severity:2, is_active:true, sort_order:0, detail:"" }>
</cfif>

<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-bug"></i></div>
        <div class="page-header-title">
            <h1>#editMode ? 'Hata Tipi Düzenle' : 'Yeni Hata Tipi'#</h1>
        </div>
    </div>
    <a href="index.cfm?fuseaction=quality.list_qc_defect_types" class="btn btn-outline-secondary">
        <i class="fas fa-arrow-left me-1"></i>Listeye Dön
    </a>
</div>

<div class="px-3">
    <div class="card">
        <div class="card-body">
            <form id="defectForm">
                <input type="hidden" name="defect_type_id" value="#currentId#">
                <div class="row g-3">
                    <div class="col-md-3">
                        <label class="form-label">Hata Kodu <span class="text-danger">*</span></label>
                        <input type="text" class="form-control" name="defect_code"
                               value="#htmlEditFormat(getRec.defect_code)#" maxlength="50" required>
                    </div>
                    <div class="col-md-5">
                        <label class="form-label">Hata Adı <span class="text-danger">*</span></label>
                        <input type="text" class="form-control" name="defect_name"
                               value="#htmlEditFormat(getRec.defect_name)#" maxlength="200" required>
                    </div>
                    <div class="col-md-2">
                        <label class="form-label">Ağırlık <span class="text-danger">*</span></label>
                        <select class="form-select" name="severity">
                            <option value="1" #val(getRec.severity) eq 1 ? 'selected' : ''#>Hafif</option>
                            <option value="2" #val(getRec.severity) eq 2 ? 'selected' : ''#>Orta</option>
                            <option value="3" #val(getRec.severity) eq 3 ? 'selected' : ''#>Ciddi</option>
                            <option value="4" #val(getRec.severity) eq 4 ? 'selected' : ''#>Kritik</option>
                        </select>
                    </div>
                    <div class="col-md-1">
                        <label class="form-label">Sıra</label>
                        <input type="number" class="form-control" name="sort_order"
                               value="#val(getRec.sort_order)#" min="0">
                    </div>
                    <div class="col-md-1">
                        <label class="form-label">Durum</label>
                        <select class="form-select" name="is_active">
                            <option value="true"  #(isBoolean(getRec.is_active) AND getRec.is_active) ? 'selected' : ''#>Aktif</option>
                            <option value="false" #(isBoolean(getRec.is_active) AND NOT getRec.is_active) ? 'selected' : ''#>Pasif</option>
                        </select>
                    </div>
                    <div class="col-12">
                        <label class="form-label">Açıklama</label>
                        <textarea class="form-control" name="detail" rows="2">#htmlEditFormat(getRec.detail)#</textarea>
                    </div>
                </div>
                <div class="mt-4 d-flex gap-2">
                    <button type="submit" class="btn btn-primary">
                        <i class="fas fa-save me-1"></i>#editMode ? 'Güncelle' : 'Kaydet'#
                    </button>
                    <a href="index.cfm?fuseaction=quality.list_qc_defect_types" class="btn btn-secondary">İptal</a>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
document.getElementById('defectForm').addEventListener('submit', function(e){
    e.preventDefault();
    var fd = new FormData(this), data = {};
    fd.forEach(function(v,k){ data[k] = v; });
    $.post('index.cfm?fuseaction=quality.save_qc_defect_type', data, function(res){
        var r = typeof res === 'string' ? JSON.parse(res) : res;
        if (r.success) {
            var act = data.defect_type_id > 0 ? 'updated' : 'added';
            window.location.href = 'index.cfm?fuseaction=quality.list_qc_defect_types&success=' + act;
        } else {
            alert('Hata: ' + (r.message || 'Kaydedilemedi'));
        }
    });
});
</script>
</cfoutput>
