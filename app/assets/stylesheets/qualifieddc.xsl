<?xml version="1.0" encoding="UTF-8"?>

<div xsl:version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<dl class="dri_object_metadata_readview">
            <xsl:for-each select="qualifieddc/*">
                <dt class="dri_capitalize">
                    <xsl:value-of select="local-name()"/>
                </dt>
                <dd>
                    <!-- 
                        if the value contains http, make it clickable
                        XSLT 2.0 could use fn:matches to use regex  
                        and match more complex uris.
                        Could also modify xml at metadatacontroller level?
                    -->
                    <xsl:choose>
                        <xsl:when test="contains(., 'http')">
                            <a href="{.}">
                                <xsl:value-of select="."/>
                            </a>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="."/>
                        </xsl:otherwise>
                    </xsl:choose>
                </dd>
            </xsl:for-each>
        </dl>
 </div>
