<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <title>Giriş Yap — Rasih Çelik Boyahane</title>

    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN" crossorigin="anonymous">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css" integrity="sha512-DTOQO9RWCH3ppGqcWaEA1BIZOC6xxalwEsw9c2QQeAIftl+Vegovlnee1c9QX4TctnWMn13TZye+giMm8e2LwA==" crossorigin="anonymous" referrerpolicy="no-referrer" />

    <style>
        :root {
            --primary:    #1a3a5c;
            --primary-dk: #0d2137;
            --accent:     #e67e22;
            --accent-dk:  #cf6d17;
        }

        *, *::before, *::after { box-sizing: border-box; }

        body {
            margin: 0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            background: var(--primary-dk);
            font-family: 'Segoe UI', system-ui, sans-serif;
            overflow: hidden;
        }

        /* Animated background blobs */
        .bg-blobs {
            position: fixed;
            inset: 0;
            z-index: 0;
            overflow: hidden;
            pointer-events: none;
        }
        .bg-blobs span {
            position: absolute;
            border-radius: 50%;
            opacity: 0.12;
            animation: drift 18s ease-in-out infinite alternate;
        }
        .bg-blobs span:nth-child(1) { width:520px;height:520px;background:var(--accent);  top:-120px;left:-160px;animation-duration:20s; }
        .bg-blobs span:nth-child(2) { width:380px;height:380px;background:#3b82f6;         bottom:-80px;right:-100px;animation-duration:15s;animation-delay:-6s; }
        .bg-blobs span:nth-child(3) { width:260px;height:260px;background:var(--primary);  top:40%;left:55%;animation-duration:22s;animation-delay:-10s; }
        @keyframes drift {
            from { transform: translate(0,0) scale(1); }
            to   { transform: translate(30px,40px) scale(1.08); }
        }

        /* Card */
        .login-card {
            position: relative;
            z-index: 1;
            display: flex;
            width: min(920px, 96vw);
            border-radius: 20px;
            overflow: hidden;
            box-shadow: 0 32px 80px rgba(0,0,0,0.45);
        }

        /* Left panel */
        .login-panel-left {
            flex: 0 0 380px;
            background: linear-gradient(160deg, var(--primary) 0%, var(--primary-dk) 100%);
            padding: 56px 44px;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            color: #fff;
            position: relative;
            overflow: hidden;
        }
        .login-panel-left::before {
            content: '';
            position: absolute;
            width: 300px; height: 300px;
            background: var(--accent);
            border-radius: 50%;
            opacity: 0.07;
            bottom: -80px; right: -80px;
        }
        .login-panel-left::after {
            content: '';
            position: absolute;
            width: 180px; height: 180px;
            background: #fff;
            border-radius: 50%;
            opacity: 0.04;
            top: -50px; left: -50px;
        }
        .brand-logo {
            width: 62px; height: 62px;
            background: var(--accent);
            border-radius: 16px;
            display: flex; align-items: center; justify-content: center;
            font-size: 1.7rem; color: #fff;
            margin-bottom: 28px;
            box-shadow: 0 8px 24px rgba(230,126,34,0.35);
        }
        .brand-name {
            font-size: 1.45rem; font-weight: 800;
            letter-spacing: -0.01em; line-height: 1.2;
            margin-bottom: 6px;
        }
        .brand-sub {
            font-size: 0.82rem; color: rgba(255,255,255,0.55);
            text-transform: uppercase; letter-spacing: 0.1em; font-weight: 600;
        }
        .left-features { margin-top: 48px; }
        .left-feature {
            display: flex; align-items: center; gap: 14px;
            margin-bottom: 20px; opacity: 0.85;
        }
        .left-feature-icon {
            width: 36px; height: 36px; border-radius: 10px;
            background: rgba(255,255,255,0.1);
            display: flex; align-items: center; justify-content: center;
            font-size: 0.95rem; flex-shrink: 0;
        }
        .left-feature-text { font-size: 0.875rem; line-height: 1.35; }
        .left-feature-text strong { display: block; font-weight: 700; color: #fff; }
        .left-feature-text span   { color: rgba(255,255,255,0.5); font-size: 0.78rem; }
        .left-footer { font-size: 0.72rem; color: rgba(255,255,255,0.28); letter-spacing: 0.04em; }

        /* Right panel */
        .login-panel-right {
            flex: 1;
            background: #fff;
            padding: 52px;
            display: flex; flex-direction: column; justify-content: center;
        }
        .login-heading { margin-bottom: 28px; }
        .login-heading h2 {
            font-size: 1.65rem; font-weight: 800;
            color: var(--primary); margin: 0 0 6px;
        }
        .login-heading p { font-size: 0.875rem; color: #6b7280; margin: 0; }

        .alert { border-radius: 12px; font-size: 0.875rem; }
        .alert-danger  { background: #fef2f2; border-color: #fecaca; color: #991b1b; }
        .alert-success { background: #f0fdf4; border-color: #bbf7d0; color: #166534; }

        .login-panel-right .form-label {
            font-size: 0.82rem; font-weight: 700; color: #374151;
            margin-bottom: 6px; letter-spacing: 0.02em; text-transform: uppercase;
        }
        .login-panel-right .input-group-text {
            background: #f8fafc; border: 1.5px solid #e2e8f0; border-right: none;
            color: #94a3b8; padding: 0 14px;
        }
        .login-panel-right .input-group > .form-control {
            border: 1.5px solid #e2e8f0; border-left: none; border-right: none;
            font-size: 0.9rem; padding: 11px 14px; color: #1e293b; background: #f8fafc;
        }
        .login-panel-right .input-group > .form-control:focus {
            border-color: var(--accent); box-shadow: none; background: #fff; z-index: 2;
        }
        .login-panel-right .input-group:focus-within .input-group-text {
            border-color: var(--accent); background: #fff;
        }
        .eye-toggle {
            background: #f8fafc; border: 1.5px solid #e2e8f0; border-left: none;
            color: #94a3b8; cursor: pointer; padding: 0 14px;
            transition: color 0.15s; border-radius: 0 8px 8px 0 !important;
        }
        .eye-toggle:hover { color: var(--accent); }
        .login-panel-right .input-group:focus-within .eye-toggle {
            border-color: var(--accent); background: #fff;
        }
        .login-meta {
            display: flex; align-items: center; justify-content: space-between;
            margin-bottom: 22px;
        }
        .form-check-input:checked { background-color: var(--accent); border-color: var(--accent); }
        .form-check-label { font-size: 0.845rem; color: #4b5563; }
        .forgot-link {
            font-size: 0.845rem; color: var(--accent);
            text-decoration: none; font-weight: 600; transition: color 0.15s;
        }
        .forgot-link:hover { color: var(--accent-dk); }

        .btn-login {
            background: linear-gradient(135deg, var(--accent) 0%, var(--accent-dk) 100%);
            border: none; color: #fff;
            font-size: 0.9rem; font-weight: 700; letter-spacing: 0.04em;
            padding: 13px 20px; border-radius: 12px; width: 100%;
            transition: transform 0.15s, box-shadow 0.15s;
            box-shadow: 0 4px 18px rgba(230,126,34,0.3);
        }
        .btn-login:hover { transform: translateY(-2px); box-shadow: 0 8px 26px rgba(230,126,34,0.4); color: #fff; }
        .btn-login:active { transform: translateY(0); }

        .login-footer-note {
            text-align: center; margin-top: 24px;
            font-size: 0.78rem; color: #9ca3af;
        }
        .login-footer-note i { color: #10b981; }

        @media (max-width: 680px) {
            .login-panel-left { display: none !important; }
            .login-panel-right { padding: 40px 28px; }
        }
    </style>
</head>
<body>

    <div class="bg-blobs"><span></span><span></span><span></span></div>

    <div class="login-card">

        <!--- Left panel --->
        <div class="login-panel-left">
            <div>
                <div class="brand-logo"><i class="fas fa-industry"></i></div>
                <div class="brand-name">Rasih Çelik<br>Boyahane</div>
                <div class="brand-sub">Yönetim Sistemi</div>
            </div>
            <div class="left-features">
                <div class="left-feature">
                    <div class="left-feature-icon"><i class="fas fa-layer-group"></i></div>
                    <div class="left-feature-text">
                        <strong>Üretim Takibi</strong>
                        <span>İş emirleri ve süreç yönetimi</span>
                    </div>
                </div>
                <div class="left-feature">
                    <div class="left-feature-icon"><i class="fas fa-boxes-stacked"></i></div>
                    <div class="left-feature-text">
                        <strong>Stok Kontrolü</strong>
                        <span>Gerçek zamanlı envanter durumu</span>
                    </div>
                </div>
                <div class="left-feature">
                    <div class="left-feature-icon"><i class="fas fa-chart-line"></i></div>
                    <div class="left-feature-text">
                        <strong>Raporlama</strong>
                        <span>Anlık analiz ve dashboard</span>
                    </div>
                </div>
                <div class="left-feature">
                    <div class="left-feature-icon"><i class="fas fa-shield-halved"></i></div>
                    <div class="left-feature-text">
                        <strong>Güvenli Erişim</strong>
                        <span>Rol bazlı yetkilendirme</span>
                    </div>
                </div>
            </div>
            <div class="left-footer">&copy; 2026 Rasih Çelik &mdash; Tüm hakları saklıdır</div>
        </div>

        <!--- Right panel --->
        <div class="login-panel-right">

            <div class="login-heading">
                <h2>Hoş Geldiniz</h2>
                <p>Devam etmek için hesabınıza giriş yapın</p>
            </div>

            <!--- Error Message --->
            <cfif structKeyExists(url, "error")>
                <div class="alert alert-danger alert-dismissible fade show mb-4" role="alert">
                    <i class="fas fa-circle-exclamation me-2"></i>
                    <cfif url.error eq "invalid">
                        <strong>Hata!</strong> Kullanıcı adı veya şifre hatalı.
                    <cfelseif url.error eq "empty">
                        <strong>Uyarı!</strong> Lütfen tüm alanları doldurun.
                    <cfelseif url.error eq "inactive">
                        <strong>Hata!</strong> Hesabınız aktif değil. Yönetici ile iletişime geçin.
                    <cfelse>
                        <strong>Hata!</strong> Bir sorun oluştu, lütfen tekrar deneyin.
                    </cfif>
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Kapat"></button>
                </div>
            </cfif>

            <!--- Success Message --->
            <cfif structKeyExists(url, "success")>
                <div class="alert alert-success alert-dismissible fade show mb-4" role="alert">
                    <i class="fas fa-circle-check me-2"></i>
                    <cfif url.success eq "logout">
                        <strong>Başarılı!</strong> Güvenli çıkış yapıldı.
                    </cfif>
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Kapat"></button>
                </div>
            </cfif>

            <!--- Login Form --->
            <form method="post" action="login_action.cfm" id="loginForm" novalidate>

                <div class="mb-3">
                    <label for="username" class="form-label">Kullanıcı Adı</label>
                    <div class="input-group">
                        <span class="input-group-text"><i class="fas fa-user"></i></span>
                        <input type="text" class="form-control" id="username" name="username"
                               placeholder="Kullanıcı adınızı girin" required autofocus
                               autocomplete="username">
                    </div>
                </div>

                <div class="mb-3">
                    <label for="password" class="form-label">Şifre</label>
                    <div class="input-group">
                        <span class="input-group-text"><i class="fas fa-lock"></i></span>
                        <input type="password" class="form-control" id="password" name="password"
                               placeholder="Şifrenizi girin" required
                               autocomplete="current-password">
                        <button class="eye-toggle" type="button" onclick="togglePassword()" tabindex="-1" aria-label="Şifreyi göster/gizle">
                            <i class="fas fa-eye" id="toggleIcon"></i>
                        </button>
                    </div>
                </div>

                <div class="login-meta">
                    <div class="form-check">
                        <input class="form-check-input" type="checkbox" id="remember" name="remember">
                        <label class="form-check-label" for="remember">Beni Hatırla</label>
                    </div>
                    <a href="#" class="forgot-link" onclick="return false;">Şifremi Unuttum?</a>
                </div>

                <button type="submit" class="btn-login">
                    <i class="fas fa-right-to-bracket me-2"></i>Giriş Yap
                </button>

            </form>

            <div class="login-footer-note">
                <i class="fas fa-circle-check me-1"></i>
                SSL şifreli güvenli bağlantı &bull; Rasih Çelik &copy; 2026
            </div>

        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" integrity="sha384-C6RzsynM9kWDrMNeT87bh95OGNyZPhcTNXj1NW7RuBCsyN/o0jlpcV8Qyq46cDfL" crossorigin="anonymous"></script>
    <script>
        function togglePassword() {
            var inp  = document.getElementById('password');
            var icon = document.getElementById('toggleIcon');
            if (inp.type === 'password') {
                inp.type = 'text';
                icon.classList.replace('fa-eye', 'fa-eye-slash');
            } else {
                inp.type = 'password';
                icon.classList.replace('fa-eye-slash', 'fa-eye');
            }
        }

        document.getElementById('loginForm').addEventListener('submit', function(e) {
            var u = document.getElementById('username').value.trim();
            var p = document.getElementById('password').value.trim();
            if (!u || !p) {
                e.preventDefault();
                document.getElementById('username').focus();
            }
        });
    </script>
</body>
</html>