<cfcomponent hint="Collection of utilities">
	<!---
	Emulate CF9 directoryList function.
	Lists the contents of directory.
	Also lists the contents of the sub-directories if recurse is set to true.
	Usage: $directoryList(expandPath('cfc'),false,'name',"*.cfc","datelastmodified DESC")

	@param	path		The absolute path of the directory for which to list the contents. (Required)
	@param	recurse		Whether ColdFusion performs the action on subdirectories. (Optional)
	@param	listInfo	[name,path,query] - name: returns an array of names of files and directories; path: returns an array of paths of files and directories; query: returns a query. (Optional)
	@param	filter		File extension filter applied to returned names, for example, *.cfm. One filter can be applied. (Optional)
	@param	sort		Query columns by which to sort a directory listing. (Optional)
	@return If listInfo="query" returns query, otherwise array
	@author Marko Simic (marko.simic@gmail.com)
	@version 1
	--->
	<cffunction name="directoryList" access="public" returntype="any"
		hint="Emulate CF9 directoryList function. Lists the contents of directory. Also lists the content of the sub-directories if recurse is set to true.">
		<cfargument name="path" hint="The absolute path of the directory for which to list the contents." type="string" required="true">
		<cfargument name="recurse"
					hint="Whether ColdFusion performs the action on subdirectories"
					type="boolean" default="false" required="false">
		<cfargument name="listInfo" hint="[name,path,query] - name: returns an array of names of files and directories; path: returns an array of paths of files and directories; query: returns a query." type="string" default="path" required="false">
		<cfargument name="filter" hint="File extension filter applied to returned names, for example, *.cfm. One filter can be applied." type="string" default="" required="false">
		<cfargument name="sort" hint="Query columns by which to sort a directory listing. " type="string" default="" required="false">

		<cfset var local = structNew()>

		<cfif not directoryExists(arguments.path)>
			<cfthrow message="The specified directory #arguments.path# does not exist.">
		</cfif>

		<!---
			Dont flame me for this. I am just emulating bahvior of cf9 function
			I know that "/" works eveywhere
		--->
		<cfset local.objSystem = createObject("java", "java.lang.System")>
		<cfset local.fileSeparator = local.objSystem.getProperty("file.separator")>

		<cfset local.listInfo = 'all'>

		<cfdirectory
			directory = "#arguments.path#"
			action = "list"
			filter = "#arguments.filter#"
			listInfo = "#local.listInfo#"
			name = "local.retval"
			recurse = "#arguments.recurse#"
			sort = "#arguments.sort#"
			type = 'all' >

		<!---
			This is there point where performance difference is made (compared to original function)
			Otherwords, for listInfo = query, difference is insignificant
		--->
		<cfswitch expression="#arguments.listInfo#">
			<cfcase value="path">
				<cfquery name="local.qryGetFullPaths" dbtype="query">
					select
						(DIRECTORY + '#local.fileSeparator#' + NAME) as fspath
					from [local].retval
				</cfquery>
				<cfset local.retval = listToArray(valueList(local.qryGetFullPaths.fspath))>
			</cfcase>
			<cfcase value="name">
				<cfset local.retval = listToArray(valueList(local.retval.NAME))>
			</cfcase>
		</cfswitch>

		<cfreturn local.retval/>
	</cffunction>
	<!---
	A function equivalent of the cflog tag, which can be used in <cfscript>.
	@usage writelog (text, type, application, file, log)
	--->
	<cffunction
		access="public"
		returntype="void"
		name="writeLog"
		hint="A function equivalent of the cflog tag, which can be used in <cfscript>.">
		<cfargument
			required="true"
			type="string"
			name="text"
			hint="Message text to log.">
		<cfargument
			required="false"
			type="boolean"
			name="application"
			default="true"
			hint="yes - ogs the application name, if it is specified in a cfapplication tag or Application.cfc file.">
		<cfargument
			required="false"
			type="string"
			name="file"
			default=""
			hint="Message file. Specify only the main part of the filename. For example, to log to the Testing.log file, specify 'Testing'. The file must be located in the default log directory.">
		<cfargument
			required="false"
			type="string"
			name="log"
			default=""
			hint="[Application,Scheduler] - If you omit the file attribute, writes messages to standard log file. Ignored, if you specify file attribute.">
		<cfargument
			required="false"
			type="string"
			name="type"
			default="Information"
			hint="[Information,Warning,Error,Fatal] - Type (severity) of the message">
			<cfset var args = structNew()>
			<cfset args = duplicate(arguments)>
			<cfif arguments.file eq "">
				<cfset structDelete(args,"file")>
			</cfif>
			<cfif arguments.log eq "">
				<cfset structDelete(args,"log")>
			</cfif>
			<cflog attributecollection = "#args#"/>
	</cffunction>
</cfcomponent>