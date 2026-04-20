<cfprocessingdirective pageEncoding="utf-8">

<cfparam name="url.qc_inspection_id" default="0">
<cfset inspId = isNumeric(url.qc_inspection_id) AND val(url.qc_inspection_id) gt 0 ? val(url.qc_inspection_id) : 0>

<cfif inspId eq 0>
    <cflocation url="index.cfm?fuseaction=quality.list_qc_inspections" addtoken="false">
</cfif>

<cfquery name="getInsp" datasource="boyahane">
    SELECT qi.*,
           COALESCE(p.product_name,'')              AS product_name,
           COALESCE(p.product_code,'')              AS product_code,
           COALESCE(sh.ship_number,'')              AS ship_number,
           COALESCE(po.p_order_no,'')               AS p_order_no,
           COALESCE(qpl.plan_name,'')               AS plan_name,
           COALESCE(sc.nickname, sc.fullname,'')    AS ship_company,
           COALESCE(poc.nickname, poc.fullname,'')  AS order_company
    FROM qc_inspections qi
    LEFT JOIN product           p   ON qi.product_id  = p.product_id
    LEFT JOIN ship             sh   ON qi.ship_id     = sh.ship_id
    LEFT JOIN company          sc   ON sh.company_id  = sc.company_id
    LEFT JOIN production_orders po  ON qi.p_order_id  = po.p_order_id
    LEFT JOIN stocks           st   ON po.stock_id    = st.stock_id
    LEFT JOIN color_info       ci   ON st.stock_id    = ci.stock_id
    LEFT JOIN company          poc  ON ci.company_id  = poc.company_id
    LEFT JOIN qc_plans         qpl  ON qi.qc_plan_id  = qpl.qc_plan_id
    WHERE qi.qc_inspection_id = <cfqueryparam value="#inspId#" cfsqltype="cf_sql_integer">
</cfquery>

<cfif NOT getInsp.recordCount>
    <cflocation url="index.cfm?fuseaction=quality.list_qc_inspections" addtoken="false">
</cfif>

<cfquery name="getResults" datasource="boyahane">
    SELECT r.qc_result_id, r.measured_value, r.text_result, r.is_pass, r.notes,
           qp.param_code, qp.param_name, qp.unit_name, qp.param_type,
           qp.min_value, qp.max_value
    FROM qc_inspection_results r
    JOIN qc_parameters qp ON r.qc_param_id = qp.qc_param_id
    WHERE r.qc_inspection_id = <cfqueryparam value="#inspId#" cfsqltype="cf_sql_integer">
    ORDER BY qp.sort_order, qp.param_name
</cfquery>

<cfquery name="getDefects" datasource="boyahane">
    SELECT d.qc_defect_id, d.defect_count, d.defect_location, d.notes,
           dt.defect_code, dt.defect_name, dt.severity
    FROM qc_inspection_defects d
    JOIN qc_defect_types dt ON d.defect_type_id = dt.defect_type_id
    WHERE d.qc_inspection_id = <cfqueryparam value="#inspId#" cfsqltype="cf_sql_integer">
    ORDER BY dt.sort_order, dt.defect_name
</cfquery>

<cfset itLabel = ""><cfset itClass = ""
><cfset resLabel = ""><cfset resClass = "">
<cfswitch expression="#getInsp.inspection_type#">
    <cfcase value="1"><cfset itLabel="Giriş Kontrol">   <cfset itClass="primary"></cfcase>
    <cfcase value="2"><cfset itLabel="Operasyon Kontrol"><cfset itClass="warning"></cfcase>
    <cfcase value="3"><cfset itLabel="Final Kontrol">   <cfset itClass="info"></cfcase>
</cfswitch>
<cfswitch expression="#getInsp.result#">
    <cfcase value="1"><cfset resLabel="Kabul">          <cfset resClass="success"></cfcase>
    <cfcase value="2"><cfset resLabel="Koşullu Kabul">  <cfset resClass="warning"></cfcase>
    <cfcase value="3"><cfset resLabel="Ret">            <cfset resClass="danger"></cfcase>
</cfswitch>

<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-microscope"></i></div>
        <div class="page-header-title">
            <h1>Muayene: #htmlEditFormat(getInsp.inspection_no)#</h1>
            <p>
                <span class="badge bg-#itClass#">#itLabel#</span>
                <span class="badge bg-#resClass# ms-1">#resLabel#</span>
            </p>
        </div>
    </div>
    <div class="d-flex gap-2">
        <a href="index.cfm?fuseaction=quality.add_qc_inspection&qc_inspection_id=#inspId#"
           class="btn btn-outline-primary"><i class="fas fa-edit me-1"></i>Düzenle</a>
        <a href="index.cfm?fuseaction=quality.list_qc_inspections"
           class="btn btn-outline-secondary"><i class="fas fa-arrow-left me-1"></i>Listeye Dön</a>
    </div>
</div>

<div class="px-3">
    <!--- Başlık Bilgileri --->
    <div class="row g-3 mb-3">
        <div class="col-md-8">
            <div class="card h-100">
                <div class="card-header fw-bold"><i class="fas fa-info-circle me-1"></i>Muayene Bilgileri</div>
                <div class="card-body">
                    <div class="row g-2">
                        <div class="col-6 col-md-3"><small class="text-muted d-block">Muayene No</small><strong>#htmlEditFormat(getInsp.inspection_no)#</strong></div>
                        <div class="col-6 col-md-3"><small class="text-muted d-block">Tip</small><span class="badge bg-#itClass#">#itLabel#</span></div>
                        <div class="col-6 col-md-3"><small class="text-muted d-block">Tarih</small>#isDate(getInsp.inspection_date) ? dateFormat(getInsp.inspection_date,"dd/mm/yyyy") & " " & timeFormat(getInsp.inspection_date,"HH:mm") : ""#</div>
                        <div class="col-6 col-md-3"><small class="text-muted d-block">Kontrolör</small>#htmlEditFormat(getInsp.inspector_name ?: '—')#</div>
                        <div class="col-6 col-md-3"><small class="text-muted d-block">Lot No</small>#htmlEditFormat(getInsp.lot_no ?: '—')#</div>
                        <div class="col-6 col-md-3"><small class="text-muted d-block">Miktar</small>#getInsp.quantity#</div>
                        <div class="col-6 col-md-3"><small class="text-muted d-block">Numune</small>#getInsp.sample_quantity#</div>
                        <div class="col-6 col-md-3"><small class="text-muted d-block">KK Planı</small>#htmlEditFormat(getInsp.plan_name ?: '—')#</div>
                        <cfif len(getInsp.ship_number)>
                        <div class="col-6 col-md-4"><small class="text-muted d-block">İrsaliye</small>
                            <a href="index.cfm?fuseaction=ship.list_ship">#htmlEditFormat(getInsp.ship_number)#</a>
                            <small class="text-muted">#htmlEditFormat(getInsp.ship_company)#</small>
                        </div>
                        </cfif>
                        <cfif len(getInsp.p_order_no)>
                        <div class="col-6 col-md-4"><small class="text-muted d-block">Üretim Emri</small>
                            <a href="index.cfm?fuseaction=production.view_production_order&p_order_id=#getInsp.p_order_id#">#htmlEditFormat(getInsp.p_order_no)#</a>
                            <small class="text-muted">#htmlEditFormat(getInsp.order_company)#</small>
                        </div>
                        </cfif>
                        <cfif len(getInsp.product_name)>
                        <div class="col-12"><small class="text-muted d-block">Ürün</small>#htmlEditFormat(getInsp.product_name)#</div>
                        </cfif>
                        <cfif len(getInsp.notes)>
                        <div class="col-12"><small class="text-muted d-block">Notlar</small>#htmlEditFormat(getInsp.notes)#</div>
                        </cfif>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-md-4">
            <div class="card h-100 border-#resClass#">
                <div class="card-body d-flex flex-column align-items-center justify-content-center text-center">
                    <cfswitch expression="#resClass#">
                        <cfcase value="success"><i class="fas fa-check-circle text-success" style="font-size:4rem"></i></cfcase>
                        <cfcase value="warning"><i class="fas fa-exclamation-circle text-warning" style="font-size:4rem"></i></cfcase>
                        <cfdefaultcase><i class="fas fa-times-circle text-danger" style="font-size:4rem"></i></cfdefaultcase>
                    </cfswitch>
                    <h2 class="mt-3 text-#resClass#">#resLabel#</h2>
                    <p class="text-muted mb-0">Genel Muayene Sonucu</p>
                    <div class="mt-2">
                        <span class="badge bg-#resClass# fs-6 px-3 py-2">#resLabel#</span>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!--- Ölçüm Sonuçları --->
    <cfif getResults.recordCount gt 0>
    <div class="card mb-3">
        <div class="card-header fw-bold"><i class="fas fa-ruler me-1"></i>Ölçüm Sonuçları (#getResults.recordCount# parametre)</div>
        <div class="card-body p-0">
            <table class="table table-sm table-hover mb-0">
                <thead class="table-light">
                    <tr>
                        <th>Parametre</th>
                        <th>Ölçülen Değer</th>
                        <th>Hedef Aralık</th>
                        <th>Durum</th>
                        <th>Not</th>
                    </tr>
                </thead>
                <tbody>
                    <cfloop query="getResults">
                    <tr class="#NOT is_pass ? 'table-danger' : ''#">
                        <td>
                            <strong>#htmlEditFormat(param_code)#</strong> — #htmlEditFormat(param_name)#
                            <cfif len(unit_name)><small class="text-muted">(#htmlEditFormat(unit_name)#)</small></cfif>
                        </td>
                        <td>
                            <cfif param_type eq 1>
                                <strong>#measured_value#</strong> <cfif len(unit_name)><small>#htmlEditFormat(unit_name)#</small></cfif>
                            <cfelse>
                                #htmlEditFormat(text_result ?: '—')#
                            </cfif>
                        </td>
                        <td>
                            <cfif param_type eq 1>
                                <cfif isNumeric(min_value) OR isNumeric(max_value)>
                                    <cfif isNumeric(min_value)>Min: #min_value#</cfif>
                                    <cfif isNumeric(max_value)> Max: #max_value#</cfif>
                                <cfelse>—</cfif>
                            <cfelse>Geçti/Kaldı</cfif>
                        </td>
                        <td>
                            <cfif is_pass>
                                <span class="badge bg-success"><i class="fas fa-check me-1"></i>Geçti</span>
                            <cfelse>
                                <span class="badge bg-danger"><i class="fas fa-times me-1"></i>Kaldı</span>
                            </cfif>
                        </td>
                        <td><small>#htmlEditFormat(notes ?: '')#</small></td>
                    </tr>
                    </cfloop>
                </tbody>
            </table>
        </div>
    </div>
    </cfif>

    <!--- Tespit Edilen Hatalar --->
    <cfif getDefects.recordCount gt 0>
    <div class="card mb-3">
        <div class="card-header fw-bold"><i class="fas fa-bug me-1"></i>Tespit Edilen Hatalar (#getDefects.recordCount# tip)</div>
        <div class="card-body p-0">
            <table class="table table-sm table-hover mb-0">
                <thead class="table-light">
                    <tr>
                        <th>Hata Tipi</th>
                        <th>Ağırlık</th>
                        <th>Adet</th>
                        <th>Konum</th>
                        <th>Not</th>
                    </tr>
                </thead>
                <tbody>
                    <cfloop query="getDefects">
                    <cfset sevCls = severity eq 4 ? 'danger' : (severity eq 3 ? 'warning' : (severity eq 2 ? 'secondary' : 'info'))>
                    <cfset sevLbl = severity eq 4 ? 'Kritik'  : (severity eq 3 ? 'Ciddi'   : (severity eq 2 ? 'Orta'      : 'Hafif'))>
                    <tr>
                        <td><strong>#htmlEditFormat(defect_code)#</strong> — #htmlEditFormat(defect_name)#</td>
                        <td><span class="badge bg-#sevCls#">#sevLbl#</span></td>
                        <td>#defect_count#</td>
                        <td>#htmlEditFormat(defect_location ?: '—')#</td>
                        <td><small>#htmlEditFormat(notes ?: '')#</small></td>
                    </tr>
                    </cfloop>
                </tbody>
            </table>
        </div>
    </div>
    </cfif>
</div>
</cfoutput>
