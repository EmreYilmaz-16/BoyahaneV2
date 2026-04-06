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
