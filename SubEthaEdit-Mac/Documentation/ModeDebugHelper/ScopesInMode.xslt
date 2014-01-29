<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

	<xsl:output omit-xml-declaration="yes" indent="yes" encoding="UTF-8" method="text"/>

	<xsl:template name="scopes-in-mode">
	    <xsl:text>=== </xsl:text><xsl:value-of select="syntax/head/name" /><xsl:text>&#xa;</xsl:text>
		<xsl:for-each select="//*[@scope]">
			<xsl:value-of select="@scope"/> - <xsl:value-of select="name()"/> // <xsl:value-of select="@id"/><xsl:text>&#xa;</xsl:text>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template match="/">
		<xsl:call-template name="scopes-in-mode" />
	</xsl:template>

</xsl:stylesheet>
