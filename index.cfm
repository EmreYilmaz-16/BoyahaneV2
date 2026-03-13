<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <title>Boyahane - Rasih Çelik</title>
    
    <!--- Bootstrap CSS --->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN" crossorigin="anonymous">
    
    <!--- Font Awesome --->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css" integrity="sha512-DTOQO9RWCH3ppGqcWaEA1BIZOC6xxalwEsw9c2QQeAIftl+Vegovlnee1c9QX4TctnWMn13TZye+giMm8e2LwA==" crossorigin="anonymous" referrerpolicy="no-referrer" />
    
    <!--- DevExtreme CSS --->
    <link rel="stylesheet" href="https://cdn3.devexpress.com/jslib/23.2.5/css/dx.light.css">
    
    <!--- Custom CSS --->
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f8f9fa;
        }
        .navbar-brand {
            font-weight: bold;
            font-size: 1.5rem;
        }
        .main-content {
            min-height: calc(100vh - 120px);
        }
        .footer {
            background-color: #343a40;
            color: white;
            padding: 20px 0;
            margin-top: 50px;
        }
        .card-custom {
            transition: transform 0.2s;
            height: 100%;
        }
        .card-custom:hover {
            transform: translateY(-5px);
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
        }
    </style>
</head>
<body>
    <!--- Navigation Bar --->
    <nav class="navbar navbar-expand-lg navbar-dark bg-dark">
        <div class="container-fluid">
            <a class="navbar-brand" href="index.cfm">
                <i class="fas fa-industry me-2"></i>Rasih Çelik Boyahane
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
                        <a class="nav-link" href="#uretim">
                            <i class="fas fa-cogs"></i> Üretim
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="#stok">
                            <i class="fas fa-boxes"></i> Stok
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="#raporlar">
                            <i class="fas fa-chart-bar"></i> Raporlar
                        </a>
                    </li>
                    <li class="nav-item dropdown">
                        <a class="nav-link dropdown-toggle" href="#" id="navbarDropdown" role="button" data-bs-toggle="dropdown" aria-expanded="false">
                            <i class="fas fa-user-circle"></i> Kullanıcı
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="navbarDropdown">
                            <li><a class="dropdown-item" href="#profil"><i class="fas fa-user me-2"></i>Profil</a></li>
                            <li><a class="dropdown-item" href="#ayarlar"><i class="fas fa-cog me-2"></i>Ayarlar</a></li>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item" href="#cikis"><i class="fas fa-sign-out-alt me-2"></i>Çıkış</a></li>
                        </ul>
                    </li>
                </ul>
            </div>
        </div>
    </nav>

    <!--- Main Content --->
    <div class="container-fluid main-content mt-4">
        <div class="row">
            <div class="col-12">
                <h2 class="mb-4">
                    <i class="fas fa-dashboard me-2"></i>Kontrol Paneli
                </h2>
            </div>
        </div>

        <!--- Dashboard Cards --->
        <div class="row g-4 mb-4">
            <div class="col-md-3">
                <div class="card card-custom text-white bg-primary">
                    <div class="card-body">
                        <div class="d-flex justify-content-between align-items-center">
                            <div>
                                <h6 class="card-title text-uppercase mb-0">Günlük Üretim</h6>
                                <h2 class="mt-2 mb-0">1,245</h2>
                            </div>
                            <div class="fs-1">
                                <i class="fas fa-box-open"></i>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card card-custom text-white bg-success">
                    <div class="card-body">
                        <div class="d-flex justify-content-between align-items-center">
                            <div>
                                <h6 class="card-title text-uppercase mb-0">Aktif Siparişler</h6>
                                <h2 class="mt-2 mb-0">42</h2>
                            </div>
                            <div class="fs-1">
                                <i class="fas fa-shopping-cart"></i>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card card-custom text-white bg-warning">
                    <div class="card-body">
                        <div class="d-flex justify-content-between align-items-center">
                            <div>
                                <h6 class="card-title text-uppercase mb-0">Bekleyen</h6>
                                <h2 class="mt-2 mb-0">18</h2>
                            </div>
                            <div class="fs-1">
                                <i class="fas fa-clock"></i>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card card-custom text-white bg-danger">
                    <div class="card-body">
                        <div class="d-flex justify-content-between align-items-center">
                            <div>
                                <h6 class="card-title text-uppercase mb-0">Geciken</h6>
                                <h2 class="mt-2 mb-0">5</h2>
                            </div>
                            <div class="fs-1">
                                <i class="fas fa-exclamation-triangle"></i>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!--- DevExtreme Grid Example --->
        <div class="row">
            <div class="col-12">
                <div class="card">
                    <div class="card-header bg-white">
                        <h5 class="mb-0">
                            <i class="fas fa-table me-2"></i>Son İşlemler
                        </h5>
                    </div>
                    <div class="card-body">
                        <div id="dataGrid"></div>
                    </div>
                </div>
            </div>
        </div>

        <!--- Chart Section --->
        <div class="row mt-4">
            <div class="col-md-8">
                <div class="card">
                    <div class="card-header bg-white">
                        <h5 class="mb-0">
                            <i class="fas fa-chart-line me-2"></i>Üretim Grafiği
                        </h5>
                    </div>
                    <div class="card-body">
                        <div id="chart"></div>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card">
                    <div class="card-header bg-white">
                        <h5 class="mb-0">
                            <i class="fas fa-pie-chart me-2"></i>Durum Dağılımı
                        </h5>
                    </div>
                    <div class="card-body">
                        <div id="pieChart"></div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!--- Footer --->
    <footer class="footer mt-5">
        <div class="container-fluid">
            <div class="row">
                <div class="col-md-6 text-center text-md-start">
                    <p class="mb-0">
                        <i class="fas fa-copyright me-1"></i>2026 Rasih Çelik Boyahane - Tüm hakları saklıdır
                    </p>
                </div>
                <div class="col-md-6 text-center text-md-end">
                    <p class="mb-0">
                        Powered by <strong>Workcube Catalyst</strong>
                    </p>
                </div>
            </div>
        </div>
    </footer>

    <!--- jQuery --->
    <script src="https://code.jquery.com/jquery-3.7.1.min.js" integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=" crossorigin="anonymous"></script>
    
    <!--- Bootstrap JS --->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" integrity="sha384-C6RzsynM9kWDrMNeT87bh95OGNyZPhcTNXj1NW7RuBCsyN/o0jlpcV8Qyq46cDfL" crossorigin="anonymous"></script>
    
    <!--- DevExtreme JS --->
    <script src="https://cdn3.devexpress.com/jslib/23.2.5/js/dx.all.js"></script>
    
    <!--- Custom JavaScript --->
    <script>
        $(document).ready(function() {
            // DevExtreme DataGrid
            $("#dataGrid").dxDataGrid({
                dataSource: [
                    { id: 1, siparis: "SIP-2026-001", urun: "Profil 40x40", miktar: 250, durum: "Tamamlandı", tarih: "2026-03-13" },
                    { id: 2, siparis: "SIP-2026-002", urun: "Boru 50mm", miktar: 180, durum: "İşlemde", tarih: "2026-03-13" },
                    { id: 3, siparis: "SIP-2026-003", urun: "Lama 30x30", miktar: 320, durum: "Beklemede", tarih: "2026-03-12" },
                    { id: 4, siparis: "SIP-2026-004", urun: "Profil 60x60", miktar: 150, durum: "Tamamlandı", tarih: "2026-03-12" },
                    { id: 5, siparis: "SIP-2026-005", urun: "Sac 2mm", miktar: 420, durum: "İşlemde", tarih: "2026-03-11" }
                ],
                columns: [
                    { dataField: "siparis", caption: "Sipariş No", width: 150 },
                    { dataField: "urun", caption: "Ürün" },
                    { dataField: "miktar", caption: "Miktar", dataType: "number", format: "#,##0" },
                    { dataField: "durum", caption: "Durum", 
                        cellTemplate: function(container, options) {
                            let badgeClass = "badge bg-secondary";
                            if(options.value === "Tamamlandı") badgeClass = "badge bg-success";
                            else if(options.value === "İşlemde") badgeClass = "badge bg-primary";
                            else if(options.value === "Beklemede") badgeClass = "badge bg-warning";
                            $("<span>").addClass(badgeClass).text(options.value).appendTo(container);
                        }
                    },
                    { dataField: "tarih", caption: "Tarih", dataType: "date", format: "dd.MM.yyyy" }
                ],
                showBorders: true,
                showRowLines: true,
                rowAlternationEnabled: true,
                columnAutoWidth: true,
                paging: {
                    pageSize: 10
                },
                pager: {
                    showPageSizeSelector: true,
                    allowedPageSizes: [5, 10, 20],
                    showInfo: true
                },
                filterRow: {
                    visible: true
                },
                headerFilter: {
                    visible: true
                },
                searchPanel: {
                    visible: true,
                    placeholder: "Ara..."
                },
                export: {
                    enabled: true
                }
            });

            // DevExtreme Chart
            $("#chart").dxChart({
                dataSource: [
                    { gun: "Pazartesi", miktar: 1150 },
                    { gun: "Salı", miktar: 1320 },
                    { gun: "Çarşamba", miktar: 1080 },
                    { gun: "Perşembe", miktar: 1450 },
                    { gun: "Cuma", miktar: 1245 },
                    { gun: "Cumartesi", miktar: 980 },
                    { gun: "Pazar", miktar: 750 }
                ],
                series: [{
                    argumentField: "gun",
                    valueField: "miktar",
                    type: "bar",
                    color: "#0d6efd"
                }],
                title: {
                    text: "Haftalık Üretim (Adet)"
                },
                legend: {
                    visible: false
                },
                tooltip: {
                    enabled: true,
                    customizeTooltip: function(arg) {
                        return {
                            text: arg.argumentText + ": " + arg.valueText + " adet"
                        };
                    }
                }
            });

            // DevExtreme PieChart
            $("#pieChart").dxPieChart({
                dataSource: [
                    { durum: "Tamamlandı", deger: 45 },
                    { durum: "İşlemde", deger: 30 },
                    { durum: "Beklemede", deger: 18 },
                    { durum: "Geciken", deger: 7 }
                ],
                series: [{
                    argumentField: "durum",
                    valueField: "deger",
                    label: {
                        visible: true,
                        connector: {
                            visible: true
                        },
                        customizeText: function(arg) {
                            return arg.argumentText + " (" + arg.valueText + "%)";
                        }
                    }
                }],
                legend: {
                    visible: false
                },
                tooltip: {
                    enabled: true,
                    customizeTooltip: function(arg) {
                        return {
                            text: arg.argumentText + ": %" + arg.valueText
                        };
                    }
                }
            });

            // Smooth scroll for anchor links
            $('a[href^="#"]').on('click', function(event) {
                var target = $(this.getAttribute('href'));
                if(target.length) {
                    event.preventDefault();
                    $('html, body').stop().animate({
                        scrollTop: target.offset().top - 70
                    }, 1000);
                }
            });
        });
    </script>
</body>
</html>