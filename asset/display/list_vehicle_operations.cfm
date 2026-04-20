<cfprocessingdirective pageEncoding="utf-8">

<!--- ================================================ --->
<!--- ARAÇ YÖNETİMİ – Envanter + Operasyon Sayfası    --->
<!--- ================================================ --->

<!--- Araç Envanteri (plaka, şasi, tarihler) --->
<cfquery name="getVehicleEnv" datasource="boyahane">
    SELECT
        am.asset_id, am.asset_name, am.brand, am.model,
        am.purchase_date, am.acquisition_cost, am.asset_status,
        COALESCE(vd.plate_no,       '')   AS plate_no,
        COALESCE(vd.chassis_no,     '')   AS chassis_no,
        COALESCE(vd.engine_no,      '')   AS engine_no,
        vd.model_year,
        COALESCE(vd.fuel_type,      '')   AS fuel_type,
        COALESCE(vd.current_km,     0)    AS current_km,
        vd.traffic_insurance_end,
        vd.casco_end,
        vd.mtv_due_date,
        vd.inspection_due_date,
        vd.emission_due_date,
        vd.lease_start_date,
        vd.lease_end_date
    FROM asset_master am
    LEFT JOIN vehicle_details vd ON vd.asset_id = am.asset_id
    WHERE am.asset_type = 'VEHICLE'
    ORDER BY am.asset_name
</cfquery>

<!--- Kaza / Hasar kayıtları --->
<cfquery name="getAccidents" datasource="boyahane">
    SELECT
        a.accident_id, a.asset_id, am.asset_name,
        COALESCE(vd.plate_no,'') AS plate_no,
        a.accident_date, a.damage_description,
        COALESCE(a.estimated_cost,0) AS estimated_cost,
        COALESCE(a.actual_cost,0)    AS actual_cost,
        COALESCE(a.insurance_claim_no,'') AS insurance_claim_no,
        COALESCE(a.process_status,'OPEN') AS process_status
    FROM vehicle_accidents a
    INNER JOIN asset_master am ON am.asset_id = a.asset_id
    LEFT  JOIN vehicle_details vd ON vd.asset_id = a.asset_id
    ORDER BY a.accident_id DESC
    LIMIT 300
</cfquery>

<!--- Lastik kayıtları --->
<cfquery name="getTireLogs" datasource="boyahane">
    SELECT
        t.tire_log_id, t.asset_id, am.asset_name,
        COALESCE(vd.plate_no,'') AS plate_no,
        t.log_date,
        COALESCE(t.log_type,'OTHER')     AS log_type,
        COALESCE(t.odometer_km,0)        AS odometer_km,
        COALESCE(t.tire_position,'')     AS tire_position,
        COALESCE(t.tire_brand,'')        AS tire_brand,
        COALESCE(t.tire_size,'')         AS tire_size,
        COALESCE(t.cost,0)               AS cost,
        COALESCE(t.note,'')              AS note
    FROM vehicle_tire_logs t
    INNER JOIN asset_master am ON am.asset_id = t.asset_id
    LEFT  JOIN vehicle_details vd ON vd.asset_id = t.asset_id
    ORDER BY t.tire_log_id DESC
    LIMIT 300
</cfquery>

<cfquery name="getFuel" datasource="boyahane">
    SELECT f.fuel_log_id, f.asset_id, am.asset_name,
           COALESCE(vd.plate_no,'') AS plate_no,
           f.fuel_date,
           f.odometer_km, f.liters, f.amount,
           COALESCE(f.station_name,'') AS station_name,
           COALESCE(f.invoice_no,'') AS invoice_no
    FROM vehicle_fuel_logs f
    INNER JOIN asset_master am ON am.asset_id = f.asset_id
    LEFT  JOIN vehicle_details vd ON vd.asset_id = f.asset_id
    ORDER BY f.fuel_log_id DESC
    LIMIT 300
</cfquery>

<cfquery name="getService" datasource="boyahane">
    SELECT s.service_id, s.asset_id, am.asset_name,
           COALESCE(vd.plate_no,'') AS plate_no,
           s.service_type, s.service_date,
           s.odometer_km, s.labor_cost, s.material_cost, s.total_cost,
           s.next_service_date,
           COALESCE(s.note,'') AS note
    FROM vehicle_service_logs s
    INNER JOIN asset_master am ON am.asset_id = s.asset_id
    LEFT  JOIN vehicle_details vd ON vd.asset_id = s.asset_id
    ORDER BY s.service_id DESC
    LIMIT 300
</cfquery>

<cfquery name="getVehicles" datasource="boyahane">
    SELECT asset_id, asset_name FROM asset_master
    WHERE asset_type = 'VEHICLE' AND asset_status NOT IN ('SCRAPPED','SOLD')
    ORDER BY asset_name
</cfquery>

<cfset fuelArr     = []>
<cfset serviceArr  = []>
<cfset envArr      = []>
<cfset accidentArr = []>
<cfset tireArr     = []>
<cfset totalLiters = 0>
<cfset totalFuelAmt= 0>
<cfset totalSvcAmt = 0>
<cfset today       = now()>

<!--- Araç Envanteri --->
<cfloop query="getVehicleEnv">
    <cfset fuelLbl = "">
    <cfswitch expression="#fuel_type#">
        <cfcase value="GASOLINE"> <cfset fuelLbl="Benzin"></cfcase>
        <cfcase value="DIESEL">   <cfset fuelLbl="Dizel"></cfcase>
        <cfcase value="LPG">      <cfset fuelLbl="LPG"></cfcase>
        <cfcase value="HYBRID">   <cfset fuelLbl="Hibrit"></cfcase>
        <cfcase value="ELECTRIC"> <cfset fuelLbl="Elektrik"></cfcase>
        <cfcase value="OTHER">    <cfset fuelLbl="Diğer"></cfcase>
        <cfdefaultcase>           <cfset fuelLbl=""></cfdefaultcase>
    </cfswitch>
    <!--- Tarih uyarı fonksiyonu: 0=ok, 1=yaklaşıyor (30 gün), 2=geçmiş --->
    <cffunction name="dateWarn" returntype="numeric" access="private">
        <cfargument name="d">
        <cfif isDate(d)>
            <cfset diff = dateDiff("d", today, d)>
            <cfif diff LT 0>    <cfreturn 2>
            <cfelseif diff LT 31><cfreturn 1>
            <cfelse>            <cfreturn 0>
            </cfif>
        </cfif>
        <cfreturn -1>
    </cffunction>
    <cfset arrayAppend(envArr, {
        "asset_id":               val(asset_id),
        "asset_name":             asset_name ?: "",
        "plate_no":               plate_no ?: "",
        "chassis_no":             chassis_no ?: "",
        "engine_no":              engine_no ?: "",
        "brand":                  brand ?: "",
        "model":                  model ?: "",
        "model_year":             isNumeric(model_year) ? val(model_year) : 0,
        "fuel_type":              fuelLbl,
        "fuel_type_code":         fuel_type ?: "",
        "current_km":             isNumeric(current_km) ? val(current_km) : 0,
        "asset_status":           asset_status ?: "",
        "purchase_date":          isDate(purchase_date) ? dateFormat(purchase_date,"dd/mm/yyyy") : "",
        "acquisition_cost":       isNumeric(acquisition_cost) ? val(acquisition_cost) : 0,
        "traffic_insurance_end":  isDate(traffic_insurance_end) ? dateFormat(traffic_insurance_end,"dd/mm/yyyy") : "",
        "traffic_insurance_warn": isDate(traffic_insurance_end) ? dateWarn(traffic_insurance_end) : -1,
        "casco_end":              isDate(casco_end) ? dateFormat(casco_end,"dd/mm/yyyy") : "",
        "casco_warn":             isDate(casco_end) ? dateWarn(casco_end) : -1,
        "mtv_due_date":           isDate(mtv_due_date) ? dateFormat(mtv_due_date,"dd/mm/yyyy") : "",
        "mtv_warn":               isDate(mtv_due_date) ? dateWarn(mtv_due_date) : -1,
        "inspection_due_date":    isDate(inspection_due_date) ? dateFormat(inspection_due_date,"dd/mm/yyyy") : "",
        "inspection_warn":        isDate(inspection_due_date) ? dateWarn(inspection_due_date) : -1,
        "emission_due_date":      isDate(emission_due_date) ? dateFormat(emission_due_date,"dd/mm/yyyy") : "",
        "emission_warn":          isDate(emission_due_date) ? dateWarn(emission_due_date) : -1,
        "lease_start_date":       isDate(lease_start_date) ? dateFormat(lease_start_date,"dd/mm/yyyy") : "",
        "lease_end_date":         isDate(lease_end_date) ? dateFormat(lease_end_date,"dd/mm/yyyy") : ""
    })>
</cfloop>

<!--- Kazalar --->
<cfloop query="getAccidents">
    <cfset statusLbl = "">
    <cfswitch expression="#process_status#">
        <cfcase value="OPEN">     <cfset statusLbl="Açık"></cfcase>
        <cfcase value="IN_REPAIR"><cfset statusLbl="Onarımda"></cfcase>
        <cfcase value="CLOSED">   <cfset statusLbl="Kapalı"></cfcase>
        <cfdefaultcase>           <cfset statusLbl=process_status ?: ""></cfdefaultcase>
    </cfswitch>
    <cfset arrayAppend(accidentArr, {
        "accident_id":        val(accident_id),
        "asset_name":         asset_name ?: "",
        "plate_no":           plate_no ?: "",
        "accident_date":      isDate(accident_date) ? dateFormat(accident_date,"dd/mm/yyyy") : "",
        "damage_description": damage_description ?: "",
        "estimated_cost":     isNumeric(estimated_cost) ? val(estimated_cost) : 0,
        "actual_cost":        isNumeric(actual_cost) ? val(actual_cost) : 0,
        "insurance_claim_no": insurance_claim_no ?: "",
        "process_status":     process_status ?: "",
        "status_label":       statusLbl
    })>
</cfloop>

<!--- Lastik --->
<cfloop query="getTireLogs">
    <cfset logTypeLbl = "">
    <cfswitch expression="#log_type#">
        <cfcase value="CHANGE">   <cfset logTypeLbl="Değişim"></cfcase>
        <cfcase value="BALANCE">  <cfset logTypeLbl="Balans"></cfcase>
        <cfcase value="ROTATION"> <cfset logTypeLbl="Rotasyon"></cfcase>
        <cfcase value="OTHER">    <cfset logTypeLbl="Diğer"></cfcase>
        <cfdefaultcase>           <cfset logTypeLbl=log_type ?: ""></cfdefaultcase>
    </cfswitch>
    <cfset arrayAppend(tireArr, {
        "tire_log_id":  val(tire_log_id),
        "asset_name":   asset_name ?: "",
        "plate_no":     plate_no ?: "",
        "log_date":     isDate(log_date) ? dateFormat(log_date,"dd/mm/yyyy") : "",
        "log_type":     log_type ?: "",
        "log_type_lbl": logTypeLbl,
        "odometer_km":  isNumeric(odometer_km) ? val(odometer_km) : 0,
        "tire_position":tire_position ?: "",
        "tire_brand":   tire_brand ?: "",
        "tire_size":    tire_size ?: "",
        "cost":         isNumeric(cost) ? val(cost) : 0,
        "note":         note ?: ""
    })>
</cfloop>

<cfloop query="getFuel">
    <cfset totalLiters  += isNumeric(liters) ? val(liters) : 0>
    <cfset totalFuelAmt += isNumeric(amount) ? val(amount) : 0>
    <cfset arrayAppend(fuelArr, {
        "fuel_log_id":  val(fuel_log_id),
        "asset_name":   asset_name ?: "",
        "plate_no":     plate_no ?: "",
        "fuel_date":    isDate(fuel_date) ? dateFormat(fuel_date,"dd/mm/yyyy") : "",
        "odometer_km":  isNumeric(odometer_km) ? val(odometer_km) : 0,
        "liters":       isNumeric(liters) ? val(liters) : 0,
        "amount":       isNumeric(amount) ? val(amount) : 0,
        "station_name": station_name ?: "",
        "invoice_no":   invoice_no ?: ""
    })>
</cfloop>

<cfloop query="getService">
    <cfset totalSvcAmt += isNumeric(total_cost) ? val(total_cost) : 0>
    <cfset typeLbl = "">
    <cfswitch expression="#service_type#">
        <cfcase value="PERIODIC">       <cfset typeLbl="Periyodik"></cfcase>
        <cfcase value="REPAIR">         <cfset typeLbl="Onarım"></cfcase>
        <cfcase value="TIRE">           <cfset typeLbl="Lastik"></cfcase>
        <cfcase value="ACCIDENT_REPAIR"><cfset typeLbl="Hasar Onarımı"></cfcase>
        <cfcase value="OTHER">          <cfset typeLbl="Diğer"></cfcase>
        <cfdefaultcase>                 <cfset typeLbl=service_type ?: ""></cfdefaultcase>
    </cfswitch>
    <cfset arrayAppend(serviceArr, {
        "service_id":       val(service_id),
        "asset_name":       asset_name ?: "",
        "plate_no":         plate_no ?: "",
        "service_type":     service_type ?: "",
        "type_label":       typeLbl,
        "service_date":     isDate(service_date) ? dateFormat(service_date,"dd/mm/yyyy") : "",
        "odometer_km":      isNumeric(odometer_km) ? val(odometer_km) : 0,
        "labor_cost":       isNumeric(labor_cost) ? val(labor_cost) : 0,
        "material_cost":    isNumeric(material_cost) ? val(material_cost) : 0,
        "total_cost":       isNumeric(total_cost) ? val(total_cost) : 0,
        "next_service_date":isDate(next_service_date) ? dateFormat(next_service_date,"dd/mm/yyyy") : ""
    })>
</cfloop>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-car"></i></div>
        <div class="page-header-title">
            <h1>Araç Operasyonları</h1>
            <p>Yakıt tüketimi, servis ve bakım gider takibi</p>
        </div>
    </div>
</div>

<div class="px-3 pb-4">

    <div class="row g-3 mb-3">
        <div class="col-md-4 col-xl">
            <div class="summary-card summary-card-blue">
                <div class="summary-icon"><i class="fas fa-car"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Toplam Araç</span>
                    <span class="summary-value"><cfoutput>#getVehicleEnv.recordCount#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-4 col-xl">
            <div class="summary-card summary-card-green">
                <div class="summary-icon"><i class="fas fa-gas-pump"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Yakıt Kaydı</span>
                    <span class="summary-value"><cfoutput>#getFuel.recordCount#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-4 col-xl">
            <div class="summary-card summary-card-orange">
                <div class="summary-icon"><i class="fas fa-tint"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Toplam Litre</span>
                    <span class="summary-value"><cfoutput>#numberFormat(totalLiters,"9999.9")#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-4 col-xl">
            <div class="summary-card summary-card-purple">
                <div class="summary-icon"><i class="fas fa-wrench"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Servis Kaydı</span>
                    <span class="summary-value"><cfoutput>#getService.recordCount#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-4 col-xl">
            <div class="summary-card summary-card-red">
                <div class="summary-icon"><i class="fas fa-car-crash"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Kaza/Hasar</span>
                    <span class="summary-value"><cfoutput>#getAccidents.recordCount#</cfoutput></span>
                </div>
            </div>
        </div>
    </div>

    <div class="grid-card">
        <div class="grid-card-header pb-0" style="border-bottom:none;">
            <div class="grid-card-header-title"><i class="fas fa-car-side"></i>Operasyon Kayıtları</div>
        </div>
        <div class="card-body p-3">
            <ul class="nav nav-tabs mb-3" id="vehTabs">
                <li class="nav-item">
                    <a class="nav-link active" id="tab-env" href="#" onclick="switchTab('env',this);return false;">
                        <i class="fas fa-id-card me-1"></i>Araç Envanter
                        <span class="badge bg-secondary ms-1" id="envCount"></span>
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" id="tab-fuel" href="#" onclick="switchTab('fuel',this);return false;">
                        <i class="fas fa-gas-pump me-1"></i>Yakıt
                        <span class="badge bg-secondary ms-1" id="fuelCount"></span>
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" id="tab-svc" href="#" onclick="switchTab('svc',this);return false;">
                        <i class="fas fa-tools me-1"></i>Servis
                        <span class="badge bg-secondary ms-1" id="svcCount"></span>
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" id="tab-acc" href="#" onclick="switchTab('acc',this);return false;">
                        <i class="fas fa-car-crash me-1"></i>Kaza/Hasar
                        <span class="badge bg-secondary ms-1" id="accCount"></span>
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" id="tab-tire" href="#" onclick="switchTab('tire',this);return false;">
                        <i class="fas fa-circle-notch me-1"></i>Lastik
                        <span class="badge bg-secondary ms-1" id="tireCount"></span>
                    </a>
                </li>
            </ul>

            <!--- Araç Envanter Panel --->
            <div id="panelEnv">
                <div class="d-flex justify-content-end mb-2">
                    <button class="btn btn-sm btn-primary" onclick="openVehicleDetail(0)">
                        <i class="fas fa-plus me-1"></i>Araç Detayı Ekle
                    </button>
                </div>
                <div id="envGrid"></div>
            </div>

            <div id="panelFuel" style="display:none;">
                <div class="d-flex justify-content-end mb-2">
                    <button class="btn btn-sm btn-warning text-dark fw-bold" data-bs-toggle="modal" data-bs-target="#fuelModal">
                        <i class="fas fa-plus me-1"></i>Yakıt Ekle
                    </button>
                </div>
                <div id="fuelGrid"></div>
            </div>
            <div id="panelSvc" style="display:none;">
                <div class="d-flex justify-content-end mb-2">
                    <button class="btn btn-sm btn-warning text-dark fw-bold" data-bs-toggle="modal" data-bs-target="#svcModal">
                        <i class="fas fa-plus me-1"></i>Servis Ekle
                    </button>
                </div>
                <div id="svcGrid"></div>
            </div>
            <!--- Kaza/Hasar Panel --->
            <div id="panelAcc" style="display:none;">
                <div class="d-flex justify-content-end mb-2">
                    <button class="btn btn-sm btn-danger" data-bs-toggle="modal" data-bs-target="#accModal">
                        <i class="fas fa-plus me-1"></i>Kaza/Hasar Ekle
                    </button>
                </div>
                <div id="accGrid"></div>
            </div>
            <!--- Lastik Panel --->
            <div id="panelTire" style="display:none;">
                <div class="d-flex justify-content-end mb-2">
                    <button class="btn btn-sm btn-secondary" data-bs-toggle="modal" data-bs-target="#tireModal">
                        <i class="fas fa-plus me-1"></i>Lastik Kaydı Ekle
                    </button>
                </div>
                <div id="tireGrid"></div>
            </div>
        </div>
    </div>
</div>

<!--- Araç Detay Modal (Plaka, Şasi, Tarihler) --->
<div class="modal fade" id="vehicleDetailModal" tabindex="-1">
    <div class="modal-dialog modal-xl">
        <div class="modal-content">
            <div class="modal-header" style="background:var(--primary);color:#fff;">
                <h5 class="modal-title"><i class="fas fa-id-card me-2"></i>Araç Detay Bilgileri</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <input type="hidden" id="vd_asset_id">
                <div class="row g-3">
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Araç *</label>
                        <select id="vd_asset_sel" class="form-select">
                            <option value="">Seçiniz</option>
                            <cfoutput query="getVehicles">
                                <option value="#asset_id#">#encodeForHTML(asset_name)#</option>
                            </cfoutput>
                        </select>
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Plaka No *</label>
                        <input type="text" id="vd_plate_no" class="form-control" maxlength="20" placeholder="34 ABC 123">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Yakıt Tipi</label>
                        <select id="vd_fuel_type" class="form-select">
                            <option value="">Seçiniz</option>
                            <option value="GASOLINE">Benzin</option>
                            <option value="DIESEL">Dizel</option>
                            <option value="LPG">LPG</option>
                            <option value="HYBRID">Hibrit</option>
                            <option value="ELECTRIC">Elektrik</option>
                            <option value="OTHER">Diğer</option>
                        </select>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Şasi No</label>
                        <input type="text" id="vd_chassis_no" class="form-control" maxlength="100">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Motor No</label>
                        <input type="text" id="vd_engine_no" class="form-control" maxlength="100">
                    </div>
                    <div class="col-md-2">
                        <label class="form-label fw-semibold">Model Yılı</label>
                        <input type="number" id="vd_model_year" class="form-control" min="1990" max="2099">
                    </div>
                    <div class="col-md-2">
                        <label class="form-label fw-semibold">Güncel KM</label>
                        <input type="number" step="0.1" min="0" id="vd_current_km" class="form-control">
                    </div>
                    <div class="col-12"><hr class="my-1"><small class="text-muted fw-semibold text-uppercase">Yasal Yükümlülük Tarihleri</small></div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold"><i class="fas fa-shield-alt text-success me-1"></i>Trafik Sigortası Bitiş</label>
                        <input type="date" id="vd_traffic_ins_end" class="form-control">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold"><i class="fas fa-car text-primary me-1"></i>Kasko Bitiş</label>
                        <input type="date" id="vd_casco_end" class="form-control">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold"><i class="fas fa-receipt text-warning me-1"></i>MTV Ödeme Tarihi</label>
                        <input type="date" id="vd_mtv_due" class="form-control">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold"><i class="fas fa-clipboard-check text-info me-1"></i>Muayene Tarihi</label>
                        <input type="date" id="vd_inspection_due" class="form-control">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold"><i class="fas fa-smog text-secondary me-1"></i>Egzoz Emisyon Tarihi</label>
                        <input type="date" id="vd_emission_due" class="form-control">
                    </div>
                    <div class="col-12"><hr class="my-1"><small class="text-muted fw-semibold text-uppercase">Kiralama (Opsiyonel)</small></div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Kiralama Başlangıç</label>
                        <input type="date" id="vd_lease_start" class="form-control">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Kiralama Bitiş</label>
                        <input type="date" id="vd_lease_end" class="form-control">
                    </div>
                </div>
                <div id="vdSaveMsg" class="mt-3"></div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-outline-secondary" data-bs-dismiss="modal">Kapat</button>
                <button class="btn btn-primary" id="vdSaveBtn" onclick="saveVehicleDetail()">
                    <i class="fas fa-save me-2"></i>Kaydet
                </button>
            </div>
        </div>
    </div>
</div>

<!--- Kaza/Hasar Modal --->
<div class="modal fade" id="accModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header" style="background:#991b1b;color:#fff;">
                <h5 class="modal-title"><i class="fas fa-car-crash me-2"></i>Kaza / Hasar Kaydı Ekle</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <div class="row g-3">
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Araç *</label>
                        <select id="a_asset_id" class="form-select">
                            <option value="">Seçiniz</option>
                            <cfoutput query="getVehicles">
                                <option value="#asset_id#">#encodeForHTML(asset_name)#</option>
                            </cfoutput>
                        </select>
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Kaza Tarihi *</label>
                        <input type="date" id="a_accident_date" class="form-control">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Sigorta Dosya No</label>
                        <input type="text" id="a_insurance_claim_no" class="form-control" maxlength="100">
                    </div>
                    <div class="col-12">
                        <label class="form-label fw-semibold">Hasar Açıklaması</label>
                        <textarea id="a_damage_description" class="form-control" rows="3"></textarea>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Tahmini Maliyet</label>
                        <input type="number" step="0.01" min="0" id="a_estimated_cost" class="form-control" value="0">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Gerçek Maliyet</label>
                        <input type="number" step="0.01" min="0" id="a_actual_cost" class="form-control" value="0">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Durum</label>
                        <select id="a_process_status" class="form-select">
                            <option value="OPEN">Açık</option>
                            <option value="IN_REPAIR">Onarımda</option>
                            <option value="CLOSED">Kapalı</option>
                        </select>
                    </div>
                </div>
                <div id="accSaveMsg" class="mt-2"></div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-outline-secondary" data-bs-dismiss="modal">Kapat</button>
                <button class="btn btn-danger" id="accSaveBtn" onclick="saveAccident()">
                    <i class="fas fa-save me-2"></i>Kaydet
                </button>
            </div>
        </div>
    </div>
</div>

<!--- Lastik Modal --->
<div class="modal fade" id="tireModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header" style="background:#374151;color:#fff;">
                <h5 class="modal-title"><i class="fas fa-circle-notch me-2"></i>Lastik Kaydı Ekle</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <div class="row g-3">
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Araç *</label>
                        <select id="t_asset_id" class="form-select">
                            <option value="">Seçiniz</option>
                            <cfoutput query="getVehicles">
                                <option value="#asset_id#">#encodeForHTML(asset_name)#</option>
                            </cfoutput>
                        </select>
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Tarih *</label>
                        <input type="date" id="t_log_date" class="form-control">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">İşlem Tipi *</label>
                        <select id="t_log_type" class="form-select">
                            <option value="CHANGE">Lastik Değişimi</option>
                            <option value="BALANCE">Balans</option>
                            <option value="ROTATION">Rotasyon</option>
                            <option value="OTHER">Diğer</option>
                        </select>
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">KM (Sayaç)</label>
                        <input type="number" step="0.1" min="0" id="t_odometer_km" class="form-control">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Konum</label>
                        <input type="text" id="t_tire_position" class="form-control" maxlength="50" placeholder="Ön Sol, Tümü...">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Lastik Markası</label>
                        <input type="text" id="t_tire_brand" class="form-control" maxlength="100">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Ebat</label>
                        <input type="text" id="t_tire_size" class="form-control" maxlength="50" placeholder="205/55R16">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Maliyet</label>
                        <input type="number" step="0.01" min="0" id="t_cost" class="form-control" value="0">
                    </div>
                    <div class="col-md-8">
                        <label class="form-label fw-semibold">Not</label>
                        <input type="text" id="t_note" class="form-control">
                    </div>
                </div>
                <div id="tireSaveMsg" class="mt-2"></div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-outline-secondary" data-bs-dismiss="modal">Kapat</button>
                <button class="btn btn-secondary" id="tireSaveBtn" onclick="saveTire()">
                    <i class="fas fa-save me-2"></i>Kaydet
                </button>
            </div>
        </div>
    </div>
</div>

<!-- Yakıt Modal -->
<div class="modal fade" id="fuelModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header" style="background:var(--primary);color:#fff;">
                <h5 class="modal-title"><i class="fas fa-gas-pump me-2"></i>Yakıt Kaydı Ekle</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <div class="row g-3">
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Araç *</label>
                        <select id="f_asset_id" class="form-select">
                            <option value="">Seçiniz</option>
                            <cfoutput query="getVehicles">
                                <option value="#asset_id#">#encodeForHTML(asset_name)#</option>
                            </cfoutput>
                        </select>
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Yakıt Tarihi *</label>
                        <input type="date" id="f_fuel_date" class="form-control">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">KM (Sayaç)</label>
                        <input type="number" step="0.1" min="0" id="f_odometer_km" class="form-control">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Litre *</label>
                        <input type="number" step="0.001" min="0.001" id="f_liters" class="form-control">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Tutar *</label>
                        <input type="number" step="0.01" min="0" id="f_amount" class="form-control">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">İstasyon</label>
                        <input type="text" id="f_station_name" class="form-control" maxlength="150">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Fiş/Fatura No</label>
                        <input type="text" id="f_invoice_no" class="form-control" maxlength="50">
                    </div>
                    <div class="col-md-8">
                        <label class="form-label fw-semibold">Not</label>
                        <input type="text" id="f_note" class="form-control">
                    </div>
                </div>
                <div id="fuelSaveMsg" class="mt-2"></div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-outline-secondary" data-bs-dismiss="modal">Kapat</button>
                <button class="btn btn-warning text-dark fw-bold" id="fuelSaveBtn" onclick="saveFuel()">
                    <i class="fas fa-save me-2"></i>Kaydet
                </button>
            </div>
        </div>
    </div>
</div>

<!-- Servis Modal -->
<div class="modal fade" id="svcModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header" style="background:var(--primary);color:#fff;">
                <h5 class="modal-title"><i class="fas fa-tools me-2"></i>Servis Kaydı Ekle</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <div class="row g-3">
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Araç *</label>
                        <select id="s_asset_id" class="form-select">
                            <option value="">Seçiniz</option>
                            <cfoutput query="getVehicles">
                                <option value="#asset_id#">#encodeForHTML(asset_name)#</option>
                            </cfoutput>
                        </select>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Servis Tipi *</label>
                        <select id="s_service_type" class="form-select">
                            <option value="PERIODIC">Periyodik Bakım</option>
                            <option value="REPAIR">Onarım</option>
                            <option value="TIRE">Lastik</option>
                            <option value="ACCIDENT_REPAIR">Hasar Onarımı</option>
                            <option value="OTHER">Diğer</option>
                        </select>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Servis Tarihi *</label>
                        <input type="date" id="s_service_date" class="form-control">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">KM (Sayaç)</label>
                        <input type="number" step="0.1" min="0" id="s_odometer_km" class="form-control">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Sonraki Servis</label>
                        <input type="date" id="s_next_service_date" class="form-control">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">İşçilik Maliyeti</label>
                        <input type="number" step="0.01" min="0" id="s_labor_cost" class="form-control" value="0">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Malzeme Maliyeti</label>
                        <input type="number" step="0.01" min="0" id="s_material_cost" class="form-control" value="0">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Not</label>
                        <input type="text" id="s_note" class="form-control">
                    </div>
                </div>
                <div id="svcSaveMsg" class="mt-2"></div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-outline-secondary" data-bs-dismiss="modal">Kapat</button>
                <button class="btn btn-warning text-dark fw-bold" id="svcSaveBtn" onclick="saveSvc()">
                    <i class="fas fa-save me-2"></i>Kaydet
                </button>
            </div>
        </div>
    </div>
</div>

<cfoutput>
<style>
##vehicleDetailModal, ##accModal, ##tireModal, ##fuelModal, ##svcModal { z-index: 99999 !important; }
.modal-backdrop { z-index: 99998 !important; }
.summary-card { display:flex;align-items:center;gap:14px;padding:16px 20px;border-radius:10px;color:##fff;box-shadow:0 2px 10px rgba(0,0,0,.12); }
.summary-card-blue  { background:linear-gradient(135deg,##1a3a5c,##2563ab); }
.summary-card-green { background:linear-gradient(135deg,##15803d,##22c55e); }
.summary-card-orange{ background:linear-gradient(135deg,##92400e,##f59e0b); }
.summary-card-purple{ background:linear-gradient(135deg,##6d28d9,##a78bfa); }
.summary-card-red   { background:linear-gradient(135deg,##991b1b,##ef4444); }
.summary-icon  { font-size:1.8rem;opacity:.85; }
.summary-label { font-size:.75rem;opacity:.85;display:block; }
.summary-value { font-size:1.6rem;font-weight:700;display:block; }
.badge-st { display:inline-block;padding:3px 10px;border-radius:10px;font-size:.72rem;font-weight:600; }
.bst-PERIODIC      { background:##dbeafe;color:##1e40af; }
.bst-REPAIR        { background:##fee2e2;color:##b91c1c; }
.bst-TIRE          { background:##fef3c7;color:##92400e; }
.bst-ACCIDENT_REPAIR{ background:##ffedd5;color:##c2410c; }
.bst-OTHER         { background:##f3f4f6;color:##6b7280; }
/* Tarih uyarı renkleri */
.dw-ok   { color:##15803d; font-weight:600; }
.dw-warn { color:##b45309; font-weight:700; }
.dw-exp  { color:##b91c1c; font-weight:700; }
.dw-na   { color:##9ca3af; }
/* Araç kart plaka etiketi */
.plate-badge { display:inline-block;background:##1a3a5c;color:##fff;border-radius:6px;padding:2px 10px;font-size:.8rem;font-weight:700;letter-spacing:.05em; }
.nav-tabs .nav-link { color:var(--primary); }
.nav-tabs .nav-link.active { color:var(--primary);border-bottom-color:var(--accent);border-bottom-width:2px;font-weight:700; }
</style>
<script>
var allEnv      = #serializeJSON(envArr)#;
var allFuel     = #serializeJSON(fuelArr)#;
var allSvc      = #serializeJSON(serviceArr)#;
var allAccident = #serializeJSON(accidentArr)#;
var allTire     = #serializeJSON(tireArr)#;

var stBadge = {
    'PERIODIC':       '<span class="badge-st bst-PERIODIC">Periyodik</span>',
    'REPAIR':         '<span class="badge-st bst-REPAIR">Onarım</span>',
    'TIRE':           '<span class="badge-st bst-TIRE">Lastik</span>',
    'ACCIDENT_REPAIR':'<span class="badge-st bst-ACCIDENT_REPAIR">Hasar Onarımı</span>',
    'OTHER':          '<span class="badge-st bst-OTHER">Diğer</span>'
};

var accBadge = {
    'OPEN':      '<span class="badge-st" style="background:##fee2e2;color:##b91c1c">Açık</span>',
    'IN_REPAIR': '<span class="badge-st" style="background:##fef3c7;color:##92400e">Onarımda</span>',
    'CLOSED':    '<span class="badge-st" style="background:##dcfce7;color:##15803d">Kapalı</span>'
};

var tireBadge = {
    'CHANGE':   '<span class="badge-st" style="background:##dbeafe;color:##1e40af">Değişim</span>',
    'BALANCE':  '<span class="badge-st" style="background:##f3f4f6;color:##374151">Balans</span>',
    'ROTATION': '<span class="badge-st" style="background:##f5f3ff;color:##6d28d9">Rotasyon</span>',
    'OTHER':    '<span class="badge-st" style="background:##f3f4f6;color:##6b7280">Diğer</span>'
};

function dateWarnHtml(dateStr, warnLevel) {
    if (!dateStr) return '<span class="dw-na">—</span>';
    if (warnLevel === 2) return '<span class="dw-exp"><i class="fas fa-exclamation-circle me-1"></i>'+dateStr+'</span>';
    if (warnLevel === 1) return '<span class="dw-warn"><i class="fas fa-exclamation-triangle me-1"></i>'+dateStr+'</span>';
    return '<span class="dw-ok">'+dateStr+'</span>';
}

window.addEventListener('load', function(){
    [document.getElementById('vehicleDetailModal'),
     document.getElementById('accModal'),
     document.getElementById('tireModal'),
     document.getElementById('fuelModal'),
     document.getElementById('svcModal')
    ].forEach(function(m){ if(m) document.body.appendChild(m); });

    document.getElementById('envCount').textContent  = allEnv.length;
    document.getElementById('fuelCount').textContent = allFuel.length;
    document.getElementById('svcCount').textContent  = allSvc.length;
    document.getElementById('accCount').textContent  = allAccident.length;
    document.getElementById('tireCount').textContent = allTire.length;

    /* ---- Araç Envanter Grid ---- */
    $("##envGrid").dxDataGrid({
        dataSource: allEnv, keyExpr:"asset_id",
        showBorders:false, showRowLines:true, showColumnLines:false,
        rowAlternationEnabled:true, hoverStateEnabled:true,
        paging:{ pageSize:25 },
        pager:{ showPageSizeSelector:true, allowedPageSizes:[25,50], showInfo:true },
        sorting:{ mode:"multiple" },
        export:{ enabled:true, fileName:"arac_envanter" },
        headerFilter:{ visible:true },
        columns:[
            { dataField:"asset_id", caption:"##", width:55, alignment:"center" },
            {
                dataField:"plate_no", caption:"Plaka", width:110,
                cellTemplate: function(el,i){ el.html(i.value ? '<span class="plate-badge">'+i.value+'</span>' : '<span class="dw-na">—</span>'); }
            },
            { dataField:"asset_name", caption:"Araç Adı", minWidth:130 },
            { dataField:"brand",      caption:"Marka",    width:90 },
            { dataField:"model",      caption:"Model",    width:90 },
            { dataField:"model_year", caption:"Yıl",      width:60, alignment:"center" },
            { dataField:"fuel_type",  caption:"Yakıt",    width:85 },
            { dataField:"chassis_no", caption:"Şasi No",  width:150 },
            { dataField:"engine_no",  caption:"Motor No", width:120 },
            {
                dataField:"current_km", caption:"Güncel KM", width:110, alignment:"right",
                cellTemplate: function(el,i){ el.text(i.value > 0 ? parseFloat(i.value).toLocaleString('tr-TR',{minimumFractionDigits:1}) : '—'); }
            },
            {
                dataField:"traffic_insurance_end", caption:"Trafik Sig.", width:115, alignment:"center",
                cellTemplate: function(el,i){ el.html(dateWarnHtml(i.data.traffic_insurance_end, i.data.traffic_insurance_warn)); }
            },
            {
                dataField:"casco_end", caption:"Kasko", width:110, alignment:"center",
                cellTemplate: function(el,i){ el.html(dateWarnHtml(i.data.casco_end, i.data.casco_warn)); }
            },
            {
                dataField:"mtv_due_date", caption:"MTV", width:110, alignment:"center",
                cellTemplate: function(el,i){ el.html(dateWarnHtml(i.data.mtv_due_date, i.data.mtv_warn)); }
            },
            {
                dataField:"inspection_due_date", caption:"Muayene", width:110, alignment:"center",
                cellTemplate: function(el,i){ el.html(dateWarnHtml(i.data.inspection_due_date, i.data.inspection_warn)); }
            },
            {
                dataField:"emission_due_date", caption:"Emisyon", width:110, alignment:"center",
                cellTemplate: function(el,i){ el.html(dateWarnHtml(i.data.emission_due_date, i.data.emission_warn)); }
            },
            {
                caption:"", width:80, alignment:"center",
                cellTemplate: function(el,i){
                    el.html('<button class="btn btn-xs btn-outline-primary py-0 px-2" onclick="openVehicleDetail('+i.data.asset_id+','+JSON.stringify(i.data).replace(/"/g,"&quot;")+')"><i class="fas fa-edit"></i></button>');
                }
            }
        ]
    });

    /* ---- Yakıt Grid ---- */
    $("##fuelGrid").dxDataGrid({
        dataSource: allFuel, keyExpr:"fuel_log_id",
        showBorders:false, showRowLines:true, showColumnLines:false,
        rowAlternationEnabled:true, hoverStateEnabled:true,
        paging:{ pageSize:25 },
        pager:{ showPageSizeSelector:true, allowedPageSizes:[25,50,100], showInfo:true },
        sorting:{ mode:"multiple" },
        export:{ enabled:true, fileName:"yakit_kayitlari" },
        headerFilter:{ visible:true },
        columns:[
            { dataField:"fuel_log_id",  caption:"##",     width:65,  alignment:"center", sortOrder:"desc" },
            {
                dataField:"plate_no", caption:"Plaka", width:100,
                cellTemplate: function(el,i){ el.html(i.value ? '<span class="plate-badge">'+i.value+'</span>' : '<span class="dw-na">—</span>'); }
            },
            { dataField:"asset_name",   caption:"Araç",  minWidth:120 },
            { dataField:"fuel_date",    caption:"Tarih", width:110, alignment:"center" },
            {
                dataField:"odometer_km", caption:"KM", width:110, alignment:"right",
                cellTemplate: function(el,i){ el.text(i.value > 0 ? parseFloat(i.value).toLocaleString('tr-TR',{minimumFractionDigits:1,maximumFractionDigits:1}) : '-'); }
            },
            {
                dataField:"liters", caption:"Litre", width:100, alignment:"right",
                cellTemplate: function(el,i){ el.text(parseFloat(i.value||0).toLocaleString('tr-TR',{minimumFractionDigits:3,maximumFractionDigits:3})); }
            },
            {
                dataField:"amount", caption:"Tutar", width:120, alignment:"right",
                cellTemplate: function(el,i){ el.text(parseFloat(i.value||0).toLocaleString('tr-TR',{minimumFractionDigits:2,maximumFractionDigits:2})); }
            },
            { dataField:"station_name", caption:"İstasyon",     width:150 },
            { dataField:"invoice_no",   caption:"Fiş/Fatura No", width:130 }
        ]
    });

    /* ---- Servis Grid ---- */
    $("##svcGrid").dxDataGrid({
        dataSource: allSvc, keyExpr:"service_id",
        showBorders:false, showRowLines:true, showColumnLines:false,
        rowAlternationEnabled:true, hoverStateEnabled:true,
        paging:{ pageSize:25 },
        pager:{ showPageSizeSelector:true, allowedPageSizes:[25,50,100], showInfo:true },
        sorting:{ mode:"multiple" },
        export:{ enabled:true, fileName:"servis_kayitlari" },
        headerFilter:{ visible:true },
        columns:[
            { dataField:"service_id",   caption:"##",   width:65,  alignment:"center", sortOrder:"desc" },
            {
                dataField:"plate_no", caption:"Plaka", width:100,
                cellTemplate: function(el,i){ el.html(i.value ? '<span class="plate-badge">'+i.value+'</span>' : '<span class="dw-na">—</span>'); }
            },
            { dataField:"asset_name",   caption:"Araç",  minWidth:120 },
            {
                dataField:"service_type", caption:"Tip", width:130, alignment:"center",
                cellTemplate: function(el,i){ el.html(stBadge[i.value] || i.value || '-'); }
            },
            { dataField:"service_date", caption:"Tarih",  width:110, alignment:"center" },
            {
                dataField:"odometer_km", caption:"KM", width:110, alignment:"right",
                cellTemplate: function(el,i){ el.text(i.value > 0 ? parseFloat(i.value).toLocaleString('tr-TR',{minimumFractionDigits:1,maximumFractionDigits:1}) : '-'); }
            },
            {
                dataField:"labor_cost", caption:"İşçilik", width:110, alignment:"right",
                cellTemplate: function(el,i){ el.text(parseFloat(i.value||0).toLocaleString('tr-TR',{minimumFractionDigits:2,maximumFractionDigits:2})); }
            },
            {
                dataField:"material_cost", caption:"Malzeme", width:110, alignment:"right",
                cellTemplate: function(el,i){ el.text(parseFloat(i.value||0).toLocaleString('tr-TR',{minimumFractionDigits:2,maximumFractionDigits:2})); }
            },
            {
                dataField:"total_cost", caption:"Toplam", width:120, alignment:"right",
                cellTemplate: function(el,i){ el.html('<strong style="color:##1a3a5c">'+parseFloat(i.value||0).toLocaleString('tr-TR',{minimumFractionDigits:2,maximumFractionDigits:2})+'</strong>'); }
            },
            { dataField:"next_service_date", caption:"Sonraki Servis", width:130, alignment:"center" }
        ]
    });

    /* ---- Kaza/Hasar Grid ---- */
    $("##accGrid").dxDataGrid({
        dataSource: allAccident, keyExpr:"accident_id",
        showBorders:false, showRowLines:true, showColumnLines:false,
        rowAlternationEnabled:true, hoverStateEnabled:true,
        paging:{ pageSize:25 },
        pager:{ showPageSizeSelector:true, allowedPageSizes:[25,50], showInfo:true },
        sorting:{ mode:"multiple" },
        export:{ enabled:true, fileName:"kaza_hasar" },
        columns:[
            { dataField:"accident_id",   caption:"##",    width:65, alignment:"center", sortOrder:"desc" },
            {
                dataField:"plate_no", caption:"Plaka", width:100,
                cellTemplate: function(el,i){ el.html(i.value ? '<span class="plate-badge">'+i.value+'</span>' : '<span class="dw-na">—</span>'); }
            },
            { dataField:"asset_name",        caption:"Araç",         minWidth:120 },
            { dataField:"accident_date",     caption:"Kaza Tarihi",  width:110, alignment:"center" },
            { dataField:"damage_description",caption:"Hasar Açıklaması", minWidth:200 },
            {
                dataField:"estimated_cost", caption:"Tahmini Maliyet", width:130, alignment:"right",
                cellTemplate: function(el,i){ el.text(i.value > 0 ? parseFloat(i.value).toLocaleString('tr-TR',{minimumFractionDigits:2}) : '—'); }
            },
            {
                dataField:"actual_cost", caption:"Gerçek Maliyet", width:130, alignment:"right",
                cellTemplate: function(el,i){ el.text(i.value > 0 ? parseFloat(i.value).toLocaleString('tr-TR',{minimumFractionDigits:2}) : '—'); }
            },
            { dataField:"insurance_claim_no", caption:"Sigorta Dosya No", width:150 },
            {
                dataField:"process_status", caption:"Durum", width:110, alignment:"center",
                cellTemplate: function(el,i){ el.html(accBadge[i.value] || i.value || '—'); }
            }
        ]
    });

    /* ---- Lastik Grid ---- */
    $("##tireGrid").dxDataGrid({
        dataSource: allTire, keyExpr:"tire_log_id",
        showBorders:false, showRowLines:true, showColumnLines:false,
        rowAlternationEnabled:true, hoverStateEnabled:true,
        paging:{ pageSize:25 },
        pager:{ showPageSizeSelector:true, allowedPageSizes:[25,50], showInfo:true },
        sorting:{ mode:"multiple" },
        export:{ enabled:true, fileName:"lastik_kayitlari" },
        columns:[
            { dataField:"tire_log_id", caption:"##",   width:65, alignment:"center", sortOrder:"desc" },
            {
                dataField:"plate_no", caption:"Plaka", width:100,
                cellTemplate: function(el,i){ el.html(i.value ? '<span class="plate-badge">'+i.value+'</span>' : '<span class="dw-na">—</span>'); }
            },
            { dataField:"asset_name",    caption:"Araç",        minWidth:120 },
            { dataField:"log_date",      caption:"Tarih",       width:110, alignment:"center" },
            {
                dataField:"log_type", caption:"İşlem", width:110, alignment:"center",
                cellTemplate: function(el,i){ el.html(tireBadge[i.value] || i.value || '—'); }
            },
            {
                dataField:"odometer_km", caption:"KM", width:110, alignment:"right",
                cellTemplate: function(el,i){ el.text(i.value > 0 ? parseFloat(i.value).toLocaleString('tr-TR',{minimumFractionDigits:1}) : '—'); }
            },
            { dataField:"tire_position", caption:"Konum",  width:110 },
            { dataField:"tire_brand",    caption:"Marka",   width:110 },
            { dataField:"tire_size",     caption:"Ebat",    width:100 },
            {
                dataField:"cost", caption:"Maliyet", width:110, alignment:"right",
                cellTemplate: function(el,i){ el.text(i.value > 0 ? parseFloat(i.value).toLocaleString('tr-TR',{minimumFractionDigits:2}) : '—'); }
            },
            { dataField:"note", caption:"Not", minWidth:120 }
        ]
    });
});

function switchTab(tab, el) {
    ['Env','Fuel','Svc','Acc','Tire'].forEach(function(t){
        document.getElementById('panel'+t).style.display = 'none';
    });
    document.getElementById('panel'+tab.charAt(0).toUpperCase()+tab.slice(1)).style.display = '';
    document.querySelectorAll('##vehTabs .nav-link').forEach(function(a){ a.classList.remove('active'); });
    el.classList.add('active');
    var gridMap = { env:'envGrid', fuel:'fuelGrid', svc:'svcGrid', acc:'accGrid', tire:'tireGrid' };
    if (document.getElementById(gridMap[tab])) {
        $("##"+gridMap[tab]).dxDataGrid('repaint');
    }
}

function openVehicleDetail(assetId, rowData) {
    document.getElementById('vd_asset_id').value = assetId || '';
    if (rowData) {
        var sel = document.getElementById('vd_asset_sel');
        for (var i=0; i<sel.options.length; i++) {
            if (parseInt(sel.options[i].value) === assetId) { sel.selectedIndex = i; break; }
        }
        document.getElementById('vd_plate_no').value     = rowData.plate_no || '';
        document.getElementById('vd_chassis_no').value   = rowData.chassis_no || '';
        document.getElementById('vd_engine_no').value    = rowData.engine_no || '';
        document.getElementById('vd_model_year').value   = rowData.model_year || '';
        document.getElementById('vd_fuel_type').value    = rowData.fuel_type_code || '';
        document.getElementById('vd_current_km').value   = rowData.current_km || '';
        // tarihleri dd/mm/yyyy -> yyyy-mm-dd dönüştür
        function toInput(s){ if(!s)return''; var p=s.split('/'); return p.length===3?p[2]+'-'+p[1]+'-'+p[0]:''; }
        document.getElementById('vd_traffic_ins_end').value = toInput(rowData.traffic_insurance_end);
        document.getElementById('vd_casco_end').value       = toInput(rowData.casco_end);
        document.getElementById('vd_mtv_due').value         = toInput(rowData.mtv_due_date);
        document.getElementById('vd_inspection_due').value  = toInput(rowData.inspection_due_date);
        document.getElementById('vd_emission_due').value    = toInput(rowData.emission_due_date);
        document.getElementById('vd_lease_start').value     = toInput(rowData.lease_start_date);
        document.getElementById('vd_lease_end').value       = toInput(rowData.lease_end_date);
    } else {
        ['vd_asset_sel','vd_fuel_type'].forEach(function(id){ document.getElementById(id).selectedIndex=0; });
        ['vd_plate_no','vd_chassis_no','vd_engine_no','vd_model_year','vd_current_km',
         'vd_traffic_ins_end','vd_casco_end','vd_mtv_due','vd_inspection_due','vd_emission_due',
         'vd_lease_start','vd_lease_end'].forEach(function(id){ document.getElementById(id).value=''; });
    }
    document.getElementById('vdSaveMsg').innerHTML = '';
    var m = new bootstrap.Modal(document.getElementById('vehicleDetailModal'));
    m.show();
}

function saveVehicleDetail() {
    var assetId  = document.getElementById('vd_asset_sel').value || document.getElementById('vd_asset_id').value;
    var plateNo  = document.getElementById('vd_plate_no').value.trim();
    if (!assetId) { alert('Araç seçin.'); return; }
    if (!plateNo) { alert('Plaka No zorunludur.'); return; }
    var btn = document.getElementById('vdSaveBtn');
    btn.disabled=true; btn.innerHTML='<i class="fas fa-spinner fa-spin me-2"></i>Kaydediliyor...';
    $.ajax({
        url:'/asset/form/save_vehicle_detail.cfm', method:'POST', dataType:'json',
        data:{
            asset_id:            assetId,
            plate_no:            plateNo,
            chassis_no:          document.getElementById('vd_chassis_no').value,
            engine_no:           document.getElementById('vd_engine_no').value,
            model_year:          document.getElementById('vd_model_year').value,
            fuel_type:           document.getElementById('vd_fuel_type').value,
            current_km:          document.getElementById('vd_current_km').value,
            traffic_ins_end:     document.getElementById('vd_traffic_ins_end').value,
            casco_end:           document.getElementById('vd_casco_end').value,
            mtv_due:             document.getElementById('vd_mtv_due').value,
            inspection_due:      document.getElementById('vd_inspection_due').value,
            emission_due:        document.getElementById('vd_emission_due').value,
            lease_start:         document.getElementById('vd_lease_start').value,
            lease_end:           document.getElementById('vd_lease_end').value
        },
        success: function(res){
            btn.disabled=false; btn.innerHTML='<i class="fas fa-save me-2"></i>Kaydet';
            if(res&&res.success){ document.getElementById('vdSaveMsg').innerHTML='<div class="alert alert-success py-2">Araç detayı kaydedildi.</div>'; setTimeout(function(){ location.reload(); },1200); }
            else{ document.getElementById('vdSaveMsg').innerHTML='<div class="alert alert-danger py-2">'+(res.message||'Hata oluştu.')+'</div>'; }
        },
        error:function(){ btn.disabled=false; btn.innerHTML='<i class="fas fa-save me-2"></i>Kaydet'; document.getElementById('vdSaveMsg').innerHTML='<div class="alert alert-danger py-2">Sunucu hatası.</div>'; }
    });
}

function saveAccident() {
    var assetId = document.getElementById('a_asset_id').value;
    var adate   = document.getElementById('a_accident_date').value;
    if (!assetId) { alert('Araç seçin.'); return; }
    if (!adate)   { alert('Kaza tarihi girin.'); return; }
    var btn = document.getElementById('accSaveBtn');
    btn.disabled=true; btn.innerHTML='<i class="fas fa-spinner fa-spin me-2"></i>Kaydediliyor...';
    $.ajax({
        url:'/asset/form/save_vehicle_accident.cfm', method:'POST', dataType:'json',
        data:{
            asset_id:            assetId,
            accident_date:       adate,
            damage_description:  document.getElementById('a_damage_description').value,
            estimated_cost:      document.getElementById('a_estimated_cost').value,
            actual_cost:         document.getElementById('a_actual_cost').value,
            insurance_claim_no:  document.getElementById('a_insurance_claim_no').value,
            process_status:      document.getElementById('a_process_status').value
        },
        success: function(res){
            btn.disabled=false; btn.innerHTML='<i class="fas fa-save me-2"></i>Kaydet';
            if(res&&res.success){ document.getElementById('accSaveMsg').innerHTML='<div class="alert alert-success py-2">Kaza kaydı oluşturuldu.</div>'; setTimeout(function(){ location.reload(); },1200); }
            else{ document.getElementById('accSaveMsg').innerHTML='<div class="alert alert-danger py-2">'+(res.message||'Hata oluştu.')+'</div>'; }
        },
        error:function(){ btn.disabled=false; btn.innerHTML='<i class="fas fa-save me-2"></i>Kaydet'; document.getElementById('accSaveMsg').innerHTML='<div class="alert alert-danger py-2">Sunucu hatası.</div>'; }
    });
}

function saveTire() {
    var assetId = document.getElementById('t_asset_id').value;
    var tdate   = document.getElementById('t_log_date').value;
    if (!assetId) { alert('Araç seçin.'); return; }
    if (!tdate)   { alert('Tarih girin.'); return; }
    var btn = document.getElementById('tireSaveBtn');
    btn.disabled=true; btn.innerHTML='<i class="fas fa-spinner fa-spin me-2"></i>Kaydediliyor...';
    $.ajax({
        url:'/asset/form/save_vehicle_tire.cfm', method:'POST', dataType:'json',
        data:{
            asset_id:     assetId,
            log_date:     tdate,
            log_type:     document.getElementById('t_log_type').value,
            odometer_km:  document.getElementById('t_odometer_km').value,
            tire_position:document.getElementById('t_tire_position').value,
            tire_brand:   document.getElementById('t_tire_brand').value,
            tire_size:    document.getElementById('t_tire_size').value,
            cost:         document.getElementById('t_cost').value,
            note:         document.getElementById('t_note').value
        },
        success: function(res){
            btn.disabled=false; btn.innerHTML='<i class="fas fa-save me-2"></i>Kaydet';
            if(res&&res.success){ document.getElementById('tireSaveMsg').innerHTML='<div class="alert alert-success py-2">Lastik kaydı oluşturuldu.</div>'; setTimeout(function(){ location.reload(); },1200); }
            else{ document.getElementById('tireSaveMsg').innerHTML='<div class="alert alert-danger py-2">'+(res.message||'Hata oluştu.')+'</div>'; }
        },
        error:function(){ btn.disabled=false; btn.innerHTML='<i class="fas fa-save me-2"></i>Kaydet'; document.getElementById('tireSaveMsg').innerHTML='<div class="alert alert-danger py-2">Sunucu hatası.</div>'; }
    });
}

function saveFuel() {
    var assetId = document.getElementById('f_asset_id').value;
    var fdate   = document.getElementById('f_fuel_date').value;
    var liters  = document.getElementById('f_liters').value;
    var amount  = document.getElementById('f_amount').value;
    if (!assetId) { alert('Araç seçin.'); return; }
    if (!fdate)   { alert('Tarih girin.'); return; }
    if (!liters || parseFloat(liters) <= 0) { alert('Litre miktarı zorunludur.'); return; }
    if (!amount || parseFloat(amount) <= 0) { alert('Tutar zorunludur.'); return; }
    var btn = document.getElementById('fuelSaveBtn');
    btn.disabled = true; btn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Kaydediliyor...';
    $.ajax({
        url:'/asset/form/save_vehicle_fuel.cfm', method:'POST', dataType:'json',
        data:{
            asset_id:     assetId,
            fuel_date:    fdate,
            odometer_km:  document.getElementById('f_odometer_km').value,
            liters:       liters, amount: amount,
            station_name: document.getElementById('f_station_name').value,
            invoice_no:   document.getElementById('f_invoice_no').value,
            note:         document.getElementById('f_note').value
        },
        success: function(res){
            btn.disabled=false; btn.innerHTML='<i class="fas fa-save me-2"></i>Kaydet';
            if(res && res.success){ document.getElementById('fuelSaveMsg').innerHTML='<div class="alert alert-success py-2">Kayıt oluşturuldu.</div>'; setTimeout(function(){ location.reload(); },1200); }
            else{ document.getElementById('fuelSaveMsg').innerHTML='<div class="alert alert-danger py-2">'+(res.message||'Hata oluştu.')+'</div>'; }
        },
        error:function(){ btn.disabled=false; btn.innerHTML='<i class="fas fa-save me-2"></i>Kaydet'; document.getElementById('fuelSaveMsg').innerHTML='<div class="alert alert-danger py-2">Sunucu hatası.</div>'; }
    });
}

function saveSvc() {
    var assetId = document.getElementById('s_asset_id').value;
    var sdate   = document.getElementById('s_service_date').value;
    if (!assetId) { alert('Araç seçin.'); return; }
    if (!sdate)   { alert('Servis tarihi girin.'); return; }
    var btn = document.getElementById('svcSaveBtn');
    btn.disabled=true; btn.innerHTML='<i class="fas fa-spinner fa-spin me-2"></i>Kaydediliyor...';
    $.ajax({
        url:'/asset/form/save_vehicle_service.cfm', method:'POST', dataType:'json',
        data:{
            asset_id:         assetId,
            service_type:     document.getElementById('s_service_type').value,
            service_date:     sdate,
            odometer_km:      document.getElementById('s_odometer_km').value,
            labor_cost:       document.getElementById('s_labor_cost').value,
            material_cost:    document.getElementById('s_material_cost').value,
            next_service_date:document.getElementById('s_next_service_date').value,
            note:             document.getElementById('s_note').value
        },
        success: function(res){
            btn.disabled=false; btn.innerHTML='<i class="fas fa-save me-2"></i>Kaydet';
            if(res && res.success){ document.getElementById('svcSaveMsg').innerHTML='<div class="alert alert-success py-2">Servis kaydı oluşturuldu.</div>'; setTimeout(function(){ location.reload(); },1200); }
            else{ document.getElementById('svcSaveMsg').innerHTML='<div class="alert alert-danger py-2">'+(res.message||'Hata oluştu.')+'</div>'; }
        },
        error:function(){ btn.disabled=false; btn.innerHTML='<i class="fas fa-save me-2"></i>Kaydet'; document.getElementById('svcSaveMsg').innerHTML='<div class="alert alert-danger py-2">Sunucu hatası.</div>'; }
    });
}
</script>
</cfoutput>