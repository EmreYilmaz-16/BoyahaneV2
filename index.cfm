<cfprocessingdirective pageEncoding="utf-8">
<!--- Session kontrolü - Giriş yapılmamışsa login sayfasına yönlendir --->
<cfif not structKeyExists(session, "authenticated") or not session.authenticated>
    <cflocation url="login.cfm" addtoken="false">
    <cfabort>
</cfif>

<!--- Fuseaction kontrolü ve window_type belirleme --->
<cfset showLayout = true>
<cfset loadAssets = true>
<cfset pageContent = "">
<cfset permissionEnforced = false>
<cfset accessDenied = false>
<cfset accessDeniedMessage = "Bu modül için yetkiniz bulunmamaktadır.">
<cfset requiredPermission = "view">
<cfset currentModuleId = 0>

<cfif isDefined("attributes.fuseaction") and attributes.fuseaction neq "">
    <cfquery name="getObject" datasource="boyahane">
        SELECT * FROM pbs_objects WHERE full_fuseaction = <cfqueryparam value="#attributes.fuseaction#" cfsqltype="cf_sql_varchar">
    </cfquery>

    <!--- Kullanıcının herhangi bir modül yetkisi tanımlı mı? --->
    <cfquery name="getUserPermissionCount" datasource="boyahane">
        SELECT COUNT(*) AS cnt
        FROM user_module_permissions
        WHERE user_id = <cfqueryparam value="#session.user.id#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfset permissionEnforced = val(getUserPermissionCount.cnt) gt 0>
    
    <cfif getObject.recordCount>
        <cfset currentModuleId = val(getObject.module_id)>
        <cfif findNoCase(".delete", attributes.fuseaction)>
            <cfset requiredPermission = "delete">
        <cfelseif findNoCase(".save", attributes.fuseaction) OR findNoCase(".add", attributes.fuseaction) OR findNoCase(".edit", attributes.fuseaction) OR findNoCase(".update", attributes.fuseaction)>
            <cfset requiredPermission = "update">
        </cfif>

        <cfif permissionEnforced>
            <cfquery name="getCurrentModulePermission" datasource="boyahane">
                SELECT can_view, can_update, can_delete
                FROM user_module_permissions
                WHERE user_id = <cfqueryparam value="#session.user.id#" cfsqltype="cf_sql_integer">
                  AND module_id = <cfqueryparam value="#currentModuleId#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfif NOT getCurrentModulePermission.recordCount OR NOT getCurrentModulePermission.can_view>
                <cfset accessDenied = true>
                <cfset accessDeniedMessage = "Bu modülü görüntüleme yetkiniz bulunmuyor.">
            <cfelseif requiredPermission EQ "update" AND NOT getCurrentModulePermission.can_update>
                <cfset accessDenied = true>
                <cfset accessDeniedMessage = "Bu işlem için güncelleme yetkiniz bulunmuyor.">
            <cfelseif requiredPermission EQ "delete" AND NOT getCurrentModulePermission.can_delete>
                <cfset accessDenied = true>
                <cfset accessDeniedMessage = "Bu işlem için silme yetkiniz bulunmuyor.">
            </cfif>
        </cfif>

        <!--- Window type'a göre ayarları yap --->
        <cfif getObject.window_type eq "popup">
            <cfset showLayout = false>
            <cfset loadAssets = false>
        <cfelseif getObject.window_type eq "ajaxpage">
            <cfset showLayout = false>
            <cfset loadAssets = false>
        <cfelse>
            <cfset showLayout = true>
            <cfset loadAssets = true>
        </cfif>
    <cfelse>
        <!--- Sayfa bulunamadı --->
        <cfset showLayout = true>
        <cfset loadAssets = true>
    </cfif>
<cfelse>
    <!--- Anasayfa --->
    <cflocation url="index.cfm?fuseaction=myhome.welcome" addtoken="no">
</cfif>

<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <title>Boyahane - Rasih Çelik</title>
    
    <cfif loadAssets>
    <!--- Bootstrap CSS --->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN" crossorigin="anonymous">
    
    <!--- Font Awesome --->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css" integrity="sha512-DTOQO9RWCH3ppGqcWaEA1BIZOC6xxalwEsw9c2QQeAIftl+Vegovlnee1c9QX4TctnWMn13TZye+giMm8e2LwA==" crossorigin="anonymous" referrerpolicy="no-referrer" />
    
    <!--- DevExtreme CSS --->
    <link rel="stylesheet" href="https://cdn3.devexpress.com/jslib/23.2.5/css/dx.common.css">
    <link rel="stylesheet" href="https://cdn3.devexpress.com/jslib/23.2.5/css/dx.light.css">
    <link rel="stylesheet" href="/assets/css/custom.css">
    <!--- Custom CSS --->
    
    <!--- jQuery ve Bootstrap JS (head'de yükle - sayfaiçi scriptlerin erişimi için) --->
    <script src="https://code.jquery.com/jquery-3.7.1.min.js" integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=" crossorigin="anonymous"></script>
    <script src="https://code.jquery.com/ui/1.13.3/jquery-ui.min.js" integrity="sha256-sw0iNNXmOJbQhYFuC9OF2kOlD5KQKe1y5lfBn4C9Sjg=" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" integrity="sha384-C6RzsynM9kWDrMNeT87bh95OGNyZPhcTNXj1NW7RuBCsyN/o0jlpcV8Qyq46cDfL" crossorigin="anonymous"></script>
    </cfif>
</head>
<body>
    <!--- Menü için verileri çek (sadece layout varsa) --->
<cfif showLayout>
    <cfif permissionEnforced>
    <cfquery name="getSolutions" datasource="boyahane">
        SELECT DISTINCT s.*
        FROM pbs_solution s
        INNER JOIN pbs_family f ON f.solution_id = s.solution_id
        INNER JOIN pbs_module m ON m.family_id = f.family_id
        INNER JOIN user_module_permissions ump ON ump.module_id = m.module_id
        WHERE s.is_active = true AND s.show_menu = true
          AND f.is_active = true AND f.show_menu = true
          AND m.is_active = true AND m.show_menu = true
          AND ump.user_id = <cfqueryparam value="#session.user.id#" cfsqltype="cf_sql_integer">
          AND ump.can_view = true
        ORDER BY s.order_no, s.solution_name
    </cfquery>
    
    <cfquery name="getFamilies" datasource="boyahane">
        SELECT DISTINCT f.*
        FROM pbs_family f
        INNER JOIN pbs_module m ON m.family_id = f.family_id
        INNER JOIN user_module_permissions ump ON ump.module_id = m.module_id
        WHERE f.is_active = true AND f.show_menu = true
          AND m.is_active = true AND m.show_menu = true
          AND ump.user_id = <cfqueryparam value="#session.user.id#" cfsqltype="cf_sql_integer">
          AND ump.can_view = true
        ORDER BY f.solution_id, f.order_no, f.family_name
    </cfquery>
    
    <cfquery name="getModules" datasource="boyahane">
        SELECT m.*
        FROM pbs_module m
        INNER JOIN user_module_permissions ump ON ump.module_id = m.module_id
        WHERE m.is_active = true AND m.show_menu = true
          AND ump.user_id = <cfqueryparam value="#session.user.id#" cfsqltype="cf_sql_integer">
          AND ump.can_view = true
        ORDER BY m.family_id, m.order_no, m.module_name
    </cfquery>
    
    <cfquery name="getObjects" datasource="boyahane">
        SELECT o.*
        FROM pbs_objects o
        INNER JOIN user_module_permissions ump ON ump.module_id = o.module_id
        WHERE o.is_active = true AND o.show_menu = true
          AND ump.user_id = <cfqueryparam value="#session.user.id#" cfsqltype="cf_sql_integer">
          AND ump.can_view = true
        ORDER BY o.module_id, o.order_no, o.object_name
    </cfquery>
    <cfelse>
    <cfquery name="getSolutions" datasource="boyahane">
        SELECT * FROM pbs_solution 
        WHERE is_active = true AND show_menu = true
        ORDER BY order_no, solution_name
    </cfquery>
    
    <cfquery name="getFamilies" datasource="boyahane">
        SELECT * FROM pbs_family
        WHERE is_active = true AND show_menu = true
        ORDER BY solution_id, order_no, family_name
    </cfquery>
    
    <cfquery name="getModules" datasource="boyahane">
        SELECT * FROM pbs_module
        WHERE is_active = true AND show_menu = true
        ORDER BY family_id, order_no, module_name
    </cfquery>
    
    <cfquery name="getObjects" datasource="boyahane">
        SELECT * FROM pbs_objects
        WHERE is_active = true AND show_menu = true
        ORDER BY module_id, order_no, object_name
    </cfquery>
    </cfif>

    <!--- Kullanıcı favorileri --->    
    <cfquery name="getUserFavorites" datasource="boyahane">
        SELECT favorite_id, fuseaction, page_title, page_icon
        FROM user_favorites
        WHERE user_id = <cfqueryparam value="#session.user.id#" cfsqltype="cf_sql_integer">
        ORDER BY added_date DESC
    </cfquery>

    <!--- Mevcut sayfa favoride mi? --->
    <cfset currentPageFavorited = false>
    <cfset currentPageTitle = "">
    <cfset currentPageIcon  = "fas fa-file">
    <cfif isDefined("attributes.fuseaction") AND attributes.fuseaction NEQ "" AND getObject.recordCount>
        <cfset currentPageTitle = getObject.object_name>
        <cfset currentPageIcon  = "fas fa-file">
        <cfloop query="getUserFavorites">
            <cfif fuseaction EQ attributes.fuseaction>
                <cfset currentPageFavorited = true>
                <cfbreak>
            </cfif>
        </cfloop>
    </cfif>
    </cfif>
    
    <cfif showLayout>
    <!--- Navigation Bar - Fixed Top --->
    <nav class="navbar navbar-expand-lg navbar-dark fixed-top">
        <div class="container-fluid">
            <button class="btn btn-sm me-2" id="sidebarToggle" type="button">
                <i class="fas fa-bars"></i>
            </button>
            <a class="navbar-brand" href="index.cfm">
                <div class="brand-icon"><i class="fas fa-industry"></i></div>
                <div class="brand-text">
                    <span class="brand-sub">Boyahane Yönetim Sistemi</span>
                    <span class="brand-main">Rasih Çelik</span>
                </div>
            </a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav ms-auto">
                    <li class="nav-item">
                        <a class="nav-link active" href="index.cfm">
                            <i class="fas fa-home"></i> Ana Sayfa
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="/index.cfm?fuseaction=production.list_production_orders">
                            <i class="fas fa-cogs"></i> Üretim
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="#stok">
                            <i class="fas fa-boxes"></i> Stok
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="/index.cfm?fuseaction=report.list_reports">
                            <i class="fas fa-chart-bar"></i> Raporlar
                        </a>
                    </li>
                    <!--- Favoriler Dropdown --->
                    <li class="nav-item dropdown me-1">
                        <a class="nav-link fav-nav-link" href="#" id="favDropdown" role="button" data-bs-toggle="dropdown" aria-expanded="false" title="Kısayollarım">
                            <i class="fas fa-bookmark"></i>
                            <cfoutput><cfif getUserFavorites.recordCount gt 0><span class="fav-badge">#getUserFavorites.recordCount#</span></cfif></cfoutput>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end fav-dropdown-menu" aria-labelledby="favDropdown">
                            <li class="fav-dropdown-header">
                                <i class="fas fa-bookmark me-2"></i>Kısayollarım
                            </li>
                            <li><hr class="dropdown-divider my-1"></li>
                            <cfoutput>
                            <cfset favColors = ["##3b82f6","##10b981","##f59e0b","##8b5cf6","##ef4444","##06b6d4","##f97316","##ec4899"]>
                            <cfif getUserFavorites.recordCount>
                                <cfloop query="getUserFavorites">
                                <cfset itemColor = favColors[((currentRow - 1) mod arrayLen(favColors)) + 1]>
                                <li class="fav-list-item d-flex align-items-center pe-2">
                                    <a class="dropdown-item fav-item flex-grow-1" href="index.cfm?fuseaction=#fuseaction#">
                                        <span class="fav-icon-dot" style="background:#itemColor#"><i class="#page_icon#"></i></span>
                                        <span>#htmlEditFormat(page_title)#</span>
                                    </a>
                                    <button class="fav-remove-btn" onclick="removeFavorite(this,'#jsStringFormat(fuseaction)#')" title="Kısayoldan kaldır" type="button">
                                        <i class="fas fa-times"></i>
                                    </button>
                                </li>
                                </cfloop>
                            <cfelse>
                                <li><span class="dropdown-item-text fav-empty"><i class="fas fa-star-half-alt me-1"></i>Henüz kısayol yok.</span></li>
                            </cfif>
                            </cfoutput>
                            <li><hr class="dropdown-divider my-1"></li>
                            <li><span class="fav-hint text-light"><i class="fas fa-star me-1"></i>Sayfa başlığındaki yıldıza basarak kısayol ekleyin</span></li>
                        </ul>
                    </li>

                    <!--- Yıldız: Mevcut sayfayı favorile --->
                    <cfoutput>
                    <cfif isDefined("attributes.fuseaction") AND attributes.fuseaction NEQ "" AND getObject.recordCount>
                    <li class="nav-item me-1">
                        <button class="nav-link btn btn-link px-2 star-btn" id="btnStarPage"
                            onclick="toggleFavorite()"
                            data-fuseaction="#htmlEditFormat(attributes.fuseaction)#"
                            data-title="#htmlEditFormat(currentPageTitle)#"
                            data-icon="#htmlEditFormat(currentPageIcon)#"
                            title="#currentPageFavorited ? 'Favorilerden kaldır' : 'Favorilere ekle'#">
                            <i class="#currentPageFavorited ? 'fas' : 'far'# fa-star star-icon"
                               style="color:#currentPageFavorited ? '##f59e0b' : 'rgba(255,255,255,0.55)'#"></i>
                        </button>
                    </li>
                    </cfif>
                    </cfoutput>

                    <!--- Kullanıcı Dropdown --->
                    <li class="nav-item dropdown">
                        <a class="nav-link dropdown-toggle" href="#" id="navbarDropdown" role="button" data-bs-toggle="dropdown" aria-expanded="false">
                            <span class="user-avatar"><cfoutput>#Left(session.user.fullname, 1)#</cfoutput></span>
                            <cfoutput>#session.user.fullname#</cfoutput>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="navbarDropdown">
                            <li class="dropdown-header">
                                <small class="text-muted">
                                    <cfoutput>@#session.user.username#</cfoutput>
                                </small>
                            </li>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item" href="#profil"><i class="fas fa-user me-2"></i>Profil</a></li>
                            <li><a class="dropdown-item" href="index.cfm?fuseaction=setup.update_center"><i class="fas fa-cog me-2"></i>Ayarlar</a></li>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item text-danger" href="logout.cfm"><i class="fas fa-sign-out-alt me-2"></i>Çıkış Yap</a></li>
                        </ul>
                    </li>
                </ul>
            </div>
        </div>
    </nav>

    <!--- Sidebar Menu --->
    <div class="sidebar">
        <div class="sidebar-header">
            <i class="fas fa-th-large"></i>Ana Menü
        </div>
        
        <cfoutput query="getSolutions">
            <div class="menu-solution" data-solution="#solution_id#">
                <i class="#icon#"></i>
                <span>#solution_name#</span>
                <i class="fas fa-chevron-right toggle-icon"></i>
            </div>
            
            <div class="menu-family" id="solution-#solution_id#" style="display:none;">
                <cfquery name="familiesForSolution" dbtype="query">
                    SELECT * FROM getFamilies
                    WHERE solution_id = #solution_id#
                </cfquery>
                
                <cfloop query="familiesForSolution">
                    <div class="menu-family-item" data-family="#family_id#">
                        <i class="#icon#"></i>
                        <span>#family_name#</span>
                        <i class="fas fa-chevron-right toggle-icon"></i>
                    </div>
                    
                    <div class="menu-module" id="family-#family_id#" style="display:none;">
                        <cfquery name="modulesForFamily" dbtype="query">
                            SELECT * FROM getModules
                            WHERE family_id = #family_id#
                        </cfquery>
                        
                        <cfloop query="modulesForFamily">
                            <div class="menu-module-item" data-module="#module_id#">
                                <i class="#icon#"></i>
                                <span>#module_name#</span>
                                <i class="fas fa-chevron-right toggle-icon"></i>
                            </div>
                            
                            <div class="menu-objects" id="module-#module_id#" style="display:none;">
                                <cfquery name="objectsForModule" dbtype="query">
                                    SELECT * FROM getObjects
                                    WHERE module_id = #module_id#
                                </cfquery>
                                
                                <cfloop query="objectsForModule">
                                    <a href="index.cfm?fuseaction=#full_fuseaction#" class="menu-object-item text-decoration-none d-block" data-object="#object_id#">
                                        <i class="fas fa-circle"></i>
                                        <span>#object_name#</span>
                                    </a>
                                </cfloop>
                            </div>
                        </cfloop>
                    </div>
                </cfloop>
            </div>
        </cfoutput>
    </div>
    
    <!--- Sidebar Backdrop for Mobile --->
    <div class="sidebar-backdrop" id="sidebarBackdrop"></div>
    </cfif>

    <!--- Main Content --->
    <cfif showLayout>
    <div class="content-wrapper">
    </cfif>
        <div class="container-fluid main-content">
        <cfif isDefined("attributes.fuseaction") and attributes.fuseaction neq "">
            <cfif getObject.recordCount>
                    <cfif accessDenied>
                        <div class="alert alert-warning text-center" role="alert">
                            <h4 class="alert-heading"><i class="fas fa-lock me-2"></i>Yetki Hatası</h4>
                            <p><cfoutput>#accessDeniedMessage#</cfoutput></p>
                            <hr>
                            <p class="mb-0">Ana sayfaya dönmek için <a href="index.cfm?fuseaction=myhome.welcome" class="alert-link">buraya tıklayın</a>.</p>
                        </div>
                    <cfelse>
                        <cfinclude template="#getObject.file_path#">
                    </cfif>
                <cfelse>
                    <div class="alert alert-danger text-center" role="alert">
                        <h4 class="alert-heading"><i class="fas fa-exclamation-triangle me-2"></i>Hata!</h4>
                        <p>İstenen sayfa bulunamadı. Lütfen geçerli bir sayfa isteğinde bulunun.</p>
                        <hr>
                        <p class="mb-0">Anasayfaya dönmek için <a href="index.cfm" class="alert-link">buraya tıklayın</a>.</p>
                    </div>
                </cfif>
                <cfelse>
                    <cflocation url="index.cfm?fuseaction=myhome.welcome" addtoken="no">
        </cfif>
        </div>
    <cfif showLayout>
    </div>
    </cfif>

    <cfif showLayout>
    <!--- Footer - Fixed Bottom --->
    <footer class="footer">
        <div class="container-fluid">
            <div class="row align-items-center w-100">
                <div class="col-md-6 text-center text-md-start">
                    <i class="fas fa-copyright me-1"></i>2026 Rasih Çelik Boyahane &mdash; Tüm hakları saklıdır
                </div>
                <div class="col-md-6 text-center text-md-end">
                    Powered by <strong>Workcube Catalyst</strong>
                </div>
            </div>
        </div>
    </footer>
    </cfif>

    <cfif loadAssets>
    <!--- DevExtreme JS --->
    <script src="https://cdn3.devexpress.com/jslib/23.2.5/js/dx.all.js"></script>
    
    <!--- DevExtreme Türkçe Lokalizasyon --->
    <script src="https://cdn3.devexpress.com/jslib/23.2.5/js/localization/dx.messages.tr.js"></script>
    
    <!--- Custom JavaScript --->
    <script>
        $(document).ready(function() {
            // Sidebar durumunu localStorage'dan geri yükle (sadece desktop)
            if ($(window).width() > 768 && localStorage.getItem('sidebarCollapsed') === '1') {
                $('body').addClass('sidebar-collapsed');
            }

            // Sidebar toggle - her ekran boyutunda çalışır
            $('#sidebarToggle').click(function() {
                if ($(window).width() <= 768) {
                    // Mobil: show/hide overlay
                    $('.sidebar').toggleClass('show');
                    $('#sidebarBackdrop').toggleClass('show');
                } else {
                    // Desktop: collapse/expand
                    $('body').toggleClass('sidebar-collapsed');
                    localStorage.setItem('sidebarCollapsed', $('body').hasClass('sidebar-collapsed') ? '1' : '0');
                }
            });
            
            // Sidebar backdrop veya dışına tıklandığında kapat (mobil)
            $('#sidebarBackdrop').click(function() {
                $('.sidebar').removeClass('show');
                $(this).removeClass('show');
            });
            
            $(document).click(function(event) {
                if ($(window).width() <= 768) {
                    if (!$(event.target).closest('.sidebar, #sidebarToggle').length) {
                        $('.sidebar').removeClass('show');
                        $('#sidebarBackdrop').removeClass('show');
                    }
                }
            });
            
            // Menü toggle işlemleri
            $('.menu-solution').click(function() {
                var solutionId = $(this).data('solution');
                var menu = $('#solution-' + solutionId);
                var icon = $(this).find('.toggle-icon');
                
                menu.slideToggle(300);
                icon.toggleClass('rotate');
            });
            
            $('.menu-family-item').click(function(e) {
                e.stopPropagation();
                var familyId = $(this).data('family');
                var menu = $('#family-' + familyId);
                var icon = $(this).find('.toggle-icon');
                
                menu.slideToggle(300);
                icon.toggleClass('rotate');
            });
            
            $('.menu-module-item').click(function(e) {
                e.stopPropagation();
                var moduleId = $(this).data('module');
                var menu = $('#module-' + moduleId);
                var icon = $(this).find('.toggle-icon');
                
                menu.slideToggle(300);
                icon.toggleClass('rotate');
            });
            
            // Menü öğesine tıklandığında mobilde sidebar'ı kapat
            $('.menu-object-item').click(function() {
                if ($(window).width() <= 768) {
                    $('.sidebar').removeClass('show');
                    $('#sidebarBackdrop').removeClass('show');
                }
            });
            
            // Aktif menü öğesini işaretle
            var currentFuseaction = new URLSearchParams(window.location.search).get('fuseaction');
            if(currentFuseaction) {
                $('.menu-object-item').each(function() {
                    if($(this).attr('href').includes(currentFuseaction)) {
                        $(this).addClass('menu-active');
                        
                        // Üst menüleri aç
                        var moduleDiv = $(this).closest('.menu-objects');
                        var moduleId = moduleDiv.attr('id');
                        moduleDiv.show();
                        $('.menu-module-item[data-module="' + moduleId.replace('module-', '') + '"]').find('.toggle-icon').addClass('rotate');
                        
                        var familyDiv = moduleDiv.closest('.menu-module');
                        var familyId = familyDiv.attr('id');
                        familyDiv.show();
                        $('.menu-family-item[data-family="' + familyId.replace('family-', '') + '"]').find('.toggle-icon').addClass('rotate');
                        
                        var solutionDiv = familyDiv.closest('.menu-family');
                        var solutionId = solutionDiv.attr('id');
                        solutionDiv.show();
                        $('.menu-solution[data-solution="' + solutionId.replace('solution-', '') + '"]').find('.toggle-icon').addClass('rotate');
                    }
                });
            }
            
            // ---- Favoriler / Kısayollar ----
            window.removeFavorite = function(btn, fuseaction) {
                var li = btn.closest('li');
                btn.disabled = true;
                $.post('/assets/api/toggle_favorite.cfm', { fuseaction: fuseaction }, function(res) {
                    if (!res || !res.success) { btn.disabled = false; return; }
                    li.remove();
                    // Rozeti güncelle
                    var badge = document.querySelector('.fav-badge');
                    if (badge) {
                        var n = (parseInt(badge.textContent) || 0) - 1;
                        if (n <= 0) badge.remove();
                        else badge.textContent = n;
                    }
                    // Liste boşaldıysa mesaj göster
                    var menu = document.querySelector('.fav-dropdown-menu');
                    if (!menu.querySelector('.fav-list-item')) {
                        var first = menu.querySelector('.dropdown-divider');
                        var emptyLi = document.createElement('li');
                        emptyLi.innerHTML = '<span class="dropdown-item-text fav-empty"><i class="fas fa-star-half-alt me-1"></i>Henüz kısayol yok.</span>';
                        first.after(emptyLi);
                    }
                    // Mevcut sayfa silindiyse yıldızı güncelle
                    var starBtn = document.getElementById('btnStarPage');
                    if (starBtn && starBtn.dataset.fuseaction === fuseaction) {
                        var starEl = starBtn.querySelector('.star-icon');
                        starEl.classList.replace('fas', 'far');
                        starEl.style.color = 'rgba(255,255,255,0.55)';
                        starBtn.title = 'Favorilere ekle';
                    }
                }, 'json');
            };

            window.toggleFavorite = function() {
                var btn       = document.getElementById('btnStarPage');
                if (!btn) return;
                var fuseaction = btn.dataset.fuseaction;
                var title      = btn.dataset.title;
                var icon       = btn.dataset.icon;
                var starEl     = btn.querySelector('.star-icon');

                btn.disabled = true;

                $.post('/assets/api/toggle_favorite.cfm', {
                    fuseaction : fuseaction,
                    page_title : title,
                    page_icon  : icon
                }, function(res) {
                    btn.disabled = false;
                    if (!res || !res.success) return;

                    if (res.is_favorite) {
                        starEl.classList.remove('far');
                        starEl.classList.add('fas');
                        starEl.style.color = '#f59e0b';
                        btn.title = 'Favorilerden kaldır';
                    } else {
                        starEl.classList.remove('fas');
                        starEl.classList.add('far');
                        starEl.style.color = 'rgba(255,255,255,0.55)';
                        btn.title = 'Favorilere ekle';
                    }

                    // Sayfa yenilenmeden badge + liste güncelle
                    setTimeout(function() { location.reload(); }, 300);
                }, 'json');
            };

            // Smooth scroll for anchor links (for content-wrapper)
            $('a[href^="#"]').on('click', function(event) {
                var target = $(this.getAttribute('href'));
                if(target.length) {
                    event.preventDefault();
                    var scrollContainer = $('.content-wrapper');
                    if(scrollContainer.length) {
                        scrollContainer.stop().animate({
                            scrollTop: target.offset().top - scrollContainer.offset().top + scrollContainer.scrollTop() - 20
                        }, 1000);
                    }
                }
            });
        });
    </script>
    </cfif>
</body>
</html>
