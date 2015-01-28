<?xml version="1.0" encoding="UTF-8"?>

<div xsl:version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<div class="modal-header">
	<button type="button" class="close" data-dismiss="modal">
		<span aria-hidden="true">×</span><span class="sr-only">Close</span>
	</button>
	<h4 class="modal-title" id="">Dublin Core Metadata</h4>
</div>
	<div>
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
        </div>
</div>