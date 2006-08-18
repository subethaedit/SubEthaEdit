<?xml version="1.0" encoding="iso-8859-1"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="xml" encoding="iso-8859-1"/>
	
	<!-- Concatenate files -->

	<xsl:template match="filelist">
		<book>
			<xsl:for-each select="document(file/@href)">
				<xsl:copy-of select="*"/>
			</xsl:for-each>
		</book>
	</xsl:template>	

</xsl:stylesheet>