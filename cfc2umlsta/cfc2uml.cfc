<!---
	Translate component meta data to XMI (UML) format
	@author Marko Simic (marko.simic@gmail.com)
	@version 1.0, December 5, 2010
--->
<cfcomponent displayname="cfc2uml" hint="Translate component meta data to XMI (UML) format" output="false">

	<cffunction
		access="public"
		returntype="cfc2uml"
		name="init"
		hint="Constructor"
		output="false">
		<cfargument
			required="true"
			type="string"
			name="cfcPath"
			hint="Absolute or dot-delimited path to cfc file">
		<cfargument
			required="false"
			type="xml"
			name="xmlUML"
			default="#xmlNew()#"
			hint="XMI object">
		<cfargument
			required="false"
			type="struct"
			name="sPrimitivesMap"
			default="#structNew()#"
			hint="ID-Name hashmap of UML primitive definitions">

		<cfscript>
			var strCFCPath = arguments.cfcPath;

			if (strCFCPath == ""){
				throw (message="Path to cfc file cannot be empty!");
			}

			//UMl unique id of this component
			variables.strClassUMLId="";

			//id-name hashmap of primitive definitions
			variables.sPrimitivesMap={};

			// dot-delimited path to cfc
			variables.strCFCDotPath = '';

			// XML template with basic definitions
			variables.strXmlTemplate = '<?xml version="1.0" encoding="UTF-8"?>
				<uml:Model xmi:version="2.1" xmlns:xmi="http://schema.omg.org/spec/XMI/2.1" xmlns:uml="http://www.eclipse.org/uml2/3.0.0/UML" xmi:id="_PUhO8fR6Ed6NwpmnSdyTVA" name="" viewpoint=""></uml:Model>';

			// server type (adobe,railo)
			variables.servertype = server.coldfusion.productname;

			//ref to cfc2umlutils component
			variables.refUtilities = createObject("cfc2umlutils");

			// XMI object (xml)
			if (arguments.xmlUML!=''){
				variables.xmlUML = arguments.xmlUML;
			}else{
				variables.xmlUML = xmlParse(variables.strXmlTemplate);
			}

			//ID-Name hashmap of UML primitive definitions
			if (!structIsEmpty(arguments.sPrimitivesMap)){
				variables.sPrimitivesMap = arguments.sPrimitivesMap;
				variables.strPrimitivesAnyId = variables.sPrimitivesMap['any'];
			}
			else{
				//load primitive definitions into XML
				loadPrimitiveDefs();
			}

			//convert win to *nix path separators
			strCFCPath = replace(strCFCPath,chr(92),chr(47),"all");

			//check for path type
			if (!find("/",strCFCPath)){ //no slashes implies dot-delimited path
				variables.strCFCDotPath = strCFCPath;
			}else{
				if (!fileExists(strCFCPath)){
					throw(message="File at location #arguments.cfcPath# does not exist");
				}

				variables.strCFCDotPath = AbsoluteToDotPath(strCFCPath);
			}

		</cfscript>

		<cfreturn this/>
	</cffunction>

	<cffunction
		access="private"
		returntype="void"
		name="loadPrimitiveDefs"
		hint="Loads XML file with CF primitive types definitions. File cfc2uml.xml must be at the same location as this component."
		output="false">

		<cfset var sXmlDefs = ''>
		<cfset var arrXmlPrimitives = ''>
		<cfset var sXmlPrimitive = ''>
		<cfset var strPrimitiveName = ''>
		<cfset var strPrimitiveId = ''>
		<cfset var strCFC2UMLXMLPath = getDirectoryFromPath(getCurrentTemplatePath()) & "cfc2uml.xml">

		<cfif !fileExists(strCFC2UMLXMLPath)>
			<cfthrow message="File #strCFC2UMLXMLPath# does not exist!">
		</cfif>

		<cfscript>
			sXmlDegs = xmlParse(strCFC2UMLXMLPath);
			arrXmlPrimitives = xmlSearch(sXmlDegs, "/primitives/primitive");

			for (i=1; i <= arrayLen(arrXmlPrimitives); ++i){
				sXmlPrimitive = arrXmlPrimitives[i];

				strPrimitiveName = sXmlPrimitive.xmlAttributes["name"];
				strPrimitiveId = sXmlPrimitive.xmlAttributes["id"];

				variables.sPrimitivesMap[strPrimitiveName] = strPrimitiveId;
				arrayAppend(variables.xmlUML.xmlRoot.xmlChildren,
							createPrimitiveElement(
											strPrimitiveName,
											variables.xmlUML,
											strPrimitiveId
										)
							);
			}

			//Id of "Any" primitive type. Cache it for frequent use.
			variables.strPrimitivesAnyId = variables.sPrimitivesMap['any'];
		</cfscript>
	</cffunction>

	<cffunction
		access="private"
		returntype="string"
		name="getClassId"
		hint="Tries to locate UML ID of class in XMI. Returns ID if search is successfull otherwise returns an empty string.">
		<cfargument
			required="true"
			type="string"
			name="cfcDotPath"
			hint="dot-delimited path to CFC">

		<cfscript>
			var i = 1;
			var strUMLClassId = "";
			var strLoc = "";
			var strXPath = "";
			var arrSearchRes = "";
			var xmlCFCElem = "";

			for(i=1;i<listLen(arguments.cfcDotPath,'.');++i){
				strLoc = listGetAt(arguments.cfcDotPath,i,'.');
				strXPath &= "packagedElement[@type='uml:Package' and @name='" & strLoc & "']/";
			}

			strXPath &= "packagedElement[@type='uml:Class' and @name='" & listLast(arguments.cfcDotPath,'.') & "']";

			arrSearchRes = xmlSearch(variables.xmlUML,"//" & strXPath);
			if (isArray(arrSearchRes) && arraylen(arrSearchRes)){
				xmlCFCElem = arrSearchRes[1];
				strUMLClassId = xmlCFCElem.xmlAttributes["xmi:id"];
			}
		</cfscript>

		<cfreturn strUMLClassId />
	</cffunction>

	<cffunction
		access="private"
		returntype="xml"
		name="buildPackages"
		hint="Check if package is described in XMI, if not create node. Returns XML node of last/deepest package found in hierarchy.">
		<cfargument
			required="true"
			type="string"
			name="cfcDotPath"
			hint="dot-delimited path to CFC">

		<cfscript>
			var i = 1;
			var strUMLClassId = "";
			var strLoc = "";
			var strXPath = "";
			var arrSearchRes = "";
			var xmlCFCElem = variables.xmlUML.xmlRoot;

			strXPath = "";
			for(i=1;i<listLen(arguments.cfcDotPath,'.');++i){
				strLoc = listGetAt(arguments.cfcDotPath,i,'.');
				strXPath &= "packagedElement[@type='uml:Package' and @name='" & strLoc & "']/";

				arrSearchRes = xmlSearch(variables.xmlUML,"//" & strXPath);
				if (!(isArray(arrSearchRes) && arrayLen(arrSearchRes)>0)){
					arrayAppend(xmlCFCElem.xmlChildren,createPackageElement(strLoc,variables.xmlUML));
					xmlCFCElem = xmlCFCElem.xmlChildren[arrayLen(xmlCFCElem.xmlChildren)];
				}
				else{
					xmlCFCElem=arrSearchRes[1];
				}
			}
		</cfscript>

		<cfreturn xmlCFCElem />
	</cffunction>

	<cffunction
		access="private"
		returntype="String"
		name="getUinqueID"
		hint="Generate unique id"
		output="false">

		<cfset var uuid = "_" & replaceNoCase(lcase(createUUID()),"-","")>

		<cfreturn uuid/>
	</cffunction>

	<cffunction
		access="private"
		returntype="xml"
		name="createPrimitiveElement"
		output="false">
		<cfargument
			required="true"
			type="string"
			name="primitiveName"
			hint="Primitive name">
		<cfargument
			required="true"
			type="any"
			name="xmlObject"
			hint="XML document object in which you are creating the element">
		<cfargument
			required="false"
			type="string"
			name="id"
			default="#getUinqueID()#"
			hint="Primitive unique id">


		<cfscript>
			var xmlElement = xmlElemNew(arguments.xmlObject,"packagedElement");
			xmlElement.xmlAttributes["xmi:type"]="uml:PrimitiveType";
			xmlElement.xmlAttributes["xmi:id"]=arguments.id;
			xmlElement.xmlAttributes["name"]=arguments.primitiveName;
		</cfscript>

		<cfreturn xmlElement/>
	</cffunction>

	<cffunction
		access="private"
		returntype="xml"
		name="createPackageElement"
		output="false">
		<cfargument
			required="true"
			type="string"
			name="packageName"
			hint="Package name">
		<cfargument
			required="true"
			type="any"
			name="xmlObject"
			hint="XML document object in which you are creating the element">

		<cfscript>
			var xmlElement = xmlElemNew(arguments.xmlObject,"packagedElement");
			xmlElement.xmlAttributes["xmi:type"]="uml:Package";
			xmlElement.xmlAttributes["xmi:id"]=getUinqueID();
			xmlElement.xmlAttributes["name"]=arguments.packageName;
		</cfscript>

		<cfreturn xmlElement/>
	</cffunction>

	<cffunction
		access="private"
		returntype="xml"
		name="createClassElement"
		output="false">
		<cfargument
			required="true"
			type="string"
			name="className"
			hint="Package name">
		<cfargument
			required="true"
			type="any"
			name="xmlObject"
			hint="XML document object in which you are creating the element">

		<cfscript>
			var strExtClassId = '';
			var objCFCXml = '';
			var xmlElement = xmlElemNew(arguments.xmlObject,"packagedElement");
			xmlElement.xmlAttributes["xmi:type"]="uml:Class";
			variables.strClassUMLId=getUinqueID();
			xmlElement.xmlAttributes["xmi:id"]=variables.strClassUMLId;
			xmlElement.xmlAttributes["name"]=arguments.className;
		</cfscript>

		<cfreturn xmlElement/>
	</cffunction>

	<cffunction
		access="private"
		returntype="xml"
		name="createGeneralizationElement"
		output="false">
		<cfargument
			required="true"
			type="string"
			name="extClassId"
			hint="ID of parent class">
		<cfargument
			required="true"
			type="any"
			name="xmlObject"
			hint="XML document object in which you are creating the element">

		<cfscript>
			var xmlElement = xmlElemNew(arguments.xmlObject,"generalization");
			xmlElement.xmlAttributes["xmi:id"]=getUinqueID();
			xmlElement.xmlAttributes["general"]=arguments.extClassId;
		</cfscript>

		<cfreturn xmlElement/>
	</cffunction>

	<cffunction
		access="private"
		returntype="xml"
		name="createProperty"
		hint="Creates xmi elements which describes component property"
		output="false">
		<cfargument
			required="true"
			type="string"
			name="name"
			hint="property name">
		<cfargument
			required="true"
			type="string"
			name="typeId"
			hint="Argument's primitive type UML ID. Defined in cfc2uml.xml">
		<cfargument
			required="true"
			type="any"
			name="xmlObject"
			hint="XML document object in which you are creating the element" >

		<cfscript>
			var xmlProp = xmlElemNew(arguments.xmlObject,"ownedAttribute");
			xmlProp.xmlAttributes["xmi:id"]=getUinqueID();
			xmlProp.xmlAttributes["name"]=arguments.name;
			xmlProp.xmlAttributes["type"]=arguments.typeId;
		</cfscript>

		<cfreturn xmlProp/>
	</cffunction>

	<cffunction
		access="private"
		returntype="xml"
		name="createMethodElement"
		output="false">
		<cfargument
			required="true"
			type="string"
			name="methodName"
			hint="Operation name">
		<cfargument
			required="true"
			type="string"
			name="returnTypeId"
			hint="Return type UML Id. Defined in cfc2uml.xml">
		<cfargument
			required="true"
			type="any"
			name="xmlObject"
			hint="XML document object in which you are creating the element">
		<cfargument
			required="false"
			type="array"
			name="methodArguments"
			default="#arrayNew(1)#"
			hint="Array of arguments">
		<cfargument
			required="false"
			type="string"
			name="access"
			default="public"
			hint="Access type aka visibility">

		<cfscript>
			var i=1;
			var xmlArgumentAttribute = '';
			var strArgumentTypeId = strPrimitivesAnyId;
			var xmlMethodElement = xmlElemNew(arguments.xmlObject,"ownedOperation");

			xmlMethodElement.xmlAttributes["xmi:id"]=getUinqueID();
			xmlMethodElement.xmlAttributes["name"]=arguments.methodName;
			if (!listFind("public,remote",lcase(arguments.access))){
				xmlMethodElement.xmlAttributes["visibility"]=lcase(arguments.access);
			}

			if (arguments.returnTypeId!="0"){ //if returnType is not VOID
				xmlArgumentAttribute = xmlElemNew(arguments.xmlObject,"ownedParameter");
				xmlArgumentAttribute.xmlAttributes["xmi:id"]=getUinqueID();
				xmlArgumentAttribute.xmlAttributes["type"]=arguments.returnTypeId;
				xmlArgumentAttribute.xmlAttributes["direction"]="return";
				arrayAppend(xmlMethodElement.xmlChildren,xmlArgumentAttribute);
			}

			if (arrayLen(methodArguments) > 0){
				for (i=1;i<=arrayLen(methodArguments);++i){
					if (structKeyExists(methodArguments[i],'type')){
						strArgumentTypeId =  getDataTypeId(methodArguments[i].type);
					}
					else{
						strArgumentTypeId = strPrimitivesAnyId;
					}

					arrayAppend(xmlMethodElement.xmlChildren,
								createMethodArgument(
									methodArguments[i].name,
									strArgumentTypeId,
									arguments.xmlObject
								)
					);
				}
			}
		</cfscript>

		<cfreturn xmlMethodElement/>
	</cffunction>

	<cffunction
		access="private"
		returntype="xml"
		name="createMethodArgument"
		hint="Creates xmi elements which describes input method argument"
		output="false">
		<cfargument
			required="true"
			type="string"
			name="name"
			hint="argument name">
		<cfargument
			required="true"
			type="string"
			name="typeId"
			hint="Argument's primitive type UML ID. Defined in cfc2uml.xml">
		<cfargument
			required="true"
			type="any"
			name="xmlObject"
			hint="XML document object in which you are creating the element" >

		<cfscript>
			var xmlArgumentAttribute = xmlElemNew(arguments.xmlObject,"ownedParameter");
			xmlArgumentAttribute.xmlAttributes["xmi:id"]=getUinqueID();
			xmlArgumentAttribute.xmlAttributes["name"]=arguments.name;
			xmlArgumentAttribute.xmlAttributes["type"]=arguments.typeId;
		</cfscript>

		<cfreturn xmlArgumentAttribute/>
	</cffunction>

	<cffunction
		access="public"
		returntype="xml"
		name="XMLSort"
		hint="Sort by name attribute in alphabetical order">
		<cfargument
			required="true"
			type="xml"
			name="xmlObject"
			hint="XML to sort" >

		<cfscript>
			//read stylesheet
			//var xmlO = arguments.xmlObject;
			//var strXSLfile = fileRead(expandPath("cfc2umlsort.xsl"));
			//var strXmlO = xmlTransform(xmlO,strXSLfile);
			var strXmlO = XSLTtransform(
				xmlSource=toString(arguments.xmlObject),
				xslSource=expandPath("cfc2umlsort.xsl"));
		</cfscript>
		<cfreturn strXmlO />
	</cffunction>

	<cffunction
		access="public"
		returntype="string"
		name="XSLTtransform" output="No">
		<cfargument
			required="yes"
			type="string"
			name="xmlSource">
		<cfargument
			required="yes"
			type="string"
			name="xslSource">
		<cfargument
			required="no"
			type="struct"
			name="stParameters"
			default="#StructNew()#">

		<cfscript>
		var source = "";
		var transformer = "";
		var aParamKeys = "";
		var pKey = "";
		var xmlReader = "";
		var xslReader = "";
		var pLen = 0;
		var xmlWriter = "";
		var xmlResult = "";
		var pCounter = 0;
		var tFactory = createObject("java", "javax.xml.transform.TransformerFactory").newInstance();

		//if xml use the StringReader - otherwise, just assume it is a file source.
		if(Find("<", arguments.xslSource) neq 0){
			xslReader = createObject("java", "java.io.StringReader").init(arguments.xslSource);
			source = createObject("java", "javax.xml.transform.stream.StreamSource").init(xslReader);
		}
		else{
			source = createObject("java", "javax.xml.transform.stream.StreamSource").init("file:///#arguments.xslSource#");
		}
		transformer = tFactory.newTransformer(source);

		//if xml use the StringReader - otherwise, just assume it is a file source.
		if(Find("<", arguments.xmlSource) neq 0) {
			xmlReader = createObject("java", "java.io.StringReader").init(arguments.xmlSource);
			source = createObject("java", "javax.xml.transform.stream.StreamSource").init(xmlReader);
		}
		else {
			source = createObject("java", "javax.xml.transform.stream.StreamSource").init("file:///#arguments.xmlSource#");
		}

		//use a StringWriter to allow us to grab the String out after.
		xmlWriter = createObject("java", "java.io.StringWriter").init();
		xmlResult = createObject("java", "javax.xml.transform.stream.StreamResult").init(xmlWriter);

		if(StructCount(arguments.stParameters) gt 0) {
			aParamKeys = structKeyArray(arguments.stParameters);
			pLen = ArrayLen(aParamKeys);
			for(pCounter = 1; pCounter LTE pLen; pCounter = pCounter + 1) {
				//set params
				pKey = aParamKeys[pCounter];
				transformer.setParameter(pKey, arguments.stParameters[pKey]);
			}
		}
		transformer.transform(source, xmlResult);
		</cfscript>

		<cfreturn xmlWriter.toString() />
	</cffunction>

	<cffunction
		access="public"
		returntype="xml"
		name="getUML"
		hint="Translate CFC metadata to XMI format.">

		<cfscript>
		var strPname = '';
		var sPckgRoot = xmlNew();
		var sFun = '';
		var strFunRetTypeId = strPrimitivesAnyId;
		var strPropTypeId = strPrimitivesAnyId;
		var cfcMeta = getComponentMetaData(variables.strCFCDotPath);
		var strCFCExtendsDotPath = ''; //dot-path to component which extends
		var strFunAccess = 'public';
		var objCFCXml = '';
		var i=1; //local counter

		//if class is already described
		if (componentExists(variables.strCFCDotPath,variables.xmlUML)){
			return variables.xmlUML;
		}

		//remove backslashes from name
		cfcMeta.fullName = replace(cfcMeta.fullName,chr(47),".","all");

		//create packages
		if (listLen(cfcMeta.fullName,'.') > 1){
			sPckgRoot = buildPackages(variables.strCFCDotPath);
		}else{
			sPckgRoot = variables.xmlUML.xmlRoot;
		}

		//create class
		strPname = listLast(cfcMeta.fullName,'.');

		//every component implicitly extends web-inf.cftags.component
		//in case of railo that is railo-context.component
		if (structKeyExists(cfcMeta,'extends') &&
			compare(lcase(cfcMeta.extends.fullName),"web-inf.cftags.component") &&
			compare(lcase(cfcMeta.extends.fullName),"railo-context.component")
			){
			cfcMeta.extends.fullName = replace(cfcMeta.extends.fullName,chr(47),".","all");
			strCFCExtendsDotPath = cfcMeta.extends.fullName;
		}

		arrayAppend(sPckgRoot.xmlChildren, createClassElement(strPname,variables.xmlUML));
		//set new parent to last created child
		sPckgRoot = sPckgRoot.xmlChildren[arrayLen(sPckgRoot.xmlChildren)];

		if (strCFCExtendsDotPath!=''){
			//checks if component is already described...
			strExtClassId = getClassId(strCFCExtendsDotPath);

			//...if not, do it
			if (strExtClassId==""){
				objCFCXml = createObject('component',AbsoluteToDotPath(getCurrentTemplatePath())).init(
																		cfcPath=strCFCExtendsDotPath,
																		xmlUML=variables.xmlUML,
																		sPrimitivesMap=variables.sPrimitivesMap
																	);
				variables.xmlUML = objCFCXml.getUML();
				strExtClassId = objCFCXml.getClassUMLId();
				objCFCXml = ''; //"free" space occupied by this object
			}
			arrayAppend(sPckgRoot.xmlChildren, createGeneralizationElement(strExtClassId,variables.xmlUML));
		}

		//check properties
		//this primarly has sense for ORM CFCs
		if (structKeyExists(cfcMeta,'properties')){

			for (i=1;i<=arraylen(cfcMeta.properties);++i){
				sProp = cfcMeta.properties[i];

				if (structKeyExists(sProp,'type')){
					strPropTypeId = getDataTypeId(sProp.type);
				}
				else{
					strPropTypeId = strPrimitivesAnyId;
				}

				arrayAppend(sPckgRoot.xmlChildren,
								createProperty(
											sProp.name,
											strPropTypeId,
											variables.xmlUML
										)
							);
			}
		}


		if (structKeyExists(cfcMeta,'functions')){
			for (i=1;i<=arraylen(cfcMeta.functions);++i){
				sFun = cfcMeta.functions[i];

				if (structKeyExists(sFun,'returnType')){
					strFunRetTypeId = getDataTypeId(sFun.returnType,cfcMeta.fullName);
				}
				else{
					strFunRetTypeId = strPrimitivesAnyId;
				}

				if (structKeyExists(sFun,'access')){
					strFunAccess = sFun.access;
				}
				else{
					strFunAccess = 'public';
				}

				arrayAppend(sPckgRoot.xmlChildren,
							createMethodElement(
											sFun.name,
											strFunRetTypeId,
											variables.xmlUML,
											sFun.parameters,
											strFunAccess
										)
							);
			}
		}
		</cfscript>

		<cfreturn variables.xmlUML/>
	</cffunction>

	<cffunction
		access="private"
		returntype="string"
		name="getDataTypeId"
		hint="Check if returntype type [primitive, void,component] and if exists. In case it does not, creates it. Returns UML Id, exclusively in case of void returns empty string">
		<cfargument
			required="false"
			type="string"
			name="datatype"
			hint="Data type name">

		<cfscript>
			var local = structNew();
			local.strUMLtypeId = "";
			local.sCFCMeta = "";

			//conditions ordered by statistical frequency, desc
			if (structKeyExists(variables.sPrimitivesMap,arguments.datatype)){
				local.strUMLtypeId = variables.sPrimitivesMap[arguments.datatype];
			}else if (!comparenocase("void",arguments.datatype)){
				local.strUMLtypeId = "";
			}else{ //component type

				//check if component reference contains namespace or is just "named"
				if (!find('.',arguments.datatype)){ //contains dot means contains namespace,else directly
					arguments.datatype = listSetAt(variables.strCFCDotPath,listLen(variables.strCFCDotPath,'.'),arguments.datatype,'.');
				}
				try{
					local.sCFCMeta = getComponentMetadata(arguments.datatype);
					local.strUMLtypeId = getClassId(local.sCFCMeta.fullName);
				}
				catch(any ex){
					local.strUMLtypeId = variables.strPrimitivesAnyId;
					local.errMessage = ex.Message & ". Default ""any"" reference used instead. Either define custom primitive type in cfc2uml.xml or change type on existing one.";
					$writeLog(
						text=local.errMessage
					);
				}

				//CFC is not described yet, so do it
				if (local.strUMLtypeId==""){
					local.objCFCXml = createObject('component',AbsoluteToDotPath(getCurrentTemplatePath())).init(
																			cfcPath=arguments.datatype,
																			xmlUML=variables.xmlUML,
																			sPrimitivesMap=variables.sPrimitivesMap
																		);
					variables.xmlUML = local.objCFCXml.getUML();
					local.strUMLtypeId = local.objCFCXml.getClassUMLId();
					local.objCFCXml=''; //"free" space occupied by this object
				}
			}
		</cfscript>

		<cfreturn local.strUMLtypeId />
	</cffunction>

	<!--- Getters and setters --->
	<cffunction
		access="public"
		returntype="string"
		name="getClassUMLId"
		hint="Return Unique UML Id of this component"
		output="false">
		<cfreturn variables.strClassUMLId />
	</cffunction>

	<cffunction
		access="public"
		returntype="struct"
		name="getPrimitivesMap"
		hint="Return UMLId-name map of CF spcific primitive types"
		output="false">
		<cfreturn variables.sPrimitivesMap />
	</cffunction>
	<!--- End Of Getters and setters --->

	<cffunction
		access="public"
		returntype="string"
		name="AbsoluteToDotPath"
		hint="Converts absolute path to dot-delimited format, taking internal mappings in consideration"
		output="false">
		<cfargument
			required="true"
			type="string"
			name="cfcAbsPath"
			hint="Absolute path">

		<cfscript>
			var refTemplFactory = "";
			var objJavaFile = "";
			var strDotPath = "";
			switch (lcase(variables.servertype)){
				case "railo": //railo
					strDotPath = contractPath(cfcAbsPath);
					strDotPath = right(strDotPath,len(strDotPath)-1); // strip leading slash
					strDotPath = left(strDotPath,len(strDotPath)-4); // remove file extension
					strDotPath = replace(strDotPath,"/",".",'all'); // replace slash with dot
				break;
				case "coldfusion server": //adobe
					refTemplFactory = createObject('java','coldfusion.runtime.TemplateProxyFactory');
					objJavaFile = createObject('java','java.io.File').init(arguments.cfcAbsPath);
					strDotPath = refTemplFactory.getFullName(objJavaFile, getPageContext(), false);
				break;
			}
		</cfscript>

		<cfreturn strDotPath/>
	</cffunction>

	<cffunction
		access="private"
		returntype="boolean"
		name="componentExists"
		hint="Check if component is already described in XML. If so returns true, otherwise false.">
		<cfargument
			required="true"
			type="string"
			name="cfcPath"
			hint="Absolute or dot-delimited path to cfc file">

		<cfscript>
			var local = structNew();
			local.strCFCPath = arguments.cfcPath;
			local.strCFCDotPath = '';
			local.strClassUMLId = '';
			local.bExists = false;

			if (local.strCFCPath == ""){
				throw (message="Path to cfc file cannot be empty!");
			}

			//convert win to *nix path separators
			local.strCFCPath = replace(local.strCFCPath,"\","/","all");

			//check for path type
			if (!find("/",local.strCFCPath)){ //no slashes implies dot-delimited path
				local.strCFCDotPath = local.strCFCPath;
			}else{
				if (!fileExists(local.strCFCPath)){
					throw(message="File at location #local.strCFCPath# does not exist");
				}

				local.strCFCDotPath = AbsoluteToDotPath(local.strCFCPath);
			}

			local.strClassUMLId = getClassId(local.strCFCDotPath);

			local.bExists = (local.strClassUMLId!='');
		</cfscript>

		<cfreturn local.bExists />
	</cffunction>

	<!---
	Mimics the CFTHROW tag.

	@param Type      Type for exception. (Optional)
	@param Message      Message for exception. (Optional)
	@param Detail      Detail for exception. (Optional)
	@param ErrorCode      Error code for exception. (Optional)
	@param ExtendedInfo      Extended Information for exception. (Optional)
	@param Object      Object to throw. (Optional)
	@return Does not return a value.
	@author Raymond Camden (ray@camdenfamily.com)
	@version 1, October 15, 2002
	--->
	<cffunction
		access="private"
		returntype="void"
		name="throw"
		hint="CFML Throw wrapper"
		output="false">
		<cfargument required="false" type="string" name="message" default="" hint="Message for Exception">
	    <cfargument required="false" type="string" name="type" default="Application" hint="Type for Exception">
	    <cfargument required="false" type="string" name="detail" default="" hint="Detail for Exception">
	    <cfargument required="false" type="string" name="errorCode" default="" hint="Error Code for Exception">
	    <cfargument required="false" type="string" name="extendedInfo" default="" hint="Extended Info for Exception">
	    <cfargument required="false" type="any" name="object" hint="Object for Exception">

	    <cfif not isDefined("object")>
	        <cfthrow type="#type#" message="#message#" detail="#detail#" errorCode="#errorCode#" extendedInfo="#extendedInfo#">
	    <cfelse>
	        <cfthrow object="#object#">
	    </cfif>

	</cffunction>

	<cffunction
		access="private"
		returntype="void"
		name="$writeLog"
		hint="Calls writeLog method from cfc2umlutils components with predefined settings">
		<cfargument
			required="true"
			type="string"
			name="text">
		<cfargument
			required="false"
			type="string"
			name="type"
			default="Information"
			hint="[Information,Warning,Error,Fatal] - Type (severity) of the message">
		<cfset variables.refUtilities.writeLog(
										text=arguments.text,
										file="cfc2uml",
										type=arguments.type
										)>
	</cffunction>


</cfcomponent>