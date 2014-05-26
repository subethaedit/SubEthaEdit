<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
	<xsl:param name="style-attribute">color</xsl:param>
	<xsl:output omit-xml-declaration="yes" indent="yes" encoding="UTF-8" method="text"/>

	<xsl:template name="sss-for-attribute">
		<xsl:param name="style-attribute"/>

		<xsl:param name="name">
			<xsl:value-of select="syntax/head/name"/>
		</xsl:param>

		<xsl:for-each select="//*[@*[name() = $style-attribute]]">
			<xsl:value-of select="@scope"/>
			<xsl:text> { </xsl:text>
			<xsl:value-of select="$style-attribute"/>
			<xsl:text> : </xsl:text>
			<xsl:value-of select="@*[name() = $style-attribute]"/>
			<xsl:text>; }</xsl:text>
			<xsl:text> /* </xsl:text>
			<xsl:value-of select="@id"/>
			<xsl:text>  --- </xsl:text>
			<xsl:value-of select="$name"/>			
			<xsl:text> */</xsl:text>
			<xsl:text>&#xa;</xsl:text>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="/">
		<xsl:call-template name="sss-for-attribute">
			<xsl:with-param name="style-attribute" select="$style-attribute"/>
		</xsl:call-template>
	</xsl:template>

</xsl:stylesheet>
