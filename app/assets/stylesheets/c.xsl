<?xml version="1.0" encoding="UTF-8"?>
<div xsl:version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
        <dl class="dri_object_metadata_readview">
            <xsl:for-each select="c/*">
                <dt class="dri_capitalize">
                    <xsl:value-of select="local-name()"/>
                </dt>
                <dd>
	            <xsl:for-each select="*">
	                <dt class="dri_capitalize">
	                    <xsl:value-of select="local-name()"/>
	                </dt>
	                <dd>
	                    <xsl:value-of select="."/>
	                </dd>
	            </xsl:for-each>
                </dd>
            </xsl:for-each>
        </dl>
</div>