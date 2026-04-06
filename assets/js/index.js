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


        function openBoxDraggable(url, modal_id = "", size = "", form){
	var uniqueId = modal_id == '' ? Math.floor(Math.random() * 999999999999999) : modal_id;
	if($('#popup_box_' + uniqueId + '').length == 0){ $('<div>').addClass("ui-draggable-box" + " " + size).attr({"id" : "popup_box_" + uniqueId + ""}).appendTo($('body')); }
	$('#popup_box_' + uniqueId + '').css({'display' : 'block', 'visibility' : 'visible'});
	$("body").addClass("modal-opened");

	var box_address_obj = $("<input>").attr({"type": "hidden", "name":"box_address_" + uniqueId + "", "id": "box_address_" + uniqueId + ""}).val(url);
	url += !url.includes('&modal_id=') ? "&draggable=1&modal_id=" + uniqueId + "" : "&draggable=1";

	$("#working_div_main").css({"z-index":"999999999", "display":"flex"}).show();

	if( form != undefined ) var data = new FormData( form[0] );
	else var data = new FormData();

	AjaxControlPostData( url, data, function( response ){ 
		$("#popup_box_" + uniqueId + "").html(box_address_obj).append( response );
		$("#working_div_main").css({"z-index":"99999999"}).hide(); 
	});
	return false;
}
function refreshBox(box_id = '', refresh_modal_id = '') {
	if(box_id != ''){
		if( $("#"+ box_id +" i.catalyst-refresh").length >0 ) $("#"+ box_id +" i.catalyst-refresh").parent('a').click();
		else if ( $("#"+ box_id +" span.catalyst-refresh").length >0 ) $("#"+ box_id +" span.catalyst-refresh").click();
		else if ( $("#"+ box_id +" a#wrk_search_button").length >0 ) $("#"+ box_id +" a#wrk_search_button").click();
	}else if(refresh_modal_id != ''){
		if($('#popup_box_' + refresh_modal_id + '').length != 0){
			var url = $('#popup_box_' + refresh_modal_id + '').find("input[name = box_address_" + refresh_modal_id + "]").val();
			openBoxDraggable( url, refresh_modal_id );
		}
	}
}
function closeBoxDraggable( modal_id = "", box_id = "", refresh_modal_id = "" ){
	if (modal_id !== '') {
		$('#popup_box_' + modal_id).remove();
	} else {
		/* modal_id bilinmiyorsa açık olan tüm popup_box_* divlerini kaldır */
		$('[id^="popup_box_"]').remove();
	}
	$("body").removeClass("modal-opened");
	if( box_id != '' || refresh_modal_id != '') refreshBox(box_id, refresh_modal_id);
}
function loadPopupBox(form_name, modal_id = ""){
	var form = $('form[name = ' + form_name + ']');
	openBoxDraggable( decodeURIComponent( form.attr( "action" ) ).replaceAll("+", " "), modal_id, "", form );
	return false;
}
function runUrl(url, params, box_id) {
	var data = new FormData();
	if( typeof params != undefined ) for(var i in params) data.append(i, params[i]);
	AjaxControlPostDataJson( url, data, function( response ){ 
		if( response.STATUS ){ 
			if( typeof box_id != undefined ) refreshBox(box_id);
		} else alertObject({message: response.MESSAGE, type: "danger"});
	});
}

// İstenilen url'den içeriği alır ve id'si verilen elementin içine basar.
function AjaxLoader( url, element ){
	$( element ).html('<div id="divPageLoad"><?xml version="1.0" encoding="utf-8"?><svg width="32px" height="32px" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" preserveAspectRatio="xMidYMid" class="uil-ring-alt"><rect x="0" y="0" width="100" height="100" fill="none" class="bk"></rect><circle cx="50" cy="50" r="40" stroke="rgba(255,255,255,0)" fill="none" stroke-width="10" stroke-linecap="round"></circle><circle cx="50" cy="50" r="40" stroke="#ff8a00" fill="none" stroke-width="6" stroke-linecap="round"><animate attributeName="stroke-dashoffset" dur="2s" repeatCount="indefinite" from="0" to="502"></animate><animate attributeName="stroke-dasharray" dur="2s" repeatCount="indefinite" values="150.6 100.4;1 250;150.6 100.4"></animate></circle></svg></div>');
    new AjaxControl.AjaxRequest().get(url + "&isAjax=1", function( response ) {
        $( element ).html( response );
    });
}
function AjaxLoaderWithData( url, data, element, afterfunction){
	$( element ).html('<div id="divPageLoad"><?xml version="1.0" encoding="utf-8"?><svg width="32px" height="32px" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" preserveAspectRatio="xMidYMid" class="uil-ring-alt"><rect x="0" y="0" width="100" height="100" fill="none" class="bk"></rect><circle cx="50" cy="50" r="40" stroke="rgba(255,255,255,0)" fill="none" stroke-width="10" stroke-linecap="round"></circle><circle cx="50" cy="50" r="40" stroke="#ff8a00" fill="none" stroke-width="6" stroke-linecap="round"><animate attributeName="stroke-dashoffset" dur="2s" repeatCount="indefinite" from="0" to="502"></animate><animate attributeName="stroke-dasharray" dur="2s" repeatCount="indefinite" values="150.6 100.4;1 250;150.6 100.4"></animate></circle></svg></div>');
    new AjaxControl.AjaxRequest().postData(url + "&isAjax=1", data, function( response ) {
        $( element ).html( response );
		if(typeof afterfunction == 'function') afterfunction();
    });
}
// İstenilen url'ye parametreleri formdata olarak post metoduyla gönderir. callback aracılığıyla response ile işlem yapmanızı sağlar
function AjaxControlPostData( url, data, calback ){
    new AjaxControl.AjaxRequest().postData(url + "&isAjax=1", data, calback) 
}
// İstenilen url'ye parametreleri formdata olarak post metoduyla gönderir. callback aracılığıyla json response ile işlem yapmanızı sağlar
function AjaxControlPostDataJson( url, data, calback, beforeSend ){
    new AjaxControl.AjaxRequest().postDataJson(url + "&isAjax=1", data, calback, function(rsp){console.log(rsp);}, beforeSend) 
}
// İstenilen url'ye parametreleri formdata olarak get metoduyla gönderir. callback aracılığıyla json response ile işlem yapmanızı sağlar
function AjaxControlGetDataJson( url, data, calback ){
    new AjaxControl.AjaxRequest().getDataJson(url + "&isAjax=1", data, calback) 
}