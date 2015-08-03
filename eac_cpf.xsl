<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="2.0"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:eac="urn:isbn:1-931666-33-4"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns="urn:isbn:1-931666-33-4"
                exclude-result-prefixes="#all"
                >
    <!-- 
         Author: Tom Laudeman
         The Institute for Advanced Technology in the Humanities
         
         Copyright 2013 University of Virginia. Licensed under the Educational Community License, Version 2.0
         (the "License"); you may not use this file except in compliance with the License. You may obtain a
         copy of the License at
         
         http://www.osedu.org/licenses/ECL-2.0
         http://opensource.org/licenses/ECL-2.0         
         
         Unless required by applicable law or agreed to in writing, software distributed under the License is
         distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
         implied. See the License for the specific language governing permissions and limitations under the
         License.
         
         This file is included in oclc_marc2cpf.xsl and called to write files by template tpt_body. In
         general, only the minimum amount of code is here, leaving this file as clean as possible.
         
         exclude-result-prefixes="xs eac xlink"
    -->

    <xsl:template name="tpt_body">
        <xsl:param name="exist_dates"/>
        <xsl:param name="leader06"/>
        <xsl:param name="leader07"/>
        <xsl:param name="leader08"/>
        <xsl:param name="mods"/>
        <xsl:param name="rel_entry"/>
        <xsl:param name="local_affiliation"/>
        <xsl:param name="wcrr_arc_role"/>
        <xsl:param name="controlfield_001"/>
        <xsl:param name="is_r_flag" as="xs:boolean"/>
        <xsl:param name="is_c_flag" as="xs:boolean"/>
        <xsl:param name="fn_suffix"/>
        <xsl:param name="cpf_relation"/>
        <xsl:param name="entity_type"/>
        <xsl:param name="record_id"/>
        <xsl:param name="date"/>
        <xsl:param name="entity_name"/>
        <xsl:param name="xslt_vendor"/>
        <xsl:param name="xslt_version"/>
        <xsl:param name="xslt_vendor_url"/>
        <xsl:param name="tag_545"/>
        <xsl:param name="tag_245"/>
        <xsl:param name="xslt_script"/>
        <xsl:param name="original"/>
        <xsl:param name="lang_decl" />
        <xsl:param name="topical_subject"/>
        <xsl:param name="geographic_subject"/>
        <!-- <xsl:param name="occupation" /> -->
        <xsl:param name="language" />
        <!-- <xsl:param name="function" /> -->
        <xsl:param name="param_data"/>
        
        <xsl:processing-instruction name="oxygen">RNGSchema="http://socialarchive.iath.virginia.edu/shared/cpf.rng" type="xml"</xsl:processing-instruction>
        <xsl:text>&#x0A;</xsl:text>        
        <eac-cpf>
            <control>
                <xsl:choose>
                    <xsl:when test="$param_data/eac:cpf_record_id/text()">
                        <!-- Newer code: BL, NARA -->
                        <recordId><xsl:value-of select="$param_data/eac:cpf_record_id"/></recordId>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- Legacy code: WorldCat, SIA agency, SIA fieldbooks, NYSA -->
                        <recordId><xsl:value-of select="concat($record_id, '.', $fn_suffix)"/></recordId>
                    </xsl:otherwise>
                </xsl:choose>
                <maintenanceStatus>new</maintenanceStatus>
                <maintenanceAgency>
                    <xsl:copy-of select="$param_data/eac:snac_info/*"/>
                </maintenanceAgency>
                <xsl:copy-of select="$lang_decl"/>
                <maintenanceHistory>
                    <maintenanceEvent>
                        <eventType>created</eventType>
                        <eventDateTime standardDateTime="{$date}">
                            <xsl:value-of select="$date"/>
                        </eventDateTime>
                        <agentType>machine</agentType>
                        <agent>
                            <xsl:text>XSLT </xsl:text>
                            <xsl:value-of select="$xslt_script"/>
                            <xsl:text> </xsl:text>
                            <xsl:value-of select="$xslt_vendor"/>
                            <xsl:text> </xsl:text>
                            <xsl:value-of select="$xslt_version"/>
                            <xsl:text> </xsl:text>
                            <xsl:value-of select="$xslt_vendor_url"/>
                        </agent>
                        <eventDescription><xsl:value-of select="$param_data/eac:ev_desc"/></eventDescription>
                    </maintenanceEvent>
                </maintenanceHistory>
                <sources>
                    <source>
                        <xsl:choose>
                            <xsl:when test="$param_data/eac:use_source_href = false()">
                                <!--
                                    NYSA is a MARC-based extraction where the source href doesn't work for the
                                    the MARC records.
                                    
                                    Apr 2 2015 SIA FB Fix. Probably best to have something in the source, but
                                    we don't have a true href, so just go with the record id aka
                                    $controlfield_001.
                                -->
                                <xsl:attribute name="xlink:href"
                                               select="$controlfield_001"/>
                                <xsl:attribute name="xlink:type"
                                               select="'simple'"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:attribute name="xlink:href"
                                               select="concat($param_data/eac:rr_xlink_href, '/', $controlfield_001)"/>
                                <xsl:attribute name="xlink:type"
                                               select="'simple'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        <!--
                            Defaults to true. inc_orig=0 on the command line will make it false. We can't
                            simply test the value because xlst can't grok the truthiness of node values the
                            same way it groks the truthiness of variables.
                        -->
                        <xsl:if test="$param_data/eac:inc_orig = 'true'"> 
                            <objectXMLWrap>
                                <xsl:copy-of select="$original"/>
                            </objectXMLWrap>
                        </xsl:if>
                    </source>
                </sources>
            </control>
            <cpfDescription>
                <identity>
                    <entityType><xsl:value-of select="$entity_type"/></entityType>
                    <!--
                        To maintain backward compatibility, don't rely on a new element in $param_data.
                    -->
                    <xsl:variable name="nameEntry_lang">
                        <xsl:choose>
                            <xsl:when test="$param_data/eac:en_lang/text()">
                                <xsl:value-of select="$param_data/eac:en_lang"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="'en-Latn'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="string-length($entity_name) > 0">
                            <nameEntry xml:lang="{$nameEntry_lang}">
                                <part><xsl:value-of select="$entity_name"/></part>
                                <authorizedForm><xsl:value-of select="$param_data/eac:rules"/></authorizedForm>
                            </nameEntry>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- 
                                 See bl2cpf.xsl for element construction esp. tpt_name_info and $param_data.
                            -->
                            <xsl:for-each select="$param_data/eac:e_name/eac:name_entry">
                                <nameEntry xml:lang="{@en_lang}">
                                    <xsl:if test="@localType">
                                        <xsl:attribute name="localType">
                                            <xsl:value-of select="@localType"/>
                                        </xsl:attribute>
                                    </xsl:if>
                                    <xsl:copy-of select="./*"/>
                                    <!-- authorizedForm or alternateForm -->
                                    <xsl:if test="string-length(@a_form) = 0">
                                        <xsl:message>
                                            <xsl:text>null nameEntry: </xsl:text>
                                            <xsl:copy-of select="."/>
                                            <xsl:text>&#x0A;</xsl:text>
                                        </xsl:message>
                                    </xsl:if>
                                    <xsl:element name="{@a_form}"><xsl:value-of select="$param_data/eac:rules"/></xsl:element>
                                </nameEntry>
                            </xsl:for-each>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:if test="string-length($param_data/eac:descriptiveNote)">
                        <xsl:copy-of select="$param_data/eac:descriptiveNote"/>
                    </xsl:if>
                </identity>
                
                <xsl:if test="$is_c_flag">
                    <description>
                        <!--
                            The existDates were created (in lib.xsl) with the namespace that this file knows
                            as eac. Don't show unparsed dates. Those are hanging around for QA and possibly
                            for some future use.
                        -->
                        <xsl:if test="string-length($exist_dates) > 0 and not($exist_dates[@unparsed])">
                            <xsl:copy-of select="$exist_dates"/>
                        </xsl:if>
                        <!-- 
                             Note that eac:occ and eac:func are /* which means "children of". Don't mess it
                             up.
                        -->
                        <xsl:copy-of select="$param_data/eac:container/eac:occ/*"/>
                        <xsl:copy-of select="$param_data/eac:container/eac:func/*"/>
                        <xsl:copy-of select="$param_data/eac:function"/>

                        <xsl:if test="$is_c_flag">
                            <xsl:copy-of select="$local_affiliation"/>
                            <xsl:copy-of select="$topical_subject"/>
                            <xsl:copy-of select="$geographic_subject"/>
                            <xsl:copy-of select="$language"/>
                            <xsl:if test="$tag_545 != ''">
                                <biogHist>
                                    <xsl:copy-of select="$tag_545"/>
                                    <xsl:copy-of select="$param_data/eac:citation" />
                                </biogHist>
                            </xsl:if>
                        </xsl:if>
                    </description>
                </xsl:if>

                <xsl:if test="$is_r_flag and (string-length($exist_dates) > 0)">
                    <description>
                        <!--
                            The existDates were created (in lib.xsl) with the
                            namespace that this file knows as eac. Don't show
                            unparsed dates. Those are hanging around for QA and
                            possibly for some future use. If $exist_dates is an
                            empty string, don't show the description element.
                        -->
                        <xsl:if test="string-length($exist_dates) > 0 and not($exist_dates[@unparsed])">
                            <xsl:copy-of select="$exist_dates"/>
                        </xsl:if>
                        <xsl:if test="boolean($param_data/eac:container/eac:occ/*) or boolean($param_data/eac:container/eac:func/*)">
                            <xsl:copy-of select="$param_data/eac:container/eac:occ/*"/>
                            <xsl:copy-of select="$param_data/eac:container/eac:func/*"/>
                        </xsl:if>
                    </description>
                </xsl:if>

                <relations>
                    <xsl:choose>
                        <!--
                            New template-ish cpfRelation used by NARA. The classic cpfRelation was XML built
                            elsewhere and just inserted here as an xsl:copy-of the variable.
                            
                            Feb 24 2015 Add a when check for @fn_suffix not an empty string. Don't concat() a
                            dot and nothing. We only want the dot when there's a suffix.
                            
                            jun 23 2015 If @href then must not have descriptiveNote. @href is for external
                            cpfRelations, while descriptiveNote is used exclusively for cpfRelations inside
                            SNAC. sameAs cpfRelations will have @href, and we assume that relation is reliable
                            enough that we won't test xlink:role for $av_sameAs.
                            
                            Use an xsl:choose so we can have an else and create log entries so non-obvious
                            bugs are more obvious. XSL boolean tests are fragile and unreliable, so more
                            logging is better than less logging.
                        -->
                        <xsl:when test="$param_data/eac:use_cpf_rel">
                            <xsl:for-each select="$param_data/eac:cpf_relation">
                                <xsl:variable name="en_type" select="@en_type"/>
                                <cpfRelation xlink:type="simple"
                                             xlink:role="{$etype/eac:value[@key = $en_type]}"
                                             xlink:arcrole="{@cpf_arc_role}">
                                    <xsl:if test="./@href">
                                        <xsl:attribute name="xlink:href" select="./@href"/>
                                    </xsl:if>
                                    <relationEntry><xsl:value-of select="."/></relationEntry>
                                    <xsl:choose>
                                    <xsl:when test="not(./@href)">
                                        <descriptiveNote>
                                            <p>
                                                <span localType="{$av_extractRecordId}">
                                                    <xsl:choose>
                                                        <xsl:when test="string-length(./@fn_suffix) > 0">
                                                            <xsl:value-of select="concat(./@record_id, '.', ./@fn_suffix)"/>
                                                        </xsl:when>
                                                        <xsl:otherwise>
                                                            <xsl:value-of select="./@record_id"/>
                                                        </xsl:otherwise>
                                                    </xsl:choose>
                                                </span>
                                            </p>
                                        </descriptiveNote>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:message>
                                            <xsl:text>warning: (this is usually intentional) no descriptiveNote: due to @href</xsl:text>
                                            <xsl:value-of select="./@href"/>
                                        </xsl:message>
                                    </xsl:otherwise>
                                    </xsl:choose>
                                </cpfRelation>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy-of select="$cpf_relation"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:choose>
                        <xsl:when test="count($param_data/eac:rrel) > 0  or $param_data/eac:use_rrel = true()">
                            <xsl:message>
                                <xsl:text>have use_rrel</xsl:text>
                            </xsl:message>
                            <!--
                                NYSA agency histories (and perhaps SIA agency histories?) could have multiple
                                resourceRelations, so we put a nodeset with all the info into
                                $param_data. rrel also allows us to not include a slash at the end of the
                                rr_xlink_href base URI. Maybe someday another data set will have multiple
                                resourceRelations. In any case, the otherwise clause supports all the legacy
                                XSL script.
                                
                                Fix jul 28 2014 BL (and others?) was getting xlink_role from
                                $param_data/eac:xlink_role, but xlink_role is actually in <rrel> so the actual
                                path is $param_data/eac:rrel/eac:rr_xlink_role.

                                Note: <use_rrel as="xs:boolean">
                            -->
                            <xsl:for-each select="$param_data/eac:rrel">
                                <resourceRelation xlink:arcrole="{eac:rrel_arc_role}"
                                                  xlink:role="{eac:rr_xlink_role}"
                                                  xlink:type="simple"
                                                  xlink:href="{eac:rr_xlink_href}">
                                <relationEntry><xsl:value-of select="eac:rel_entry"/></relationEntry>
                                <xsl:copy-of select="eac:mods/*"/>
                                <xsl:copy-of select="eac:object_xml/*"/>
                                <xsl:if test="string-length(eac:leader06)>0 or
                                              string-length(eac:leader07)>0 or
                                              string-length(eac:leader08)>0">
                                    <descriptiveNote>
			                <p>
				            <span localType="{$param_data/eac:av_Leader06}"><xsl:value-of select="eac:leader06"/></span>
				            <span localType="{$param_data/eac:av_Leader07}"><xsl:value-of select="eac:leader07"/></span>
				            <span localType="{$param_data/eac:av_Leader08}"><xsl:value-of select="eac:leader08"/></span>
			                </p>
			            </descriptiveNote>
                                </xsl:if>
                            </resourceRelation>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                            <!--
                                The classic, legacy single resourceRelation version with the included slash
                                character. Use rrel (above) if you don't want the slash.  
                                
                                jul 21 2015 Note: the classic may still be using eac:xlink_role and not the
                                newer eac:rr_xlink_role used in rrel.
                            -->
                            <resourceRelation xlink:arcrole="{$wcrr_arc_role}"
                                              xlink:role="{$param_data/eac:xlink_role}"
                                              xlink:type="simple"
                                              xlink:href="{$param_data/eac:rr_xlink_href}/{$controlfield_001}">
                                <relationEntry><xsl:value-of select="$rel_entry"/></relationEntry>
                                <xsl:copy-of select="$mods"/>

                                <xsl:if test="string-length($leader06)>0 or string-length($leader07)>0 or string-length($leader08)>0">
        		            <descriptiveNote>
			                <p>
				            <span localType="{$param_data/eac:av_Leader06}"><xsl:value-of select="$leader06"/></span>
				            <span localType="{$param_data/eac:av_Leader07}"><xsl:value-of select="$leader07"/></span>
				            <span localType="{$param_data/eac:av_Leader08}"><xsl:value-of select="$leader08"/></span>
			                </p>
			            </descriptiveNote>
                                </xsl:if>

                            </resourceRelation>
                        </xsl:otherwise>
                    </xsl:choose>
                </relations>
            </cpfDescription>
        </eac-cpf>
</xsl:template>

<xsl:template match="*" mode="serialize">
    <xsl:param name="tabs"/>
    <xsl:value-of select="concat($cr,$tabs)"/>
    <xsl:element name="{name()}">
        <xsl:for-each select="@*">
            <xsl:attribute name="{name()}" select="."/>
        </xsl:for-each>
        <xsl:choose>
            <xsl:when test="node()">
                <xsl:apply-templates mode="serialize">
                    <xsl:with-param name="tabs">
                        <xsl:value-of select="concat($tabs, '&#9;')"/>
                    </xsl:with-param>
                </xsl:apply-templates>
            </xsl:when>
        </xsl:choose>
    </xsl:element>
</xsl:template>

<xsl:template match="text()" mode="serialize">
    <xsl:param name="tabs"/>
    <xsl:value-of select="concat($cr,$tabs)"/>
    <xsl:value-of select="."/>
</xsl:template>

</xsl:stylesheet>
