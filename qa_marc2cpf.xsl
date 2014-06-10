<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
                xmlns:eac="urn:isbn:1-931666-33-4"                
                xmlns:lib="http://example.com/"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:saxon="http://saxon.sf.net/"
                xmlns:fn="http://www.w3.org/2005/xpath-functions"
                xmlns:mods="http://www.loc.gov/mods/v3"
                exclude-result-prefixes="#all"
                >

    <!--
        Needs a way to flag files in the list that were never checked.
        
        See qa_notes.md. Tests here should be in the same order as qa_notes.md.
        
        echo "<container>" > qa_marc_list.xml; find cpf -type f -printf "<file>%h/%f</file>\n" >> qa_marc_list.xml; echo "</container>" >> qa_marc_list.xml
        saxon.sh qa_marc_list.xml qa_marc2cpf.xsl | less
        
        or

        saxon.sh qa_marc_list.xml qa_marc2cpf.xsl >qa_marc.txt 2>&1
        
        Based on qa_report.xsl. 
        
        This error usually means you are missing a file in qa_marc_list.xml, and you need to regenerate qa_marc_list.xml
        via the shell command above:
        
        SXXP0003: Error reported by XML parser: Content is not allowed in prolog.
    -->

    <xsl:output method="text" indent="no"/>

    <xsl:param name="debug" select="false()"/>

    <xsl:param name="output_dir" select="'./cpf'"/>
    <xsl:param name="fallback_default" select="'US-SNAC'"/>
    <xsl:param name="auth_form" select="'WorldCat'"/>
    <xsl:param name="inc_orig" select="true()"  as="xs:boolean"/>
    <xsl:param name="archive_name" select="'WorldCat'"/>

    <!-- These three params (variables) are passed to the cpf template eac_cpf.xsl via params to tpt_body. -->

    <xsl:param name="ev_desc" select="'Derived from MARC'"/> <!-- eventDescription -->
    <!-- xlink:role The $av_ variables are in lib.xsl. -->
    <xsl:param name="xlink_role" select="$av_archivalResource"/> 
    <xsl:param name="xlink_href" select="'http://www.worldcat.org/oclc'"/> <!-- Not / terminated. Add the / in eac_cpf.xsl. xlink:href -->

    <xsl:include href="lib.xsl"/>

    <xsl:template match="/">
        <xsl:call-template name="tpt_match_record">
            <xsl:with-param name="list" select="."/>
        </xsl:call-template>
    </xsl:template>


    <xsl:template name="tpt_match_record">
        <xsl:param name="list"/>
        
        <!-- <xsl:variable name="name" select="document(concat('./', text()))/*"/> -->
        <!-- <xsl:when test="matches($uri, '11422625\.r01')"> -->
        <!-- <xsl:variable name="uri" select="''"/> -->
        <!-- <xsl:copy-of select="$list/container/file[matches(., '11422625\.r01')]"/> -->

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '11422625\.r01')]))/*">
            <xsl:choose>
                <xsl:when test="/eac:eac-cpf/eac:cpfDescription/eac:relations/eac:resourceRelation/@xlink:arcrole =
                                $av_creatorOf">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '11447242\.r03')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:resourceRelation[@xlink:href='http://www.worldcat.org/oclc/11447242'
                                and @xlink:arcrole=$av_creatorOf]) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '11447242\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:cpfRelation[matches(eac:relationEntry, 'Washburn family', 'i')]) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '122456647\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:localDescription) = 8 and
                                count(//eac:description/eac:place) = 7">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '26891471\.r01')]))/*">
            <xsl:choose>
                <xsl:when test="(count(//eac:resourceRelation[matches(@xlink:href, '26891471') and
                                @xlink:arcrole=$av_creatorOf]) = 1) and
                                //eac:description/eac:existDates/eac:date = 'active approximately 1987'">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '122519914\.r01')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates) = 0">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '122537190\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:relationEntry[text() = 'Sundown \&amp;\and\ La Plata Mining Company (Utah).']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '122542862\.r76')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates/eac:date[@localType=$av_suspiciousDate and text() = '1735-1???.']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '123408061a\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:function[eac:term='Administration of nonprofit organizations']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '123410709\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates/eac:dateRange[eac:fromDate='active 1917' and eac:toDate='active 1960']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '123415450\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates/eac:dateRange[eac:fromDate='1061 or 1062' and eac:toDate='1121']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '123415456\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates/eac:dateRange[eac:fromDate='' and eac:toDate='0767 or 0768']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '123415574\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates/eac:dateRange[
                                eac:fromDate[@notBefore='1212' and @notAfter='1214']
                                and eac:toDate[@notBefore='1295' and @notAfter='1297']]) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <!-- This one and the following one go together -->
        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '123439095\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:resourceRelation[matches(@xlink:href, '123439095') and
                                @xlink:arcrole=$av_creatorOf]) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                    <xsl:copy-of select="//eac:resourceRelation"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <!-- This one and the previous one go together -->
        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '123439095\.r07')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:resourceRelation[matches(@xlink:href, '123439095') and
                                @xlink:arcrole=$av_creatorOf]) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                    <xsl:copy-of select="//eac:resourceRelation"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '123452814\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:cpfRelation[matches(eac:relationEntry, 'Horowitz')]) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                    <xsl:copy-of select="//eac:resourceRelation"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '155416763\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:function) = 1 and count(//eac:occupation) = 0">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '155438491\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates/eac:dateRange
                                [eac:fromDate='approximately 1865' and eac:toDate='1944']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '155448889\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates/eac:dateRange
                                [eac:fromDate='' and eac:toDate='1688']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '17851136\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:occupation[eac:term='Collectors.']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '209838303\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:languageDeclaration[eac:language='Swedish']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '210324503\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates/eac:date
                                [@localType=$av_suspiciousDate]) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '220227335\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates[eac:date[@localType=$av_suspiciousDate] and eac:date='1912-0.']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '220426543\.r01')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates[eac:date[@localType=$av_suspiciousDate] and eac:date='1?54-']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '222612265x\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates/eac:dateRange
                                [eac:fromDate='1920' and eac:toDate[@notBefore='1983' and @notAfter='1989']='approximately 1986' ]) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '222612265a\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates/eac:dateRange
                                [eac:fromDate='approximately 1896' and eac:toDate='']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '225810091a\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:occupation[eac:term='Academics.']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '225851373\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:localDescription
                                [@localType=$av_associatedSubject]/eac:term) = 8 and 
                                count(//eac:description/eac:place
                                [@localType=$av_associatedPlace]/eac:placeEntry) = 2">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '233844794\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates[eac:date
                                [@localType=$av_active and @notBefore='0101' and @ notAfter='0200']
                                ='active 2nd century']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '270617660\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates/eac:dateRange[eac:toDate
                                [@localType=$av_died and @notBefore='1601' and @ notAfter='1602']
                                ='1601 or 1602']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '270657317\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates[eac:date
                                [@localType=$av_active and @notBefore='1724' and @ notAfter='1725']
                                ='active 1724 or 1725']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '270873349\.r01')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates/eac:date[@localType=$av_suspiciousDate and text() = '1834-1876 or later.']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <!--
            Also has another later test for de-duplicating cpfRelations.
            
            Test that this is not suspicious. We had a bug where multi century dateRanges > 60 years were
            suspicious, but century dates don't work like other dateRanges, so the >60 test does not apply.
        -->
        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '281846814\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates
                                [localType=$av_suspiciousDate]) = 0 and
                                count(//eac:description/eac:existDates/eac:dateRange[eac:fromDate
                                [@localType=$av_active and @notBefore='1801' and @notAfter='1900']
                                ='19th century']) = 1 and
                                count(//eac:description/eac:existDates/eac:dateRange[eac:toDate
                                [@localType=$av_active and @notBefore='1901' and @notAfter='2000']
                                ='20th century']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '313817562\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates/eac:dateRange[eac:fromDate
                                [@localType=$av_born]
                                ='1837']) = 1 and
                                count(//eac:description/eac:existDates/eac:dateRange[eac:toDate
                                [@localType=$av_died]
                                ='1889']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '3427618\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates/eac:date[@localType=$av_suspiciousDate and text() = '194l-']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '367559635\.c')]))/*">
            <xsl:choose>
                <xsl:when test="/eac:eac-cpf/eac:cpfDescription/eac:identity/eac:nameEntry/eac:part='Jones, Mrs. J.C., 1854-'">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '39793761\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:cpfRelation) = 1 and
                                //eac:cpfRelation/eac:relationEntry='Japanese American Research Project (University of California, Los Angeles)'">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                    <xsl:copy-of select="//eac:resourceRelation"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '42714894\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates/eac:dateRange[eac:fromDate='active 1839']) = 1 and
                                count(//eac:description/eac:existDates/eac:dateRange[eac:toDate='active 1906']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <!-- Only checking for 2 cpfRelation tags is minimal, but enough for this test. -->
        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '44529109\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:cpfRelation) = 2">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                    <xsl:copy-of select="//eac:resourceRelation"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '505818582\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates/eac:dateRange/eac:fromDate
                                [@localType=$av_born and @notBefore='1870' and @notAfter='1879']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '505818582a\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates/eac:dateRange[eac:fromDate
                                [@localType=$av_born and @notBefore='1800' and @notAfter='1899']='1800s']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '51451353\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:occupation[@localType=$av_derivedFromRole and eac:term='Photographers.']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '55316797\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:localDescription
                                [@localType=$av_associatedSubject
                                and eac:term='CHILE--MINISTERIO DE TIERRAS Y COLONIZACION--DEPARTAMENTO JURIDICO Y DE INPECCION DE SERVICIOS']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '611138843\.r56')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates/eac:date
                                [@localType=$av_suspiciousDate and text() = '1714 or -15-1757.']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '678631801\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates/eac:date
                                [@localType=$av_suspiciousDate and text() = '16uu-17uu.']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '702176575\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates
                                [eac:date[@localType=$av_active and @notBefore='0001' and @notAfter='0100']= 'active 1st century']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '777390959\.r08')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates/eac:date
                                [@localType=$av_suspiciousDate and text() = '8030-1857.']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '8560008\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:cpfRelation) = 3 and
                                //eac:cpfRelation/eac:relationEntry='Kane, Thomas Leiper, 1822-1883.'">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                    <xsl:copy-of select="//eac:resourceRelation"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <!--
            I printed out the string-length() then hard coded it into the xpath. If it changes, something is
            probably wrong.
        -->
        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '8560380\.c')]))/*">
            <xsl:choose>
                <xsl:when test="string-length(//eac:resourceRelation/eac:objectXMLWrap/mods:mods/mods:abstract)=2337">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                    <xsl:copy-of select="//eac:resourceRelation"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '8562615\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:place
                                [@localType=$av_associatedPlace and eac:placeEntry='Ohio--Ashtabula County']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '8563535\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:cpfRelation) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                    <xsl:copy-of select="//eac:resourceRelation"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '8586125\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates/eac:dateRange[eac:fromDate='active 1922']) = 1 and
                                count(//eac:description/eac:existDates/eac:dateRange[eac:toDate='active 1949']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '123410649\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates/eac:dateRange[eac:fromDate='active 1938']) = 1 and
                                count(//eac:description/eac:existDates/eac:dateRange[eac:toDate='active 2006']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '85037313a\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates/eac:dateRange[eac:fromDate='active 1813']) = 1 and
                                count(//eac:description/eac:existDates/eac:dateRange[eac:toDate='active 1944']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '147444338\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:occupation[@localType=$av_derivedFromRole and eac:term='Compilers.']) = 1 and
                                count(//eac:occupation[eac:term='Silversmiths.']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '155416763\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:function[@localType=$av_derivedFromRole and eac:term='Collectors.']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <!--
            This fussy test will break if anything changes how biogHist/p is created. If that happens, check
            that the biogHist is correct, then update the hard code string length value.
        -->
        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '123439230\.c')]))/*">
            <xsl:variable name="tmp">
                <xsl:value-of select="//eac:description/eac:biogHist/eac:p"/>
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="string-length($tmp) = 2973">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                    <!-- <xsl:value-of select="string-length($tmp)"/> -->
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '14638716\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates/eac:dateRange
                                [eac:fromDate[@localType=$av_active]='active 1768']) = 1 and
                                count(//eac:description/eac:existDates/eac:dateRange
                                [eac:toDate[@localType=$av_active]='active 1792']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '62173411\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates/eac:dateRange
                                [eac:fromDate[@localType=$av_active and @notBefore='1920' and @notAfter='1929']
                                ='active approximately 1920s']) = 1 and 
                                count(//eac:description/eac:existDates/eac:dateRange
                                [eac:toDate[@localType=$av_active and @notBefore='1980' and @notAfter='1989']
                                ='active 1980s']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '85016803\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates
                                [eac:date[@localType=$av_active and @notBefore='1701' and @notAfter='1800']
                                ='active 18th century']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '62173411b\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates/eac:dateRange
                                [eac:fromDate[@localType=$av_active and @notBefore='1920' and @notAfter='1929']
                                ='active approximately 1920s']) = 1 and
                                count(//eac:description/eac:existDates/eac:dateRange
                                [eac:toDate[@localType=$av_active and @notBefore='1980' and @notAfter='1989']
                                ='active approximately 1980s']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '62173411c\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates
                                [eac:date[@localType=$av_active and @notBefore='1920' and @notAfter='1929']
                                ='active approximately 1920s']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '54643931\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates
                                [eac:date[@localType=$av_active]
                                ='active 1947']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <!--
           Test that this is not suspicious. We had a bug where multi century dateRanges > 60 years were
           suspicious, but century dates don't work like other dateRanges, so the >60 test does not apply.
        -->
        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '311261944\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates
                                [localType=$av_suspiciousDate]) = 0 and
                                count(//eac:description/eac:existDates/eac:dateRange
                                [eac:fromDate[@localType=$av_active and @notBefore='1801' and @notAfter='1900']
                                ='19th century']) = 1 and
                                count(//eac:description/eac:existDates/eac:dateRange
                                [eac:toDate[@localType=$av_active and @notBefore='1901' and @notAfter='2000']
                                ='20th century']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '227009956\.r01')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates/eac:dateRange
                                [eac:fromDate[@localType=$av_born]
                                ='1852']) = 1 and
                                count(//eac:description/eac:existDates/eac:dateRange
                                [eac:toDate[@localType=$av_died]
                                ='1911']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '123429932b\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:place
                                [eac:placeEntry='United States']) = 1 and 
                                count(//eac:description/eac:place
                                [eac:placeEntry='Soviet Union']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '123429932\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:place
                                [eac:placeEntry='United States']) = 1 and 
                                count(//eac:description/eac:place
                                [eac:placeEntry='Soviet Union']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '34992098\.r03')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:resourceRelation[matches(@xlink:href, '34992098') and
                                @xlink:arcrole=$av_referencedIn]) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                    <xsl:copy-of select="//eac:resourceRelation"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '281846814\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:cpfRelation[eac:relationEntry='Russell, Hattie, 19th/20th cent.']) = 1 and
                                count(//eac:cpfRelation[eac:relationEntry='Daly, Augustin, 1838-1899']) = 1 and 
                                count(//eac:cpfRelation) = 2">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                    <xsl:copy-of select="//eac:resourceRelation"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '281846814\.r02')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:cpfRelation
                                [eac:relationEntry='Russell, R. Fulton, 19th/20th cent.' and
                                @xlink:arcrole=$av_correspondedWith]) = 1 and
                                count(//eac:cpfRelation) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                    <xsl:copy-of select="//eac:resourceRelation"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '435496213a\.r09')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates/eac:dateRange
                                [eac:fromDate[@localType=$av_born and @notBefore='1829' and @notAfter='1830']
                                ='1829 or 1830']) = 1 and
                                count(//eac:description/eac:existDates/eac:dateRange
                                [eac:toDate[@localType=$av_died and @notBefore='1912' and @notAfter='1916']
                                ='1912 or 1916']) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '45038108\.c')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:cpfRelation
                                [eac:relationEntry='Comer, Hugh M., fl. 1888.' and
                                @xlink:arcrole=$av_correspondedWith]) = 1 and
                                count(//eac:cpfRelation
                                [eac:relationEntry='Central of Georgia Railway Clerks'' Organization (Ga.).' and
                                @xlink:arcrole=$av_correspondedWith]) = 1 and
                                count(//eac:cpfRelation
                                [eac:relationEntry='Central Rail Road and Banking Company of Georgia.' and
                                @xlink:arcrole=$av_correspondedWith]) = 1 and 
                                count(//eac:cpfRelation
                                [eac:relationEntry='Railroad Mutual Loan Association (Ga.).' and
                                @xlink:arcrole=$av_correspondedWith]) = 1 ">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                    <xsl:copy-of select="//eac:resourceRelation"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '45038108\.r05')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:cpfRelation
                                [eac:relationEntry='Central of Georgia Railway. Executive Dept.' and
                                @xlink:arcrole=$av_correspondedWith]) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                    <xsl:copy-of select="//eac:resourceRelation"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat('./', $list/container/file[matches(., '776715862\.r03')]))/*">
            <xsl:choose>
                <xsl:when test="count(//eac:description/eac:existDates
                                [@localType=$av_suspiciousDate]) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error:', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


    </xsl:template>
</xsl:stylesheet>
