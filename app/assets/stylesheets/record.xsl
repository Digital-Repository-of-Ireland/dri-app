<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns="http://www.loc.gov/MARC21/slim" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html"/>

	<xsl:template match="/">
		 <div>
      <dl class="dri_object_metadata_readview">
        <ul>
			<xsl:apply-templates/>
		    </ul><p></p>
      </dl>
    </div>
	</xsl:template>

	<xsl:template match="leader">
		<b>LEADER</b>
		<xsl:variable name="leader" select="text()"/>
		<xsl:variable name="leader5" select="substring($leader,6,1)"/>
		<xsl:variable name="leader6" select="substring($leader,7,1)"/>
		<xsl:variable name="leader7" select="substring($leader,8,1)"/>
		<xsl:variable name="leader8" select="substring($leader,9,1)"/>
		<xsl:variable name="leader9" select="substring($leader,10,1)"/>
		<xsl:variable name="leader17" select="substring($leader,18,1)"/>
		<xsl:variable name="leader18" select="substring($leader,19,1)"/>
		<xsl:variable name="leader19" select="substring($leader,20,1)"/>
		<ul>
			<li>Record Status:
			<xsl:value-of select="$leader5"/>
			</li>
			<li>Type of record:
			<xsl:value-of select="$leader6"/>
			</li>
			<li>Bibliographic level:
			<xsl:value-of select="$leader7"/>
			</li>
			<li>Type of control:
			<xsl:value-of select="$leader8"/>
			</li>
			<li>Undefined:
			<xsl:value-of select="$leader9"/>
			</li>
			<li>Encoding level:
			<xsl:value-of select="$leader17"/>
			</li>
			<li>Descriptive cataloging form:
			<xsl:value-of select="$leader18"/>
			</li>
			<li>Linked record requirement:
			<xsl:value-of select="$leader19"/>
			</li>
		</ul><p></p>
		
	</xsl:template>

  <xsl:template match="controlfield[@tag=005]">
		<b>DATE AND TIME OF LATEST TRANSACTION
		</b>
		<xsl:variable name="date_and_time" select="text()"/>
		<xsl:variable name="date" select="substring($date_and_time,1,8)"/>
		<xsl:variable name="time" select="substring($date_and_time,9,8)"/>
		<ul>
			<li>Date:
			 <xsl:value-of select="$date"/>
			</li>
			<li>Time:
			 <xsl:value-of select="$time"/>
			</li>
		</ul>
		
	</xsl:template>
  
  <xsl:template match="controlfield[@tag=008]">
		<b>FIXED LENGTH DATA ELEMENTS-GENERAL INFORMATION
		</b>
		<xsl:variable name="data_elements" select="text()"/>
		<xsl:variable name="date_on_file" select="substring($data_elements,1,6)"/>
		<xsl:variable name="type_of_date" select="substring($data_elements,7,1)"/>
		<xsl:variable name="date1" select="substring($data_elements,8,4)"/>
		<xsl:variable name="date2" select="substring($data_elements,12,4)"/>
    <xsl:variable name="place" select="substring($data_elements,16,3)"/>
    <xsl:variable name="language" select="substring($data_elements,36,3)"/>
		<ul>
			<li>Date entered on file:
			 <xsl:value-of select="$date_on_file"/>
			</li>
			<li>Type of date/Publication status:
			 <xsl:value-of select="$type_of_date"/>
			</li>
			<li>Date 1:
			 <xsl:value-of select="$date1"/>
			</li>
			<li>Date 2:
			 <xsl:value-of select="$date2"/>
			</li>
			<li>Place of publication, production, or execution:
				<xsl:value-of select="$place"/>
			</li>
			<li>Language:
				<xsl:value-of select="$language"/>
			</li>
		</ul><p></p>
		
	</xsl:template>

	<xsl:template match="datafield[@tag=010]">
		<b>LIBRARY OF CONGRESS CONTROL NUMBER
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>LC control number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>NUCMC control number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Cancelled/invalid LC control number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=011]">
		<b>LINKING LIBRARY OF CONGRESS CONTROL NUMBER
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Linking LC control number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=013]">
		<b>PATENT CONTROL INFORMATION
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Country:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Type of number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Date:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Status:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Party to document:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
		
	</xsl:template>
	<xsl:template match="datafield[@tag=014]">
		<b>LINKAGE NUMBER
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Linkage number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Source of number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Cancelled/invalid linkage number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
		
	</xsl:template>
	<xsl:template match="datafield[@tag=015]">
		<b>NATIONAL BIBLIOGRAPHY NUMBER
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>National bibliography number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
		
	</xsl:template>
	<xsl:template match="datafield[@tag=016]">
		<b>NATIONAL BIBLIOGRAPHIC AGENCY CONTROL NUMBER
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Record control number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Canceled/invalid control number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
		
	</xsl:template>
	<xsl:template match="datafield[@tag=017]">
		<b>COPYRIGHT REGISTRATION NUMBER
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Copyright registration number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Source (agency assigning number):
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
		
	</xsl:template>
	<xsl:template match="datafield[@tag=018]">
		<b>COPYRIGHT ARTICLE-FEE CODE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Copyright article-fee code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
		
	</xsl:template>
	<xsl:template match="datafield[@tag=020]">
		<b>INTERNATIONAL STANDARD BOOK NUMBER
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>International Standard Book Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Binding information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Terms of availability:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Cancelled/invalid ISBN:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=022]">
		<b>INTERNATIONAL STANDARD SERIAL NUMBER
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>International Standard Serial Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>Incorrect ISSN:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Cancelled ISSN:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
		
	</xsl:template>
	<xsl:template match="datafield[@tag=024]">
		<b>OTHER STANDARD IDENTIFIER
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Standard recording code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Terms of availability:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Additional codes following the standard number or code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Cancelled/invalid standard code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Source of code or number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
		
	</xsl:template>
	<xsl:template match="datafield[@tag=025]">
		<b>OVERSEAS ACQUISITION NUMBER
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Overseas acquisition number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
		
	</xsl:template>
	<xsl:template match="datafield[@tag=027]">
		<b>STANDARD TECHNICAL REPORT NUMBER
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Standard Technical Report Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Cancelled/invalid STRN:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
		
	</xsl:template>
	<xsl:template match="datafield[@tag=028]">
		<b>PUBLISHER NUMBER FOR MUSIC
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Publisher number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
		
	</xsl:template>
	<xsl:template match="datafield[@tag=030]">
		<b>CODEN DESIGNATION
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>CODEN:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Cancelled/invalid CODEN:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
		
	</xsl:template>
	<xsl:template match="datafield[@tag=032]">
		<b>POSTAL REGISTRATION NUMBER
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Postal registration number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Source (agency assigning number):
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
		
	</xsl:template>
	<xsl:template match="datafield[@tag=033]">
		<b>DATE/TIME AND PLACE OF AN EVENT
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Formatted date/time:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Geographic classification area code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Geographic classification subarea code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=034]">
		<b>CODED CARTOGRAPHIC MATHEMATICAL DATA
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Category of scale:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Constant ratio linear horizontal scale:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Constant ratio linear vertical scale:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Coordinates--westernmost longitude:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Coordinates--easternmost longitude:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Coordinates--northernmost latitude:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Coordinates--southernmost latitude:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Angular scale:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='j']">
				<li>Declination--northern limit:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Declination--southern limit:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Right ascension--eastern limit:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Right ascension--western limit:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Equinox:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>G-ring latitude:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>G-ring longitude:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=035]">
		<b>SYSTEM CONTROL NUMBER
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>System control number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Cancelled/invalid system control number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=036]">
		<b>ORIGINAL STUDY NUMBER FOR COMPUTER DATA FILES
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Original study number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Source (agency assigning number):
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=037]">
		<b>SOURCE OF ACQUISITION
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Stock number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Source of stock number/acquisition:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Terms of availability:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Form of issue:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Additional format characteristics:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=039]">
		<b>LEVEL OF BIBLIOGRAPHIC CONTROL AND CODING DETAIL
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Level of rules in bibliographic description:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Level of effort used to assign nonsubject heading access points:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Level of effort used to assign subject headings:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Level of effort used to assign classification:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Number of fixed field character positions coded:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=040]">
		<b>CATALOGING SOURCE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Original cataloging agency:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Language of cataloging:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Transcribing agency:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Modifying agency:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Description conventions:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
		
	</xsl:template>
	<xsl:template match="datafield[@tag=041]">
		<b>LANGUAGE CODE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Language code of text/sound track or separate title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Language code of summary or abstract/overprinted title or subtitle:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Language code of sung or spoken text:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Language code of librettos:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Language code of table of contents:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Language code of accompanying material other than librettos:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Language code of original and/or intermediate translations of text:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
		
	</xsl:template>
	<xsl:template match="datafield[@tag=042]">
		<b>AUTHENTICATION CODE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Authentication code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
		
	</xsl:template>
	<xsl:template match="datafield[@tag=043]">
		<b>GEOGRAPHIC AREA CODE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Geographic area code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Local GAC code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Source of local code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
		
	</xsl:template>
	<xsl:template match="datafield[@tag=044]">
		<b>COUNTRY OF PUBLISHING/PRODUCING ENTITY CODE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Country of publishing/producing entity code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Local subentity code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>ISO subentity code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Source of local subentity data:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
		
	</xsl:template>
	<xsl:template match="datafield[@tag=045]">
		<b>TIME PERIOD OF CONTENT
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Time period code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Formatted 9999 B.C. through A.D. time period:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Formatted pre-9999 B.C. time period:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=046]">
		<b>SPECIAL CODED DATES
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Type of date code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Date 1 (B.C. date):
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Date 1 (A.D. date):
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Date 2 (B.C. date):
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Date 2 (A.D. date):
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=047]">
		<b>FORM OF MUSICAL COMPOSITION CODE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Form of musical composition code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=048]">
		<b>NUMBER OF MUSICAL INSTRUMENTS OR VOICES CODE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Performer or ensemble:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Soloist:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=050]">
		<b>LIBRARY OF CONGRESS CALL NUMBER
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and number sequence:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Classification number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Item number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Supplementary class number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=051]">
		<b>LIBRARY OF CONGRESS COPY, ISSUE, OFFPRINT STATEMENT
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Classification number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Item number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Copy information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=052]">
		<b>GEOGRAPHIC CLASSIFICATION
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Geographic classification area code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Geographic classification subarea code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Subject:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Populated place name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Code source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=055]">
		<b>CALL NUMBERS/CLASS NUMBERS ASSIGNED IN CANADA
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Classification number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Item number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Source of call/class number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=058]">
		<b>OTHER GEOGRAPHIC CLASSIFICATION CODE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Geographic classification area code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Geographic classification subarea code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Code source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=060]">
		<b>NATIONAL LIBRARY OF MEDICINE CALL NUMBER
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Classification number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Item number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=061]">
		<b>NATIONAL LIBRARY OF MEDICINE COPY STATEMENT
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Classification number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Item number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Copy information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=066]">
		<b>CHARACTER SETS PRESENT
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Non-ASCII G0 default character set designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Non-ANSEL G1 default character set designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Alternate graphic character set identification:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=070]">
		<b>NATIONAL AGRICULTURAL LIBRARY CALL NUMBER
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Classification number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Item number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=071]">
		<b>NATIONAL AGRICULTURAL LIBRARY COPY STATEMENT
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Classification number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Item number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Copy information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=072]">
		<b>SUBJECT CATEGORY CODE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Subject category code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>Subject category code subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Code source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=073]">
		<b>TYPE OF PROGRAM OR ORGANIZATION CODE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Type of program or organization code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Code source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=074]">
		<b>GPO ITEM NUMBER
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>GPO item number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Cancelled/invalid GPO item number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=080]">
		<b>UNIVERSAL DECIMAL CLASSIFICATION NUMBER
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Universal Decimal Classification number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Item number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>Common auxiliary subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Edition identifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=082]">
		<b>DEWEY DECIMAL CALL NUMBER
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Classification number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>DDC number--abridged NST version:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Edition number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=084]">
		<b>OTHER CLASSIFICATION NUMBER
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Classification number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Item number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Source of number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=086]">
		<b>GOVERNMENT DOCUMENT CLASSIFICATION NUMBER
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Classification number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Cancelled/invalid classification number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Number source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=088]">
		<b>REPORT NUMBER
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Report number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Cancelled/invalid report number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=090]">
		<b>LOCAL CALL NUMBER
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Local class number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Local Cutter number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=091]">
		<b>MICROFILM SHELF LOCATION
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Microfilm shelf location:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=100]">
		<b>MAIN ENTRY--PERSONAL NAME
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Personal name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Numeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Titles and other words associated with a name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Dates associated with a name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Relator term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Date of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Miscellaneous information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='j']">
				<li>Attribution qualifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Form subheading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Language of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Fuller form of name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Affiliation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='4']">
				<li>Relator code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=110]">
		<b>MAIN ENTRY--CORPORATE NAME
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Corporate name or jurisdiction name as entry element:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Subordinate unit:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Location of meeting:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Date of meeting or treaty signing:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Relator term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Date of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Miscellaneous information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Form subheading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Language of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section/meeting:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Affiliation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='4']">
				<li>Relator code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=111]">
		<b>MAIN ENTRY--MEETING NAME
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Meeting name or jurisdiction name as entry element:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Number (BK CF MP MU SE VM MX):
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Location of meeting:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Date of meeting:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Subordinate unit:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Date of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Miscellaneous information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Form subheading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Language of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section/meeting:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Name of meeting following jurisdiction name entry element:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Affiliation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='4']">
				<li>Relator code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
		
	</xsl:template>
	<xsl:template match="datafield[@tag=130]">
		<b>MAIN ENTRY--UNIFORM TITLE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Uniform title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Date of treaty signing:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Date of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Miscellaneous information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Medium:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Form subheading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Language of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Medium of performance for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Arranged statement for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Key for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Version:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
		
	</xsl:template>
	<xsl:template match="datafield[@tag=210]">
		<b>ABBREVIATED TITLE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Abbreviated title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Qualifying information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
		
	</xsl:template>
	<xsl:template match="datafield[@tag=211]">
		<b>ACRONYM OR SHORTENED TITLE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Acronym or shortened title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=212]">
		<b>VARIANT ACCESS TITLE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Variant access title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=214]">
		<b>AUGMENTED TITLE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Augmented title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=222]">
		<b>KEY TITLE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Key title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Qualifying information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=240]">
		<b>UNIFORM TITLE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Uniform title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Date of treaty signing:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Date of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Miscellaneous information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Medium:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Form subheading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Language of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Medium of performance for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Arranged statement for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Key for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Version:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=241]">
		<b>ROMANIZED TITLE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Romanized title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Medium:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=242]">
		<b>TRANSLATION OF TITLE BY CATALOGING AGENCY
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Remainder of title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Remainder of title page transcription /statement of responsibility:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Designation of section:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Name of part/section (BK AM MP MU VM SE):
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Medium:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>Language code of translated title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=243]">
		<b>COLLECTIVE UNIFORM TITLE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Uniform title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Date of treaty signing:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Date of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Miscellaneous information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Medium:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Form subheading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Language of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Medium of performance for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Arranged statement for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Key for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Version:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=245]">
		<b>TITLE STATEMENT
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Remainder of title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Remainder of title page transcription/statement of responsibility:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Designation of section:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Name of part/section (SE):
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Inclusive dates:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Bulk dates:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Medium:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Form:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Version:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
		
	</xsl:template>
	<xsl:template match="datafield[@tag=246]">
		<b>VARYING FORM OF TITLE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Title proper/short title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Remainder of title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Designation of section:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Name of part/section (SE):
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Designation of volume and issue number and/or date of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Miscellaneous information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Medium:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>Display text:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='5']">
				<li>Institution to which field applies:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=247]">
		<b>FORMER TITLE OR TITLE VARIATIONS
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Title proper/short title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Remainder of title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Designation of section:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Name of part/section (SE):
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Designation of volume and issue number and/or date of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Miscellaneous information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Medium:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>International Standard Serial Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=250]">
		<b>EDITION STATEMENT
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Edition statement:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Remainder of edition statement:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=254]">
		<b>MUSICAL PRESENTATION STATEMENT
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Musical presentation statement:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=255]">
		<b>CARTOGRAPHIC MATHEMATICAL DATA
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Statement of scale:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Statement of projection:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Statement of coordinates:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Statement of zone:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Statement of equinox:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Outer G-ring coordinate pairs:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Exclusion G-ring coordinate pairs:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=256]">
		<b>COMPUTER FILE CHARACTERISTICS
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Computer file characteristics:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=257]">
		<b>COUNTRY OF PRODUCING ENTITY FOR ARCHIVAL FILMS
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Country of producing entity for archival films:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=260]">
		<b>PUBLICATION, DISTRIBUTION, ETC. (IMPRINT)
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Place of publication, distribution, etc.:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Name of publisher, distributor, etc.:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Date of publication, distribution, etc.:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Place of manufacture:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Manufacturer:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Date of manufacture:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=263]">
		<b>PROJECTED PUBLICATION DATE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Projected publication date:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=265]">
		<b>SOURCE FOR ACQUISITION/SUBSCRIPTION ADDRESS
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Source for acquisition/subscription address:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=270]">
		<b>ADDRESS
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Address:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>270-b = City:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>State or province:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Country:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Postal code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Title preceding attention name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Attention name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Title following attention name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>Type of address:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='j']">
				<li>Specialized telephone number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Telephone number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Fax number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Electronic mail address:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>TDD or TTY number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Contact person:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Title of contact person:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Hours:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Public note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='4']">
				<li>Relator code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=300]">
		<<b>PHYSICAL DESCRIPTION
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Extent:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Other physical details:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Dimensions:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Accompanying material:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Type of unit:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Size of unit:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
		
	</xsl:template>
	<xsl:template match="datafield[@tag=301]">
		<b>PHYSICAL DESCRIPTION FOR FILMS (PRE-AACR 2)
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Extent of item:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Sound characteristics:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Color characteristics:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Dimensions:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Accompanying material:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Speed:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=302]">
		<b>PAGE OR ITEM COUNT
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Page count:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=303]">
		<b>SUBORDINATE ENTITIES
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Name or description:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Schedule:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Location:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Contact person:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=304]">
		<b>LINEAR FOOTAGE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Linear footage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=305]">
		<b>PHYSICAL DESCRIPTION FOR SOUND RECORDINGS (Pre-AACR 2)
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Extent:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Other physical details:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Dimensions:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Microgroove or standard:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Stereophonic, monaural:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Number of tracks:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Serial identification:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Matrix and/or take number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=306]">
		<b>PLAYING TIME
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Playing time:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=307]">
		<b>HOURS, ETC.
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Hours:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Additional information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=308]">
		<b>PHYSICAL DESCRIPTION FOR FILMS (ARCHIVAL)
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Number of reels:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Footage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Sound characteristics:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Color characteristics:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Width:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Presentation format:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=310]">
		<b>CURRENT PUBLICATION FREQUENCY
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Current publication frequency:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Date of current publication frequency:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=311]">
		<b>MEETING ROOMS AND FACILITIES AVAILABLE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>General description of facilities:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Name and location:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Physical description:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Capacity:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Equipment available:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Rental fee:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Special restrictions:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Accommodations for the disabled:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Miscellaneous information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Contact person:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=312]">
		<b>EQUIPMENT AVAILABLE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Type of equipment:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Brand name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Physical description:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Rental fee:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Special restrictions:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Accommodations for the disabled:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Miscellaneous information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Contact person:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=315]">
		<b>FREQUENCY
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Frequency:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Dates of frequency:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=321]">
		<b>FORMER PUBLICATION FREQUENCY
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Former publication frequency:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Dates of former publication frequency:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=340]">
		<b>PHYSICAL MEDIUM
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Material base and configuration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Dimensions:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Materials applied to surface:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Information recording technique:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Support:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Production rate/ratio:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Location within medium:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>Technical specifications of medium:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=342]">
		<b>GEOSPATIAL REFERENCE DATA
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Coordinate or distance units:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Latitude resolution:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Longitude resolution:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Standard parallel or oblique line latitude:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Oblique line longitude:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Longitude of central meridian or projection center:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Latitude of projection origin or projection center:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>False easting:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='j']">
				<li>False northing:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Scale factor:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Height of perspective point above surface:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Azimuthal angle:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Azimuth measure point longitude or straight vertical longitude from pole:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Landsat number and path number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Zone identifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Ellipsoid name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Semi-major axis:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Denominator of flattening ratio:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Vertical resolution:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Vertical encoding method:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='v']">
				<li>Local planar, local, or other projection or grid description:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='w']">
				<li>Local planar or local georeference information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Reference method used:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=343]">
		<b>PLANAR COORDINATE DATA
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Planar coordinate encoding method:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Planar distance units:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Abscissa resolution:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Ordinate resolution:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Distance resolution:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Bearing resolution:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Bearing units:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Bearing reference direction:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>Bearing reference meridian:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='=']">
				<li>ICE:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Price:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Form of issue:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=351]">
		<b>ORGANIZATION AND ARRANGEMENT OF MATERIALS
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Organization:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Arrangement:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Hierarchical level:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=352]">
		<b>DIGITAL GRAPHIC REPRESENTATION
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Direct reference method:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Object type:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Object count:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Row count:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Column count:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Vertical count:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>Indirect reference description:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=355]">
		<b>SECURITY CLASSIFICATION CONTROL
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Security classification:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Handling instructions:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>External dissemination information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Downgrading or declassification event:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Classification system:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Country of origin code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Downgrading date:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Declassification date:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='j']">
				<li>Authorization:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=357]">
		<b>ORIGINATOR DISSEMINATION CONTROL
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Originator control term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Originating agency:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Authorized recipients of material:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Other restrictions:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=359]">
		<b>RENTAL PRICE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Rental price:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=362]">
		<b>DATES OF PUBLICATION AND/OR SEQUENTIAL DESIGNATION
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Dates of publication and/or sequential designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Source of information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=440]">
		<b>SERIES STATEMENT/ADDED ENTRY--TITLE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='v']">
				<li>Volume number/sequential designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>International Standard Serial Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=490]">
		<b>SERIES STATEMENT
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Series statement:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Library of Congress call number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='v']">
				<li>Volume number/sequential designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>International Standard Serial Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=500]">
		<b>GENERAL NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>General note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Library of Congress call number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>International Standard Serial Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Source of note information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='5']">
				<li>Institution to which field applies:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=501]">
		<b>WITH NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>With note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='5']">
				<li>Institution to which field applies:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=502]">
		<b>DISSERTATION NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Dissertation note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=503]">
		<b>BIBLIOGRAPHIC HISTORY NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Bibliographic history note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=504]">
		<b>BIBLIOGRAPHY, ETC. NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Bibliography, etc. note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Number of references:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=505]">
		<b>FORMATTED CONTENTS NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Formatted contents note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Miscellaneous information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Statement of responsibility:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Uniform Resource Identifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=506]">
		<b>RESTRICTIONS ON ACCESS NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Terms governing access:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Jurisdiction:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Physical access provisions:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Authorized users:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Authorization:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='5']">
				<li>Institution to which field applies:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=507]">
		<b>SCALE NOTE FOR GRAPHIC MATERIAL
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Representative fraction of scale note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Remainder of scale note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=508]">
		<b>CREATION/PRODUCTION CREDITS NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Creation/production credits note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=510]">
		<b>CITATION/REFERENCES NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Name of source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Dates of coverage of source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Location within source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>International Standard Serial Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=511]">
		<b>PARTICIPANT OR PERFORMER NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Participant or performer note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=512]">
		<b>EARLIER OR LATER VOLUMES SEPARATELY CATALOGED NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Earlier or later volumes separately cataloged note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=513]">
		<b>TYPE OF REPORT AND PERIOD COVERED NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Type of report:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Period covered:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=514]">
		<b>DATA QUALITY NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Attribute accuracy report:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Attribute accuracy value:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Attribute accuracy explanation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Logical consistency report:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Completeness report:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Horizontal position accuracy report:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Horizontal position accuracy value:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Horizontal position accuracy explanation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>Vertical positional accuracy report:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='j']">
				<li>Vertical positional accuracy value:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Vertical positional accuracy explanation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Cloud cover:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Uniform Resource Identifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Display note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=515]">
		<b>NUMBERING PECULIARITIES NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Numbering peculiarities note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Source of note information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=516]">
		<b>TYPE OF COMPUTER FILE OR DATA NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Type of computer file or data note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=517]">
		<b>CATEGORIES OF FILMS NOTE (ARCHIVAL)
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Different formats:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Content descriptors:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Additional animation techniques:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=518]">
		<b>DATE/TIME AND PLACE OF AN EVENT NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Date/time and place of an event note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=520]">
		<b>SUMMARY, ETC.
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Summary, etc.:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Expansion of summary note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Uniform Resource Identifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Source of note information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=521]">
		<b>TARGET AUDIENCE NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Target audience note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=522]">
		<b>GEOGRAPHIC COVERAGE NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Geographic coverage note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=523]">
		<b>TIME PERIOD OF CONTENT NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Time period of content note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Dates of data collection note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=524]">
		<b>PREFERRED CITATION OF DESCRIBED MATERIALS NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Preferred citation of described materials note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Source of schema used:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=525]">
		<b>SUPPLEMENT NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Supplement note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Source of note information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=526]">
		<b>STUDY PROGRAM INFORMATION NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Program name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Interest level:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Reading level:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Title point value:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>Display text:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>Nonpublic note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Public note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='5']">
				<li>Institution to which field applies:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=527]">
		<b>CENSORSHIP NOTE
</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Censorship note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=530]">
		<b>ADDITIONAL PHYSICAL FORM AVAILABLE NOTE
</b>
		<ul>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Additional physical form available note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Availability source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Availability conditions:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Order number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Uniform Resource Identifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Source of note information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=531]">
		<b>ELIGIBILITY, FEES, PROCEDURES NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Eligibility:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Fee:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Admission procedures:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Documents required:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Waiting list:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Waiting period:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=533]">
		<b>REPRODUCTION NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Type of reproduction:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Place of reproduction:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Agency responsible for reproduction:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Date of reproduction:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Physical description of reproduction:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Series statement of reproduction:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Dates of publication and/or sequential designation of issues reproduced:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Note about reproduction:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='7']">
				<li>Fixed-length data elements of reproduction:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=534]">
		<b>ORIGINAL VERSION NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Main entry of original:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Edition statement of original:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Publication, distribution, etc. of original:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Physical description, etc. of original:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Series statement of original:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Key title of original:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Location of original:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Material specific details:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Note about original:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Introductory phrase:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title statement of original:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>International Standard Serial Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>International Standard Book Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=535]">
		<b>LOCATION OF ORIGINALS/DUPLICATES NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Custodian:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Postal address:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Country:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Telecommunications address:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Repository location code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=536]">
		<b>FUNDING INFORMATION NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Text of note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Contract number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Grant number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Undifferentiated number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Program element number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Project number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Task number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Work unit number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=537]">
		<b>SOURCE OF DATA NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Source of data note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=538]">
		<b>SYSTEM DETAILS NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>System details note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=540]">
		<b>TERMS GOVERNING USE AND REPRODUCTION NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Terms governing use and reproduction:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Jurisdiction:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Authorization:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Authorized users:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='5']">
				<li>Institution to which field applies:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=541]">
		<b>IMMEDIATE SOURCE OF ACQUISITION NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Source of acquisition:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Address:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Method of acquisition:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Date of acquisition:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Accession number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Owner:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Purchase price:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Extent:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Type of unit:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='5']">
				<li>Institution to which field applies:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=543]">
		<b>SOLICITATION INFORMATION NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Solicitation information note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=544]">
		<b>LOCATION OF OTHER ARCHIVAL MATERIALS NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Custodian:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Address:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Country:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Provenance:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=545]">
		<b>BIOGRAPHICAL OR HISTORICAL DATA
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Biographical or historical data:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Expansion:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Uniform Resource Identifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=546]">
		<b>LANGUAGE NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Language note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Information code or alphabet:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Source of note information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=547]">
		<b>FORMER TITLE COMPLEXITY NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Former title complexity note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Source of note information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=550]">
		<b>ISSUING BODY NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Issuing body note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Source of note information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=552]">
		<b>ENTITY AND ATTRIBUTE INFORMATION NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Entity type label:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Entity type definition and source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Attribute label:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Attribute definition and source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Enumerated domain value:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Enumerated domain value definition and source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Range domain minimum and maximum:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Codeset name and source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>Unrepresentable domain:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='j']">
				<li>Attribute units of measurement and resolution:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Beginning date and ending date of attribute values:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Attribute value accuracy:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Attribute value accuracy explanation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Attribute measurement frequency:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Entity and attribute overview:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Entity and attribute detail citation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Uniform Resource Identifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Display note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=555]">
		<b>CUMULATIVE INDEX/FINDING AIDS NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Cumulative index/finding aids note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Availability source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Degree of control:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Bibliographic reference:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Uniform Resource Identifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=556]">
		<b>INFORMATION ABOUT DOCUMENTATION NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Information about documentation note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>International Standard Book Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=561]">
		<b>OWNERSHIP AND CUSTODIAL HISTORY
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>History:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Time of collation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='5']">
				<li>Institution to which field applies:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=562]">
		<b>COPY AND VERSION IDENTIFICATION NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Identifying markings:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Copy identification:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Version identification:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Presentation format:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Number of copies:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='5']">
				<li>Institution to which field applies:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=565]">
		<b>CASE FILE CHARACTERISTICS NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Number of cases/variables:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Name of variable:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Unit of analysis:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Universe of data:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Filing scheme or code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=567]">
		<b>METHODOLOGY NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Methodology note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=570]">
		<b>EDITOR NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Editor note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Source of note information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=571]">
		<b>VOLUNTEERS NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Volunteers note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Special requirements:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=572]">
		<b>AFFILIATION AND OTHER RELATIONSHIPS NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Affiliation and other relationships note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=573]">
		<b>CREDENTIALS NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Credentials note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=574]">
		<b>TRANSPORTATION AND DIRECTIONS NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Transportation and directions note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=575]">
		<b>ACCOMMODATIONS FOR THE DISABLED NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Accommodations for the disabled note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=576]">
		<b>SERVICES AVAILABLE NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Services available note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=580]">
		<b>LINKING ENTRY COMPLEXITY NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Linking entry complexity note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Source of note information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=581]">
		<b>PUBLICATIONS ABOUT DESCRIBED MATERIALS NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Publications about described materials note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>International Standard Book Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=582]">
		<b>RELATED COMPUTER FILES NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Related computer files note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=583]">
		<b>ACTION NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Action:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Action identification:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Time of action:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Action interval:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Contingency for action:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Authorization:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Jurisdiction:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>Method of action:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='j']">
				<li>Site of action:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Action agent:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Status:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Extent:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Type of unit:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Uniform Resource Identifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>Nonpublic note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Public note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Source of item:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='5']">
				<li>Institution to which field applies:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=584]">
		<b>ACCUMULATION AND FREQUENCY OF USE NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Accumulation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Frequency of use:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='5']">
				<li>Institution to which field applies:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=585]">
		<b>EXHIBITIONS NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Exhibitions note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='5']">
				<li>Institution to which field applies:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=586]">
		<b>AWARDS NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Awards note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=587]">
		<b>OTHER INFORMATION AVAILABLE NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Other information available note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=590]">
		<b>LOCAL NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Local note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Provenance:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Condition of individual reels:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=600]">
		<b>SUBJECT ADDED ENTRY--PERSONAL NAME
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Personal name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Numeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Titles and other words associated with a name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Dates associated with a name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Relator term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Date of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Miscellaneous information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Medium:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='j']">
				<li>Attribution qualifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Form subheading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Language of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Medium of performance for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Arranged statement for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Fuller form of name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Key for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Version:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Affiliation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='v']">
				<li>Form subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>General subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>Chronological subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Geographic subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Source of heading or term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='4']">
				<li>Relator code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=610]">
		<b>SUBJECT ADDED ENTRY--CORPORATE NAME
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Corporate name or jurisdiction name as entry element:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Subordinate unit:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Location of meeting:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Date of meeting or treaty signing:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Relator term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Date of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Miscellaneous information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Medium:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Form subheading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Language of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Medium of performance for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section/meeting:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Arranged statement for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Key for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Version:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Affiliation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='v']">
				<li>Form subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>General subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>Chronological subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Geographic subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Source of heading or term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='4']">
				<li>Relator code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=611]">
		<b>SUBJECT ADDED ENTRY--MEETING NAME
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Meeting name or jurisdiction name as entry element:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Number (BK CF MP MU SE VM MX):
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Location of meeting:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Date of meeting:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Subordinate unit:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Date of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Miscellaneous information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Medium:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Form subheading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Language of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section/meeting:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Name of meeting following jurisdiction name entry element:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Version:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Affiliation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='v']">
				<li>Form subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>General subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>Chronological subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Geographic subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Source of heading or term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='4']">
				<li>Relator code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=630]">
		<b>SUBJECT ADDED ENTRY--UNIFORM TITLE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Uniform title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Date of treaty signing:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Date of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Miscellaneous information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Medium:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Form subheading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Language of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Medium of performance for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Arranged statement for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Key for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Version:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='v']">
				<li>Form subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>General subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>Chronological subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Geographic subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Source of heading or term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=650]">
		<b>SUBJECT ADDED ENTRY--TOPICAL TERM
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Topical term or geographic name as entry element:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Topical term following geographic name as entry element:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Location of event:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Active dates:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Relator term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='v']">
				<li>Form subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>General subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>Chronological subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Geographic subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Source of heading or term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=651]">
		<b>SUBJECT ADDED ENTRY--GEOGRAPHIC NAME
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Geographic name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Geographic name following place entry element:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='v']">
				<li>Form subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>General subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>Chronological subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Geographic subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Source of heading or term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=652]">
		<b>SUBJECT ADDED ENTRY--REVERSED GEOGRAPHIC
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Geographic name of place element:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>General subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>Chronological subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Geographic subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=653]">
		<b>INDEX TERM--UNCONTROLLED
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Uncontrolled term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=654]">
		<b>SUBJECT ADDED ENTRY--FACETED TOPICAL TERMS
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Focus term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Non-focus term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Facet/hierarchy designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='v']">
				<li>Form subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>Chronological subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Geographic subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Source of heading or term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Material specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=655]">
		<b>INDEX TERM--GENRE/FORM/PHYSICAL CHARACTERISTICS
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Genre/form/physical characteristics:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Non-focus term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Facet/hierarchy designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='v']">
				<li>Form subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>General subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>Chronological subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Geographic subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Source of term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='5']">
				<li>Institution to which field applies:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
		
	</xsl:template>
	<xsl:template match="datafield[@tag=656]">
		<b>INDEX TERM--OCCUPATION
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Occupation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Form:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='v']">
				<li>Form subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>General subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>Chronological subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Geographic subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Source of term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=657]">
		<b>INDEX TERM--FUNCTION
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Function:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='v']">
				<li>Form subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>General subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>Chronological subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Geographic subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Source of term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=658]">
		<b>INDEX TERM--CURRICULUM OBJECTIVE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Main curriculum objective:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Subordinate curriculum objective:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Curriculum code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Correlation factor:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Source of term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=700]">
		<b>ADDED ENTRY--PERSONAL NAME
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Personal name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Numeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Titles and other words associated with a name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Dates associated with a name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Relator term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Date of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Miscellaneous information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Medium:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='j']">
				<li>Attribution qualifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Form subheading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Language of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Medium of performance for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Arranged statement for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Fuller form of name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Key for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Version:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Affiliation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>International Standard Serial Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='4']">
				<li>Relator code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='5']">
				<li>Institution to which field applies:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=705]">
		<b>ADDED ENTRY--PERSONAL NAME (PERFORMER)
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Personal name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Numeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Titles and other words associated with a name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Dates associated with a name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Relator term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Date of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Miscellaneous information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Medium:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Form subheading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Language of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Medium of performance for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Arranged statement for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Key for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Version:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=710]">
		<b>ADDED ENTRY--CORPORATE NAME
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Corporate name or jurisdiction name as entry element:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Subordinate unit:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Location of meeting:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Date of meeting or treaty signing:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Relator term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Date of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Miscellaneous information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Medium:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Form subheading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Language of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Medium of performance for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section/meeting:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Arranged statement for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Key for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Version:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Affiliation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>International Standard Serial Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='4']">
				<li>Relator code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='5']">
				<li>Institution to which field applies:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=711]">
		<b>ADDED ENTRY--MEETING NAME
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Meeting name or jurisdiction name as entry element:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Number (BK CF MP MU SE VM MX):
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Location of meeting:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Date of meeting:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Subordinate unit:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Date of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Miscellaneous information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Medium:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Form subheading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Language of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section/meeting:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Name of meeting following jurisdiction name entry element:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Version:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Affiliation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>International Standard Serial Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='4']">
				<li>Relator code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='5']">
				<li>Institution to which field applies:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=715]">
		<b>ADDED ENTRY--CORPORATE NAME-PERFORMING GROUP
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Corporate name or jurisdiction name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Subordinate unit:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Relator term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Date of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Miscellaneous information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Medium:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Form subheading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Language of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Medium of performance for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section/meeting:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Arranged statement for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Key for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Version:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Nonprinting information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=720]">
		<b>ADDED ENTRY--UNCONTROLLED NAME
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Relator term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='4']">
				<li>Relator code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=730]">
		<b>ADDED ENTRY--UNIFORM TITLE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Uniform title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Date of treaty signing:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Date of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Miscellaneous information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Medium:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Form subheading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Language of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Medium of performance for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Arranged statement for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Key for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Version:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>International Standard Serial Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='5']">
				<li>Institution to which field applies:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=740]">
		<b>ADDED ENTRY--UNCONTROLLED RELATED/ANALYTICAL TITLE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Uncontrolled related/analytical title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Medium:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='5']">
				<li>Institution to which field applies:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=752]">
		<b>ADDED ENTRY--HIERARCHICAL PLACE NAME
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Country:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>State, province, territory:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>County, region, islands area:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>City:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=753]">
		<b>SYSTEM DETAILS ACCESS TO COMPUTER FILES
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Make and model of machine:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Programming language:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Operating system:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=754]">
		<b>ADDED ENTRY--TAXONOMIC IDENTIFICATION
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Taxonomic name/taxonomic hierarchical category:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Source of taxonomic identification:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=755]">
		<b>ADDED ENTRY--PHYSICAL CHARACTERISTICS
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Access term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>General subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>Chronological subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Geographic subdivision:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Source of term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=760]">
		<b>MAIN SERIES ENTRY
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Main entry heading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Edition:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Qualifying information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Place, publisher, and date of publication:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Relationship information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>Display text:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Physical description:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Material-specific details:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Other item identifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Parallel title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Uniform title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='w']">
				<li>Record control number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>International Standard Serial Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>CODEN designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='7']">
				<li>Control subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=762]">
		<b>SUBSERIES ENTRY
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Main entry heading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Edition:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Qualifying information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Place, publisher, and date of publication:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Relationship information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Physical description of source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>Display text:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Material-specific details:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Other item identifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Parallel title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Uniform title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='w']">
				<li>Record control number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>International Standard Serial Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>CODEN designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='7']">
				<li>Control subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=765]">
		<b>ORIGINAL LANGUAGE ENTRY
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Main entry heading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Edition:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Qualifying information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Place, publisher, and date of publication:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Relationship information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Physical description of source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>Display text:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Series data for related item:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Material-specific details:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Other item identifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Parallel title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Report number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Uniform title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Standard Technical Report Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='w']">
				<li>Record control number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>International Standard Serial Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>CODEN designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>International Standard Book Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='7']">
				<li>Control subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=767]">
		<b>TRANSLATION ENTRY
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Main entry heading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Edition:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Qualifying information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Place, publisher, and date of publication:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Relationship information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Physical description of source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>Display text:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Series data for related item:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Material-specific details:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Other item identifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Parallel title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Report number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Uniform title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Standard Technical Report Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='w']">
				<li>Record control number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>International Standard Serial Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>CODEN designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>International Standard Book Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='7']">
				<li>Control subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=770]">
		<b>SUPPLEMENT/SPECIAL ISSUE ENTRY
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Main entry heading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Edition:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Qualifying information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Place, publisher, and date of publication:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Relationship information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Physical description of source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>Display text:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Series data for related item:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Material-specific details:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Other item identifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Parallel title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Report number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Uniform title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Standard Technical Report Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='w']">
				<li>Record control number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>International Standard Serial Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>CODEN designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>International Standard Book Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='7']">
				<li>Control subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=772]">
		<b>PARENT RECORD ENTRY
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Main entry heading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Edition:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Qualifying information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Place, publisher, and date of publication:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Relationship information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Physical description of source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>Display text:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Series data for related item:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Material-specific details:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Other item identifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Parallel title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Report number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Uniform title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Standard Technical Report Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='w']">
				<li>Record control number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>International Standard Serial Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>CODEN designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>International Standard Book Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='7']">
				<li>Control subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=773]">
		<b>HOST ITEM ENTRY
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Main entry heading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Edition:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Place, publisher, and date of publication:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Relationship information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Physical description of source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>Display text:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Series data for related item:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Material-specific details:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Other item identifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Abbreviated title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Report number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Uniform title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Standard Technical Report Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='w']">
				<li>Record control number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>International Standard Serial Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>CODEN designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>International Standard Book Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='7']">
				<li>Control subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>

	</xsl:template>
	<xsl:template match="datafield[@tag=774]">
		<b>CONSTITUENT UNIT ENTRY
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Main entry heading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Edition:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Qualifying information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Place, publisher, and date of publication:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Relationship information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Physical description of source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>Display text:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Series data for related item:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Material-specific details:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Other item identifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Report number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Uniform title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Standard Technical Report Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='w']">
				<li>Record control number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>International Standard Serial Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>CODEN designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>International Standard Book Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='7']">
				<li>Control subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=775]">
		<b>OTHER EDITION ENTRY
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Main entry heading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Edition:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Qualifying information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Place, publisher, and date of publication:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Language code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Country code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Relationship information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Physical description of source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>Display text:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Series data for related item:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Material-specific details:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Other item identifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Parallel title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Report number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Uniform title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Standard Technical Report Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='w']">
				<li>Record control number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>International Standard Serial Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>CODEN designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>International Standard Book Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='7']">
				<li>Control subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=776]">
		<b>ADDITIONAL PHYSICAL FORM ENTRY
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Main entry heading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Edition:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Qualifying information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Place, publisher, and date of publication:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Relationship information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Physical description of source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>Display text:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Series data for related item:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Material-specific details:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Other item identifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Parallel title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Report number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Uniform title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Standard Technical Report Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='w']">
				<li>Record control number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>International Standard Serial Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>CODEN designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>International Standard Book Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='7']">
				<li>Control subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=777]">
		<b>ISSUED WITH ENTRY
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Main entry heading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Edition:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Qualifying information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Place, publisher, and date of publication:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Relationship information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Physical description of source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>Display text:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Series data for related item:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Material-specific details:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Other item identifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Parallel title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Uniform title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='w']">
				<li>Record control number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>International Standard Serial Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>CODEN designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='7']">
				<li>Control subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=780]">
		<b>PRECEDING ENTRY
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Main entry heading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Edition:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Qualifying information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Place, publisher, and date of publication:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Relationship information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Physical description of source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>Display text:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Series data for related item:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Material-specific details:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Other item identifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Parallel title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Report number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Uniform title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Standard Technical Report Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='w']">
				<li>Record control number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>International Standard Serial Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>CODEN designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>International Standard Book Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='7']">
				<li>Control subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=785]">
		<b>SUCCEEDING ENTRY
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Main entry heading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Edition:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Qualifying information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Place, publisher, and date of publication:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Relationship information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Physical description of source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>Display text:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Series data for related item:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Material-specific details:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Other item identifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Parallel title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Report number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Uniform title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Standard Technical Report Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='w']">
				<li>Record control number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>International Standard Serial Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>CODEN designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>International Standard Book Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='7']">
				<li>Control subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=786]">
		<b>ISSUED WITH ENTRY
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='7']">
				<li>Control subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Main entry heading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Edition:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Qualifying information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Place, publisher, and date of publication:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Relationship information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Physical description:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>Display text:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='j']">
				<li>Period of content:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Series data for related item:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Material-specific details:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Other item identifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Abbreviated title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Report number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Uniform title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Standard Technical Report Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='v']">
				<li>Source contribution:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='w']">
				<li>Record control number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>International Standard Serial Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>CODEN designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>International Standard:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=787]">
		<b>NONSPECIFIC RELATIONSHIP ENTRY
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Main entry heading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Edition:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Qualifying information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Place, publisher, and date of publication:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Relationship information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Physical description of source:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>Display text:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Series data for related item:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Material-specific details:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Other item identifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Parallel title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Report number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Uniform title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Standard Technical Report Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='w']">
				<li>Record control number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>International Standard Serial Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>CODEN designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>International Standard Book Number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='7']">
				<li>Control subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=800]">
		<b>SERIES ADDED ENTRY--PERSONAL NAME
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Personal name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Numeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Titles and other words associated with a name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Dates associated with a name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Relator term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Date of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Miscellaneous information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Medium:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='j']">
				<li>Attribution qualifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Form subheading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Language of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Medium of performance for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Arranged statement for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Fuller form of name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Key for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Version:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Affiliation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='v']">
				<li>Volume number/sequential designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='4']">
				<li>Relator code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=810]">
		<b>SERIES ADDED ENTRY--CORPORATE NAME
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Corporate name or jurisdiction name as entry element:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Subordinate unit:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Location of meeting:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Date of meeting or treaty signing:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Relator term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Date of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Miscellaneous information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Medium:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Form subheading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Language of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Medium of performance for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section/meeting:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Arranged statement for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Key for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Version:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Affiliation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='v']">
				<li>Volume number/sequential designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='4']">
				<li>Relator code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=811]">
		<b>SERIES ADDED ENTRY--MEETING NAME
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Meeting name or jurisdiction name as entry element:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Number (BK CF MP MU SE VM MX):
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Location of meeting:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Date of meeting:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Subordinate unit:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Date of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Miscellaneous information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Medium:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Form subheading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Language of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section/meeting:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Name of meeting following jurisdiction name entry element:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Version:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Affiliation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='v']">
				<li>Volume number/sequential designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='4']">
				<li>Relator code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=830]">
		<b>SERIES ADDED ENTRY--UNIFORM TITLE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Uniform title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Date of treaty signing:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Date of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Miscellaneous information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Medium:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Form subheading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Language of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Medium of performance for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Arranged statement for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Key for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Version:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='v']">
				<li>Volume number/sequential designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=840]">
		<b>SERIES ADDED ENTRY--TITLE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Medium:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='v']">
				<li>Volume or number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=841]">
		<b>HOLDINGS CODED DATA VALUES
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Type of record:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Fixed-length data elements:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Encoding level:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=842]">
		<b>TEXTUAL PHYSICAL FORM DESIGNATOR
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Textual physical form designator:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=843]">
		<b>REPRODUCTION NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Type of reproduction:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Place of reproduction:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Agency responsible for reproduction:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Date of reproduction:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Physical description of reproduction:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Series statement of reproduction:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Dates of publication and/or sequential designation of issues reproduced:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Note about reproduction:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='7']">
				<li>Fixed-length data elements of reproduction:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=844]">
		<b>NAME OF UNIT
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Name of unit:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=845]">
		<b>TERMS GOVERNING USE AND REPRODUCTION NOTE
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Terms governing use and reproduction:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Jurisdiction:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Authorization:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Authorized users:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=850]">
		<b>HOLDING INSTITUTION
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Holding institution:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Holdings:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Inclusive dates:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Retention statement:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=851]">
		<b>LOCATION
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Name (custodian or owner):
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Institutional division:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Street address:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Country:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Location of units:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Item number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Repository location code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=852]">
		<b>LOCATION/CALL NUMBER
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Location:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Sublocation or collection:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Shelving location:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Address:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Coded location qualifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>= Qualifier type:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>= Number of units 1-9:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>= Unit type:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Non-coded location qualifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Classification part:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>Item part:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='j']">
				<li>Shelving control number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Call number prefix:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Shelving form of title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Call number suffix:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Country code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Piece designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Piece physical condition:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Copyright article-fee code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Copy number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>Nonpublic note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Public note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Source of classification or shelving scheme:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=853]">
		<b>CAPTIONS AND PATTERN--BASIC BIBLIOGRAPHIC UNIT
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>First level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Second level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Third level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Fourth level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Fifth level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Sixth level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Alternative numbering scheme, first level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Alternative numbering scheme, second level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>First level of chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='j']">
				<li>Second level of chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Third level of chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Fourth level of chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Alternative numbering scheme, chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Copy:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Bibliographic units per next higher level:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='v']">
				<li>Numbering continuity:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='w']">
				<li>Frequency:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>Calendar change:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>Regularity pattern:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=854]">
		<b>CAPTIONS AND PATTERN--SUPPLEMENTARY MATERIAL
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>First level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Second level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Third level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Fourth level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Fifth level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Sixth level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Alternative numbering scheme, first level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Alternative numbering scheme, second level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>First level of chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='j']">
				<li>Second level of chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Third level of chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Fourth level of chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Alternative numbering scheme, chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Type of supplementary material:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Copy:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Bibliographic units per next higher level:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='v']">
				<li>Numbering continuity:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='w']">
				<li>Frequency:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>Calendar change:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>Regularity pattern:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=855]">
		<b>CAPTIONS AND PATTERN--INDEXES
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>First level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Second level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Third level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Fourth level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Fifth level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Sixth level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Alternative numbering scheme, first level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Alternative numbering scheme, second level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>First level of chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='j']">
				<li>Second level of chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Third level of chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Fourth level of chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Alternative numbering scheme, chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Type of index:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Copy:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Bibliographic units per next higher level:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='v']">
				<li>Numbering continuity:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='w']">
				<li>Frequency:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>Calendar change:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>Regularity pattern:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=856]">
		<b>ELECTRONIC LOCATION AND ACCESS
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Field link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Host name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Access number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Compression information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Path:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Electronic name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Uniform resource name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Processor of request:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>Instruction:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='j']">
				<li>Bits per second:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Password:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Logon:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Contact for access assistance:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Name of location of host in subfield $a:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Operating system:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Port:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Electronic format type :
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Settings:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>File size:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Terminal emulation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Uniform Resource Identifier:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='v']">
				<li>Hours access method available:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='w']">
				<li>Record control number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>Nonpublic note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>Link text :
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Public note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Access method:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=863]">
		<b>ENUMERATION AND CHRONOLOGY--BASIC BIBLIOGRAPHIC UNIT
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>First level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Second level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Third level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Fourth level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Fifth level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Sixth level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Alternative numbering scheme, first level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Alternative numbering scheme, second level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>First level of chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='j']">
				<li>Second level of chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Third level of chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Fourth level of chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Alternative numbering scheme, chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Converted Gregorian year:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Piece designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Piece physical condition:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Copyright article-fee code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Copy number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='w']">
				<li>Break indicator:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>Nonpublic note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Public note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=864]">
		<b>ENUMERATION AND CHRONOLOGY--SUPPLEMENTARY MATERIAL
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>First level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Second level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Third level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Fourth level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Fifth level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Sixth level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Alternative numbering scheme, first level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Alternative numbering scheme, second level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>First level of chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='j']">
				<li>Second level of chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Third level of chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Fourth level of chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Alternative numbering scheme, chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Converted Gregorian year:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Title of supplementary material:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Piece designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Piece physical condition:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Copyright article-fee code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Copy number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='w']">
				<li>Break indicator:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>Nonpublic note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Public note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=865]">
		<b>ENUMERATION AND CHRONOLOGY--INDEXES
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>First level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Second level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Third level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Fourth level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Fifth level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Sixth level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Alternative numbering scheme, first level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Alternative numbering scheme, second level of enumeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>First level of chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='j']">
				<li>Second level of chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Third level of chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Fourth level of chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Alternative numbering scheme, chronology:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Converted Gregorian year:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Title of index:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Piece designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Piece physical condition:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Copyright article-fee code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Copy number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='w']">
				<li>Break indicator:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>Nonpublic note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Public note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=866]">
		<b>TEXTUAL HOLDINGS--BASIC BIBLIOGRAPHIC UNIT
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Textual string:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>Nonpublic note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Public note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=867]">
		<b>TEXTUAL HOLDINGS--SUPPLEMENTARY MATERIAL
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Textual holdings:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>Nonpublic note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Public note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=868]">
		<b>TEXTUAL HOLDINGS--INDEXES
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Textual holdings:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>Nonpublic note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Public note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=870]">
		<b>VARIANT PERSONAL NAME
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Personal name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Numeration:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Titles and other words associated with a name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Dates associated with a name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Relator term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Date of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Miscellaneous information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='j']">
				<li>Tag and sequence number of the field for which 870 is a variant(R):
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Form subheading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Language of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Fuller form of name:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Affiliation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='4']">
				<li>Relator code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=871]">
		<b>VARIANT CORPORATE NAME
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Corporate name or jurisdiction name as entry element:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Subordinate unit:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Location of meeting:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Date of meeting or treaty signing:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Relator term:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Date of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Miscellaneous information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='j']">
				<li>Tag and sequence number of the field for which 871 is a variant(R):
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Form subheading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Language of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section/meeting:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Affiliation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='4']">
				<li>Relator code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=872]">
		<b>VARIANT CONFERENCE OR MEETING NAME
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Meeting name or jurisdiction name as entry element:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Number (BK CF MP MU SE VM MX):
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Location of meeting:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Date of meeting:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Subordinate unit:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Date of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Miscellaneous information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='j']">
				<li>Tag and sequence number of the field for which 872 is a variant(R):
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Form subheading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Language of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section/meeting:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Name of meeting following jurisdiction name entry element:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Affiliation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='4']">
				<li>Relator code:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=873]">
		<b>VARIANT UNIFORM TITLE HEADING
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Uniform title:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Date of treaty signing:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Date of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Miscellaneous information:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Medium:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='j']">
				<li>Tag and sequence number of the field for which 873 is a variant(R):
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Form subheading:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Language of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Medium of performance for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Number of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Arranged statement for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Name of part/section of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Key for music:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Version:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Title of a work:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=876]">
		<b>ITEM INFORMATION--BASIC BIBLIOGRAPHIC UNIT
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Internal item number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Invalid or cancelled internal item number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Cost:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Date acquired:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Source of acquisition:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Use restrictions:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='j']">
				<li>Item status:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Temporary location:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Piece designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Invalid or cancelled piece designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Copy number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>Nonpublic note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Public note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=877]">
		<b>ITEM INFORMATION--SUPPLEMENTARY MATERIAL
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Internal item number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Invalid or cancelled internal item number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Cost:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Date acquired:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Source of acquisition:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Use restrictions:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='j']">
				<li>Item status:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Temporary location:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Piece designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Invalid or cancelled piece designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Copy number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>Nonpublic note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Public note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=878]">
		<b>ITEM INFORMATION--INDEXES
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Internal item number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Invalid or cancelled internal item number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Cost:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Date acquired:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Source of acquisition:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Use restrictions:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='j']">
				<li>Item status:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Temporary location:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Piece designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Invalid or cancelled piece designation:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Copy number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>Nonpublic note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Public note:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Materials specified:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Link and sequence number:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=880]">
		<b>ALTERNATE GRAPHIC REPRESENTATION
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='6']">
				<li>Linkage:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='a']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='j']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='v']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='w']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='0']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='1']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='4']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='5']">
				<li>Same as associated field:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='7']">
				<li>Undefined; each contains blank (#):
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Undefined; each contains blank (#):
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='9']">
				<li>Undefined; each contains blank (#):
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[@tag=886]">
		<b>FOREIGN MARC INFORMATION FIELD
		</b>
		<ul>
			<xsl:for-each select="subfield[@code='a']">
				<li>Tag of the foreign MARC field/Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='b']">
				<li>Content of the foreign MARC field/Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='2']">
				<li>Source of data:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='c']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='d']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='e']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='f']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='g']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='h']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='i']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='j']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='k']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='l']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='m']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='n']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='o']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='p']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='q']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='r']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='s']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='t']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='u']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='v']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='w']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='x']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='y']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='z']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='0']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='1']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='3']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='4']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='5']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='6']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='7']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='8']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
			<xsl:for-each select="subfield[@code='9']">
				<li>Foreign MARC subfield:
				<xsl:value-of select="text()"/>
				</li>
			</xsl:for-each>
		</ul><p></p>
	</xsl:template>
	<xsl:template match="datafield[starts-with(@tag,'9')]">
	</xsl:template>
</xsl:stylesheet>
<!-- Stylus Studio meta-information - (c)1998-2002 eXcelon Corp.
<metaInformation>
<scenarios ><scenario default="no" name="Ray Charles" userelativepaths="yes" externalpreview="no" url="..\xml\MARC21slim\raycharles.xml" htmlbaseurl="" processortype="internal" commandline="" additionalpath="" additionalclasspath="" postprocessortype="none" postprocesscommandline="" postprocessadditionalpath="" postprocessgeneratedext=""/><scenario default="yes" name="s7" userelativepaths="yes" externalpreview="no" url="..\ifla\sally7.xml" htmlbaseurl="" processortype="internal" commandline="" additionalpath="" additionalclasspath="" postprocessortype="none" postprocesscommandline="" postprocessadditionalpath="" postprocessgeneratedext=""/></scenarios><MapperInfo srcSchemaPath="" srcSchemaRoot="" srcSchemaPathIsRelative="yes" srcSchemaInterpretAsXML="no" destSchemaPath="" destSchemaRoot="" destSchemaPathIsRelative="yes" destSchemaInterpretAsXML="no"/>
</metaInformation>
-->