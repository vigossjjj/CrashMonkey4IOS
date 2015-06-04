<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:template match="/">
		<html>
			<head>
				<title>Test Result</title>
				<link rel="stylesheet" type="text/css" href="../bootstrap.css" />
				<style TYPE="text/css">
					<xsl:text disable-output-escaping="yes"><![CDATA[<!-- tr:nth-child(even) { background-color: #d9edf7; } -->]]></xsl:text>
				</style>
			</head>
			<body>
				<h1>UIAutomation Trace</h1>
				<table class="table table-bordered">
					<tr>
					<th>Timestamp</th>
					<th>Sequence</th>
					<th>Type</th>
					<th>Message</th>
					</tr>
					<xsl:for-each select="plist/dict/array/dict">
						<xsl:variable name="Type"><xsl:value-of select="./integer[preceding-sibling::key='Type'][1]"/></xsl:variable>
						<xsl:variable name="LogType"><xsl:value-of select="./string[preceding-sibling::key='LogType'][1]"/></xsl:variable>
						<xsl:variable name="Message"><xsl:value-of select="./string[preceding-sibling::key='Message'][1]"/></xsl:variable>
						<tr>
							<td>
								<span style="display:inline-block;white-space:nowrap;">
									<xsl:value-of select="translate(translate(date, 'T',' '), 'Z','')"/>
								</span>
							</td>
							<td>
								<span style="display:inline-block;white-space:nowrap;">
									<xsl:value-of select="position()"/>
								</span>
							</td>
							<td>
								<span style="display:inline-block;white-space:nowrap;">
									<xsl:choose>
										<xsl:when test="integer = 8"><span style="color:blue">Screenshot</span></xsl:when>
										<xsl:when test="integer = 5"><span style="color:green">Pass</span></xsl:when>
										<xsl:when test="integer = 4"><span style="color:orange">Message</span></xsl:when>
										<xsl:when test="integer = 2"><span style="color:orange">Warning</span></xsl:when>
										<xsl:when test="integer = 1"><span style="color:black">Default</span></xsl:when>
										<xsl:when test="integer = 0"><span style="color:gray">Debug</span></xsl:when>
										<xsl:when test="integer = 7"><span style="color:red">Fail</span></xsl:when>
										<xsl:when test="integer = 3"><span style="color:red">Error</span></xsl:when>
										<xsl:otherwise><xsl:value-of select="integer"/></xsl:otherwise>
									</xsl:choose>
								</span>
							</td>
							<td>
								<span style="display:inline-block;white-space:nowrap;">
									<xsl:copy-of select="$Message"/>
								</span>
							</td>
						</tr>
					</xsl:for-each>
				</table>
			</body>
		</html>
	</xsl:template>
</xsl:stylesheet>