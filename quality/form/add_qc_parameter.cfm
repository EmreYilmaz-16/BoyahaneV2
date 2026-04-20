<cfprocessingdirective pageEncoding="utf-8">

<cfparam name="url.qc_param_id" default="0">
<cfset editMode    = isNumeric(url.qc_param_id) AND val(url.qc_param_id) gt 0>
<cfset currentId   = editMode ? val(url.qc_param_id) : 0>

<cfif editMode>
    <cfquery name="getRec" datasource="boyahane">
        SELECT * FROM qc_parameters
        WHERE qc_param_id = <cfqueryparam value="#currentId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif NOT getRec.recordCount>
        <cflocation url="index.cfm?fuseaction=quality.list_qc_parameters" addtoken="false">
    </cfif>
<cfelse>
    <cfset getRec = {
        qc_param_id : 0, param_code : "", param_name : "",
        param_type  : 1, unit_name  : "", min_value  : "",
        max_value   : "", is_active : true, sort_order : 0, detail : ""
    }>
</cfif>

<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-sliders-h"></i></div>
        <div class="page-header-title">
            <h1>#editMode ? 'Parametre Düzenle' : 'Yeni KK Parametresi'#</h1>
            <p>Kalite kontrol ölçüm/test parametresi tanımla</p>
        </div>
    </div>
    <a href="index.cfm?fuseaction=quality.list_qc_parameters" class="btn btn-outline-secondary">
        <i class="fas fa-arrow-left me-1"></i>Listeye Dön
    </a>
</div>

<div class="px-3">
    <div class="card">
        <div class="card-body">
            <form id="paramForm">
                <input type="hidden" id="qc_param_id" name="qc_param_id" value="#currentId#">

                <div class="row g-3">
                    <div class="col-md-3">
                        <label class="form-label">Parametre Kodu <span class="text-danger">*</span></label>
                        <input type="text" class="form-control" id="param_code" name="param_code"
                               value="#htmlEditFormat(getRec.param_code)#" maxlength="50" required>
                    </div>
                    <div class="col-md-5">
                        <label class="form-label">Parametre Adı <span class="text-danger">*</span></label>
                        <input type="text" class="form-control" id="param_name" name="param_name"
                               value="#htmlEditFormat(getRec.param_name)#" maxlength="200" required>
                    </div>
                    <div class="col-md-2">
                        <label class="form-label">Ölçüm Tipi <span class="text-danger">*</span></label>
                        <select class="form-select" id="param_type" name="param_type" onchange="toggleNumericFields()">
                            <option value="1" #val(getRec.param_type) eq 1 ? 'selected' : ''#>Sayısal</option>
                            <option value="2" #val(getRec.param_type) eq 2 ? 'selected' : ''#>Geçti/Kaldı</option>
                            <option value="3" #val(getRec.param_type) eq 3 ? 'selected' : ''#>Metin</option>
                        </select>
                    </div>
                    <div class="col-md-2">
                        <label class="form-label">Birim</label>
                        <input type="text" class="form-control" id="unit_name" name="unit_name"
                               value="#htmlEditFormat(getRec.unit_name)#" maxlength="50">
                    </div>

                    <div id="numericFields" class="col-12">
                        <div class="row g-3">
                            <div class="col-md-2">
                                <label class="form-label">Min Değer</label>
                                <input type="number" step="any" class="form-control" id="min_value" name="min_value"
                                       value="#isNumeric(getRec.min_value) ? getRec.min_value : ''#">
                            </div>
                            <div class="col-md-2">
                                <label class="form-label">Max Değer</label>
                                <input type="number" step="any" class="form-control" id="max_value" name="max_value"
                                       value="#isNumeric(getRec.max_value) ? getRec.max_value : ''#">
                            </div>
                        </div>
                    </div>

                    <div class="col-md-2">
                        <label class="form-label">Sıra No</label>
                        <input type="number" class="form-control" id="sort_order" name="sort_order"
                               value="#val(getRec.sort_order)#" min="0">
                    </div>
                    <div class="col-md-2">
                        <label class="form-label">Durum</label>
                        <select class="form-select" id="is_active" name="is_active">
                            <option value="true"  #(isBoolean(getRec.is_active) AND getRec.is_active) ? 'selected' : ''#>Aktif</option>
                            <option value="false" #(isBoolean(getRec.is_active) AND NOT getRec.is_active) ? 'selected' : ''#>Pasif</option>
                        </select>
                    </div>
                    <div class="col-12">
                        <label class="form-label">Açıklama</label>
                        <textarea class="form-control" id="detail" name="detail" rows="2"
                                  maxlength="1000">#htmlEditFormat(getRec.detail)#</textarea>
                    </div>
                </div>

                <div class="mt-4 d-flex gap-2">
                    <button type="submit" class="btn btn-primary">
                        <i class="fas fa-save me-1"></i>#editMode ? 'Güncelle' : 'Kaydet'#
                    </button>
                    <a href="index.cfm?fuseaction=quality.list_qc_parameters" class="btn btn-secondary">İptal</a>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
function toggleNumericFields() {
    var t = document.getElementById('param_type').value;
    document.getElementById('numericFields').style.display = (t === '1') ? '' : 'none';
}
toggleNumericFields();

document.getElementById('paramForm').addEventListener('submit', function(e){
    e.preventDefault();
    var fd = new FormData(this);
    var data = {};
    fd.forEach(function(v,k){ data[k] = v; });

    $.post('index.cfm?fuseaction=quality.save_qc_parameter', data, function(res){
        var r = typeof res === 'string' ? JSON.parse(res) : res;
        if (r.success) {
            var act = data.qc_param_id > 0 ? 'updated' : 'added';
            window.location.href = 'index.cfm?fuseaction=quality.list_qc_parameters&success=' + act;
        } else {
            alert('Hata: ' + (r.message || 'Kaydedilemedi'));
        }
    });
});
</script>
</cfoutput>
