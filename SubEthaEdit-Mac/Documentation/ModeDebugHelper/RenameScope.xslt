<?xml version="1.0" encoding="UTF-8" standalone="yes"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
	<xsl:output indent="yes" encoding="UTF-8" method="xml" 
		standalone="yes"
		doctype-system="syntax.dtd" 
		cdata-section-elements="charsintokens charsincompletion" />
		
	<xsl:param name="from">color</xsl:param>
	<xsl:param name="to">color</xsl:param>

	<xsl:template match="/">
		<xsl:call-template name="rename-scope">
			<xsl:with-param name="from" select="$from" />
			<xsl:with-param name="to" select="$to" />
		</xsl:call-template>
	</xsl:template>
	
	<!-- Copy everything -->
	<xsl:template name="rename-scope" match="@*|node()|text()|comment()|processing-instruction()">
		<xsl:param name="from"/>
		<xsl:param name="to"/>
		<xsl:copy>
			<xsl:apply-templates select="@*|node()|text()|comment()|processing-instruction()">
				<xsl:with-param name="from" select="$from" />
				<xsl:with-param name="to" select="$to" />
			</xsl:apply-templates>
		</xsl:copy>
	</xsl:template>
 
	<xsl:template match="@scope">
		<xsl:param name="from"/>
		<xsl:param name="to"/>
		
		<xsl:attribute name="scope">
			<xsl:choose>
				<xsl:when test=". = $from">
					 <xsl:value-of select="$to" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="." />
    			</xsl:otherwise>
  			</xsl:choose>
  		</xsl:attribute>
	</xsl:template>
	
</xsl:stylesheet>
