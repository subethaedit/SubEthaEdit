<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
	<xsl:param name="key">CFBundleShortVersionString</xsl:param>
	<xsl:output omit-xml-declaration="yes" indent="yes" encoding="UTF-8" method="text"/>

	<xsl:template match="/">
		<xsl:value-of select="$key"/>
		<xsl:text> - </xsl:text>
		
		<xsl:apply-templates select="plist/dict/string | plist/dict/array">
			<xsl:with-param name="key" select="$key"/>		
		</xsl:apply-templates>

		<xsl:text> - </xsl:text>
		<xsl:value-of select="plist/dict/key[text()='CFBundleName']/following-sibling::string[1]"/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>

	<xsl:template match="plist/dict/string">
		<xsl:param name="key"/>

		<xsl:param name="my_key">
			<xsl:value-of select="preceding-sibling::key[1]"/>
		</xsl:param>
		
		<xsl:if test="$key = $my_key">
			<xsl:value-of select="."/>
		</xsl:if>
	</xsl:template>

	<xsl:template match="plist/dict/array">
		<xsl:param name="key"/>

		<xsl:param name="my_key">
			<xsl:value-of select="preceding-sibling::key[1]"/>
		</xsl:param>
		
		<xsl:if test="$key = $my_key">
			<xsl:apply-templates select="string"/>
		</xsl:if>
	</xsl:template>

	<xsl:template match="plist/dict/array/string">
		<xsl:value-of select="."/>
	</xsl:template>
	
</xsl:stylesheet>
