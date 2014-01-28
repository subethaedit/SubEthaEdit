<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
	<xsl:output omit-xml-declaration="yes" indent="yes" encoding="UTF-8" method="text"/>
	<xsl:template name="all-scope-styles">

		<xsl:param name="name">
			<xsl:value-of select="syntax/head/name"/>
		</xsl:param>
		
		<xsl:for-each select="//*[(@scope) and (@color|@inverted-color|@background-color|@inverted-background-color|@font-trait|@font-weight|@font-style)]">
		
			<xsl:value-of select="@scope"/>
			<xsl:text> { </xsl:text>
			
			<xsl:apply-templates select="@color"/>
			<xsl:apply-templates select="@inverted-color"/>
			<xsl:apply-templates select="@background-color"/>
			<xsl:apply-templates select="@inverted-background-color"/>
			<xsl:apply-templates select="@font-trait"/>
			<xsl:apply-templates select="@font-weight"/>
			<xsl:apply-templates select="@font-style"/>

			<xsl:text>}</xsl:text>
			<xsl:text> /* </xsl:text>
			<xsl:value-of select="@id"/>
			<xsl:text>  --- </xsl:text>
			<xsl:value-of select="$name"/>
			<xsl:text> */
</xsl:text>

		</xsl:for-each>
		
	</xsl:template>
	
	<xsl:template match="/">
		<xsl:call-template name="all-scope-styles"/>
	</xsl:template>
	
	<xsl:template name="print-node" match="@*">
		<xsl:value-of select="local-name()"/>
		<xsl:text> : </xsl:text>
		<xsl:value-of select="."/>
		<xsl:text>; </xsl:text>
	</xsl:template>

</xsl:stylesheet>
