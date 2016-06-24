<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:uml="http://www.eclipse.org/uml2/3.0.0/UML" xmlns:xmi="http://schema.omg.org/spec/XMI/2.1">
	<xsl:output method="xml" indent="yes"/>
	<xsl:template match="/">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="uml:Model|packagedElement">
		<xsl:element name="{name(.)}">
			<xsl:for-each select="@*">
				<xsl:attribute name="{name(.)}"><xsl:value-of select="."/></xsl:attribute>
			</xsl:for-each>
			<xsl:apply-templates>
				<xsl:sort select="@xmi:type" data-type="text" order="descending"/>
				<xsl:sort select="@name" data-type="text" order="ascending"/>
			</xsl:apply-templates>
		</xsl:element>
	</xsl:template>
	<xsl:template match="ownedOperation|ownedParameter|generalization|ownedAttribute">
		<xsl:copy-of select="."/>
	</xsl:template>
</xsl:stylesheet>
