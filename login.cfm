<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <title>Giriş Yap - Rasih Çelik Boyahane</title>
    
    <!--- Bootstrap CSS --->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN" crossorigin="anonymous">
    
    <!--- Font Awesome --->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css" integrity="sha512-DTOQO9RWCH3ppGqcWaEA1BIZOC6xxalwEsw9c2QQeAIftl+Vegovlnee1c9QX4TctnWMn13TZye+giMm8e2LwA==" crossorigin="anonymous" referrerpolicy="no-referrer" />
    
    <style>
        body {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }
        .login-container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 15px 50px rgba(0, 0, 0, 0.2);
            overflow: hidden;
            max-width: 900px;
            width: 100%;
        }
        .login-left {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 60px 40px;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            text-align: center;
        }
        .login-left i {
            font-size: 80px;
            margin-bottom: 30px;
            opacity: 0.9;
        }
        .login-left h2 {
            font-weight: bold;
            margin-bottom: 20px;
        }
        .login-left p {
            font-size: 1.1rem;
            opacity: 0.9;
        }
        .login-right {
            padding: 60px 50px;
        }
        .login-title {
            text-align: center;
            margin-bottom: 40px;
            color: #333;
        }
        .login-title h3 {
            font-weight: bold;
            margin-bottom: 10px;
        }
        .login-title p {
            color: #666;
        }
        .form-control:focus {
            border-color: #667eea;
            box-shadow: 0 0 0 0.2rem rgba(102, 126, 234, 0.25);
        }
        .btn-login {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border: none;
            color: white;
            padding: 12px;
            font-size: 1.1rem;
            font-weight: 600;
            transition: all 0.3s;
        }
        .btn-login:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 20px rgba(102, 126, 234, 0.4);
        }
        .input-group-text {
            background-color: #f8f9fa;
            border-right: none;
        }
        .form-control {
            border-left: none;
        }
        .alert {
            border-radius: 10px;
        }
        .remember-forgot {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }
        .remember-forgot a {
            color: #667eea;
            text-decoration: none;
        }
        .remember-forgot a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="login-container row g-0">
            <!--- Left Side --->
            <div class="col-md-5 login-left d-none d-md-flex">
                <div>
                    <i class="fas fa-industry"></i>
                    <h2>Rasih Çelik Boyahane</h2>
                    <p>Üretim Yönetim Sistemi</p>
                    <p class="mt-4">
                        <small>Güvenli, hızlı ve modern boyahane yönetimi</small>
                    </p>
                </div>
            </div>

            <!--- Right Side - Login Form --->
            <div class="col-md-7 login-right">
                <div class="login-title">
                    <h3>Hoş Geldiniz</h3>
                    <p>Devam etmek için lütfen giriş yapın</p>
                </div>

                <!--- Error Message --->
                <cfif structKeyExists(url, "error")>
                    <div class="alert alert-danger alert-dismissible fade show" role="alert">
                        <i class="fas fa-exclamation-circle me-2"></i>
                        <cfif url.error eq "invalid">
                            <strong>Hata!</strong> Kullanıcı adı veya şifre hatalı.
                        <cfelseif url.error eq "empty">
                            <strong>Uyarı!</strong> Lütfen tüm alanları doldurun.
                        <cfelseif url.error eq "inactive">
                            <strong>Hata!</strong> Hesabınız aktif değil. Lütfen yönetici ile iletişime geçin.
                        <cfelse>
                            <strong>Hata!</strong> Bir sorun oluştu. Lütfen tekrar deneyin.
                        </cfif>
                        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                    </div>
                </cfif>

                <!--- Success Message --->
                <cfif structKeyExists(url, "success")>
                    <div class="alert alert-success alert-dismissible fade show" role="alert">
                        <i class="fas fa-check-circle me-2"></i>
                        <cfif url.success eq "logout">
                            <strong>Başarılı!</strong> Güvenli çıkış yapıldı.
                        </cfif>
                        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                    </div>
                </cfif>

                <!--- Login Form --->
                <form method="post" action="login_action.cfm" id="loginForm">
                    <div class="mb-4">
                        <label for="username" class="form-label">Kullanıcı Adı</label>
                        <div class="input-group">
                            <span class="input-group-text">
                                <i class="fas fa-user"></i>
                            </span>
                            <input type="text" class="form-control" id="username" name="username" 
                                   placeholder="Kullanıcı adınızı girin" required autofocus>
                        </div>
                    </div>

                    <div class="mb-4">
                        <label for="password" class="form-label">Şifre</label>
                        <div class="input-group">
                            <span class="input-group-text">
                                <i class="fas fa-lock"></i>
                            </span>
                            <input type="password" class="form-control" id="password" name="password" 
                                   placeholder="Şifrenizi girin" required>
                            <span class="input-group-text" style="cursor: pointer; border-left: 1px solid #ced4da;" 
                                  onclick="togglePassword()">
                                <i class="fas fa-eye" id="toggleIcon"></i>
                            </span>
                        </div>
                    </div>

                    <div class="remember-forgot">
                        <div class="form-check">
                            <input class="form-check-input" type="checkbox" id="remember" name="remember">
                            <label class="form-check-label" for="remember">
                                Beni Hatırla
                            </label>
                        </div>
                        <a href="#" onclick="alert('Şifre sıfırlama özelliği yakında eklenecek.'); return false;">
                            Şifremi Unuttum?
                        </a>
                    </div>

                    <button type="submit" class="btn btn-login w-100">
                        <i class="fas fa-sign-in-alt me-2"></i>Giriş Yap
                    </button>
                </form>

                <div class="text-center mt-4">
                    <small class="text-muted">
                        <i class="fas fa-shield-alt me-1"></i>
                        Güvenli bağlantı ile korunmaktasınız
                    </small>
                </div>
            </div>
        </div>
    </div>

    <!--- Bootstrap JS --->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" integrity="sha384-C6RzsynM9kWDrMNeT87bh95OGNyZPhcTNXj1NW7RuBCsyN/o0jlpcV8Qyq46cDfL" crossorigin="anonymous"></script>
    
    <!--- Custom JavaScript --->
    <script>
        function togglePassword() {
            const passwordInput = document.getElementById('password');
            const toggleIcon = document.getElementById('toggleIcon');
            
            if (passwordInput.type === 'password') {
                passwordInput.type = 'text';
                toggleIcon.classList.remove('fa-eye');
                toggleIcon.classList.add('fa-eye-slash');
            } else {
                passwordInput.type = 'password';
                toggleIcon.classList.remove('fa-eye-slash');
                toggleIcon.classList.add('fa-eye');
            }
        }

        // Form validation
        document.getElementById('loginForm').addEventListener('submit', function(e) {
            const username = document.getElementById('username').value.trim();
            const password = document.getElementById('password').value.trim();
            
            if (!username || !password) {
                e.preventDefault();
                alert('Lütfen tüm alanları doldurun!');
                return false;
            }
        });
    </script>
</body>
</html>
