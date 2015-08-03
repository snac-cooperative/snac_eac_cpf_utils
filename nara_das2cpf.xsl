<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
                xmlns:ns="http://www.loc.gov/MARC21/slim"
                xmlns:eac="urn:isbn:1-931666-33-4"
                xmlns:date="http://exslt.org/dates-and-times"
                xmlns:exsl="http://exslt.org/common"
                xmlns:nara="http://authority.das.nara.gov/"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:lib="http://example.com/"
                extension-element-prefixes="date exsl"
                exclude-result-prefixes="#all"
                >
    
    <!--
        Author: Tom Laudeman
        The Institute for Advanced Technology in the Humanities
        
        Copyright 2015 The Rector and Visitors of the University of Virginia. Licensed under the Educational
        Community License, Version 2.0 (the "License"); you may not use this file except in compliance with
        the License. You may obtain a copy of the License at
        
        http://opensource.org/licenses/ECL-2.0
        http://www.osedu.org/licenses/ECL-2.0
        
        Unless required by applicable law or agreed to in writing, software distributed under the License is
        distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
        the License for the specific language governing permissions and limitations under the License.
        
        This script will extract NARA DAS XML to EAC-CPF XML (aka simply CPF). There are two extractions into
        a single normalized internal structure. NARA <person> records are handled by eac:person_ccpf() and
        NARA <organization> (aka CPF corporateBody) by eac:org_ccpf().
        
        Example to run the QA records.
        
        saxon.sh nara_qa.xml nara_das2cpf.xsl > nara.log 2>&1 &
        
        > head nara_qa.xml 
        <?xml version="1.0"?>
        <XMLExport>
          <das_items>
              <person>
                 <naId>10568003</naId>
                 <termName>Piard, Victor, ca. 1825-1901</termName>
                 <name>Piard, Victor,</name>
                 <isPreferred>true</isPreferred>
                 <isUnderEdit>false</isUnderEdit>
                 <isReference>false</isReference>

        > tail nara_qa.xml
                    <totalDescriptionLinkCount>22</totalDescriptionLinkCount>
                    <underEditDescriptionLinkCount>0</underEditDescriptionLinkCount>
                    <subjectLinkCount>0</subjectLinkCount>
                    <contributorLinkCount>0</contributorLinkCount>
                    <creatorLinkCount>0</creatorLinkCount>
                    <donorLinkCount>0</donorLinkCount>
                    <jurisdictionLinkCount>0</jurisdictionLinkCount>
                </linkCounts>
            </organization>
        </XMLExport>
        
        We only run the NARA person records due to issues with authority control for the organization records.
        
        saxon.sh nara_pers.xml nara_das2cpf.xsl inc_orig=0 > nara.log 2>&1 &
        
        To simplify things, the input xml file is a symbolic link to the source data. 

        > ls -dl nara_pers.xml 
        lrwxrwxrwx 1 twl8n snac 31 Jan 14 13:57 nara_pers.xml -> /data/source/nara/nara_pers.xml


    -->

    <xsl:output name="xml" method="xml" indent="yes" omit-xml-declaration="no"/>
    
    <xsl:variable name="apos">'</xsl:variable>
    <xsl:variable name="date" 
                  select="current-dateTime()"/>
    
    <xsl:variable name="xslt_script" select="'nara_das2cpf.xsl'"/>
    <xsl:variable name="xslt_version" select="system-property('xsl:version')" />
    <xsl:variable name="xslt_vendor" select="system-property('xsl:vendor')" />
    <xsl:variable name="xslt_vendor_url" select="system-property('xsl:vendor-url')" />
    
    <!--
        Enable additional messages. More verbose than debug.
    -->
    <xsl:param name="debug" select="false()"/>
    
    <xsl:param name="rules" select="'nara'"/>
    <xsl:param name="output_dir" select="'./nara_cpf'"/>
    <xsl:param name="fallback_default" select="'US-SNAC'"/>
    <xsl:param name="auth_form" select="'NARA'"/>
    <xsl:param name="inc_orig" select="true()"  as="xs:boolean"/>
    <xsl:param name="archive_name" select="'NARA'"/>
    <xsl:param name="chunk_size" select="100"/>
    <xsl:param name="chunk_prefix" select="'nochunks'"/>
    <xsl:param name="offset" select="1"/>
    <xsl:param name="use_chunks" as="xs:boolean">
        <xsl:choose>
            <xsl:when test="not($chunk_prefix='nochunks')">
                <xsl:value-of select="true()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:param>
    
    <!-- These three params (variables) are passed to the cpf template eac_cpf.xsl via params to tpt_body. -->
    
    <xsl:param name="ev_desc" select="'Derived from NARA DAS XML'"/> <!-- eventDescription -->
    <!--
        xlink:role The $av_ variables are in av.xsl which is included lib.xsl.
        
        Note: Use $param_data/eac:rrel or $param_data/eac:use_rrel with $param_data/eac:rr_xlink_href.
        
        Note: these variable names should reflect the different usages cpfRelation/@xlink:role and
        resourceRelation/@xlink:role. There have been bugs related to mixing these up.
        
        It appears that both of the vars rr_xlink_role and rr_xlink_href are used by resourceRelation.
        
        Also note: rr_xlink_href is not / terminated. We add the / and record ID in eac_cpf.xsl. tag: xlink:href
        
    -->
    <xsl:param name="rr_xlink_role" select="$av_archivalResource"/> 
    <xsl:param name="rr_xlink_href" select="'https://catalog.archives.gov/id'"/> 
    
    <!--
        The snacwc: info comes from worldcat_code.xml which was auto-extracted from worldcat identities.
    -->
    
    <xsl:variable name="agency_info" xmlns="urn:isbn:1-931666-33-4">
        <agencyCode>
            <xsl:value-of select="'nara isil code'"/>
        </agencyCode>
        <agencyName>
            <xsl:text>U.S. National Archives and Records Administration</xsl:text>
        </agencyName>
        <descriptiveNote>
            <!-- <xsl:for-each select="$ainfo/snacwc:container"> -->
            <p>
                <span localType="snacwc:original"><xsl:value-of select="'$org_query'"/></span>
                <span localType="snacwc:inst"><xsl:value-of select="'snacwc:name'"/></span>
                <span localType="snacwc:isil"><xsl:value-of select="'snacwc:isil'"/></span>
            </p>
            <!-- </xsl:for-each> -->
        </descriptiveNote>
    </xsl:variable>
    
    <xsl:include href="eac_cpf.xsl"/>
    <xsl:include href="lib.xsl"/>
    
    <!--
        Remove confusion about which template will hit by forcing the mode
    -->
    
    <xsl:template match="nonPreferredHeadingArray" mode="alt" xmlns="urn:isbn:1-931666-33-4">
        <xsl:for-each select="variantPersonName">
            <!-- <xsl:element name="{eac:npath(.,'_')}"> -->
            <xsl:element name="{name()}">
                <xsl:attribute name="path" select="eac:npath(.,'/')"/>
                <isPreferred>
                    <xsl:value-of select="normalize-space(isPreferred)"/>
                </isPreferred>
                <naId>
                    <xsl:value-of select="normalize-space(naId)"/>
                </naId>
                <fromDate>
                    <xsl:value-of select="normalize-space(birthDate)"/>
                </fromDate>
                <toDate>
                    <xsl:value-of select="normalize-space(deathDate)"/>
                </toDate>
                <!--
                    Need to normalize-space() since many entries, esp termName have extra space.
                    
                    Some dates in termName have a leading /
                    <termName>Adams, Donald B., /1890-/1973</termName>
                -->
                <name><xsl:value-of select="normalize-space(name)"/></name>
                <termName><xsl:value-of select="eac:name_cleaner(termName)"/></termName>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>
    
    <!--
        Each of these becomes a resourceRelation in $param_data/rrel.

        Remove confusion about which template will hit by forcing the mode.
        Match * so that it will match any of the archivalDescription*Array elements.
        
        Put all archival descriptions in the same type of element, distinguished by a type attribute.
        
        Feb 12 2015 Amanda says that contributors are in reality creators. Make it so by changing the $type
        for contributor to $av_creatorOf.
        
        Mar 23 2015 Add titleHierarchy as part of the title. All titleHierarchy values end with a period
        (dot). If they didn't we might want to add a trailing dot.
        
        Apr 1 2015 There are 1313 instances of <title> with no <titleHierarchy> apparently (based on
        grep). This is should not break the code because we use both fields and we call normalize-space() to
        keep things clean.
    -->
    <xsl:template match="*" mode="ref_array" xmlns="urn:isbn:1-931666-33-4">
        <xsl:for-each select="descriptionReference">
            <xsl:variable name="type">
                <xsl:choose>
                    <xsl:when test="matches(../../name(), 'Creator')">
                        <xsl:value-of select="$av_creatorOf"/>
                    </xsl:when>
                    <xsl:when test="matches(../../name(), 'Contributor')">
                        <!--
                            Contributors are in reality creatorOf.
                            nara_cpf/10601750.xml
                        -->
                        <xsl:value-of select="$av_creatorOf"/>
                    </xsl:when>
                    <xsl:when test="matches(../../name(), 'References')">
                        <xsl:value-of select="$av_referencedIn"/>
                    </xsl:when>
                    <xsl:when test="matches(../../name(), 'Donor')">
                        <xsl:value-of select="$av_donorOf"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:variable>
            <archivalDescriptions
                parent="{../../name()}"
                type="{$type}"
                name="{name()}" 
                path="{eac:npath(.,'/')}">
                <naId><xsl:value-of select="normalize-space(naId)"/></naId>
                <recordType><xsl:value-of select="normalize-space(recordType)"/></recordType>
                <title><xsl:value-of select="normalize-space(concat(titleHierarchy, ' ', title))"/></title>
            </archivalDescriptions>
        </xsl:for-each>
    </xsl:template>
    
    <!--
        mar 19 2015 Due to issues with org records, we will not generate cpfRelations for org references.

        Old: Elements organizationalReferenceArray/organization are cpfRelations, so add cpf_relation elements
        to the <identity> record.
        
        From person 10568788:
        
        <organizationalReferenceArray>
        <organization>
        <naId>12009322</naId>
        <termName>Nuclear Regulatory Commission. Office of the Commissioners. (1/19/1975 - ca. 2000)</termName>
        </organization>
        </organizationalReferenceArray>
        
        From org 10533675:
        
        <personalReferenceArray>
        <person>
        <naId>10582938</naId>
        <termName>Stettinius, Edward R. (Edward Reilly), 1900-1949</termName>
        </person>
        </personalReferenceArray>
    -->
    <xsl:template match="*" mode="org_array" xmlns="urn:isbn:1-931666-33-4">
        <xsl:variable name="context" select="."/>
        <xsl:for-each select="person|organization">
            <xsl:variable name="rel_type">
                <xsl:choose>
                    <xsl:when test="matches(name(), 'organization')">
                        <xsl:value-of select="$corp_val"/>
                    </xsl:when>
                    <xsl:when test="matches(name(), 'person')">
                        <xsl:value-of select="$pers_val"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:variable>
            <!--
                It is unclear why this cpf_relation is not identical in structure to the actual CPF
                cpfRelation element. Perhaps extra attributes and elements are necessary for debugging and
                logging. It is fine as is, but should be considered for a fix, upgrade, or refactoring.
            -->
            <cpf_relation
                name="{name()}"
                type="{$rel_type}"
                path="{eac:npath(.,'/')}">
                <naId><xsl:value-of select="normalize-space(naId)"/></naId>
                <termName><xsl:value-of select="normalize-space(termName)"/></termName>
            </cpf_relation>
        </xsl:for-each>
    </xsl:template>
    
    <!--
        For a group of organizationName elements, create cpfRelation elements for all except ourself.
    -->
    <xsl:template match="*" mode="org_cpfrels" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="self_naId"/>
        
        <xsl:variable name="context" select="."/>
        <xsl:for-each select="organizationName[naId != $self_naId]">
            <cpf_relation
                name="{name()}"
                type="{$corp_val}"
                path="{eac:npath(.,'/')}">
                <naId><xsl:value-of select="normalize-space(naId)"/></naId>
                <termName><xsl:value-of select="normalize-space(termName)"/></termName>
            </cpf_relation>
        </xsl:for-each>
    </xsl:template>
    
    <!--
        There are many nodes with children <id> and <term>. Capture them in an agnostic manner.
        What the heck does this accomplish? Seems like a copy-of would be simpler.
    -->
    
    <xsl:template match="*" mode="id_and_term" xmlns="urn:isbn:1-931666-33-4">
        <element name="{name()}"
                 path="{eac:npath(.,'/')}">
            <naId><xsl:value-of select="normalize-space(naId)"/></naId>
            <termName><xsl:value-of select="normalize-space(termName)"/></termName>
        </element>
    </xsl:template>
    
    <xsl:function name="eac:disabled_norm" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="arg"/>
        <xsl:for-each select="$arg">
            <xsl:variable name="element_path" select="eac:npath(., '_')"/>
            <xsl:message>
                <xsl:value-of select="concat('func norm: ', $element_path, $cr)"/>
                <xsl:copy-of select="."/>
            </xsl:message>
            <xsl:if test="matches($element_path, '^termName')">
                <orig_termName>
                    <xsl:value-of select="."/>
                </orig_termName>
            </xsl:if>
            <xsl:element name="{$element_path}">
                <xsl:attribute name="path" select="eac:npath(.,'/')"/>
                <xsl:if test="string-length(normalize-space(.)) > 0 and ./text() and count(./node()) = 1">
                    <!--
                        Need to normalize-space() since many entries, esp termName have extra space.
                        
                        Some dates in termName have a leading /
                        <termName>Adams, Donald B., /1890-/1973</termName>
                    -->
                    <xsl:choose>
                        <xsl:when test="matches($element_path, 'termName')">
                            <xsl:value-of select="eac:name_cleaner(.)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="normalize-space(.)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
            </xsl:element>
        </xsl:for-each>
    </xsl:function>
    
    
    <!--
        Remove confusion about which template will hit by forcing the mode
        
        What would be the difference between *//* and *? Unclear why *//* was used in the first place.
        
        When it comes to including orig_termName for debugging purposes, we only want top level termName which
        is '^termName'.
    -->
    <xsl:template match="*"  mode="norm" xmlns="urn:isbn:1-931666-33-4">
        <xsl:variable name="element_path" select="eac:npath(., '_')"/>
        <xsl:if test="matches($element_path, '^termName')">
            <orig_termName>
                <xsl:value-of select="."/>
            </orig_termName>
        </xsl:if>
        <!-- <xsl:element name="{$element_path}"> -->
        <xsl:element name="{name()}">
            <xsl:attribute name="path" select="eac:npath(.,'/')"/>
            <xsl:if test="string-length(normalize-space()) > 0 and text() and count(node()) = 1">
                <!--
                    Need to normalize-space() since many entries, esp termName have extra space.
                    
                    Some dates in termName have a leading /
                    <termName>Adams, Donald B., /1890-/1973</termName>
                -->
                <xsl:choose>
                    <xsl:when test="matches($element_path, 'termName')">
                        <xsl:value-of select="eac:name_cleaner(.)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="normalize-space(.)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
        </xsl:element>
    </xsl:template>
    
    <!--
        We can use ancestor-or-self with the separator attribute to get the path (aka path() function) of an
        element. Current saxon no longer has the path() function.
    -->
    
    <xsl:template match="/" xmlns="urn:isbn:1-931666-33-4">
        <xsl:message>
            <xsl:value-of select="concat('                       Date today: ', current-dateTime(), $cr)"/>
            <xsl:value-of select="concat('Number of geonames places read in: ', count($places/*), $cr)"/>
            <xsl:value-of select="concat('                Writing output to: ', $output_dir, $cr)"/>
            <xsl:value-of select="concat('           Default authorizedForm: ', $auth_form, $cr)"/>
            <xsl:value-of select="concat('   Fallback (default) agency code: ', $fallback_default, $cr)"/>
            <xsl:value-of select="concat('         Default eventDescription: ', $ev_desc, $cr)"/>
            <xsl:value-of select="concat('               Default resRel href: ', $rr_xlink_href, $cr)"/>
            <xsl:value-of select="concat('               Default resRel role: ', $rr_xlink_role, $cr)"/>
            <xsl:choose>
                <xsl:when test="$inc_orig">
                    <xsl:value-of select="concat('          Include original record: yes', $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('          Include original record: no', $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
            
            <xsl:choose>
                <xsl:when test="$use_chunks">
                    <xsl:value-of select="concat('                     Using chunks: yes', $cr)"/>
                    <xsl:value-of select="concat('                  Chunk size XSLT: ', $chunk_size, $cr)"/>
                    <xsl:value-of select="concat('                 Chunk dir prefix: ', $chunk_prefix, $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('                     Using chunks: no', $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:message>
        <!-- <xsl:message> -->
        <!--     <xsl:text>Only processing 1000 records</xsl:text> -->
        <!-- </xsl:message> -->
        
        <!-- 
             For person, must be isPreferred and must have at least 1 total description link count. Records
             with zero tDLC are placeholders (in some sense).
             
             Loop over all <person> and <organization> then filter with an xsl:choose. We don't want to
             processing persons who are not preferred, or who have to description links. But we want something
             in the log for every input record.
        -->
        <xsl:for-each 
            select="/XMLExport/das_items/person|/XMLExport/person|/XMLExport/das_items/organization|/XMLExport/organization">
            
            <xsl:choose>
                <xsl:when test="name() = 'person' and (isPreferred != 'true' or linkCounts/totalDescriptionLinkCount = 0)">
                    <xsl:message>
                        <xsl:text>skipping: person </xsl:text>
                        <xsl:value-of select="concat('recordSource: ', recordSource, ' naId: ', naId, ' termName: ', termName)"/>
                        <xsl:value-of select="concat(' isPreferred: ', isPreferred, ' totalDescriptionLinkCount: ', linkCounts/totalDescriptionLinkCount)"/>
                        <xsl:value-of select="$cr"/>
                        <xsl:value-of select="concat('record_id: ', naId,
                                              ' termName: ', termName,
                                              ' type: ', name(), $cr)"/>
                    </xsl:message>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="multipass">
                        <xsl:choose>
                            <xsl:when test="name() = 'person'">
                                <xsl:copy-of select="eac:person_ccpf(.)"/>
                            </xsl:when>
                            <xsl:when test="name() = 'organization'">
                                <xsl:copy-of select="eac:org_ccpf(.)"/>
                            </xsl:when>
                            <xsl:otherwise>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    
                    <xsl:for-each select="$multipass/*">
                        <xsl:call-template name="tpt_main_processing">
                            <xsl:with-param name="multipass" select="$multipass"/>
                            <xsl:with-param name="original" select="."/>
                        </xsl:call-template>
                    </xsl:for-each>

                    <xsl:message/> <!-- put a blank line in the log file -->
                    <xsl:if test="position() = last()">
                        <xsl:message>
                            <xsl:value-of select="concat('Finished ', position(), ' records.')"/>
                        </xsl:message>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        <xsl:message>
            <xsl:text>Successful finish.</xsl:text>
        </xsl:message>
    </xsl:template>

    <xsl:template name="tpt_main_processing" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="multipass"/>
        <xsl:param name="original"/>

        <!--
            Will we incur the document node problem with var $ccpf? Apparently not, so we don't need to cast
            to type xs:element/*
            
            <xsl:variable name="ccpf" as="xs:element/*">

            Variable "container cpf" (thus ccpf) has all the data necessary to create each cpf record. Minimal
            processing is necessary to create variable param_data. Template tpt_body (called below) creates
            the cpf xml file.
        -->
        
        <xsl:variable name="ccpf">
            <xsl:copy-of select="."/>
        </xsl:variable>
        
        <xsl:if test="debug = true()">
            <xsl:message>
                <xsl:text>ccpf: </xsl:text>
                <xsl:apply-templates select="$ccpf" mode="pretty"/>
            </xsl:message>
        </xsl:if>

        <!-- record source if available is usually LCNAF -->
        <xsl:message>
            <xsl:value-of select="concat('rs: ', 
                                  $ccpf/eac:identity/eac:recordSource,
                                  ' ircn: ',
                                  $ccpf/eac:identity/eac:importRecordControlNumber)"/>
        </xsl:message>
        
        <xsl:variable name="record_id" select="$ccpf/eac:identity/eac:naId"/>
        
        <xsl:variable name="chunk_count"
                      select="position() div $chunk_size"/>
        
        <xsl:variable
            name="chunk_suffix"
            select="floor((position() - 1) div $chunk_size) + 1"/>
        
        <xsl:variable name="chunk_dir">
            <xsl:choose>
                <xsl:when test="$use_chunks">
                    <xsl:value-of select="concat($output_dir, '/', $chunk_prefix, '_', $chunk_suffix)"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Allow the use of an output dir even when not using chunks -->
                    <xsl:value-of select="$output_dir"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="exist_dates">
            <xsl:variable name="type" select="$ccpf/eac:identity/@type"/>
            <existDates>
                <xsl:for-each select="$ccpf/eac:identity">
                    <xsl:copy-of select="eac:exist_dates(
                                         eac:ed(.),
                                         $type)"/>
                </xsl:for-each>
            </existDates>
        </xsl:variable>
        
        <!-- 
             Feb 16 2015 administrativeHistorNote is hidden in identity/org_info, due to ambiguity
             over its status as biographical.
             
             We assume that biographicalNotes are only person and administrativeHistoryNote is only orgs,
             therefore they won't occur together and we can simply select both knowing that only the
             existing one will occur in any given record.
        -->
        <xsl:variable name="tag_545">
            <p>
                <xsl:value-of select="$ccpf/eac:identity/eac:biographicalNote"/>
                <xsl:value-of select="$ccpf/eac:identity/eac:administrativeHistoryNote"/>
            </p>
        </xsl:variable>
        
        <!-- 
             Use new multi-name capable algo. $entity_name must be empty.  person/termName has odd formatting,
             and includes <fullerFormOfName> which we don't want. We aren't generating a record for the organization
             wrapper, but if we were, organzation/termName would be even worse because it is a | pipe
             separated concatenation of all organizationName/termName values. For these reasons, we are better
             off building the cpf name ourselves.
        -->
        <xsl:variable name="entity_name"/>
        
        <xsl:variable name="normative_name">
            <xsl:copy-of select="eac:e_name_element($ccpf)"/>
        </xsl:variable>
        
        <xsl:message>
            <xsl:text>record_id: </xsl:text>
            <xsl:value-of select="concat($record_id,
                                  ' name: ', $normative_name/eac:e_name/eac:name_entry[1]/eac:part,
                                  ' type: ', $ccpf/eac:identity/@type)"/>
        </xsl:message>
        
        <!--
            Any cpf relations from whatever sources must end up in $ccpf/eac:identity/eac:cpf_relation.
            
            Historically, CPF roles seem to be limited to $av_correspondedWith and $av_associatedWith. NARA
            has additional role sameAs aka $av_sameAs
            
            Feb 27 2015 Add lcnaf cpfRelation sameAs.
        -->
        <xsl:variable name="cpf_relation">
            <xsl:for-each select="$ccpf/eac:identity/eac:cpf_relation">
                <cpf_relation en_type="{@type}"
                              cpf_arc_role="{$av_associatedWith}"
                              record_id="{eac:naId}"
                              fn_suffix="">
                    <xsl:value-of select="eac:termName"/>
                </cpf_relation>
            </xsl:for-each>

            <!--
                mar 19 2015 Some records like 10609953 have LCNAF, but no importRecordControlNumber. Add a
                test so we don't try to make a cpfRelation for the empty lccn. Also add 10609953 to
                nara_qa_pers.xml.
                
                Basically, remove any whitespace from the NARA importRecordControNumber to get an LoC lccn.

                Heaven only knows the proper way to find the chart below. I stumbled across it by entering an invalid URL:

                http://lccn.loc.gov/n89001639
                
                | If you are looking for ...        | Enter the LCCN as ...                                              |
                | LCCN n 79-18774                   | n79018774                                                          |
                | LCCN n 86140996                   | n86140996                                                          |
                | LCCN sh 85-26371                  | sh85026371                                                         |
                | (1-3 character alphabetic prefix) | - Omit spaces and hyphens.                                         |
                | (assigned before 1/1/2001)        | - Make sure your LCCN is 9-11 characters long:                     |
                |                                   | Four numbers (representing a year) followed by six serial numbers. |
                |                                   | Add leading zeros if there are fewer than six serial numbers.      |
                | LCCN n 2011033569                 | n2011033569                                                        |
                | LCCN no2007000685                 | no2007000685                                                       |
                | LCCN sh2006006990                 | sh2006006990                                                       |
                | LCCN gf2011026169                 | gf2011026169                                                       |
                | (1-2 character alphabetic prefix) | - Omit spaces and hyphens.                                         |
                | (assigned after 12/31/2000)       | - Make sure your LCCN is 11-12 characters long:                    |
                |                                   | Four numbers (representing a year) followed by six serial numbers. |
                |                                   | Add leading zeros if there are fewer than six serial numbers.      |
            -->
            <xsl:if test="$ccpf/eac:identity/eac:recordSource= 'LCNAF' and
                          normalize-space($ccpf/eac:identity/eac:importRecordControlNumber) != ''">
                <xsl:variable name="lccn"
                              select="replace($ccpf/eac:identity/eac:importRecordControlNumber, ' ', '')"/>
                <cpf_relation en_type="{$ccpf/eac:identity/@type}"
                              cpf_arc_role="{$av_sameAs}"
                              record_id="{$lccn}"
                              fn_suffix=""
                              href="{concat('http://id.loc.gov/authorities/names/', $lccn)}">
                    <xsl:value-of select="$ccpf/eac:identity/eac:termName"/>
                </cpf_relation>
                <xsl:message>
                    <xsl:text>LCNAF: creating sameAs cpfRelation </xsl:text>
                    <xsl:value-of select="concat('http://id.loc.gov/authorities/names/', $lccn)"/>
                </xsl:message>
            </xsl:if>
            
            <!--
                Feb 27 2015 We will not be creating cpf for records with totalDescriptionLinkCount = 0, 
                so this code should always run.
                
                Create the self sameAs cpfRelation to NARA's authority record, when one exists.  Only use the
                first (occurance of the?) name if there are multiple names. To have multiples here, there
                would have to be multiple <identitiy> elements, which should be impossible since by being
                inside for-each $multipass we are inside a for-each select="identity".
            -->
            
            <xsl:if test="$ccpf/eac:identity/eac:totalDescriptionLinkCount > 0">
                <cpf_relation en_type="{$ccpf/eac:identity/@type}"
                              cpf_arc_role="{$av_sameAs}"
                              record_id="{$record_id}"
                              fn_suffix=""
                              href="{concat('https://catalog.archives.gov/id/', $record_id)}">
                    <xsl:value-of select="$normative_name/eac:e_name/eac:name_entry[1]/eac:part"/>
                </cpf_relation>
                <xsl:message>
                    <xsl:text>have totalDescriptionLinkCount: creating sameAs cpfRelation </xsl:text>
                    <xsl:value-of select="concat('https://catalog.archives.gov/id/', $record_id)"/>
                </xsl:message>
            </xsl:if>
        </xsl:variable>
        
        
        <!-- 
             New params to tpt_body are in a variable param_data, which is easier to update than the
             historical, and very, very long list of with-param values that you see in the call to tpt_body
             below. In hindsight, I should have used the param_data variable as soon as I reached half
             a dozen with-param values. The code could be refactored, but now there are 3 or 4 front
             ends using tpt_body, and all would have to be refactored, tested, etc.
             
             use_rrel invented for Smithsonian data and has been used for everything since then.
             
             Feb 2 2015 New code expects <cpf_record_id> as well.
             
             Feb 5 2015 Switch over to using multi e_name/name_entry first used by British Library. It
             generalizes both single and multi-name identities.
        -->
        <xsl:variable name="param_data" xmlns="urn:isbn:1-931666-33-4">
            <cpf_record_id>
                <xsl:value-of select="$record_id"/>
            </cpf_record_id>
            <use_cpf_rel as="xs:boolean" select="true()"/>
            <xsl:copy-of select="$cpf_relation"/>
            <use_rrel as="xs:boolean">
                <xsl:value-of select="true()"/>
            </use_rrel>
            <xsl:variable name="ead_fn" select="eac:file_name"/>
            <xsl:copy-of select="$normative_name"/>
            <!--
                Create resourceRelation internally known as rrel.
                
                There are 4 types of archivalDescriptions, and they are the same for person and org:
                
                archivalDescriptionsContributorArray/descriptionReferenceArray
                archivalDescriptionsCreatorArray/descriptionReferenceArray
                archivalDescriptionsDonorArray/descriptionReferenceArray
                archivalDescriptionsReferencesArray/descriptionReferenceArray
            -->

            <xsl:for-each select="$ccpf/eac:identity/eac:archivalDescriptions">
                <xsl:variable name="link_base" select="$rr_xlink_href"/>
                <xsl:variable name="link_text" select="eac:title"/>
                <xsl:variable name="link_href" select="concat($rr_xlink_href, '/', eac:naId)"/>
                <xsl:message>
                    <xsl:text>linktext: </xsl:text>
                    <xsl:value-of select="$link_text"/>
                    <xsl:value-of select="$cr"/>
                    <xsl:text>href: </xsl:text>
                    <xsl:value-of select="$link_href"/>
                </xsl:message>
                <rrel>
                    <rrel_arc_role><xsl:value-of select="@type"/></rrel_arc_role>
                    <rr_xlink_role><xsl:value-of select="$rr_xlink_role"/></rr_xlink_role>
                    <rr_xlink_href>
                        <xsl:value-of select="$link_href"/>
                    </rr_xlink_href>
                    <!--
                        This isn't too clear. In the old days the "resource" was the original document,
                        and thus controlfield_001, but with NARA the referenced document has its own naId.
                    -->
                    <controlfield_001><xsl:value-of select="eac:naId"/></controlfield_001>
                    <rel_entry><xsl:value-of select="$link_text"/></rel_entry>
                    <nara-special>What object xml wrap original data do we want to capture?</nara-special>
                </rrel>
            </xsl:for-each>
            <inc_orig>
                <xsl:copy-of select="$inc_orig" />
            </inc_orig>
            <xsl:copy-of select="'$tc_data/eac:agency_info'"/>
            <snac_info>
                <agencyName>SNAC: Social Networks and Archival Context Project</agencyName>
            </snac_info>
            <citation>
                <xsl:text>From the description of </xsl:text>
                <xsl:value-of select="$ccpf/eac:identity/eac:termName"/>
                <xsl:text> (</xsl:text>
                <xsl:value-of select="$agency_info/eac:agencyName"/>
                <xsl:value-of select="concat('). naId: ', $record_id)"/>
            </citation>
            <ev_desc>
                <xsl:value-of select="$ev_desc"/>
            </ev_desc>
            <rules>
                <xsl:value-of select="$rules"/>
            </rules>
            <rr_xlink_role>
                <xsl:value-of select="$rr_xlink_role"/>
            </rr_xlink_role>
            <av_Leader06>
                <xsl:value-of select="''"/>
            </av_Leader06>
            <av_Leader07>
                <xsl:value-of select="''"/>
            </av_Leader07>
            <av_Leader08>
                <xsl:value-of select="''"/>
            </av_Leader08>
            <!--
                This sends over the current eac:container wrapper element, which has all kinds of info about
                the current entity. Currently it is used for occupation and function.
            -->
            <xsl:copy-of select="."/>
        </xsl:variable> <!-- end of param_data -->
        
        <!-- 
             There are no .c or .r files from NARA. Everything is a .c, so don't put it in the file
             name. We don't use .c with British Library or Henry since those are all .c as well.
        -->
        <xsl:variable name="file_name">
            <xsl:value-of select="concat($chunk_dir, '/', $record_id, '.xml')"/>
        </xsl:variable>

        <xsl:variable name="is_c_flag" as="xs:boolean" select="true()">
            <!-- <xsl:value-of select="eac:e_name/@fn_suffix = 'c'"/> -->
        </xsl:variable>
        
        <xsl:variable name="is_r_flag" as="xs:boolean" select="false()">
            <!-- <xsl:value-of select="substring(eac:e_name/@fn_suffix, 1, 1) = 'r'"/> -->
        </xsl:variable>

        <!-- 
             NARA is all English. Make that explicit.
        -->
        <xsl:variable name="lang_decl">
            <languageDeclaration>
                <language languageCode="eng">eng</language>
                <script scriptCode="Latn">Latin Alphabet</script>
            </languageDeclaration>
        </xsl:variable>

        <xsl:variable name="language">
            <languageUsed>
                <language languageCode="eng">eng</language>
                <script scriptCode="Latn">Latin Alphabet</script>
            </languageUsed>
        </xsl:variable>

        <xsl:variable name="geographic_subject"/>

        <!-- There is already a cpf_relation variable above. -->
        <!-- <xsl:variable name="cpf_relation"/> -->

        <!--
            Note: the context is a <container> node set. <container><e_name>...</e_name><existDates>...</existDates></container>
        -->
        <xsl:message>
            <xsl:text>outfile: </xsl:text>
            <xsl:value-of select="$file_name"/>
        </xsl:message>

        <xsl:result-document href="{$file_name}" format="xml" >
            <xsl:call-template name="tpt_body">
                <xsl:with-param name="exist_dates" select="$exist_dates" as="node()*" />
                <xsl:with-param name="entity_type" select="$etype/eac:value[@cpf = $ccpf/eac:identity/@type]" />
                <xsl:with-param name="entity_name" select="$entity_name"/> <!-- empty, see $normative_name in $param_data -->
                <xsl:with-param name="leader06" select="''"/> <!-- leader is MARC only -->
                <xsl:with-param name="leader07" select="''"/> <!-- leader is MARC only -->
                <xsl:with-param name="leader08" select="''"/> <!-- leader is MARC only -->
                <xsl:with-param name="mods" select="''"/> <!-- Not used. Put mods or object_xml into rrel -->
                <xsl:with-param name="rel_entry" select="''"/> <!-- Not used. See rrel. -->
                <xsl:with-param name="wcrr_arc_role" select="'$arc_role'"/>
                <xsl:with-param name="controlfield_001" select="$record_id"/>
                <xsl:with-param name="is_c_flag" select="$is_c_flag"/>
                <xsl:with-param name="is_r_flag" select="$is_r_flag"/>
                <xsl:with-param name="fn_suffix" select="eac:e_name/@fn_suffix" />
                <xsl:with-param name="cpf_relation" select="$cpf_relation" />
                <xsl:with-param name="record_id" select="$record_id" />
                <xsl:with-param name="date" select="$date" />
                <xsl:with-param name="xslt_vendor" select="$xslt_vendor"/>
                <xsl:with-param name="xslt_version" select="$xslt_version"/>
                <xsl:with-param name="xslt_vendor_url" select="$xslt_vendor_url"/>
                <xsl:with-param name="tag_545" select="$tag_545"/>
                <xsl:with-param name="tag_245" select="normalize-space('$tag_245')"/>
                <xsl:with-param name="xslt_script" select="$xslt_script"/>
                <xsl:with-param name="original" select="$original"/> <!-- aka source -->
                <xsl:with-param name="lang_decl" select="$lang_decl"/>
                <xsl:with-param name="topical_subject" select="''"/>
                <xsl:with-param name="geographic_subject" select="$geographic_subject"/>
                <xsl:with-param name="language" select="$language"/>
                <xsl:with-param name="param_data" select="$param_data" />
            </xsl:call-template>
        </xsl:result-document>
    </xsl:template>

    <!--
        Create a name-path that doesn't include the top 2 or 3 levels. Used for information/debugging. The
        'real' paths are determined by elements within $ccpf.

        I don't see any reason to create a new namespace just for functions. So, I'm using the eac
        namespace. Works fine.
        
        jan 21 2015 Bug in matching '.*person/ which matched seeAlsoArray/person and thus naId was a path for
        two records.  The nested replace() is a bit odd to read, but perhaps more legible and more reliable
        than an alternation regex.
        
        jan 23 2015 In order to create paths / for debugging, and _ for element names, npath() now takes arg
        $sep. This makes the two replace() regexps exciting since they need to be built via concat().  It may
        look odd, but is simple, especially since it saves doing the same thing with variables, and more
        verbose. Or with a choose statement.

    -->
    <xsl:function name="eac:npath">
        <xsl:param name="arg"/>
        <xsl:param name="sep"/>
        <xsl:variable name="mpath">
            <xsl:for-each select="$arg">
                <!--
                    Start with ancestor-or-self, which goes all the way back to root. Trim off the parts we don't want.
                    
                    Other code that only needs the current node name uses name() or self::name(). 

                    <xsl:value-of select="self::*/name()" separator="{$sep}"/>
                -->
                <xsl:value-of select="ancestor-or-self::*/name()" separator="{$sep}"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="replace(
                              replace($mpath, concat('XMLExport', $sep, '(person|organization)', $sep), ''),
                              concat('XMLExport', $sep, 'das_items', $sep, '(person|organization)', $sep), '')"/>
    </xsl:function>

    <!--
        Assume we have been passed <eac:entity_name> or similar as document node, containing <fromDate> and
        <toDate>.

        Create a date field (df) aka date string that lib:edate_core() can parse into a standard date.  Seems
        like a lot of trouble, indirect, and perhaps not robust.
        
        The only reason we have var $temp is for logging.
        
        nnnn-?nnnn incorrectly parses as nnnn?-nnnn due to tokenizing rules. Do not generate dates with
        preceding the date. Note the question vars have a leading space. The circa vars have a trailing space.
    -->
    <xsl:function name="eac:ed">
        <xsl:param name="arg"/>

        <xsl:variable name="from_circa">
            <xsl:value-of
                select="normalize-space(concat($arg/eac:fromDate/eac:dateQualifier/eac:termName[text()='ca.'], ' '))"/>
        </xsl:variable>

        <xsl:variable name="from_question">
            <xsl:value-of
                select="normalize-space(concat(' ', $arg/eac:fromDate/eac:dateQualifier/eac:termName[text()='?']))"/>
        </xsl:variable>
        
        <xsl:variable name="to_circa">
            <xsl:value-of
                select="normalize-space(concat($arg/eac:toDate/eac:dateQualifier/eac:termName[text()='ca.'], ' '))"/>
        </xsl:variable>

        <xsl:variable name="to_question">
            <xsl:value-of
                select="normalize-space(concat(' ', $arg/eac:toDate/eac:dateQualifier/eac:termName[text()='?']))"/>
        </xsl:variable>

        <xsl:variable name="temp">
            <xsl:choose>
                <xsl:when test="$arg/eac:fromDate/eac:year or $arg/eac:toDate/eac:year">
                    <xsl:value-of select="concat(
                                          $from_circa,
                                          $arg/eac:fromDate/eac:year,
                                          $from_question,
                                          '-', 
                                          $to_circa,
                                          $arg/eac:toDate/eac:year,
                                          $to_question)"/>
                </xsl:when>
                <xsl:otherwise>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$temp"/>
    </xsl:function>
    
    <!--                     
         Jan 23 2015 It seems very wrong to simply remove / from every field. If necessary to
         clean, add specific cases where this cleaning will be done.
         
         Jan 27 2015 Create a specific name cleaner. Always normalize-space(). The /nnnn dates need
         work. Nothing else odd yet.
         
         Feb 2 2015 Don't break 1891 - 12/1/1905 
         less nara_cpf/12019905.xml
         
         <termName>Adams, Donald B., /1890-/1973</termName>
         less nara_cpf/10601028.xml
         
         Mar 2 2015 Remove trailing . if preceding character is not uppercase [A-Z].
         <termName>Hopkins, Sarah Winnemucca, 1844?-1891.</termName>
         less nara_cpf/10568259.xml
         <part>Hopkins, Sarah Winnemucca, 1844?-1891</part>
    -->
    <xsl:function name="eac:name_cleaner">
        <xsl:param name="arg"/>
        <xsl:value-of select="replace(
                              normalize-space(
                              replace(
                              replace($arg, '-/(\d+)', '-$1'),
                              '\s+/(\d+)', ' $1')),
                              '([^A-Z])\.$', '$1')"/>
    </xsl:function>

    <xsl:function name="eac:person_ccpf">
        <xsl:param name="arg"/>
        
        <xsl:variable name="is_max">
            <xsl:value-of select="true()"/>
        </xsl:variable>

        <identity type="{$pers_val}" is_max="{$is_max}" xmlns="urn:isbn:1-931666-33-4">
            <!--
                Feb 16 2015 Rename the internal element from <person> to <identity> because it is used for
                both person and organization.

                Feb 12 2015 As of today, multiple names from organizationName are in separate <identity>
                records, not in <entity_name> inside <indentity>. So, the comment is old, and retained only for
                historical perspective.
                
                Old: Our normative record might have multiple names (as with orgs) so all records have
                <entity_name>, although person will ever only have a single entry. Yes, here name and naId are
                used in both places (outer and inner).
            -->
            <xsl:apply-templates select="$arg/biographicalNote" mode="norm"/>
            <xsl:apply-templates select="$arg/importRecordControlNumber" mode="norm"/>
            <xsl:apply-templates select="$arg/recordSource" mode="norm"/>
            <xsl:apply-templates select="$arg/name" mode="norm"/>
            <xsl:apply-templates select="$arg/naId" mode="norm"/>
            <fromDate>
                <xsl:apply-templates select="$arg/birthDate/day" mode="norm"/>
                <xsl:apply-templates select="$arg/birthDate/month" mode="norm"/>
                <xsl:apply-templates select="$arg/birthDate/year" mode="norm"/>
                <xsl:apply-templates select="$arg/birthDate/logicalDate" mode="norm"/>
                <xsl:apply-templates select="$arg/birthDate/dateQualifier" mode="norm"/>
                <dateQualifier>
                    <xsl:apply-templates select="$arg/birthDate/dateQualifier" mode="id_and_term"/>
                </dateQualifier>
            </fromDate>
            <toDate>
                <xsl:apply-templates select="$arg/deathDate/year" mode="norm"/>
                <xsl:apply-templates select="$arg/deathDate/logicalDate" mode="norm"/>
                <xsl:apply-templates select="$arg/deathDate/dateQualifier" mode="norm"/>
                <dateQualifier>
                    <xsl:apply-templates select="$arg/deathDate/dateQualifier" mode="id_and_term"/>
                </dateQualifier>
            </toDate>
            <xsl:apply-templates select="$arg/personalTitle" mode="norm"/>
            <xsl:apply-templates select="$arg/roles/isContributor" mode="norm"/>
            <xsl:apply-templates select="$arg/roles/isCreator" mode="norm"/>
            <xsl:apply-templates select="$arg/roles/isDonor" mode="norm"/>
            <xsl:apply-templates select="$arg/roles/isReference" mode="norm"/>
            <xsl:apply-templates select="$arg/isPreferred" mode="norm"/>
            <xsl:apply-templates select="$arg/isReference" mode="norm"/>
            <xsl:apply-templates select="$arg/termName" mode="norm"/>
            <contributorTypeArray>
                <xsl:apply-templates select="$arg/contributorTypeArray/contributorType/naId" mode="norm"/>
                <xsl:apply-templates select="$arg/contributorTypeArray/contributorType/termName" mode="norm"/>
            </contributorTypeArray>
            <creatorTypeArray>
                <xsl:apply-templates select="$arg/creatorTypeArray/creatorType/naId" mode="norm"/>
                <xsl:apply-templates select="$arg/creatorTypeArray/creatorType/termName" mode="norm"/>
            </creatorTypeArray>
            <xsl:apply-templates select="$arg/linkCounts/geographicPlaceAuthorityLinkCount" mode="norm"/>
            <xsl:apply-templates select="$arg/linkCounts/jurisdictionLinkCount" mode="norm"/>
            <xsl:apply-templates select="$arg/linkCounts/organizationAuthorityLinkCount" mode="norm"/>
            <xsl:apply-templates select="$arg/linkCounts/organizationNameAuthorityLinkCount" mode="norm"/>
            <xsl:apply-templates select="$arg/linkCounts/personAuthorityLinkCount" mode="norm"/>
            <xsl:apply-templates select="$arg/linkCounts/programAreaAuthorityLinkCount" mode="norm"/>
            <xsl:apply-templates select="$arg/linkCounts/subjectLinkCount" mode="norm"/>
            <xsl:apply-templates select="$arg/linkCounts/topicalSubjectAuthorityLinkCount" mode="norm"/>
            <xsl:apply-templates select="$arg/linkCounts/totalDescriptionLinkCount" mode="norm"/>
            <xsl:apply-templates select="$arg/nonPreferredHeadingArray" mode="alt"/>

            <xsl:apply-templates select="$arg/archivalDescriptionsContributorArray/descriptionReferenceArray" mode="ref_array"/>
            <xsl:apply-templates select="$arg/archivalDescriptionsCreatorArray/descriptionReferenceArray" mode="ref_array"/>
            <xsl:apply-templates select="$arg/archivalDescriptionsDonorArray/descriptionReferenceArray" mode="ref_array"/>
            <xsl:apply-templates select="$arg/archivalDescriptionsReferencesArray/descriptionReferenceArray" mode="ref_array"/>
            <!--
                mar 19 2015 Due to issues with org records, we will not generate cpfRelations for org references.
            -->
            <!-- <xsl:apply-templates select="$arg/organizationalReferenceArray" mode="org_array"/> -->
            <xsl:if test="$arg/organizationalReferenceArray/organization">
                <xsl:message>
                    <xsl:value-of select="concat('Skipping organizationReferenceArray ora:', $cr)"/>
                    <xsl:apply-templates select="$arg/organizationalReferenceArray" mode="pretty"/>
                    <xsl:value-of select="$cr"/>
                </xsl:message>
            </xsl:if>
            <seeAlsoArray>
                <!--
                    This is a bit odd. We don't use this mode much, but it seems generalized, so go with it
                    here, even though the internals are very different from variantNameArray below. Both have
                    similar purpose, and it seems to me, that ideally their internal representation would be
                    the same.
                -->
                <xsl:apply-templates select="$arg/seeAlsoArray/person" mode="id_and_term"/>
            </seeAlsoArray>
            <variantNameArray>
                <xsl:for-each select="$arg/nonPreferredHeadingArray/variantPersonName/termName">
                    <xsl:apply-templates select="." mode="norm"/>
                </xsl:for-each>
            </variantNameArray>
        </identity>
    </xsl:function> <!-- end of eac:person_ccpf() -->

    <xsl:function name="eac:org_ccpf">
        <xsl:param name="arg"/>
        <!--
            Feb 16 2015 Rename the internal element from <person> to <identity> because it is used for both
            person and organization.
            
            We have a variable and corresponding element inside <identity> that captures <organization> data
            relevant to all <organizationName> elements. Each <organizationName> will have a separate
            <identity> and each <identity> results in a distinct cpf xml file.

            Feb 12 2015 Create a separate <identity type="corp" for each organzationName.
        -->
        
        <xsl:variable name="org_info">
            <org_info xmlns="urn:isbn:1-931666-33-4">
                <xsl:apply-templates select="$arg/administrativeHistoryNote" mode="norm"/>
                <jurisdictionArray>
                    <xsl:apply-templates select="$arg/jurisdictionArray/geographicPlaceName" mode="id_and_term"/>
                </jurisdictionArray>
                <xsl:apply-templates select="$arg/linkCounts/geographicPlaceAuthorityLinkCount" mode="norm"/>
                <xsl:apply-templates select="$arg/linkCounts/jurisdictionLinkCount" mode="norm"/>
                <xsl:apply-templates select="$arg/linkCounts/organizationAuthorityLinkCount" mode="norm"/>
                <xsl:apply-templates select="$arg/linkCounts/organizationNameAuthorityLinkCount" mode="norm"/>
                <xsl:apply-templates select="$arg/linkCounts/personAuthorityLinkCount" mode="norm"/>
                <xsl:apply-templates select="$arg/linkCounts/programAreaAuthorityLinkCount" mode="norm"/>
                <xsl:apply-templates select="$arg/linkCounts/subjectLinkCount" mode="norm"/>
                <xsl:apply-templates select="$arg/linkCounts/topicalSubjectAuthorityLinkCount" mode="norm"/>
                <xsl:apply-templates select="$arg/linkCounts/totalDescriptionLinkCount" mode="norm"/>
                <!--
                    Orgs don't have a name in the main record, just naId. We're creating CPF and thus we need a canonical
                    name to go with that naId, therefore we use the most recently dated name based on max(abolishDate).
                -->
                <xsl:apply-templates select="$arg/naId" mode="norm"/>
                <xsl:apply-templates select="$arg/personalReferenceArray" mode="org_array"/>

                <programAreaArray>
                    <xsl:apply-templates select="$arg/programAreaArray/programArea" mode="id_and_term"/>
                </programAreaArray>
                
                <!--
                    Feb 12 2015 Now that each organzationName is a separate CPF, move these main descriptions
                    (if any main descriptions exist) somewhere logical. This location (inside <org_info>) is
                    not logical.

                    Orgs are known by one or more names, and the archival descriptions are attached to the
                    organizationName elements, not the main record. We will attribute anything done by an organizationName
                    to the main org. This generates resourceRelation.
                -->
                <xsl:apply-templates select="$arg//archivalDescriptionsContributorArray/descriptionReferenceArray" mode="ref_array"/>
                <xsl:apply-templates select="$arg//archivalDescriptionsCreatorArray/descriptionReferenceArray" mode="ref_array"/>
                <xsl:apply-templates select="$arg//archivalDescriptionsDonorArray/descriptionReferenceArray" mode="ref_array"/>
                <xsl:apply-templates select="$arg//archivalDescriptionsReferencesArray/descriptionReferenceArray" mode="ref_array"/>
            </org_info>
        </xsl:variable>

        <xsl:for-each select="$arg/organizationNameArray/organizationName">
            <xsl:variable name="is_max">
                <xsl:choose>
                    <xsl:when test="./abolishDate/year=max($arg/organizationNameArray/organizationName/abolishDate/year)">
                        <xsl:value-of select="true()"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="false()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <identity type="{$corp_val}" is_max="{$is_max}" xmlns="urn:isbn:1-931666-33-4">
                <xsl:copy-of select="$org_info"/>
                <xsl:apply-templates select=".." mode="org_cpfrels">
                    <xsl:with-param name="self_naId" select="naId"/>
                </xsl:apply-templates>
                <toDate>
                    <dateQualfier>
                        <xsl:apply-templates select="./abolishDate/dateQualifier" mode="id_and_term"/>
                    </dateQualfier>
                    <xsl:apply-templates select="./abolishDate/day" mode="norm"/>
                    <xsl:apply-templates select="./abolishDate/logicalDate" mode="norm"/>
                    <xsl:apply-templates select="./abolishDate/month" mode="norm"/>
                    <xsl:apply-templates select="./abolishDate/year" mode="norm"/>
                </toDate>
                <!--
                    We might want to create different roles based on contributor type and creator type. 
                -->
                <contributorTypeArray>
                    <xsl:apply-templates select="./contributorTypeArray/contributorType" mode="id_and_term"/>
                </contributorTypeArray>
                <creatorTypeArray>
                    <xsl:apply-templates select="./contributorTypeArray/contributorType" mode="id_and_term"/>
                </creatorTypeArray>
                <fromDate>
                    <dateQualfier>
                        <xsl:apply-templates select="./establishDate/dateQualifier" mode="id_and_term"/>
                    </dateQualfier>
                    <xsl:apply-templates select="./establishDate/day" mode="norm"/>
                    <xsl:apply-templates select="./establishDate/logicalDate" mode="norm"/>
                    <xsl:apply-templates select="./establishDate/month" mode="norm"/>
                    <xsl:apply-templates select="./establishDate/year" mode="norm"/>
                </fromDate>
                <xsl:apply-templates select="./importRecordControlNumber" mode="norm"/>
                <xsl:apply-templates select="./isPreferred" mode="norm"/>
                <xsl:apply-templates select="./isReference" mode="norm"/>
                <xsl:apply-templates select="./linkCounts/approvedDescriptionLinkCount" mode="norm"/>
                <xsl:apply-templates select="./linkCounts/contributorLinkCount" mode="norm"/>
                <xsl:apply-templates select="./linkCounts/creatorLinkCount" mode="norm"/>
                <xsl:apply-templates select="./linkCounts/donorLinkCount" mode="norm"/>
                <xsl:apply-templates select="./linkCounts/geographicPlaceAuthorityLinkCount" mode="norm"/>
                <xsl:apply-templates select="./linkCounts/jurisdictionLinkCount" mode="norm"/>
                <xsl:apply-templates select="./linkCounts/organizationAuthorityLinkCount" mode="norm"/>
                <xsl:apply-templates select="./linkCounts/organizationNameAuthorityLinkCount" mode="norm"/>
                <xsl:apply-templates select="./linkCounts/personAuthorityLinkCount" mode="norm"/>
                <xsl:apply-templates select="./linkCounts/programAreaAuthorityLinkCount" mode="norm"/>
                <xsl:apply-templates select="./linkCounts/specificRecordTypeAuthorityLinkCount" mode="norm"/>
                <xsl:apply-templates select="./linkCounts/subjectLinkCount" mode="norm"/>
                <xsl:apply-templates select="./linkCounts/topicalSubjectAuthorityLinkCount" mode="norm"/>
                <xsl:apply-templates select="./linkCounts/totalDescriptionLinkCount" mode="norm"/>
                <xsl:apply-templates select="./naId" mode="norm"/>
                <xsl:apply-templates select="./name" mode="norm"/>
                <predecessorArray>
                    <xsl:apply-templates select="./predecessorArray/organizationName" mode="id_and_term"/>
                </predecessorArray>
                <xsl:apply-templates select="./recordSource" mode="norm"/>
                <xsl:apply-templates select="./roles/isContributor" mode="norm"/>
                <xsl:apply-templates select="./roles/isCreator" mode="norm"/>
                <xsl:apply-templates select="./roles/isDonor" mode="norm"/>
                <xsl:apply-templates select="./roles/isReference" mode="norm"/>
                <successorArray>
                    <xsl:apply-templates select="./successorArray/organizationName" mode="id_and_term"/>
                </successorArray>
                <xsl:apply-templates select="./termName" mode="norm"/>
                <variantNameArray>
                    <!-- This isn't quite right. Child element needs to be <termName> to follow the person convention. -->
                    <xsl:apply-templates select="./variantNameArray/variantOrganizationName" mode="norm"/>
                </variantNameArray>
                <xsl:apply-templates select=".//archivalDescriptionsContributorArray/descriptionReferenceArray" mode="ref_array"/>
                <xsl:apply-templates select=".//archivalDescriptionsCreatorArray/descriptionReferenceArray" mode="ref_array"/>
                <xsl:apply-templates select=".//archivalDescriptionsDonorArray/descriptionReferenceArray" mode="ref_array"/>
                <xsl:apply-templates select=".//archivalDescriptionsReferencesArray/descriptionReferenceArray" mode="ref_array"/>
            </identity>
        </xsl:for-each>
    </xsl:function> <!-- end of eac:org_ccpf() -->

    <!--
        Use termName, but clean it, carefully. If you want to create the cpf name from components, see
        eac:e_name_element_create() below.

        a_form is either: $av_authorizedForm, $av_alternativeForm
        
        Add alternate names here as well.
    -->
    <xsl:function name="eac:e_name_element" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="ccpf"/>

        <xsl:variable name="type" select="$ccpf/eac:identity/@type"/>

        <e_name>
            <xsl:for-each select="$ccpf/eac:identity">
                <name_entry en_lang="en-Latn"
                            a_form="{$av_authorizedForm}">
                    <part>
                        <xsl:value-of select="eac:name_cleaner(eac:termName)"/>
                    </part>
                </name_entry>
                
                <xsl:for-each select="eac:variantNameArray/eac:termName">
                    <name_entry en_lang="en-Latn"
                                a_form="{$av_alternativeForm}">
                        <part>
                            <xsl:value-of select="."/>
                        </part>
                    </name_entry>
                </xsl:for-each>
                
                <!--
                    mar 19 2015 Bug with an empty <person> no termName created an empty <part> in the
                    CPF. Don't process empty elements.
                -->
                
                <xsl:for-each select="eac:seeAlsoArray/eac:element[eac:termName != '']">
                    <name_entry en_lang="en-Latn"
                                a_form="{$av_alternativeForm}">
                        <part>
                            <xsl:value-of select="eac:termName"/>
                        </part>
                    </name_entry>
                </xsl:for-each>

            </xsl:for-each>
        </e_name>
    </xsl:function>


    <!-- 
         This version of the function creates the name from individual fields, but does not use
         fullerFormOfName. There are historical precedents.
    -->
    <xsl:function name="eac:e_name_element_create" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="ccpf"/>

        <xsl:variable name="type" select="$ccpf/eac:identity/@type"/>

        <e_name>
            <xsl:for-each select="$ccpf/eac:identity">
                <xsl:variable name="exist_dates">
                    <existDates>
                        <!--
                            Note: the type arg of eac:exist_dates() is assumed to *only* control 'active' for
                            corporateBody the date. Since the date generated here is used in the name string,
                            we do *not* want 'active' for corporateBody date strings. So, we are intentionally
                            sending $pers_val instead of $type.
                            
                            This is better than using replace() to remove '\s*active\*' since we cannot be
                            certain in what contexts '\s*active\*' will appear and we have had bugs on several
                            occasions resulting from inappropriate name cleaning.
                        -->
                        <xsl:copy-of select="eac:exist_dates(eac:ed(.), $pers_val)"/>
                    </existDates>
                </xsl:variable>
                <xsl:variable name="this_name" select="eac:name_entry_part_builder(. , $exist_dates)"/>
                <xsl:message>
                    <xsl:text>e_naid: </xsl:text>
                    <xsl:value-of select="eac:naId"/>
                    <xsl:text> e_name: </xsl:text>
                    <xsl:value-of select="$this_name"/>
                </xsl:message>
                <name_entry en_lang="en-Latn"
                            a_form="{$av_authorizedForm}">
                    <part>
                        <xsl:value-of select="$this_name"/>
                    </part>
                </name_entry>
                
                <xsl:for-each select="eac:variantNameArray/eac:termName">
                    <name_entry en_lang="en-Latn"
                                a_form="{$av_alternativeForm}">
                        <part>
                            <xsl:value-of select="."/>
                        </part>
                    </name_entry>
                </xsl:for-each>

                <xsl:for-each select="eac:seeAlsoArray/eac:element">
                    <name_entry en_lang="en-Latn"
                                a_form="{$av_alternativeForm}">
                        <part>
                            <xsl:value-of select="eac:termName"/>
                        </part>
                    </name_entry>
                </xsl:for-each>
                
            </xsl:for-each>
        </e_name>
    </xsl:function>

    <!--
        Build a name string "name, date" or lacking date simply "name".
    -->
    <xsl:function name="eac:name_entry_part_builder">
        <xsl:param name="this_entity"/>
        <xsl:param name="exist_dates"/>
        <xsl:choose>
            <xsl:when test=" $exist_dates//eac:fromDate or $exist_dates//eac:toDate">
                <xsl:value-of
                    select="replace(
                            normalize-space(
                            concat(
                            $this_entity/eac:name,
                            ', ',
                            $exist_dates//eac:fromDate[@standardDate=min(@standardDate)],
                            '-',
                            $exist_dates//eac:toDate[@standardDate=max(@standardDate)])),
                            ',,', ',')"/>
            </xsl:when>
            <xsl:when test="$exist_dates//date and count($exist_dates//date) = 1">
                <xsl:value-of
                    select="replace(
                            normalize-space(
                            concat(
                            $this_entity/eac:name, ' (', $exist_dates//eac:date, ')')),
                            ',,', ',')"/>
            </xsl:when>
            <xsl:when test="$exist_dates//date and count($exist_dates//date) > 1">
                <xsl:message>
                    <xsl:text>Warning: multi-date dateset</xsl:text>
                </xsl:message>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$this_entity/eac:name"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="eac:exist_dates">
        <xsl:param name="date_string"/>
        <xsl:param name="entity_type"/>

        <!-- <xsl:message> -->
        <!--     <xsl:text>edtype: </xsl:text> -->
        <!--     <xsl:value-of select="$entity_type"/> -->
        <!-- </xsl:message> -->

        <!--
            Can't call lib:edate_core() because it expects a marc data field in the df arg. So, we need to do
            the DAS equivalent ourselves.
        -->
        <xsl:variable name="tokens">
            <xsl:call-template name="tpt_exist_dates">
                <xsl:with-param name="xx_tag" select="''"/> <!-- not used in tpt_exist_dates -->
                <xsl:with-param name="entity_type" select="$entity_type"/>
                <xsl:with-param name="rec_pos" select="'not_used'"/>
                <xsl:with-param name="subfield_d">
                    <xsl:copy-of select="$date_string"/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:variable>
        <!-- 
             For historical reasons (and perhaps not very good reasons) is_family means is_active. If type not
             person, then dates are active, that is: corporateBody, family have active dates.
        -->
        <xsl:variable name="show_date">
            <xsl:call-template name="tpt_show_date">
                <xsl:with-param name="tokens" select="$tokens"/>
                <xsl:with-param name="is_family" select="$entity_type != $pers_val"/>
                <xsl:with-param name="entity_type" select="$entity_type"/>
                <xsl:with-param name="rec_pos" select="'not_used'"/>
            </xsl:call-template>
        </xsl:variable>
        <!-- <xsl:message> -->
        <!--     <xsl:text>sd: </xsl:text> -->
        <!--     <xsl:apply-templates select="$show_date" mode="pretty"/> -->
        <!-- </xsl:message> -->
        <xsl:copy-of select="$show_date/eac:existDates/*"/>
    </xsl:function>


    <!--
        This seems to be a pretty printer for xsl:message (after being modified with its own mode). Created by
        John Morgan. From http://www.dpawson.co.uk/xsl/sect2/pretty.html
        
        Mar 19 2015 Removed pretty print template here because it is now in lib.xsl (where it belongs).
    -->


</xsl:stylesheet>
