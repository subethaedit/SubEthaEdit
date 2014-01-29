<?xml version="1.0" encoding="UTF-8" standalone="yes"?>

<!-- Remove unwanted attributes or/and nodes -->
<!-- With help from http://openwritings.net/public/xslt/remove-attributes-or-and-nodes -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
	<xsl:output indent="yes" encoding="UTF-8" method="xml" 
		standalone="yes" 
		doctype-system="syntax.dtd" 
		cdata-section-elements="charsintokens charsincompletion" />

	<xsl:template match="/">
		<xsl:call-template name="remove-style-attribute" />
	</xsl:template>
	
<!-- Copy everything -->
	<xsl:template name="remove-style-attribute" match="@*|node()|text()|comment()|processing-instruction()">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()|text()|comment()|processing-instruction()"/>
		</xsl:copy>
	</xsl:template>
 
	<!-- To remove attributes or nodes, simply write a matching template that doesn't do anything. Therefore, it is removed -->

	<xsl:template match="@color" />
	<xsl:template match="@inverted-color" />
	<xsl:template match="@background-color" />
	<xsl:template match="@inverted-background-color" />
	<xsl:template match="@font-trait" />
	<xsl:template match="@font-weight" />
	<xsl:template match="@font-style" />

<!-- clumsy write the xml without _really_ changing it (for the <'s and the doctype etc. --><!--
	<xsl:template match="@scope">
		<xsl:attribute name="scope">
			<xsl:value-of select="." />
		</xsl:attribute>
	</xsl:template>
-->

</xsl:stylesheet>
