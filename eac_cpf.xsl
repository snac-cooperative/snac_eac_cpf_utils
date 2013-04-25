<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="2.0"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:eac="urn:isbn:1-931666-33-4"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns="urn:isbn:1-931666-33-4"
                exclude-result-prefixes="xs eac xlink"
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
    -->

    <xsl:template name="tpt_body">
        <xsl:param name="exist_dates"/>
        <xsl:param name="leader06"/>
        <xsl:param name="leader07"/>
        <xsl:param name="leader08"/>
        <xsl:param name="mods"/>
        <xsl:param name="rel_entry"/>
        <xsl:param name="local_affiliation"/>
        <xsl:param name="arc_role"/>
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
                <recordId><xsl:value-of select="concat($record_id, '.', $fn_suffix)"/></recordId>
                <maintenanceStatus>new</maintenanceStatus>
                <maintenanceAgency>
                    <xsl:copy-of select="$param_data/eac:snac_info/*"/>
                </maintenanceAgency>
                <xsl:copy-of select="$lang_decl"/>
                <maintenanceHistory>
                    <maintenanceEvent>
                        <eventType>created</eventType>
                        <eventDateTime standardDateTime="{$date}"/>
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
                    <source xlink:href="{$param_data/eac:xlink_href}/{$controlfield_001}"
                            xlink:type="simple">
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
                    <nameEntry xml:lang="en-Latn">
                        <part><xsl:value-of select="$entity_name"/></part>
                        <authorizedForm><xsl:value-of select="$param_data/eac:rules"/></authorizedForm>
                    </nameEntry>
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
                        <!-- <xsl:message> -->
                        <!--     <xsl:text>fun: </xsl:text> -->
                        <!--     <xsl:copy-of select="$param_data/eac:function" /> -->
                        <!-- </xsl:message> -->


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
                    <xsl:copy-of select="$cpf_relation"/>
                    <resourceRelation xlink:arcrole="{$arc_role}"
                                      xlink:role="{$param_data/eac:xlink_role}"
                                      xlink:type="simple"
                                      xlink:href="{$param_data/eac:xlink_href}/{$controlfield_001}">
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
                </relations>
            </cpfDescription>
        </eac-cpf>
    </xsl:template>
</xsl:stylesheet>
