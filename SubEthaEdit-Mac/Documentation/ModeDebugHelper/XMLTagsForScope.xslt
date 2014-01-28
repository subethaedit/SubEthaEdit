<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
    <xsl:param name="scope">keyword</xsl:param>
	<xsl:output omit-xml-declaration="yes" indent="yes" encoding="UTF-8" method="xml"/>
	
	<xsl:template name="definition-per-scope">
		<xsl:param name="scope"/>
	    <mode><xsl:attribute name="name"><xsl:value-of select="syntax/head/name" /></xsl:attribute>
        <xsl:for-each select="//*[@scope=$scope]">
		<xsl:copy-of select="."/>
		</xsl:for-each>
		</mode>
	</xsl:template>
	
	<xsl:template match="/">
		<xsl:call-template name="definition-per-scope">
			<xsl:with-param name="scope" select="$scope"/>
		</xsl:call-template>
	</xsl:template>
</xsl:stylesheet>
