<cfsetting showdebugoutput="false">

<cfparam name="ideeventinfo">

<cfset data = xmlParse(ideeventinfo)>

<cfscript>
	variables.strDlgMsg = "";
	variables.strDlgStatus = "error";
	try{
		variables.path = data.event.ide.projectview.resource.xmlAttributes['path'];
		variables.type = data.event.ide.projectview.resource.xmlAttributes['type'];

		variables.strFileLoc='';
		variables.bAutogen=true;
		for (i=1;i<=arraylen(data.event.user.input);++i){
			switch(data.event.user.input[i].xmlAttributes['name']){
				case "autogenerate":
					variables.bAutogen=data.event.user.input[i].xmlAttributes['value'];
				break;
				case "saveloc":
					variables.strFileLoc=data.event.user.input[i].xmlAttributes['value'];
				break;
			}
		}
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

		variables.strDlgMsg = 'UML Model successfully generated in ' & variables.strUMLFilePath & '. Please REFRESH folder (form CFB)where UML file is saved.';
		variables.strDlgStatus = "success";
	}
	catch(any ex){
		variables.strDlgMsg = "Error message: " & ex.ExtendedInfo & ": " & ex.Message;
	}
</cfscript>

<cfheader name="Content-Type" value="text/xml">
<response status="<cfoutput>#variables.strDlgStatus#</cfoutput>" showresponse="true">
	<ide message="<cfoutput>#variables.strDlgMsg#</cfoutput>" />
</response>