<cfprocessingdirective pageEncoding="utf-8">

<!--- Tüm departmanları getir --->
<cfquery name="getDepts" datasource="boyahane">
    SELECT department_id, department_head, department_detail,
           department_status, is_production, is_store,
           hierarchy, level_no, special_code, department_cat,
           record_date, update_date
    FROM department
    ORDER BY hierarchy, department_head
</cfquery>

<!--- Tüm lokasyonları getir --->
<cfquery name="getLocs" datasource="boyahane">
    SELECT sl.id, sl.location_id, sl.department_id,
           sl.department_location, sl.comment,
           sl.width, sl.height, sl.depth,
           sl.no_sale, sl.priority, sl.status,
           sl.location_type, sl.delivery,
           sl.is_quality, sl.is_scrap, sl.is_cost_action,
           sl.is_end_of_series, sl.temperature, sl.pressure
    FROM stocks_location sl
    ORDER BY sl.department_id, sl.location_id
</cfquery>

<!--- JSON'a çevir --->
<cfset deptArray = []>
<cfloop query="getDepts">
    <cfset arrayAppend(deptArray, {
        "department_id"     = department_id,
        "department_head"   = department_head ?: "",
        "department_detail" = department_detail ?: "",
        "department_status" = department_status,
        "is_production"     = is_production,
        "is_store"          = is_store ?: 0,
        "hierarchy"         = hierarchy ?: "",
        "level_no"          = level_no ?: 0,
        "special_code"      = special_code ?: "",
        "department_cat"    = department_cat ?: 0,
        "record_date"       = isDate(record_date) ? dateFormat(record_date,"dd/mm/yyyy") & " " & timeFormat(record_date,"HH:mm") : "",
        "update_date"       = isDate(update_date) ? dateFormat(update_date,"dd/mm/yyyy") & " " & timeFormat(update_date,"HH:mm") : ""
    })>
</cfloop>

<cfset locArray = []>
<cfloop query="getLocs">
    <cfset arrayAppend(locArray, {
        "id"                 = id,
        "location_id"        = location_id,
        "department_id"      = department_id,
        "department_location"= department_location ?: "",
        "comment"            = comment ?: "",
        "width"              = width ?: 0,
        "height"             = height ?: 0,
        "depth"              = depth ?: 0,
        "no_sale"            = no_sale,
        "priority"           = priority,
        "status"             = status,
        "location_type"      = location_type ?: 0,
        "delivery"           = delivery,
        "is_quality"         = is_quality,
        "is_scrap"           = is_scrap,
        "is_cost_action"     = is_cost_action,
        "is_end_of_series"   = is_end_of_series,
        "temperature"        = temperature ?: 0,
        "pressure"           = pressure ?: 0
    })>
</cfloop>

<!--- Modal'lar body'e taşınacak, burada sadece sayfa yapısı geliyor --->

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon">
            <i class="fas fa-sitemap"></i>
        </div>
        <div class="page-header-title">
            <h1>Departman &amp; Lokasyon</h1>
            <p>Departman ve lokasyonları ağaç görünümünde yönetin</p>
        </div>
    </div>
    <button class="btn-add" onclick="showDeptModal(null)">
        <i class="fas fa-plus"></i>Yeni Departman
    </button>
</div>

<div class="px-3 pb-4">
    <div class="dept-tree-layout">

        <!--- ══════════════════════════════ --->
        <!--- SOL: TREE PANEL               --->
        <!--- ══════════════════════════════ --->
        <div class="tree-panel">
            <div class="tree-panel-header">
                <span><i class="fas fa-project-diagram me-2"></i>Ağaç Görünümü</span>
                <span class="badge bg-secondary" id="deptCount">-</span>
            </div>
            <div class="tree-search-wrap">
                <input type="text" id="treeSearch" placeholder="Departman veya lokasyon ara..."
                       class="form-control form-control-sm">
            </div>
            <div class="tree-body" id="treeBody">
                <div class="tree-empty">
                    <i class="fas fa-spinner fa-spin"></i> Yükleniyor...
                </div>
            </div>
        </div>

        <!--- ══════════════════════════════ --->
        <!--- SAĞ: FORM PANEL               --->
        <!--- ══════════════════════════════ --->
        <div class="form-panel" id="formPanel">
            <!--- Boş durum --->
            <div id="panelEmpty" class="panel-empty-state">
                <i class="fas fa-hand-pointer fa-3x mb-3 opacity-25"></i>
                <p class="text-muted">Soldan bir departman veya lokasyon seçin,<br>ya da yeni departman ekleyin.</p>
            </div>

            <!--- DEPARTMAN FORMU --->
            <div id="panelDept" style="display:none" class="p-3">
                <div class="panel-form-header">
                    <div id="deptFormTitle" class="panel-form-title">
                        <i class="fas fa-building me-2 text-primary"></i>Departman
                    </div>
                    <div class="d-flex gap-2">
                        <button class="btn btn-sm btn-success" onclick="showLocModal(null, currentDeptId)">
                            <i class="fas fa-plus me-1"></i>Lokasyon Ekle
                        </button>
                        <button class="btn btn-sm btn-outline-danger" onclick="deleteDept(currentDeptId)">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </div>
                <div class="row g-3 mt-1">
                    <div class="col-12">
                        <label class="form-label fw-semibold">Departman Adı <span class="text-danger">*</span></label>
                        <input type="text" class="form-control" id="deptName" placeholder="Departman adı">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Hiyerarşi Kodu</label>
                        <input type="text" class="form-control" id="deptHierarchy" placeholder="Örn: 01, 01.01">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Özel Kod</label>
                        <input type="text" class="form-control" id="deptSpecialCode" placeholder="Özel kod">
                    </div>
                    <div class="col-12">
                        <label class="form-label fw-semibold">Açıklama</label>
                        <textarea class="form-control" id="deptDetail" rows="2" placeholder="Detay bilgi"></textarea>
                    </div>
                    <div class="col-md-4">
                        <div class="form-check form-switch mt-2">
                            <input class="form-check-input" type="checkbox" id="deptStatus">
                            <label class="form-check-label" for="deptStatus">Aktif</label>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="form-check form-switch mt-2">
                            <input class="form-check-input" type="checkbox" id="deptIsProduction">
                            <label class="form-check-label" for="deptIsProduction">Üretim</label>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="form-check form-switch mt-2">
                            <input class="form-check-input" type="checkbox" id="deptIsStore">
                            <label class="form-check-label" for="deptIsStore">Depo</label>
                        </div>
                    </div>
                    <div class="col-12">
                        <button class="btn btn-primary w-100" onclick="saveDept()">
                            <i class="fas fa-save me-2"></i>Kaydet
                        </button>
                    </div>
                </div>

                <!--- Departmana bağlı lokasyonlar mini liste --->
                <div class="mt-4" id="deptLocList"></div>
            </div>

            <!--- LOKASYON FORMU --->
            <div id="panelLoc" style="display:none" class="p-3">
                <div class="panel-form-header">
                    <div id="locFormTitle" class="panel-form-title">
                        <i class="fas fa-map-marker-alt me-2 text-success"></i>Lokasyon
                    </div>
                    <button class="btn btn-sm btn-outline-danger" onclick="deleteLoc(currentLocId)">
                        <i class="fas fa-trash"></i>
                    </button>
                </div>
                <div class="row g-3 mt-1">
                    <div class="col-12">
                        <label class="form-label fw-semibold">Lokasyon Adı <span class="text-danger">*</span></label>
                        <input type="text" class="form-control" id="locName" placeholder="Lokasyon açıklaması">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Lokasyon ID</label>
                        <input type="number" class="form-control" id="locLocationId" placeholder="0">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Açıklama</label>
                        <input type="text" class="form-control" id="locComment" placeholder="Yorum">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">En (m)</label>
                        <input type="number" class="form-control" id="locWidth" step="0.01" placeholder="0.00">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Boy (m)</label>
                        <input type="number" class="form-control" id="locHeight" step="0.01" placeholder="0.00">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Derinlik (m)</label>
                        <input type="number" class="form-control" id="locDepth" step="0.01" placeholder="0.00">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Sıcaklık (°C)</label>
                        <input type="number" class="form-control" id="locTemp" step="0.1" placeholder="0.0">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Basınç</label>
                        <input type="number" class="form-control" id="locPressure" step="0.1" placeholder="0.0">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Tip</label>
                        <input type="number" class="form-control" id="locType" placeholder="0">
                    </div>

                    <div class="col-12">
                        <div class="row g-2">
                            <div class="col-6 col-md-4">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" id="locStatus">
                                    <label class="form-check-label" for="locStatus">Aktif</label>
                                </div>
                            </div>
                            <div class="col-6 col-md-4">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" id="locNoSale">
                                    <label class="form-check-label" for="locNoSale">Satışa Kapalı</label>
                                </div>
                            </div>
                            <div class="col-6 col-md-4">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" id="locPriority">
                                    <label class="form-check-label" for="locPriority">Öncelikli</label>
                                </div>
                            </div>
                            <div class="col-6 col-md-4">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" id="locDelivery">
                                    <label class="form-check-label" for="locDelivery">Teslimat</label>
                                </div>
                            </div>
                            <div class="col-6 col-md-4">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" id="locQuality">
                                    <label class="form-check-label" for="locQuality">Kalite Kontrol</label>
                                </div>
                            </div>
                            <div class="col-6 col-md-4">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" id="locScrap">
                                    <label class="form-check-label" for="locScrap">Hurda</label>
                                </div>
                            </div>
                            <div class="col-6 col-md-4">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" id="locCostAction">
                                    <label class="form-check-label" for="locCostAction">Maliyet Hareketi</label>
                                </div>
                            </div>
                            <div class="col-6 col-md-4">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" id="locEndOfSeries">
                                    <label class="form-check-label" for="locEndOfSeries">Seri Sonu</label>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col-12">
                        <button class="btn btn-success w-100" onclick="saveLoc()">
                            <i class="fas fa-save me-2"></i>Kaydet
                        </button>
                    </div>
                </div>
            </div>
        </div>

    </div><!--- /dept-tree-layout --->
</div>

<!--- ══════════════════════════════════════════════════ --->
<!--- MODAL: Hızlı Departman Ekle                      --->
<!--- ══════════════════════════════════════════════════ --->
<div class="modal fade" id="deptModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header bg-primary text-white">
                <h5 class="modal-title"><i class="fas fa-building me-2"></i><span id="deptModalTitle">Yeni Departman</span></h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <div class="mb-3">
                    <label class="form-label fw-semibold">Departman Adı <span class="text-danger">*</span></label>
                    <input type="text" class="form-control" id="mdDeptName" placeholder="Departman adı">
                </div>
                <div class="row g-3">
                    <div class="col-6">
                        <label class="form-label fw-semibold">Hiyerarşi</label>
                        <input type="text" class="form-control" id="mdDeptHierarchy" placeholder="01, 01.01 ...">
                    </div>
                    <div class="col-6">
                        <label class="form-label fw-semibold">Özel Kod</label>
                        <input type="text" class="form-control" id="mdDeptSpecialCode">
                    </div>
                    <div class="col-12">
                        <label class="form-label fw-semibold">Açıklama</label>
                        <textarea class="form-control" id="mdDeptDetail" rows="2"></textarea>
                    </div>
                    <div class="col-4">
                        <div class="form-check form-switch mt-2">
                            <input class="form-check-input" type="checkbox" id="mdDeptStatus" checked>
                            <label class="form-check-label" for="mdDeptStatus">Aktif</label>
                        </div>
                    </div>
                    <div class="col-4">
                        <div class="form-check form-switch mt-2">
                            <input class="form-check-input" type="checkbox" id="mdDeptIsProduction">
                            <label class="form-check-label" for="mdDeptIsProduction">Üretim</label>
                        </div>
                    </div>
                    <div class="col-4">
                        <div class="form-check form-switch mt-2">
                            <input class="form-check-input" type="checkbox" id="mdDeptIsStore">
                            <label class="form-check-label" for="mdDeptIsStore">Depo</label>
                        </div>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-secondary" data-bs-dismiss="modal">İptal</button>
                <button class="btn btn-primary" onclick="saveDeptModal()">
                    <i class="fas fa-save me-1"></i>Kaydet
                </button>
            </div>
        </div>
    </div>
</div>

<!--- ══════════════════════════════════════════════════ --->
<!--- MODAL: Lokasyon Ekle / Düzenle                   --->
<!--- ══════════════════════════════════════════════════ --->
<div class="modal fade" id="locModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header bg-success text-white">
                <h5 class="modal-title"><i class="fas fa-map-marker-alt me-2"></i><span id="locModalTitle">Yeni Lokasyon</span></h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <input type="hidden" id="mdLocId">
                <input type="hidden" id="mdLocDeptId">
                <div class="row g-3">
                    <div class="col-md-8">
                        <label class="form-label fw-semibold">Lokasyon Adı <span class="text-danger">*</span></label>
                        <input type="text" class="form-control" id="mdLocName" placeholder="Lokasyon açıklaması">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Lokasyon ID</label>
                        <input type="number" class="form-control" id="mdLocLocationId" placeholder="0">
                    </div>
                    <div class="col-12">
                        <label class="form-label fw-semibold">Yorum</label>
                        <input type="text" class="form-control" id="mdLocComment" placeholder="Yorum">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">En (m)</label>
                        <input type="number" class="form-control" id="mdLocWidth" step="0.01" placeholder="0.00">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Boy (m)</label>
                        <input type="number" class="form-control" id="mdLocHeight" step="0.01" placeholder="0.00">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Derinlik (m)</label>
                        <input type="number" class="form-control" id="mdLocDepth" step="0.01" placeholder="0.00">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Tip</label>
                        <input type="number" class="form-control" id="mdLocType" placeholder="0">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Sıcaklık (°C)</label>
                        <input type="number" class="form-control" id="mdLocTemp" step="0.1" placeholder="0.0">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Basınç</label>
                        <input type="number" class="form-control" id="mdLocPressure" step="0.1" placeholder="0.0">
                    </div>

                    <div class="col-12">
                        <div class="row g-2 border rounded p-2 mx-0">
                            <div class="col-12 fw-semibold mb-1 text-muted" style="font-size:.8rem">SEÇENEKLER</div>
                            <div class="col-6 col-md-3">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" id="mdLocStatus" checked>
                                    <label class="form-check-label" for="mdLocStatus">Aktif</label>
                                </div>
                            </div>
                            <div class="col-6 col-md-3">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" id="mdLocNoSale">
                                    <label class="form-check-label" for="mdLocNoSale">Satışa Kapalı</label>
                                </div>
                            </div>
                            <div class="col-6 col-md-3">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" id="mdLocPriority">
                                    <label class="form-check-label" for="mdLocPriority">Öncelikli</label>
                                </div>
                            </div>
                            <div class="col-6 col-md-3">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" id="mdLocDelivery">
                                    <label class="form-check-label" for="mdLocDelivery">Teslimat</label>
                                </div>
                            </div>
                            <div class="col-6 col-md-3">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" id="mdLocQuality">
                                    <label class="form-check-label" for="mdLocQuality">Kalite Kontrol</label>
                                </div>
                            </div>
                            <div class="col-6 col-md-3">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" id="mdLocScrap">
                                    <label class="form-check-label" for="mdLocScrap">Hurda</label>
                                </div>
                            </div>
                            <div class="col-6 col-md-3">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" id="mdLocCostAction">
                                    <label class="form-check-label" for="mdLocCostAction">Maliyet Hareketi</label>
                                </div>
                            </div>
                            <div class="col-6 col-md-3">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" id="mdLocEndOfSeries">
                                    <label class="form-check-label" for="mdLocEndOfSeries">Seri Sonu</label>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-secondary" data-bs-dismiss="modal">İptal</button>
                <button class="btn btn-success" onclick="saveLocModal()">
                    <i class="fas fa-save me-1"></i>Kaydet
                </button>
            </div>
        </div>
    </div>
</div>

<cfoutput>
<style>
/* ══ Layout ══ */
.dept-tree-layout {
    display: flex;
    gap: 16px;
    min-height: calc(100vh - 200px);
}

/* ══ Tree paneli ══ */
.tree-panel {
    width: 320px;
    flex-shrink: 0;
    background: ##fff;
    border-radius: 12px;
    border: 1px solid ##e2e8f0;
    box-shadow: 0 1px 6px rgba(0,0,0,.07);
    display: flex;
    flex-direction: column;
    overflow: hidden;
}
.tree-panel-header {
    background: linear-gradient(135deg,##1a3a5c,##2563ab);
    color: ##fff;
    padding: 12px 16px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    font-weight: 600;
    font-size: .9rem;
    flex-shrink: 0;
}
.tree-search-wrap {
    padding: 10px 12px;
    border-bottom: 1px solid ##e9ecef;
    flex-shrink: 0;
}
.tree-body {
    flex: 1;
    overflow-y: auto;
    padding: 8px 0;
}
.tree-empty {
    text-align: center;
    color: ##adb5bd;
    padding: 40px 16px;
    font-size: .875rem;
}

/* ══ Tree node'lar ══ */
.tree-dept {
    border-bottom: 1px solid ##f0f0f0;
}
.tree-dept-row {
    display: flex;
    align-items: center;
    padding: 9px 12px;
    cursor: pointer;
    user-select: none;
    gap: 6px;
    transition: background .15s;
}
.tree-dept-row:hover { background: ##f0f6ff; }
.tree-dept-row.active { background: ##dbeafe; border-left: 3px solid ##2563ab; }
.tree-dept-toggle {
    width: 18px;
    text-align: center;
    color: ##6c757d;
    font-size: .75rem;
    flex-shrink: 0;
    transition: transform .2s;
}
.tree-dept-toggle.open { transform: rotate(90deg); }
.tree-dept-icon { color: ##2563ab; font-size: .95rem; flex-shrink: 0; }
.tree-dept-name { flex: 1; font-size: .875rem; font-weight: 600; color: ##212529; }
.tree-dept-badge {
    font-size: .7rem;
    padding: 2px 6px;
    border-radius: 12px;
    background: ##e9ecef;
    color: ##6c757d;
    flex-shrink: 0;
}
.tree-dept-add {
    display: none;
    background: none;
    border: none;
    color: ##22c55e;
    font-size: .8rem;
    cursor: pointer;
    padding: 2px 4px;
    border-radius: 4px;
    flex-shrink: 0;
}
.tree-dept-row:hover .tree-dept-add { display: inline-flex; }
.tree-dept-add:hover { background: ##dcfce7; }

/* ══ Lokasyon node'lar ══ */
.tree-locs {
    display: none;
    background: ##f8fafc;
}
.tree-locs.open { display: block; }
.tree-loc-row {
    display: flex;
    align-items: center;
    padding: 7px 12px 7px 38px;
    cursor: pointer;
    gap: 6px;
    transition: background .15s;
    border-left: 2px solid transparent;
}
.tree-loc-row:hover { background: ##f0fdf4; }
.tree-loc-row.active { background: ##dcfce7; border-left-color: ##22c55e; }
.tree-loc-icon { color: ##22c55e; font-size: .85rem; flex-shrink: 0; }
.tree-loc-name { flex: 1; font-size: .82rem; color: ##374151; }
.tree-loc-status {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    flex-shrink: 0;
}
.tree-no-loc {
    padding: 6px 12px 6px 38px;
    font-size: .78rem;
    color: ##adb5bd;
    font-style: italic;
}

/* ══ Sağ form paneli ══ */
.form-panel {
    flex: 1;
    background: ##fff;
    border-radius: 12px;
    border: 1px solid ##e2e8f0;
    box-shadow: 0 1px 6px rgba(0,0,0,.07);
    overflow-y: auto;
}
.panel-empty-state {
    height: 100%;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    color: ##adb5bd;
    text-align: center;
    padding: 40px;
}
.panel-form-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding-bottom: 12px;
    border-bottom: 2px solid ##e9ecef;
    margin-bottom: 8px;
}
.panel-form-title {
    font-size: 1.1rem;
    font-weight: 700;
    color: ##1a3a5c;
}

/* ══ Mini lokasyon listesi ══ */
.mini-loc-item {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 7px 10px;
    border: 1px solid ##e9ecef;
    border-radius: 7px;
    margin-bottom: 6px;
    cursor: pointer;
    transition: background .15s;
}
.mini-loc-item:hover { background: ##f0fdf4; border-color: ##22c55e; }
.mini-loc-item .mini-loc-name { flex: 1; font-size: .85rem; }
.mini-loc-item .mini-loc-edit { color: ##6c757d; font-size: .8rem; }

/* ══ Responsive ══ */
@media(max-width:768px){
    .dept-tree-layout { flex-direction: column; }
    .tree-panel { width: 100%; max-height: 320px; }
}
</style>

<script>
var allDepts = #serializeJSON(deptArray)#;
var allLocs  = #serializeJSON(locArray)#;

var currentDeptId = null;
var currentLocId  = null;
var modalDeptId   = null; // modal'daki mevcut dept id (güncelleme için)

/* ══════════════════════════════════════
   BAŞLANGIÇ
══════════════════════════════════════ */
window.addEventListener('load', function() {
    // Modal'ları body'e taşı (overflow stacking context fix)
    ['deptModal','locModal'].forEach(function(id){
        var el = document.getElementById(id);
        if (el && el.parentNode !== document.body) document.body.appendChild(el);
    });

    buildTree(allDepts, allLocs);

    document.getElementById('deptCount').textContent = allDepts.length + ' dept';

    document.getElementById('treeSearch').addEventListener('input', function(){
        var term = this.value.toLowerCase();
        filterTree(term);
    });
});

/* ══════════════════════════════════════
   TREE OLUŞTUR
══════════════════════════════════════ */
function buildTree(depts, locs) {
    var container = document.getElementById('treeBody');
    container.innerHTML = '';

    if (!depts.length) {
        container.innerHTML = '<div class="tree-empty"><i class="fas fa-building me-2"></i>Henüz departman yok.</div>';
        return;
    }

    depts.forEach(function(dept) {
        var deptLocs = locs.filter(function(l){ return l.department_id == dept.department_id; });

        var deptDiv = document.createElement('div');
        deptDiv.className = 'tree-dept';
        deptDiv.dataset.deptId = dept.department_id;

        var statusDot = dept.department_status
            ? '<span style="width:8px;height:8px;border-radius:50%;background:##22c55e;display:inline-block;margin-left:2px;" title="Aktif"></span>'
            : '<span style="width:8px;height:8px;border-radius:50%;background:##adb5bd;display:inline-block;margin-left:2px;" title="Pasif"></span>';

        var icons = '';
        if (dept.is_production) icons += ' <i class="fas fa-cog" title="Üretim" style="font-size:.7rem;color:##f59e0b"></i>';
        if (dept.is_store)      icons += ' <i class="fas fa-warehouse" title="Depo" style="font-size:.7rem;color:##6366f1"></i>';

        deptDiv.innerHTML =
            '<div class="tree-dept-row" onclick="toggleDept(this, ' + dept.department_id + ')">' +
                '<span class="tree-dept-toggle"><i class="fas fa-chevron-right"></i></span>' +
                '<span class="tree-dept-icon"><i class="fas fa-building"></i></span>' +
                '<span class="tree-dept-name">' + escHtml(dept.department_head) + icons + '</span>' +
                statusDot +
                '<span class="tree-dept-badge">' + deptLocs.length + '</span>' +
                '<button class="tree-dept-add" title="Lokasyon ekle" onclick="event.stopPropagation();showLocModal(null,' + dept.department_id + ')">' +
                    '<i class="fas fa-plus-circle"></i>' +
                '</button>' +
            '</div>' +
            '<div class="tree-locs" id="locs-' + dept.department_id + '">' +
                buildLocNodes(deptLocs, dept.department_id) +
            '</div>';

        container.appendChild(deptDiv);
    });
}

function buildLocNodes(locs, deptId) {
    if (!locs.length) {
        return '<div class="tree-no-loc"><i class="fas fa-inbox me-1"></i>Lokasyon yok</div>';
    }
    return locs.map(function(loc) {
        var dotColor = loc.status ? '##22c55e' : '##adb5bd';
        return '<div class="tree-loc-row" id="loc-row-' + loc.id + '" ' +
                   'onclick="selectLoc(' + loc.id + ',' + deptId + ')">' +
                   '<span class="tree-loc-icon"><i class="fas fa-map-marker-alt"></i></span>' +
                   '<span class="tree-loc-name">' + escHtml(loc.department_location || ('Lokasyon ##' + loc.location_id)) + '</span>' +
                   '<span class="tree-loc-status" style="background:' + dotColor + ';" title="' + (loc.status ? 'Aktif' : 'Pasif') + '"></span>' +
               '</div>';
    }).join('');
}

/* ══════════════════════════════════════
   TREE TOGGLE & SEÇİM
══════════════════════════════════════ */
function toggleDept(rowEl, deptId) {
    var locsDiv  = document.getElementById('locs-' + deptId);
    var toggle   = rowEl.querySelector('.tree-dept-toggle i');
    var isOpen   = locsDiv.classList.contains('open');

    if (isOpen) {
        locsDiv.classList.remove('open');
        toggle.style.transform = '';
    } else {
        locsDiv.classList.add('open');
        toggle.style.transform = 'rotate(90deg)';
    }

    // Sağ panelde departman formunu göster
    selectDept(deptId, rowEl);
}

function selectDept(deptId, rowEl) {
    // Aktif sınıfını temizle
    document.querySelectorAll('.tree-dept-row').forEach(function(r){ r.classList.remove('active'); });
    document.querySelectorAll('.tree-loc-row').forEach(function(r){ r.classList.remove('active'); });
    if (rowEl) rowEl.classList.add('active');

    currentDeptId = deptId;
    currentLocId  = null;

    var dept = allDepts.find(function(d){ return d.department_id == deptId; });
    if (!dept) return;

    // Formu doldur
    document.getElementById('deptFormTitle').innerHTML =
        '<i class="fas fa-building me-2 text-primary"></i>' + escHtml(dept.department_head);
    document.getElementById('deptName').value = dept.department_head;
    document.getElementById('deptHierarchy').value = dept.hierarchy;
    document.getElementById('deptSpecialCode').value = dept.special_code;
    document.getElementById('deptDetail').value = dept.department_detail;
    document.getElementById('deptStatus').checked = dept.department_status;
    document.getElementById('deptIsProduction').checked = dept.is_production;
    document.getElementById('deptIsStore').checked = dept.is_store == 1;

    // Mini lokasyon listesi
    renderDeptLocList(deptId);

    showPanel('dept');
}

function selectLoc(locId, deptId) {
    document.querySelectorAll('.tree-dept-row').forEach(function(r){ r.classList.remove('active'); });
    document.querySelectorAll('.tree-loc-row').forEach(function(r){ r.classList.remove('active'); });
    var locRow = document.getElementById('loc-row-' + locId);
    if (locRow) locRow.classList.add('active');

    currentLocId  = locId;
    currentDeptId = deptId;

    var loc = allLocs.find(function(l){ return l.id == locId; });
    if (!loc) return;

    document.getElementById('locFormTitle').innerHTML =
        '<i class="fas fa-map-marker-alt me-2 text-success"></i>' +
        escHtml(loc.department_location || ('Lokasyon ##' + loc.location_id));

    document.getElementById('locName').value        = loc.department_location;
    document.getElementById('locLocationId').value  = loc.location_id;
    document.getElementById('locComment').value     = loc.comment;
    document.getElementById('locWidth').value       = loc.width;
    document.getElementById('locHeight').value      = loc.height;
    document.getElementById('locDepth').value       = loc.depth;
    document.getElementById('locTemp').value        = loc.temperature;
    document.getElementById('locPressure').value    = loc.pressure;
    document.getElementById('locType').value        = loc.location_type;
    document.getElementById('locStatus').checked    = loc.status;
    document.getElementById('locNoSale').checked    = loc.no_sale;
    document.getElementById('locPriority').checked  = loc.priority;
    document.getElementById('locDelivery').checked  = loc.delivery;
    document.getElementById('locQuality').checked   = loc.is_quality;
    document.getElementById('locScrap').checked     = loc.is_scrap;
    document.getElementById('locCostAction').checked   = loc.is_cost_action;
    document.getElementById('locEndOfSeries').checked  = loc.is_end_of_series;

    showPanel('loc');
}

function renderDeptLocList(deptId) {
    var deptLocs = allLocs.filter(function(l){ return l.department_id == deptId; });
    var container = document.getElementById('deptLocList');
    if (!deptLocs.length) {
        container.innerHTML = '<div class="text-muted small"><i class="fas fa-inbox me-1"></i>Bu departmana bağlı lokasyon yok.</div>';
        return;
    }
    var html = '<div class="fw-semibold small text-muted mb-2"><i class="fas fa-map-marker-alt me-1"></i>LOKASYONLAR (' + deptLocs.length + ')</div>';
    deptLocs.forEach(function(loc) {
        html += '<div class="mini-loc-item" onclick="selectLoc(' + loc.id + ',' + deptId + ')">' +
            '<i class="fas fa-map-marker-alt text-success"></i>' +
            '<span class="mini-loc-name">' + escHtml(loc.department_location || ('##' + loc.location_id)) + '</span>' +
            '<span class="' + (loc.status ? 'text-success' : 'text-muted') + '">' +
                '<i class="fas fa-circle" style="font-size:.5rem"></i>' +
            '</span>' +
            '<span class="mini-loc-edit"><i class="fas fa-chevron-right"></i></span>' +
        '</div>';
    });
    container.innerHTML = html;
}

function showPanel(which) {
    document.getElementById('panelEmpty').style.display = 'none';
    document.getElementById('panelDept').style.display  = which === 'dept' ? '' : 'none';
    document.getElementById('panelLoc').style.display   = which === 'loc'  ? '' : 'none';
}

/* ══════════════════════════════════════
   TREE ARA
══════════════════════════════════════ */
function filterTree(term) {
    document.querySelectorAll('.tree-dept').forEach(function(deptDiv) {
        var deptRow  = deptDiv.querySelector('.tree-dept-row');
        var deptName = deptRow.querySelector('.tree-dept-name').textContent.toLowerCase();
        var locsDiv  = deptDiv.querySelector('.tree-locs');
        var locRows  = locsDiv.querySelectorAll('.tree-loc-row');
        var locMatch = false;

        locRows.forEach(function(lr) {
            var locName = lr.querySelector('.tree-loc-name').textContent.toLowerCase();
            if (!term || locName.includes(term)) {
                lr.style.display = '';
                locMatch = true;
            } else {
                lr.style.display = 'none';
            }
        });

        var deptMatch = !term || deptName.includes(term);
        deptDiv.style.display = (deptMatch || locMatch) ? '' : 'none';

        if (term && locMatch) {
            locsDiv.classList.add('open');
            var toggle = deptRow.querySelector('.tree-dept-toggle i');
            if (toggle) toggle.style.transform = 'rotate(90deg)';
        }
    });
}

/* ══════════════════════════════════════
   DEPARTMAN MODAL
══════════════════════════════════════ */
function showDeptModal(deptId) {
    modalDeptId = deptId;
    if (deptId) {
        var dept = allDepts.find(function(d){ return d.department_id == deptId; });
        document.getElementById('deptModalTitle').textContent = 'Departman Düzenle';
        document.getElementById('mdDeptName').value = dept.department_head;
        document.getElementById('mdDeptHierarchy').value = dept.hierarchy;
        document.getElementById('mdDeptSpecialCode').value = dept.special_code;
        document.getElementById('mdDeptDetail').value = dept.department_detail;
        document.getElementById('mdDeptStatus').checked = dept.department_status;
        document.getElementById('mdDeptIsProduction').checked = dept.is_production;
        document.getElementById('mdDeptIsStore').checked = dept.is_store == 1;
    } else {
        document.getElementById('deptModalTitle').textContent = 'Yeni Departman';
        document.getElementById('mdDeptName').value = '';
        document.getElementById('mdDeptHierarchy').value = '';
        document.getElementById('mdDeptSpecialCode').value = '';
        document.getElementById('mdDeptDetail').value = '';
        document.getElementById('mdDeptStatus').checked = true;
        document.getElementById('mdDeptIsProduction').checked = false;
        document.getElementById('mdDeptIsStore').checked = false;
    }
    bootstrap.Modal.getOrCreateInstance(document.getElementById('deptModal')).show();
}

function saveDeptModal() {
    var name = document.getElementById('mdDeptName').value.trim();
    if (!name) { alert('Departman adı zorunludur.'); return; }

    var payload = {
        department_id:     modalDeptId || 0,
        department_head:   name,
        hierarchy:         document.getElementById('mdDeptHierarchy').value,
        special_code:      document.getElementById('mdDeptSpecialCode').value,
        department_detail: document.getElementById('mdDeptDetail').value,
        department_status: document.getElementById('mdDeptStatus').checked ? 1 : 0,
        is_production:     document.getElementById('mdDeptIsProduction').checked ? 1 : 0,
        is_store:          document.getElementById('mdDeptIsStore').checked ? 1 : 0
    };

    $.post('department/form/save_department.cfm', payload, function(resp) {
        try {
            var r = (typeof resp === 'string') ? JSON.parse(resp) : resp;
            if (r.success) {
                bootstrap.Modal.getInstance(document.getElementById('deptModal')).hide();
                location.reload();
            } else {
                alert('Hata: ' + (r.message || 'Kaydetme başarısız.'));
            }
        } catch(e) { alert('Sunucu hatası.'); }
    });
}

/* ══════════════════════════════════════
   SAĞ PANEL DEPARTMAN KAYDET
══════════════════════════════════════ */
function saveDept() {
    var name = document.getElementById('deptName').value.trim();
    if (!name) { alert('Departman adı zorunludur.'); return; }

    var payload = {
        department_id:     currentDeptId || 0,
        department_head:   name,
        hierarchy:         document.getElementById('deptHierarchy').value,
        special_code:      document.getElementById('deptSpecialCode').value,
        department_detail: document.getElementById('deptDetail').value,
        department_status: document.getElementById('deptStatus').checked ? 1 : 0,
        is_production:     document.getElementById('deptIsProduction').checked ? 1 : 0,
        is_store:          document.getElementById('deptIsStore').checked ? 1 : 0
    };

    $.post('department/form/save_department.cfm', payload, function(resp) {
        try {
            var r = (typeof resp === 'string') ? JSON.parse(resp) : resp;
            if (r.success) {
                location.reload();
            } else {
                alert('Hata: ' + (r.message || 'Kaydetme başarısız.'));
            }
        } catch(e) { alert('Sunucu hatası.'); }
    });
}

function deleteDept(deptId) {
    if (!deptId) return;
    var dept = allDepts.find(function(d){ return d.department_id == deptId; });
    var locCount = allLocs.filter(function(l){ return l.department_id == deptId; }).length;
    var msg = '"' + (dept ? dept.department_head : deptId) + '" departmanını silmek istiyor musunuz?';
    if (locCount > 0) msg += '\n\nDikkat: Bu departmana ait ' + locCount + ' lokasyon da silinecektir!';
    if (!confirm(msg)) return;
    $.post('department/form/delete_department.cfm', { department_id: deptId }, function(resp) {
        try {
            var r = (typeof resp === 'string') ? JSON.parse(resp) : resp;
            if (r.success) location.reload();
            else alert('Hata: ' + (r.message || 'Silme başarısız.'));
        } catch(e) { alert('Sunucu hatası.'); }
    });
}

/* ══════════════════════════════════════
   LOKASYON MODAL
══════════════════════════════════════ */
function showLocModal(locId, deptId) {
    document.getElementById('mdLocId').value    = locId || 0;
    document.getElementById('mdLocDeptId').value = deptId;

    if (locId) {
        var loc = allLocs.find(function(l){ return l.id == locId; });
        document.getElementById('locModalTitle').textContent = 'Lokasyon Düzenle';
        document.getElementById('mdLocName').value      = loc.department_location;
        document.getElementById('mdLocLocationId').value = loc.location_id;
        document.getElementById('mdLocComment').value   = loc.comment;
        document.getElementById('mdLocWidth').value     = loc.width;
        document.getElementById('mdLocHeight').value    = loc.height;
        document.getElementById('mdLocDepth').value     = loc.depth;
        document.getElementById('mdLocTemp').value      = loc.temperature;
        document.getElementById('mdLocPressure').value  = loc.pressure;
        document.getElementById('mdLocType').value      = loc.location_type;
        document.getElementById('mdLocStatus').checked       = loc.status;
        document.getElementById('mdLocNoSale').checked       = loc.no_sale;
        document.getElementById('mdLocPriority').checked     = loc.priority;
        document.getElementById('mdLocDelivery').checked     = loc.delivery;
        document.getElementById('mdLocQuality').checked      = loc.is_quality;
        document.getElementById('mdLocScrap').checked        = loc.is_scrap;
        document.getElementById('mdLocCostAction').checked   = loc.is_cost_action;
        document.getElementById('mdLocEndOfSeries').checked  = loc.is_end_of_series;
    } else {
        document.getElementById('locModalTitle').textContent = 'Yeni Lokasyon';
        ['mdLocName','mdLocLocationId','mdLocComment','mdLocWidth','mdLocHeight',
         'mdLocDepth','mdLocTemp','mdLocPressure','mdLocType'].forEach(function(id){
            document.getElementById(id).value = '';
        });
        ['mdLocStatus'].forEach(function(id){ document.getElementById(id).checked = true; });
        ['mdLocNoSale','mdLocPriority','mdLocDelivery','mdLocQuality',
         'mdLocScrap','mdLocCostAction','mdLocEndOfSeries'].forEach(function(id){
            document.getElementById(id).checked = false;
        });
    }
    bootstrap.Modal.getOrCreateInstance(document.getElementById('locModal')).show();
}

function saveLocModal() {
    var name = document.getElementById('mdLocName').value.trim();
    if (!name) { alert('Lokasyon adı zorunludur.'); return; }

    var payload = buildLocPayload('md');
    $.post('department/form/save_location.cfm', payload, function(resp) {
        try {
            var r = (typeof resp === 'string') ? JSON.parse(resp) : resp;
            if (r.success) {
                bootstrap.Modal.getInstance(document.getElementById('locModal')).hide();
                location.reload();
            } else {
                alert('Hata: ' + (r.message || 'Kaydetme başarısız.'));
            }
        } catch(e) { alert('Sunucu hatası.'); }
    });
}

/* ══════════════════════════════════════
   SAĞ PANEL LOKASYON KAYDET
══════════════════════════════════════ */
function saveLoc() {
    var name = document.getElementById('locName').value.trim();
    if (!name) { alert('Lokasyon adı zorunludur.'); return; }

    var payload = {
        loc_id:            currentLocId || 0,
        department_id:     currentDeptId,
        department_location: name,
        location_id:       document.getElementById('locLocationId').value || 0,
        comment:           document.getElementById('locComment').value,
        width:             document.getElementById('locWidth').value || 0,
        height:            document.getElementById('locHeight').value || 0,
        depth:             document.getElementById('locDepth').value || 0,
        temperature:       document.getElementById('locTemp').value || 0,
        pressure:          document.getElementById('locPressure').value || 0,
        location_type:     document.getElementById('locType').value || 0,
        status:            document.getElementById('locStatus').checked ? 1 : 0,
        no_sale:           document.getElementById('locNoSale').checked ? 1 : 0,
        priority:          document.getElementById('locPriority').checked ? 1 : 0,
        delivery:          document.getElementById('locDelivery').checked ? 1 : 0,
        is_quality:        document.getElementById('locQuality').checked ? 1 : 0,
        is_scrap:          document.getElementById('locScrap').checked ? 1 : 0,
        is_cost_action:    document.getElementById('locCostAction').checked ? 1 : 0,
        is_end_of_series:  document.getElementById('locEndOfSeries').checked ? 1 : 0
    };

    $.post('department/form/save_location.cfm', payload, function(resp) {
        try {
            var r = (typeof resp === 'string') ? JSON.parse(resp) : resp;
            if (r.success) location.reload();
            else alert('Hata: ' + (r.message || 'Kaydetme başarısız.'));
        } catch(e) { alert('Sunucu hatası.'); }
    });
}

function deleteLoc(locId) {
    if (!locId) return;
    var loc = allLocs.find(function(l){ return l.id == locId; });
    if (!confirm('"' + (loc ? loc.department_location : locId) + '" lokasyonunu silmek istiyor musunuz?')) return;
    $.post('department/form/delete_location.cfm', { loc_id: locId }, function(resp) {
        try {
            var r = (typeof resp === 'string') ? JSON.parse(resp) : resp;
            if (r.success) location.reload();
            else alert('Hata: ' + (r.message || 'Silme başarısız.'));
        } catch(e) { alert('Sunucu hatası.'); }
    });
}

function buildLocPayload(prefix) {
    var p = prefix;
    return {
        loc_id:            document.getElementById(p + 'LocId').value || 0,
        department_id:     document.getElementById(p + 'LocDeptId').value,
        department_location: document.getElementById(p + 'LocName').value.trim(),
        location_id:       document.getElementById(p + 'LocLocationId').value || 0,
        comment:           document.getElementById(p + 'LocComment').value,
        width:             document.getElementById(p + 'LocWidth').value || 0,
        height:            document.getElementById(p + 'LocHeight').value || 0,
        depth:             document.getElementById(p + 'LocDepth').value || 0,
        temperature:       document.getElementById(p + 'LocTemp').value || 0,
        pressure:          document.getElementById(p + 'LocPressure').value || 0,
        location_type:     document.getElementById(p + 'LocType').value || 0,
        status:            document.getElementById(p + 'LocStatus').checked ? 1 : 0,
        no_sale:           document.getElementById(p + 'LocNoSale').checked ? 1 : 0,
        priority:          document.getElementById(p + 'LocPriority').checked ? 1 : 0,
        delivery:          document.getElementById(p + 'LocDelivery').checked ? 1 : 0,
        is_quality:        document.getElementById(p + 'LocQuality').checked ? 1 : 0,
        is_scrap:          document.getElementById(p + 'LocScrap').checked ? 1 : 0,
        is_cost_action:    document.getElementById(p + 'LocCostAction').checked ? 1 : 0,
        is_end_of_series:  document.getElementById(p + 'LocEndOfSeries').checked ? 1 : 0
    };
}

function escHtml(str) {
    if (!str) return '';
    return String(str).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}
</script>
</cfoutput>
