<cfprocessingdirective pageEncoding="utf-8">
<!--- Session kontrolü --->
<cfif not structKeyExists(session, "authenticated") or not session.authenticated>
    <cflocation url="../../login.cfm" addtoken="false">
    <cfabort>
</cfif>

<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Menü Tasarımcı - PBS Menu Designer</title>
    
    <!--- Bootstrap CSS --->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    
    <!--- Font Awesome --->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    
    <!--- SortableJS CSS --->
    <style>
        body {
            background-color: #f8f9fa;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }
        .page-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px 0;
            margin-bottom: 30px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .menu-container {
            background: white;
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }
        .sortable-ghost {
            opacity: 0.4;
            background: #f8f9fa;
        }
        .sortable-chosen {
            opacity: 0.8;
        }
        .menu-item {
            background: white;
            border: 1px solid #dee2e6;
            border-radius: 8px;
            padding: 15px;
            margin-bottom: 10px;
            cursor: move;
            transition: all 0.3s;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .menu-item:hover {
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
            border-color: #667eea;
        }
        .menu-item.level-1 {
            background: linear-gradient(135deg, #667eea15 0%, #764ba215 100%);
            font-weight: bold;
            border-left: 4px solid #667eea;
        }
        .menu-item.level-2 {
            background: #f8f9fa;
            margin-left: 30px;
            border-left: 4px solid #28a745;
        }
        .menu-item.level-3 {
            background: #fff;
            margin-left: 60px;
            border-left: 4px solid #ffc107;
        }
        .menu-item.level-4 {
            background: #fafafa;
            margin-left: 90px;
            border-left: 4px solid #17a2b8;
        }
        .menu-icon {
            font-size: 1.2em;
            margin-right: 10px;
            width: 30px;
            text-align: center;
        }
        .menu-info {
            flex: 1;
        }
        .menu-actions {
            display: flex;
            gap: 5px;
        }
        .btn-icon {
            width: 35px;
            height: 35px;
            padding: 0;
            display: inline-flex;
            align-items: center;
            justify-content: center;
        }
        .badge-level {
            font-size: 0.7em;
            padding: 4px 8px;
        }
        .add-button-container {
            position: fixed;
            bottom: 30px;
            right: 30px;
            z-index: 1000;
        }
        .fab-button {
            width: 60px;
            height: 60px;
            border-radius: 50%;
            font-size: 24px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.3);
        }
        .modal-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .icon-picker {
            max-height: 300px;
            overflow-y: auto;
        }
        .icon-option {
            cursor: pointer;
            padding: 10px;
            border: 1px solid #dee2e6;
            border-radius: 5px;
            margin: 5px;
            transition: all 0.2s;
            display: inline-block;
            width: 60px;
            text-align: center;
        }
        .icon-option:hover, .icon-option.selected {
            background: #667eea;
            color: white;
            transform: scale(1.1);
        }
        .drag-handle {
            cursor: grab;
            color: #999;
            margin-right: 10px;
        }
        .drag-handle:active {
            cursor: grabbing;
        }
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #999;
        }
        .empty-state i {
            font-size: 64px;
            margin-bottom: 20px;
        }
    </style>
</head>
<body>
    <!--- Page Header --->
    <div class="page-header">
        <div class="container-fluid">
            <div class="row align-items-center">
                <div class="col-md-6">
                    <h1 class="mb-0">
                        <i class="fas fa-sitemap me-3"></i>Menü Tasarımcı
                    </h1>
                    <p class="mb-0 mt-2">PBS Menü Yapısı Yönetimi</p>
                </div>
                <div class="col-md-6 text-end">
                    <a href="../../index.cfm" class="btn btn-light">
                        <i class="fas fa-home me-2"></i>Ana Sayfa
                    </a>
                </div>
            </div>
        </div>
    </div>

    <div class="container-fluid">
        <!--- Toolbar --->
        <div class="menu-container">
            <div class="row align-items-center">
                <div class="col-md-6">
                    <h5 class="mb-0">
                        <i class="fas fa-layer-group me-2"></i>Menü Yapısı
                    </h5>
                </div>
                <div class="col-md-6 text-end">
                    <div class="btn-group" role="group">
                        <button type="button" class="btn btn-primary" onclick="addItem('solution')">
                            <i class="fas fa-plus me-2"></i>Yeni Solution
                        </button>
                        <button type="button" class="btn btn-success" onclick="refreshMenu()">
                            <i class="fas fa-sync me-2"></i>Yenile
                        </button>
                        <button type="button" class="btn btn-info" onclick="toggleAll()">
                            <i class="fas fa-expand-arrows-alt me-2"></i>Tümünü Aç/Kapat
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!--- Menu Tree Container --->
        <div class="menu-container" id="menuTreeContainer">
            <div id="menuTree">
                <!--- Menu items will be loaded here via AJAX --->
                <div class="text-center py-5">
                    <div class="spinner-border text-primary" role="status">
                        <span class="visually-hidden">Yükleniyor...</span>
                    </div>
                </div>
            </div>
        </div>

        <!--- Statistics --->
        <div class="menu-container">
            <div class="row text-center">
                <div class="col-md-3">
                    <div class="card">
                        <div class="card-body">
                            <h2 class="text-primary mb-0" id="stat-solutions">0</h2>
                            <p class="text-muted mb-0">Solutions</p>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card">
                        <div class="card-body">
                            <h2 class="text-success mb-0" id="stat-families">0</h2>
                            <p class="text-muted mb-0">Families</p>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card">
                        <div class="card-body">
                            <h2 class="text-warning mb-0" id="stat-modules">0</h2>
                            <p class="text-muted mb-0">Modules</p>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card">
                        <div class="card-body">
                            <h2 class="text-info mb-0" id="stat-objects">0</h2>
                            <p class="text-muted mb-0">Objects</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!--- Modal: Add/Edit Item --->
    <div class="modal fade" id="itemModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="modalTitle">
                        <i class="fas fa-plus me-2"></i>Yeni Öğe Ekle
                    </h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <form id="itemForm">
                        <input type="hidden" id="itemType" name="itemType">
                        <input type="hidden" id="itemId" name="itemId">
                        <input type="hidden" id="parentId" name="parentId">
                        
                        <div class="row">
                            <div class="col-md-8">
                                <div class="mb-3">
                                    <label for="itemName" class="form-label">Öğe Adı *</label>
                                    <input type="text" class="form-control" id="itemName" name="itemName" required>
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="mb-3">
                                    <label for="orderNo" class="form-label">Sıra No</label>
                                    <input type="number" class="form-control" id="orderNo" name="orderNo" value="0">
                                </div>
                            </div>
                        </div>

                        <div class="mb-3" id="parentSelectContainer" style="display:none;">
                            <label for="parentSelect" class="form-label">Üst Öğe *</label>
                            <select class="form-select" id="parentSelect" name="parentSelect">
                                <option value="">Seçiniz...</option>
                            </select>
                        </div>

                        <div class="mb-3" id="iconFieldContainer">
                            <label class="form-label">İkon</label>
                            <div class="input-group">
                                <span class="input-group-text">
                                    <i class="fas fa-icons" id="selectedIconPreview"></i>
                                </span>
                                <input type="text" class="form-control" id="itemIcon" name="itemIcon" placeholder="fa-folder" readonly>
                                <button type="button" class="btn btn-outline-secondary" onclick="showIconPicker()">
                                    <i class="fas fa-search"></i> İkon Seç
                                </button>
                            </div>
                            <small class="text-muted">Object'lerde icon kullanılmaz</small>
                        </div>

                        <div id="objectFieldsContainer" style="display:none;">
                            <div class="mb-3">
                                <label for="windowType" class="form-label">Pencere Tipi</label>
                                <select class="form-select" id="windowType" name="windowType">
                                    <option value="standart">Standart</option>
                                    <option value="popup">Popup</option>
                                    <option value="ajaxpage">Ajax Page</option>
                                </select>
                            </div>
                            <div class="mb-3">
                                <label for="fullFuseaction" class="form-label">Full Fuseaction</label>
                                <input type="text" class="form-control" id="fullFuseaction" name="fullFuseaction" placeholder="module.action">
                            </div>
                            <div class="mb-3">
                                <label for="filePath" class="form-label">Dosya Yolu</label>
                                <input type="text" class="form-control" id="filePath" name="filePath" placeholder="/modules/example.cfm">
                            </div>
                        </div>

                        <div class="row">
                            <div class="col-md-6">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" id="showMenu" name="showMenu" checked>
                                    <label class="form-check-label" for="showMenu">
                                        Menüde Göster
                                    </label>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" id="isActive" name="isActive" checked>
                                    <label class="form-check-label" for="isActive">
                                        Aktif
                                    </label>
                                </div>
                            </div>
                        </div>
                    </form>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">İptal</button>
                    <button type="button" class="btn btn-primary" onclick="saveItem()">
                        <i class="fas fa-save me-2"></i>Kaydet
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!--- Modal: Icon Picker --->
    <div class="modal fade" id="iconPickerModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">
                        <i class="fas fa-icons me-2"></i>İkon Seç
                    </h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <input type="text" class="form-control mb-3" id="iconSearch" placeholder="İkon ara...">
                    <div class="icon-picker" id="iconPickerGrid">
                        <!--- Icons will be populated here --->
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!--- Scripts --->
    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/sortablejs@1.15.0/Sortable.min.js"></script>
    
    <script>
        // Popular Font Awesome icons
        const iconList = [
            'fa-folder', 'fa-file', 'fa-home', 'fa-user', 'fa-users', 'fa-cog', 'fa-chart-bar',
            'fa-chart-line', 'fa-chart-pie', 'fa-table', 'fa-list', 'fa-th', 'fa-th-list',
            'fa-calendar', 'fa-calendar-alt', 'fa-clock', 'fa-envelope', 'fa-inbox', 'fa-box',
            'fa-boxes', 'fa-archive', 'fa-warehouse', 'fa-shopping-cart', 'fa-shopping-bag',
            'fa-credit-card', 'fa-money-bill', 'fa-coins', 'fa-calculator', 'fa-file-invoice',
            'fa-receipt', 'fa-barcode', 'fa-qrcode', 'fa-tag', 'fa-tags', 'fa-bookmark',
            'fa-star', 'fa-heart', 'fa-thumbs-up', 'fa-check', 'fa-check-circle', 'fa-times',
            'fa-times-circle', 'fa-exclamation', 'fa-exclamation-triangle', 'fa-info', 'fa-info-circle',
            'fa-question', 'fa-question-circle', 'fa-plus', 'fa-plus-circle', 'fa-minus',
            'fa-minus-circle', 'fa-edit', 'fa-trash', 'fa-trash-alt', 'fa-save', 'fa-download',
            'fa-upload', 'fa-print', 'fa-search', 'fa-filter', 'fa-sort', 'fa-random',
            'fa-sync', 'fa-redo', 'fa-undo', 'fa-expand', 'fa-compress', 'fa-arrows-alt',
            'fa-sitemap', 'fa-network-wired', 'fa-project-diagram', 'fa-tasks', 'fa-clipboard',
            'fa-clipboard-list', 'fa-clipboard-check', 'fa-industry', 'fa-cogs', 'fa-wrench',
            'fa-tools', 'fa-hammer', 'fa-shield-alt', 'fa-lock', 'fa-unlock', 'fa-key',
            'fa-database', 'fa-server', 'fa-hdd', 'fa-laptop', 'fa-desktop', 'fa-mobile',
            'fa-tablet', 'fa-phone', 'fa-signal', 'fa-wifi', 'fa-globe', 'fa-map', 'fa-map-marker'
        ];

        let menuData = {};
        let currentModal = null;

        // Load menu on page load
        $(document).ready(function() {
            loadMenu();
            populateIconPicker();
        });

        // Load menu data
        function loadMenu() {
            console.log('Loading menu...');
            $.ajax({
                url: 'menu_designer_action.cfm',
                method: 'POST',
                data: { action: 'getMenu' },
                dataType: 'json',
                success: function(response) {
                    console.log('Menu response:', response);
                    // CFC returnformat="json" returns uppercase keys
                    if(response.SUCCESS || response.success) {
                        menuData = response.DATA || response.data;
                        console.log('Menu data loaded:', menuData);
                        renderMenu();
                        updateStatistics();
                    } else {
                        console.error('Menu load failed:', response.MESSAGE || response.message);
                        showError(response.MESSAGE || response.message || 'Menü yüklenemedi');
                    }
                },
                error: function(xhr, status, error) {
                    console.error('AJAX error:', {xhr, status, error});
                    console.error('Response text:', xhr.responseText);
                    showError('Menü yüklenirken bir hata oluştu: ' + error);
                    // Show raw response in container for debugging
                    $('#menuTree').html(`
                        <div class="alert alert-danger">
                            <h5>Hata!</h5>
                            <p>AJAX isteği başarısız. Konsol'u kontrol edin.</p>
                            <details>
                                <summary>Detaylar</summary>
                                <pre>${xhr.responseText}</pre>
                            </details>
                        </div>
                    `);
                }
            });
        }

        // Render menu tree
        function renderMenu() {
            console.log('Rendering menu...');
            const container = $('#menuTree');
            container.empty();

            const solutions = menuData.SOLUTIONS || menuData.solutions || [];
            if(solutions.length === 0) {
                console.log('No solutions found, showing empty state');
                container.html(`
                    <div class="empty-state">
                        <i class="fas fa-sitemap"></i>
                        <h4>Henüz menü öğesi yok</h4>
                        <p class="text-muted">Başlamak için "Yeni Solution" butonuna tıklayın</p>
                    </div>
                `);
                return;
            }

            console.log('Rendering', solutions.length, 'solutions');
            solutions.forEach(solution => {
                container.append(renderSolutionItem(solution));
            });

            console.log('Menu rendered, initializing sortable...');
            // Initialize Sortable for each level
            initSortable();
            console.log('Menu rendering complete!');
        }

        // Render solution item
        function renderSolutionItem(solution) {
            const solutionId = solution.SOLUTION_ID || solution.solution_id;
            const solutionName = solution.SOLUTION_NAME || solution.solution_name;
            const icon = solution.ICON || solution.icon || 'fa-folder';
            const showMenu = solution.SHOW_MENU || solution.show_menu;
            const isActive = solution.IS_ACTIVE || solution.is_active;
            const families = solution.FAMILIES || solution.families || [];
            
            let html = `
                <div class="menu-item level-1" data-id="${solutionId}" data-type="solution">
                    <div class="d-flex align-items-center flex-grow-1">
                        <i class="fas fa-bars drag-handle"></i>
                        <i class="fas ${icon}" menu-icon text-primary"></i>
                        <div class="menu-info">
                            <strong>${solutionName}</strong>
                            <span class="badge bg-primary badge-level ms-2">Solution</span>
                            ${!showMenu ? '<span class="badge bg-secondary ms-1">Gizli</span>' : ''}
                            ${!isActive ? '<span class="badge bg-danger ms-1">Pasif</span>' : ''}
                        </div>
                    </div>
                    <div class="menu-actions">
                        <button class="btn btn-sm btn-success btn-icon" onclick="addItem('family', ${solutionId})" title="Family Ekle">
                            <i class="fas fa-plus"></i>
                        </button>
                        <button class="btn btn-sm btn-primary btn-icon" onclick="editItem('solution', ${solutionId})" title="Düzenle">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn btn-sm btn-danger btn-icon" onclick="deleteItem('solution', ${solutionId})" title="Sil">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </div>
                <div class="solution-children" data-solution-id="${solutionId}">
            `;

            if(families.length > 0) {
                families.forEach(family => {
                    html += renderFamilyItem(family, solutionId);
                });
            }

            html += '</div>';
            return html;
        }

        // Render family item
        function renderFamilyItem(family, solutionId) {
            const familyId = family.FAMILY_ID || family.family_id;
            const familyName = family.FAMILY_NAME || family.family_name;
            const icon = family.ICON || family.icon || 'fa-folder';
            const showMenu = family.SHOW_MENU || family.show_menu;
            const modules = family.MODULES || family.modules || [];
            
            let html = `
                <div class="menu-item level-2" data-id="${familyId}" data-type="family" data-parent="${solutionId}">
                    <div class="d-flex align-items-center flex-grow-1">
                        <i class="fas fa-bars drag-handle"></i>
                        <i class="fas ${icon} menu-icon text-success"></i>
                        <div class="menu-info">
                            <strong>${familyName}</strong>
                            <span class="badge bg-success badge-level ms-2">Family</span>
                            ${!showMenu ? '<span class="badge bg-secondary ms-1">Gizli</span>' : ''}
                        </div>
                    </div>
                    <div class="menu-actions">
                        <button class="btn btn-sm btn-warning btn-icon" onclick="addItem('module', ${familyId})" title="Module Ekle">
                            <i class="fas fa-plus"></i>
                        </button>
                        <button class="btn btn-sm btn-primary btn-icon" onclick="editItem('family', ${familyId})" title="Düzenle">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn btn-sm btn-danger btn-icon" onclick="deleteItem('family', ${familyId})" title="Sil">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </div>
                <div class="family-children" data-family-id="${familyId}">
            `;

            if(modules.length > 0) {
                modules.forEach(module => {
                    html += renderModuleItem(module, familyId);
                });
            }

            html += '</div>';
            return html;
        }

        // Render module item
        function renderModuleItem(module, familyId) {
            const moduleId = module.MODULE_ID || module.module_id;
            const moduleName = module.MODULE_NAME || module.module_name;
            const icon = module.ICON || module.icon || 'fa-file';
            const showMenu = module.SHOW_MENU || module.show_menu;
            const objects = module.OBJECTS || module.objects || [];
            
            let html = `
                <div class="menu-item level-3" data-id="${moduleId}" data-type="module" data-parent="${familyId}">
                    <div class="d-flex align-items-center flex-grow-1">
                        <i class="fas fa-bars drag-handle"></i>
                        <i class="fas ${icon} menu-icon text-warning"></i>
                        <div class="menu-info">
                            <strong>${moduleName}</strong>
                            <span class="badge bg-warning badge-level ms-2">Module</span>
                            ${!showMenu ? '<span class="badge bg-secondary ms-1">Gizli</span>' : ''}
                        </div>
                    </div>
                    <div class="menu-actions">
                        <button class="btn btn-sm btn-info btn-icon" onclick="addItem('object', ${moduleId})" title="Object Ekle">
                            <i class="fas fa-plus"></i>
                        </button>
                        <button class="btn btn-sm btn-primary btn-icon" onclick="editItem('module', ${moduleId})" title="Düzenle">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn btn-sm btn-danger btn-icon" onclick="deleteItem('module', ${moduleId})" title="Sil">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </div>
                <div class="module-children" data-module-id="${moduleId}">
            `;

            if(objects.length > 0) {
                objects.forEach(obj => {
                    html += renderObjectItem(obj, moduleId);
                });
            }

            html += '</div>';
            return html;
        }

        // Render object item
        function renderObjectItem(obj, moduleId) {
            const objectId = obj.OBJECT_ID || obj.object_id;
            const objectName = obj.OBJECT_NAME || obj.object_name;
            const windowType = obj.WINDOW_TYPE || obj.window_type || 'standart';
            const showMenu = obj.SHOW_MENU || obj.show_menu;
            const fullFuseaction = obj.FULL_FUSEACTION || obj.full_fuseaction || '';
            
            const windowTypeColors = {
                'popup': 'info',
                'ajaxpage': 'primary',
                'standart': 'secondary'
            };
            const color = windowTypeColors[windowType] || 'secondary';

            return `
                <div class="menu-item level-4" data-id="${objectId}" data-type="object" data-parent="${moduleId}">
                    <div class="d-flex align-items-center flex-grow-1">
                        <i class="fas fa-bars drag-handle"></i>
                        <i class="fas fa-file menu-icon text-info"></i>
                        <div class="menu-info">
                            <strong>${objectName}</strong>
                            <span class="badge bg-info badge-level ms-2">Object</span>
                            <span class="badge bg-${color} badge-level ms-1">${windowType}</span>
                            ${!showMenu ? '<span class="badge bg-secondary ms-1">Gizli</span>' : ''}
                            ${fullFuseaction ? `<br><small class="text-muted">${fullFuseaction}</small>` : ''}
                        </div>
                    </div>
                    <div class="menu-actions">
                        <button class="btn btn-sm btn-primary btn-icon" onclick="editItem('object', ${objectId})" title="Düzenle">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn btn-sm btn-danger btn-icon" onclick="deleteItem('object', ${objectId})" title="Sil">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </div>
            `;
        }

        // Initialize Sortable
        function initSortable() {
            // Solutions sortable
            new Sortable(document.getElementById('menuTree'), {
                animation: 150,
                handle: '.drag-handle',
                filter: '.solution-children',
                onEnd: function(evt) {
                    updateOrder('solution', evt);
                }
            });
        }

        // Update order after drag & drop
        function updateOrder(type, evt) {
            const items = $(evt.to).children('.menu-item');
            const orderData = [];
            
            items.each(function(index) {
                orderData.push({
                    id: $(this).data('id'),
                    order_no: index + 1
                });
            });

            $.ajax({
                url: 'menu_designer_action.cfm',
                method: 'POST',
                data: {
                    action: 'updateOrder',
                    type: type,
                    orderData: JSON.stringify(orderData)
                },
                dataType: 'json',
                success: function(response) {
                    if(response.SUCCESS || response.success) {
                        showSuccess('Sıralama güncellendi');
                    }
                },
                error: function() {
                    showError('Sıralama güncellenirken bir hata oluştu.');
                }
            });
        }

        // Add new item
        function addItem(type, parentId = null) {
            $('#itemForm')[0].reset();
            $('#itemType').val(type);
            $('#itemId').val('');
            $('#parentId').val(parentId || '');
            $('#showMenu').prop('checked', true);
            $('#isActive').prop('checked', true);
            
            const titles = {
                'solution': 'Yeni Solution Ekle',
                'family': 'Yeni Family Ekle',
                'module': 'Yeni Module Ekle',
                'object': 'Yeni Object Ekle'
            };
            
            $('#modalTitle').html(`<i class="fas fa-plus me-2"></i>${titles[type]}`);
            
            // Show/hide parent select
            if(type !== 'solution') {
                $('#parentSelectContainer').show();
                populateParentSelect(type, parentId);
            } else {
                $('#parentSelectContainer').hide();
            }

            // Show/hide object fields
            if(type === 'object') {
                $('#objectFieldsContainer').show();
                $('#iconFieldContainer').hide(); // Objects don't have icons
            } else {
                $('#objectFieldsContainer').hide();
                $('#iconFieldContainer').show();
            }

            currentModal = new bootstrap.Modal(document.getElementById('itemModal'));
            currentModal.show();
        }

        // Edit item
        function editItem(type, id) {
            // Load item data and populate form
            $.ajax({
                url: 'menu_designer_action.cfm',
                method: 'POST',
                data: { action: 'getItem', type: type, id: id },
                dataType: 'json',
                success: function(response) {
                    if(response.SUCCESS || response.success) {
                        const item = response.DATA || response.data;
                        $('#itemType').val(type);
                        $('#itemId').val(id);
                        $('#itemName').val(item.NAME || item.name);
                        $('#itemIcon').val(item.ICON || item.icon || '');
                        $('#orderNo').val(item.ORDER_NO || item.order_no);
                        $('#showMenu').prop('checked', item.SHOW_MENU || item.show_menu);
                        $('#isActive').prop('checked', item.IS_ACTIVE || item.is_active);
                        
                        if(type === 'object') {
                            $('#windowType').val(item.WINDOW_TYPE || item.window_type);
                            $('#fullFuseaction').val(item.FULL_FUSEACTION || item.full_fuseaction);
                            $('#filePath').val(item.FILE_PATH || item.file_path);
                            $('#objectFieldsContainer').show();
                            $('#iconFieldContainer').hide(); // Objects don't have icons
                        } else {
                            $('#objectFieldsContainer').hide();
                            $('#iconFieldContainer').show();
                        }

                        const titles = {
                            'solution': 'Solution Düzenle',
                            'family': 'Family Düzenle',
                            'module': 'Module Düzenle',
                            'object': 'Object Düzenle'
                        };
                        
                        $('#modalTitle').html(`<i class="fas fa-edit me-2"></i>${titles[type]}`);
                        $('#parentSelectContainer').hide();

                        currentModal = new bootstrap.Modal(document.getElementById('itemModal'));
                        currentModal.show();
                    }
                }
            });
        }

        // Save item
        function saveItem() {
            const formData = $('#itemForm').serialize() + '&action=saveItem';
            
            $.ajax({
                url: 'menu_designer_action.cfm',
                method: 'POST',
                data: formData,
                dataType: 'json',
                success: function(response) {
                    if(response.SUCCESS || response.success) {
                        showSuccess(response.MESSAGE || response.message);
                        currentModal.hide();
                        loadMenu();
                    } else {
                        showError(response.MESSAGE || response.message);
                    }
                },
                error: function() {
                    showError('Kaydetme sırasında bir hata oluştu.');
                }
            });
        }

        // Delete item
        function deleteItem(type, id) {
            if(!confirm('Bu öğeyi silmek istediğinizden emin misiniz? Alt öğeler de silinecektir.')) {
                return;
            }

            $.ajax({
                url: 'menu_designer_action.cfm',
                method: 'POST',
                data: { action: 'deleteItem', type: type, id: id },
                dataType: 'json',
                success: function(response) {
                    if(response.SUCCESS || response.success) {
                        showSuccess(response.MESSAGE || response.message);
                        loadMenu();
                    } else {
                        showError(response.MESSAGE || response.message);
                    }
                },
                error: function() {
                    showError('Silme işlemi sırasında bir hata oluştu.');
                }
            });
        }

        // Populate parent select
        function populateParentSelect(type, selectedId) {
            const select = $('#parentSelect');
            select.empty().append('<option value="">Seçiniz...</option>');

            const solutions = menuData.SOLUTIONS || menuData.solutions || [];

            if(type === 'family') {
                solutions.forEach(solution => {
                    const solutionId = solution.SOLUTION_ID || solution.solution_id;
                    const solutionName = solution.SOLUTION_NAME || solution.solution_name;
                    select.append(`<option value="${solutionId}" ${selectedId == solutionId ? 'selected' : ''}>${solutionName}</option>`);
                });
            } else if(type === 'module') {
                solutions.forEach(solution => {
                    const solutionName = solution.SOLUTION_NAME || solution.solution_name;
                    const families = solution.FAMILIES || solution.families || [];
                    if(families.length > 0) {
                        families.forEach(family => {
                            const familyId = family.FAMILY_ID || family.family_id;
                            const familyName = family.FAMILY_NAME || family.family_name;
                            select.append(`<option value="${familyId}" ${selectedId == familyId ? 'selected' : ''}>${solutionName} > ${familyName}</option>`);
                        });
                    }
                });
            } else if(type === 'object') {
                solutions.forEach(solution => {
                    const solutionName = solution.SOLUTION_NAME || solution.solution_name;
                    const families = solution.FAMILIES || solution.families || [];
                    if(families.length > 0) {
                        families.forEach(family => {
                            const familyName = family.FAMILY_NAME || family.family_name;
                            const modules = family.MODULES || family.modules || [];
                            if(modules.length > 0) {
                                modules.forEach(module => {
                                    const moduleId = module.MODULE_ID || module.module_id;
                                    const moduleName = module.MODULE_NAME || module.module_name;
                                    select.append(`<option value="${moduleId}" ${selectedId == moduleId ? 'selected' : ''}>${solutionName} > ${familyName} > ${moduleName}</option>`);
                                });
                            }
                        });
                    }
                });
            }
        }

        // Populate icon picker
        function populateIconPicker() {
            const grid = $('#iconPickerGrid');
            grid.empty();

            iconList.forEach(icon => {
                grid.append(`
                    <div class="icon-option" data-icon="${icon}" onclick="selectIcon('${icon}')">
                        <i class="fas ${icon}"></i>
                    </div>
                `);
            });
        }

        // Show icon picker
        function showIconPicker() {
            const modal = new bootstrap.Modal(document.getElementById('iconPickerModal'));
            modal.show();

            $('#iconSearch').off('input').on('input', function() {
                const search = $(this).val().toLowerCase();
                $('.icon-option').each(function() {
                    const icon = $(this).data('icon');
                    $(this).toggle(icon.includes(search));
                });
            });
        }

        // Select icon
        function selectIcon(icon) {
            $('#itemIcon').val(icon);
            $('#selectedIconPreview').attr('class', `fas ${icon}`);
            $('.icon-option').removeClass('selected');
            $(`.icon-option[data-icon="${icon}"]`).addClass('selected');
            bootstrap.Modal.getInstance(document.getElementById('iconPickerModal')).hide();
        }

        // Update statistics
        function updateStatistics() {
            let solutionCount = 0, familyCount = 0, moduleCount = 0, objectCount = 0;

            const solutions = menuData.SOLUTIONS || menuData.solutions || [];
            if(solutions.length > 0) {
                solutionCount = solutions.length;
                solutions.forEach(solution => {
                    const families = solution.FAMILIES || solution.families || [];
                    if(families.length > 0) {
                        familyCount += families.length;
                        families.forEach(family => {
                            const modules = family.MODULES || family.modules || [];
                            if(modules.length > 0) {
                                moduleCount += modules.length;
                                modules.forEach(module => {
                                    const objects = module.OBJECTS || module.objects || [];
                                    if(objects.length > 0) {
                                        objectCount += objects.length;
                                    }
                                });
                            }
                        });
                    }
                });
            }

            $('#stat-solutions').text(solutionCount);
            $('#stat-families').text(familyCount);
            $('#stat-modules').text(moduleCount);
            $('#stat-objects').text(objectCount);
        }

        // Refresh menu
        function refreshMenu() {
            loadMenu();
            showSuccess('Menü yenilendi');
        }

        // Toggle all items
        function toggleAll() {
            // Implementation for expand/collapse all
            $('.menu-item').slideToggle();
        }

        // Show success message
        function showSuccess(message) {
            // Simple alert for now, can be replaced with toast
            const alert = $(`
                <div class="alert alert-success alert-dismissible fade show position-fixed top-0 start-50 translate-middle-x mt-3" role="alert" style="z-index:9999;">
                    <i class="fas fa-check-circle me-2"></i>${message}
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
            `);
            $('body').append(alert);
            setTimeout(() => alert.alert('close'), 3000);
        }

        // Show error message
        function showError(message) {
            const alert = $(`
                <div class="alert alert-danger alert-dismissible fade show position-fixed top-0 start-50 translate-middle-x mt-3" role="alert" style="z-index:9999;">
                    <i class="fas fa-exclamation-circle me-2"></i>${message}
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
            `);
            $('body').append(alert);
            setTimeout(() => alert.alert('close'), 5000);
        }
    </script>
</body>
</html>
