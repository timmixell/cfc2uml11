<cfsetting showdebugoutput="false">

<cfparam name="form.trfile" default="">
<cfparam name="form.trfolder" default="">

<cfset strRoot = expandPath("../")>

<cfscript>
	variables.strDlgMsg = "";
	variables.strDlgStatus = "error";
	
	try{
		if(form.trfile==""){
			variables.path = strRoot & form.trfolder;
			variables.type = "folder"; 
		}
		else{
			variables.path = strRoot & form.trfile;
			variables.type = "file";		
		}

		variables.strFileLoc='';
		variables.bAutogen=true;
		
		variables.refCFC2UML = createObject('component','cfc2uml');

		switch (variables.type){
			case "folder":
				variables.utilities = createObject('component','cfc2umlutils');
				variables.arrFiles = variables.utilities.directoryList(variables.path, true, 'path', "*.cfc");

				variables.xmlUML = ''; //UML XMI file
				variables.sPrimitivesMap = ''; //chached map of custuom primitive types definitions (cfc2xml.xml)
				variables.objCFC2UML = '';

				for(i=1;i<=arrayLen(variables.arrFiles);++i){
					variables.strCFCAbsFilePath = variables.arrFiles[i];

					if (variables.xmlUML==''){ //first pass
						variables.objCFC2UML = variables.refCFC2UML.init(
																	variables.strCFCAbsFilePath
																);
					}
					else{
						variables.objCFC2UML = variables.refCFC2UML.init(
																	cfcPath=variables.strCFCAbsFilePath,
																	xmlUML=variables.xmlUML,
																	sPrimitivesMap=variables.sPrimitivesMap
																);
					}
					variables.xmlUML = variables.objCFC2UML.getUML();
					variables.sPrimitivesMap = variables.objCFC2UML.getPrimitivesMap();
				}

				if (variables.bAutogen || variables.strFileLoc==''){
					variables.strUMLFilePath = variables.path & "/" & createUUID() & ".uml"; //UML file path
				}
				else{
					variables.strUMLFilePath = variables.strFileLoc;
				}
				
				variables.xmlUML = variables.refCFC2UML.XMLSort(variables.xmlUML);
				fileWrite(variables.strUMLFilePath,variables.xmlUML,'utf-8');
			break;
			case "file":
				variables.objCFC2UML = variables.refCFC2UML.init(variables.path);
				variables.xmlUML = variables.objCFC2UML.getUML();

				if (variables.bAutogen || variables.strFileLoc==''){
					variables.strUMLFilePath = variables.path & ".uml";
				}
				else{
					variables.strUMLFilePath = variables.strFileLoc;
				}
				
				variables.xmlUML = variables.refCFC2UML.XMLSort(variables.xmlUML);
				fileWrite(variables.strUMLFilePath,variables.xmlUML,'utf-8');
			break;
		}

		variables.strDlgMsg = 'UML Model successfully generated in ' & variables.strUMLFilePath;
		variables.strDlgStatus = "success";
	}
	catch(any ex){
		//writelog(log="Application",text=ex.Message);
		variables.strDlgMsg = "Error message:" & ex.Message;
	}
</cfscript>
<h3>
STATUS: <cfoutput>#variables.strDlgStatus#</cfoutput><br>
MESSAGE: <cfoutput>#variables.strDlgMsg#</cfoutput><br>
</h3>