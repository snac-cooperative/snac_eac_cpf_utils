<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="2.0"
                xmlns:eac="urn:isbn:1-931666-33-4"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                exclude-result-prefixes="#all"
                >

    <!--
        Return results from xpath select
        extension-element-prefixes="date exsl"
        
        Example command line using find:
        find lds_cpf -type f -exec saxon.sh {} xpath_select.xsl \; >> xpath.log 2>&1 &
    -->
    
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:variable name="cr" select="'&#x0A;'"/>
    
    <xsl:param name="search"/>
    
    <!--
        This is a small script just to run an xpath on some xml. The Linux xpath utility doesn't quite give
        useful output, although a Perl script similar to xpath, based on XML::LibXML or XML::Xpath would be
        good and very fast. And it would have dynamic xpath execution.
        
        No dynamic xpath in XSLT, so you'll just have to copy the xpath from the for-each into the
        container/@xpath attribute.
        
        When creating a new xpath, copy the most similar good one into test="true()" and change the old test to "false()" in
        order to save it for future reference.
    -->
    <xsl:template match="/">
        <xsl:choose>

            <xsl:when test="true()">
                <!--
                    jun 29 2015 a real, working example
                    saxon.sh /data/source/nara/archive/nara_corp.xml xpath_select.xsl > xpath.log 2>&1 &

                    > grep found xpath.log | wc -l
                    54986
                -->
                <container xpath="XMLExport/das_items/organization">
                    <xsl:for-each
                        select="XMLExport/das_items/organization">
                        <found><xsl:value-of select="naId"/></found>
                    </xsl:for-each>
                </container>
                <container xpath="XMLExport/organization">
                    <xsl:for-each
                        select="XMLExport/organization">
                        <found><xsl:value-of select="naId"/></found>
                    </xsl:for-each>
                </container>
            </xsl:when>


            <xsl:when test="false()">
                <!--
                    Find examples of existDates that has <date>
                -->
                <container xpath="eac:eac-cpf/eac:cpfDescription/eac:description/eac:existDates[eac:date]">
                    <xsl:for-each
                        select="eac:eac-cpf/eac:cpfDescription/eac:description/eac:existDates[eac:date]">
                        <found>
                            <xsl:copy-of select="."/>
                        </found>
                    </xsl:for-each>
                </container>
            </xsl:when>


            <xsl:when test="false()">
                <!--
                    Count person records.
                -->
                <container xpath="/ead/archdesc/descgrp/bioghist">
                    <xsl:for-each
                        select="/ead/archdesc/descgrp/bioghist">
                        <found>
                            <xsl:value-of select="concat('len: ', string-length(.))"/>
                        </found>
                    </xsl:for-each>
                </container>
            </xsl:when>


            <xsl:when test="false()">
                <!--
                    Count person records.
                    
                -->
                <container xpath="(/XMLExport/person|XMLExport/das_items/person)">
                    <xsl:for-each
                        select="(/XMLExport/person|XMLExport/das_items/person)">
                        <found naId="{naId}">
                            <xsl:value-of select="name"/>
                        </found>
                    </xsl:for-each>
                </container>
            </xsl:when>

            <xsl:when test="false()">
                <!--
                    Count person records with descriptionReference that has title, but no titleHierarchy.
                    
                    The outer for-each selects a <person> record so we can get the naId. The inner for-each is
                    mostly used to set the context, but also serves as an xsl:if (which is what every for-each
                    does, but here we're clear about the if-ish behavior).
                    
                    Use position() = 1 with the inner for-each because we only need one record to hit in order
                    to count the <person> as needing a fix.
                -->
                <container xpath="(/XMLExport/person|XMLExport/das_items/person)//descriptionReference[title and not(titleHierarchy)]">
                    <xsl:for-each
                        select="(/XMLExport/person|XMLExport/das_items/person)">
                        <xsl:variable name="naId" select="naId"/>
                        <xsl:for-each
                            select=".//descriptionReference[title and not(titleHierarchy) and position() = 1]">
                            <found naId="{$naId}">
                                <xsl:copy-of select="."/>
                            </found>
                        </xsl:for-each>
                    </xsl:for-each>
                </container>
            </xsl:when>
            <xsl:when test="false()">
                <container xpath="//eac:cpfRelation/@xlink:arcrole">
                    <xsl:for-each select="//eac:cpfRelation/@xlink:arcrole">
                        <found>
                            <xsl:value-of select="."/>
                        </found>
                    </xsl:for-each>
                </container>
            </xsl:when>
            <xsl:when test="false()">
                <container xpath="//person/contributorTypeArray/contributorType/termName">
                    <xsl:for-each select="//person/contributorTypeArray/contributorType/termName">
                        <found>
                            <xsl:value-of select="concat('contributorType: ', .)"/>
                        </found>
                    </xsl:for-each>
                </container>
            </xsl:when>
            <xsl:when test="false()">
                <container xpath="(//person)[linkCounts/totalDescriptionLinkCount = 0]/naId">
                    <!-- <xsl:copy-of select="(//organizationName)[linkCounts/totalDescriptionLinkCount = 0]"/> -->
                    <!-- <xsl:for-each select="(//organizationName)[linkCounts/totalDescriptionLinkCount = 0]/naId"> -->
                    <xsl:for-each select="(//person)[linkCounts/totalDescriptionLinkCount = 0]/naId">
                        <found>
                            <xsl:copy-of select="concat('https://catalog.archives.gov/id/', .)"/>
                        </found>
                    </xsl:for-each>
                </container>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
