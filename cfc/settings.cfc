<!--- json_type parametresi 1 : tab menü, 2: page bar, null : page designer 
	objectID parametresi gelirse pageBar duzenleniyor
--->
	
<cfcomponent>
	<cffunction name="params" access="remote" returntype="struct">
    	<cfscript>
			var systemParam.dsn = 'boyahane';
			var systemParam.dsn3 = 'boyahane';
			if(isDefined("session.ep.PERIOD_YEAR")){
				var systemParam.dsn2 = 'boyahane';
			}else{
			var systemParam.dsn2 = 'boyahane';}
			var systemParam.uploadFolder = '\\devappsrv\documents\';
			dir_seperator = '\';
		</cfscript>
        <cfreturn systemParam>
    </cffunction>
	<cffunction method="post" name="changeSystemParams"  access="remote" returntype="struct">
		<cfargument  name="CompanyId">
		<cfargument  name="PeriodYear">
		<cfscript>
			var systemParam.dsn = 'boyahane';
			var systemParam.dsn3 = 'boyahane';
			
			//	var systemParam.dsn2 = 'boyahane';
			
			var systemParam.dsn2 = 'boyahane';
			var systemParam.uploadFolder = '\\devappsrv\documents\';
			dir_seperator = '\';
		</cfscript>
        <cfreturn systemParam>
    </cffunction>
</cfcomponent>