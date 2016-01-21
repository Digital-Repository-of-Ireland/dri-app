<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:mods="http://www.loc.gov/mods/v3"
  exclude-result-prefixes="xs" version="2.0">
  <xsl:output method="html" indent="yes"/>
  <!-- Root element -->
  <xsl:template match="/mods:mods">
    <div>
      <dl class="dri_object_metadata_readview">
        <ul style="list-style-type: none;">
          <xsl:apply-templates select="node()"/>
        </ul>
      </dl>
    </div>
  </xsl:template>
  
  <!-- For every node -->
  <xsl:template match="*">
    <li>
    <dt class="dri_capitalize">
      <xsl:value-of select="local-name()"/>
    </dt>
    <xsl:choose>
      <xsl:when test="not(./*[normalize-space()])">
        <dd>
          <xsl:value-of select="."/>
        </dd>
      </xsl:when>
      <xsl:otherwise>
        <ul style="list-style-type: none;">
          <xsl:apply-templates select="node()"/>
        </ul>
      </xsl:otherwise>
    </xsl:choose>
    </li>
  </xsl:template>
  
  <!-- For text nodes -->
  <xsl:template match="text()[normalize-space()]">
    <dd><xsl:value-of select="normalize-space(.)"/></dd>
  </xsl:template>
  
</xsl:stylesheet>