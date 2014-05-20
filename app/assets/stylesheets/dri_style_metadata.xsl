<?xml version="1.0" encoding="UTF-8"?>
<html xsl:version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <head>
        <title>Styled XML</title>
        <link href="http://localhost:3000/assets/dri/dri_layouts.css?body=1" media="screen" rel="stylesheet" type="text/css" />
    </head>
    <body>
        <dl class="dri_object_metadata_readview">
            <xsl:for-each select="qualifieddc/*">
                <dt class="dri_capitalize">
                    <xsl:value-of select="local-name()"/>
                </dt>
                <dd>
                    <xsl:value-of select="."/>
                </dd>
            </xsl:for-each>
        </dl>
    </body>
</html>