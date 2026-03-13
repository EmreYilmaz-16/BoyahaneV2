<cfprocessingdirective pageEncoding="utf-8">
<!--- Logout - Session'ı temizle --->

<cflock scope="session" type="exclusive" timeout="10">
    <cfset structClear(session)>
</cflock>

<!--- Cookie'yi temizle --->
<cfcookie name="boyahane_remember" value="" expires="now">

<!--- Login sayfasına yönlendir --->
<cflocation url="login.cfm?success=logout" addtoken="false">
