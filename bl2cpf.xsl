<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="2.0"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:lib="http://example.com/"
                xmlns:rel="http://example.com/relator"
                xmlns:bl="http://example.com/bl"
                xmlns:eac="urn:isbn:1-931666-33-4"
                xmlns="urn:isbn:1-931666-33-4"
                xmlns:xlink="http://www.w3.org/1999/xlink" 
                exclude-result-prefixes="xsl xs lib eac xlink rel bl"
                >
    <!--
        Author: Tom Laudeman
        The Institute for Advanced Technology in the Humanities
        
        Copyright 2013 University of Virginia. Licensed under the Educational Community License, Version 2.0 (the
        "License"); you may not use this file except in compliance with the License. You may obtain a copy of the
        License at
        
        http://opensource.org/licenses/ECL-2.0
        http://www.osedu.org/licenses/ECL-2.0
        
        Unless required by applicable law or agreed to in writing, software distributed under the License is
        distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
        the License for the specific language governing permissions and limitations under the License.
        
        Reads a list of British Library Names xml records and writes out EAC-CFP XML. 
        
        saxon british_library/name_target.xml bl2cpf.xsl limit=100

        See readme.md for details.
        
        There is no point in doing omit-xml-declaration="yes" with Saxon, because it won't omit it for xml
        output to stdout. However, if set to "yes" it will omit the declaration for result-document() output
        to a file, which could be bad.
        
        Templates in this file:
        
        tpt_main match="/" This the xslt equivalent of main().
        tpt_match_record
        tpt_container match="marc:collection"
        not_1xx match="//marc:record[not(marc:datafield[@tag='100' or @tag='110' or @tag='111'])]"
        catch_all match="*"
        match_subfield
        top_record match="marc:record"
        match_snac match="snac"
        mode "copy-no-ns" match="*"
        
        See also lib.xsl, eac_cpf.xsl.

        
        What does this do in the XSL header?
        extension-element-prefixes="date"
    -->

    <!-- zero is all records -->
    <xsl:param name="limit" select="0"/>
    <xsl:param name="debug" select="false()"/>

    <xsl:param name="output_dir" select="'./britlib'"/>
    <xsl:param name="fallback_default" select="'UK-BL'"/>
    <xsl:param name="auth_form" select="'BL'"/>
    <xsl:param name="inc_orig" select="true()"  as="xs:boolean"/>
    <xsl:param name="archive_name" select="'BLArchive'"/>

    <!--
        Enable BL alternate format names nameEntry via use_bl_alt_name=1 on the command line.
        Note that enabling the BL alt format will break XTF indexing.
    -->
    <xsl:param name="use_bl_alt_name" select="false()" as="xs:boolean"/>

    <!-- These three params (variables) are passed to the cpf template eac_cpf.xsl via params to tpt_body. -->

    <xsl:param name="ev_desc" select="'Derived from British Library'"/> <!-- eventDescription -->
    <!-- xlink:role The $av_ variables are in lib.xsl. -->
    <xsl:param name="xlink_role" select="$av_archivalResource"/> 
    <xsl:param name="xlink_href" select="'http://www.bl.uk/place_holder'"/> <!-- Not / terminated. Add the / in eac_cpf.xsl. xlink:href -->
    
    <!--
        When we find the tag <Corporation> we set the locn to 'CorporateBody'. Person and Family are ok.
        
        $pers_val, $fami_val, $corp_val come from lib.xsl.
    -->

    <!--
        This is the full list of all types of files and target values. This var exists for lookup so we can
        quickly find the file associated with a given target.
    -->
    <xsl:variable name="file_target" select="document('british_library/file_target.xml')/*"/>

    <!-- 
         Create a key that we'll use on $file_target to look up the <file> based on file/@target.
    -->
    <xsl:key name="ft_key" match="file" use="@target" />

    <xsl:include href="eac_cpf.xsl"/>
    <xsl:include href="lib.xsl"/>
    <!--
        name="xml" method="xml" is for the result-document() output of CPF.
        
        The unnamed output is just normal, default xml output.
    -->

    <xsl:output name="xml" method="xml" indent="yes" omit-xml-declaration="no"/>
    <xsl:output indent="yes" omit-xml-declaration="no"/>
    <xsl:strip-space elements="*"/>
    <xsl:preserve-space elements="layout"/>
    
    <!-- 
         Chunking related. The prefix does not include _ or /.
    -->
    <xsl:param name="chunk_size" select="100"/>
    <xsl:param name="chunk_prefix" select="'zzz'"/>
    <xsl:param name="offset" select="1"/>

    <xsl:param name="use_chunks" as="xs:boolean">
        <xsl:choose>
            <xsl:when test="not($chunk_prefix='zzz')">
                <xsl:value-of select="true()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:param>

    <xsl:variable name="xslt_script" select="'bl2cpf.xsl'"/>
    <xsl:variable name="xslt_version" select="system-property('xsl:version')" />
    <xsl:variable name="xslt_vendor" select="system-property('xsl:vendor')" />
    <xsl:variable name="xslt_vendor_url" select="system-property('xsl:vendor-url')" />

    <!-- a key-value node set, somewhat akin to a hash -->
    <xsl:variable name="fn_suffix">
        <key value="c">
            <xsl:copy-of select="true()"/>
        </key>
        <key value="r">
            <xsl:copy-of select="false()"/>
        </key>
    </xsl:variable>
    
    <!-- 
         Main root template start here.
    -->
    <xsl:template name="tpt_main" match="/">
        <xsl:message>
            <xsl:value-of select="concat('Date today: ', current-dateTime(), '&#x0A;')"/>
            <xsl:value-of select="concat('Number of geonames places read in: ', count($places/*), '&#x0A;')"/>
            <xsl:value-of select="concat('Writing output to: ', $output_dir, '&#x0A;')"/>
            <xsl:value-of select="concat('Default authorizedForm: ', $auth_form, '&#x0A;')"/>
            <xsl:value-of select="concat('Fallback (default) agency code: ', $fallback_default, '&#x0A;')"/>
            <xsl:value-of select="concat('Default eventDescription: ', $ev_desc, '&#x0A;')"/>
            <xsl:value-of select="concat('Default xlink href: ', $xlink_href, '&#x0A;')"/>
            <xsl:value-of select="concat('Default xlink role: ', $xlink_role, '&#x0A;')"/>
            <xsl:value-of select="concat('limit: ', $limit, '&#x0A;')"/>
            <xsl:value-of select="concat('use_bl_alt_name: ' , $use_bl_alt_name, '&#x0A;')"/>
            <xsl:choose>
                <xsl:when test="$inc_orig">
                    <xsl:value-of select="concat('Include original record: yes', '&#x0A;')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Include original record: no', '&#x0A;')"/>
                </xsl:otherwise>
            </xsl:choose>
            
            <xsl:choose>
            <xsl:when test="$use_chunks">
                <xsl:value-of select="concat('Using chunks: yes', '&#x0A;')"/>
                <xsl:value-of select="concat('Chunk size XSLT: ', $chunk_size, '&#x0A;')"/>
                <xsl:value-of select="concat('Chunk dir prefix: ', $chunk_prefix, '&#x0A;')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat('Using chunks: no', '&#x0A;')"/>
            </xsl:otherwise>
            </xsl:choose>
        </xsl:message>

        <!-- 
             Read each Names* file into a var, make that var the context, and call a template to process the
             data.
             
             Save the file name, and pass that into tpt_match_record. We'll create our cpf output using the
             same name as the input, and we get chunking for free.
        -->
        
        <xsl:for-each select="container/file[($limit = 0 or (position() &lt; $limit)) and matches(., 'Names')]">
            <xsl:variable name="ofile" select="text()"/>
            <xsl:variable name="name" select="document(concat('british_library/', text()))/*"/>
            <xsl:for-each select="$name">
                <xsl:call-template name="tpt_match_record">
                    <xsl:with-param name="ofile" select="$ofile"/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>


    <xsl:template name="tpt_match_record" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="ofile"/>

        <xsl:variable name="orig_record">
            <xsl:copy-of select="."/>
        </xsl:variable>

        <xsl:variable
            name="chunk_count"
            select="(position() + $offset) div $chunk_size"/>

        <!--
            Using format-number() with picture string '0' seems to convince it
            to save the number as a string of the real number and not to switch
            to scientific notation.
        -->
        <xsl:variable
            name="record_position"
            select="format-number(position()+$offset, '0')"/>

        <xsl:variable
            name="chunk_suffix"
            select="floor((position() + $offset - 1) div $chunk_size) + 1"/>

        <xsl:variable name="controlfield_001">
            <!-- 
                 Some data may have missing/duplicate 001. Using position() should be sufficient to make a
                 unique 001 value. I'm unclear how well the 010 or 035 would perform as record id values.
            -->
            <xsl:choose>
                <xsl:when test="string-length(normalize-space(.//@RecordID))>0">
                    <xsl:value-of select="normalize-space(.//@RecordID)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('missing001_', position())"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- 
             agency_info is not <maintenanceAgency><agencyName>. The SNAC project is the maintainer of the CPF
             data, not the agency where the data originated. The two concepts (current maintainer, mainttainer
             of the original) are now separate variables.
        -->

        <xsl:variable name="agency_info">
            <agencyCode>
                <xsl:value-of select="$fallback_default"/>
            </agencyCode>
            <agencyName>
                <xsl:value-of select=".//Repository"/>
            </agencyName>
        </xsl:variable>

        <xsl:variable name="record_id"
                      select="concat($agency_info/eac:agencyCode, '-', $controlfield_001)"/>

        <xsl:variable name="date" 
                      select="current-dateTime()"/>

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

        <!--
            Similar to $all_xx or $exp_data, $final_per, $final_org and so on. A list of CPF entities
            we've discovered.
        -->
        <xsl:variable name="all_cpf">
            <!-- Why was variable "citation" here? Made no sense. -->
            
            <!--
                First handle the main cpf entity described in the current Names*/ file. Create a var for name
                info, to normalize cpf name info regardless whether it is from c, p, or f.
            -->
            <xsl:variable name="ninfo">
                <xsl:call-template name="tpt_name_info">
                    <xsl:with-param name="is_c_flag" select="true()"/>
                    <xsl:with-param name="is_r_flag" select="false()"/>
                    <xsl:with-param name="record_id" select="$record_id"/>
                    <xsl:with-param name="cf" select="concat('ninfo ', $record_id)"/>
                </xsl:call-template>
            </xsl:variable>

            <container>
                <xsl:copy-of select="$ninfo"/>
            </container>
            
            <!-- 
                 key() only works with the context, and we have to use for-each to set the context, so we
                 have to create a new var for the file name we're looking up with key().
                 
                 <NameAuthorityRelationships>
                   <RelatedNamedAuthority RelationshipNumber="047-001686191">
                     <NatureRelationshipTargetDescription>Member</NatureRelationshipTargetDescription>
                     <NatureRelationshipSourceDescription>Member</NatureRelationshipSourceDescription>
                     <TargetRecordId>047-001686191</TargetRecordId>
                     <CategoryOfRelationship>Family</CategoryOfRelationship>
                     <DateRange/>
                   </RelatedNamedAuthority>
                 ...
                 </NameAuthorityRelationships>
            -->
            <xsl:for-each select=".//NameAuthorityRelationships/RelatedNamedAuthority/TargetRecordId">
                <xsl:variable name="tid" select="text()"/>

                <xsl:variable name="nar_file">
                    <xsl:for-each select="$file_target">
                        <xsl:value-of select="key('ft_key', $tid)"/>
                    </xsl:for-each>
                </xsl:variable>

                <xsl:variable name="nar_info">
                    <xsl:choose>
                        <xsl:when test="string-length($nar_file) > 0">
                            <xsl:copy-of select="document(concat('british_library/', $nar_file))/*"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message>
                                <xsl:text>Missing Names tid: </xsl:text>
                                <xsl:value-of select="$tid"/>
                                <xsl:text> rid: </xsl:text>
                                <xsl:value-of select="$record_id"/>
                                <xsl:text> Called from: tpt_match</xsl:text>
                                <!-- <xsl:text>&#x0A;</xsl:text> -->
                            </xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>

                <!-- 
                     Use for-each to set $nar_info as the context. There better only be one name or cpf in
                     $nar_info.
                -->
                <xsl:for-each select="$nar_info/*">
                    <xsl:variable name="is_c_flag" select="false()" as="xs:boolean" />
                    <xsl:variable name="is_r_flag" select="true()" as="xs:boolean" />
                    <xsl:variable name="ninfo">
                        <xsl:call-template name="tpt_name_info">
                            <xsl:with-param name="is_c_flag" select="false()"/>
                            <xsl:with-param name="is_r_flag" select="true()"/>
                            <xsl:with-param name="record_id" select="concat('UK-BL-', $tid)"/>
                            <xsl:with-param name="cf" select="concat('nar ', $tid)"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <container>
                        <xsl:copy-of select="$ninfo"/>
                    </container>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>
        
        <!--
            For the BL data we only create a file for the "main" entry, and we only need to build cpfRelation
            data for the "main" entity. We assume that all other cpfs will have their own file, and will be
            processed accordingly. In BL data, is_c_flag means "is the main cpf entity".
            
            Note: the context is a <container> node set. <container><e_name>...</e_name><existDates>...</existDates></container>
        -->

        <xsl:for-each select="$all_cpf/eac:container[eac:e_name/@is_c_flag = 'true']">
            <!--
                Create a set of cpfRelation elements for the current node. We are inside a for-each, so the
                current node should be the context.
            -->
            <xsl:variable name="cpf_relation">
                <xsl:call-template name="tpt_cpf_relation">
                    <xsl:with-param name="all_xx" select="$all_cpf"/>
                </xsl:call-template>
            </xsl:variable>

            <!--
                Originally, we only had a single resourceRelation, but NYSA can have multiples, so since
                that time, we now use a rrel element to hold one or more node sets for
                resourceRelation. This replaces individual elements of the same name out in param_data.
                
                radna is RelatedArchiveDescriptionNamedAuthority.
                
                The radna is for the related descs. We need to pass in our target id.
                
                Only call tpt_snac_info for WorldCat
            -->
            <xsl:variable name="param_data" xmlns="urn:isbn:1-931666-33-4">
                <xsl:copy-of select="eac:descriptiveNote"/>
                <use_rrel as="xs:boolean">
                    <xsl:value-of select="true()"/>
                </use_rrel>
                <rules>
                    <xsl:value-of select="$auth_form"/>
                </rules>
                <inc_orig>
                    <xsl:copy-of select="$inc_orig" />
                </inc_orig>
                <snac_info>
                    <xsl:call-template name="tpt_snac_info"/>
                </snac_info>
                
                <!--
                    Calling capitalize() doesn't hurt, but we shouldn't need to capitalized @entity_type
                    because the values are from $pers_val etc. from lib.xsl.
                -->
                <citation>
                    <xsl:text>British Library Archives and Manuscripts Catalogue : </xsl:text>
                    <xsl:value-of select="lib:capitalize(eac:e_name/@entity_type)"/>
                    <xsl:text> : Description : </xsl:text>
                    <xsl:value-of select="eac:ark"/>
                </citation>

                <!-- 
                     tpt_radna creates the necessary rrel elements (resourceRelation) for this CPF entry.
                     
                     Create a couple of vars because the outer context is not available to the inner context
                     of the for-each.
                -->
                <xsl:variable name="entity_tid" select="eac:e_name/@enid"/>
                <xsl:variable name="entity_type" select="string(eac:e_name/@entity_type)"/>

                <xsl:for-each select="eac:dinfo/*">

                    <!-- <xsl:message> -->
                    <!--     <xsl:text>calling radna et: </xsl:text> -->
                    <!--     <xsl:copy-of select="."/> -->
                    <!--     <xsl:text>&#x0A;</xsl:text> -->
                    <!-- </xsl:message> -->


                    <xsl:call-template name="tpt_radna">
                        <xsl:with-param name="entity_tid" select="$entity_tid"/>
                        <xsl:with-param name="controlfield_001" select="$controlfield_001"/>
                        <xsl:with-param name="rid" select="$record_id"/>
                        <xsl:with-param name="entity_type" select="$entity_type"/>
                    </xsl:call-template>
                </xsl:for-each>

                <en_lang>
                    <!-- entry language, applies only to the first (main) name if there are multiple names. -->
                    <xsl:value-of select="eac:e_name/@en_lang"/>
                </en_lang>
                <cpf_record_id>
                    <!-- Used in the eac_cpf template control/recordId element. -->
                    <xsl:value-of select="$record_id"/>
                </cpf_record_id>

                <!-- authorized and alternative names are all together now -->
                <xsl:copy-of select="eac:e_name"/>

                <!--
                    This sends over the current eac:container wrapper element, which has all kinds of info
                    about the current entity. It is used for occupation and function.
                -->
                <xsl:copy-of select="."/>

            </xsl:variable>
            
            <xsl:variable name="file_name" select="concat($output_dir, '/', $ofile)"/>
            
            <xsl:result-document href="{$file_name}" format="xml" >
                <xsl:call-template name="tpt_body">
                    <xsl:with-param name="param_data" select="$param_data" />
                    <xsl:with-param name="exist_dates" select="./eac:existDates" as="node()*" />
                    <xsl:with-param name="entity_type" select="eac:e_name/@entity_type_cpf" />
                    
                    <!-- Do not use. Superceded by $param_data/e_name for records with multi or alternative names. -->
                    <!-- <xsl:with-param name="entity_name" select="eac:e_name"/> -->

                    <xsl:with-param name="controlfield_001" select="$controlfield_001"/>
                    <xsl:with-param name="is_c_flag" select="eac:e_name/@is_c_flag"/>
                    <xsl:with-param name="is_r_flag" select="eac:e_name/@is_r_flag"/>
                    <xsl:with-param name="fn_suffix" select="eac:e_name/@fn_suffix" />
                    <xsl:with-param name="cpf_relation" select="$cpf_relation" />
                    <xsl:with-param name="record_id" select="$record_id" />
                    <xsl:with-param name="date" select="$date" />
                    <xsl:with-param name="xslt_vendor" select="$xslt_vendor"/>
                    <xsl:with-param name="xslt_version" select="$xslt_version"/>
                    <xsl:with-param name="xslt_vendor_url" select="$xslt_vendor_url"/>
                    <xsl:with-param name="tag_545" select="eac:tag_545/*"/>
                    <xsl:with-param name="xslt_script" select="$xslt_script"/>
                    <!-- The original must be a node set, not text. -->
                    <xsl:with-param name="original">
                        <original><xsl:copy-of select="$orig_record"/></original>
                    </xsl:with-param>
                    <xsl:with-param name="geographic_subject" select="eac:geo_subj/*"/>
                    <xsl:with-param name="topical_subject" select="eac:topical_subj/*"/>

                    <!-- Lots of stuff that doesn't apply to the BL data. -->
                    <!-- <xsl:with-param name="leader06" select="$leader06"/> -->
                    <!-- <xsl:with-param name="leader07" select="$leader07"/> -->
                    <!-- <xsl:with-param name="leader08" select="$leader08"/> -->
                    <!-- <xsl:with-param name="mods" select="$mods"/> -->
                    <!-- <xsl:with-param name="rel_entry" select="$rel_entry"/> -->
                    <!-- <xsl:with-param name="arc_role" select="$arc_role"/> -->
                    <!-- <xsl:with-param name="tag_245" select="normalize-space($tag_245)"/> -->
                    <!-- <xsl:with-param name="lang_decl" select="$lang_decl"/> -->
                    <!-- <xsl:with-param name="topical_subject" select="$topical_subject"/> -->
                    <!-- <xsl:with-param name="language" select="$language"/> -->
                </xsl:call-template>
            </xsl:result-document>
        </xsl:for-each>

    </xsl:template> <!-- end tpt_match_record -->
    

    <xsl:template name="tpt_bl_arc_role" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="rel_type"/>
        <!--
            Only "subject" is subject. All others are creatorOf. Discussed Aug 8 2013.
            
            Daniel says: BL's manuscript collections. We will call every last one of these "archival," and
            almost every name will either be the creator or referencedIn a resource. (Almost?)
            
            Use value-of to turn one or more nodes (or a sequence) into a single string that we can test with
            a regex matches().
        -->

        <xsl:variable name="denorm_role">
            <xsl:value-of select="$rel_type"/>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="matches($denorm_role, 'subject', 'i')">
                <xsl:value-of select="$av_referencedIn"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$av_creatorOf"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="tpt_name_info">
        <xsl:param name="is_c_flag"/>
        <xsl:param name="is_r_flag"/>
        <xsl:param name="record_id"/>
        <xsl:param name="cf"/>
        
        <!-- 
             We have to be consistent in how record id values are determined. Other data has .c records that
             refer to .r records which are contained internally in the original MARC record. BL has
             independent CPF entities, some of which refer to each other.
        -->

        <xsl:variable name="locn">
            <xsl:choose>
                <xsl:when test="./local-name() = 'Corporation'">
                    <xsl:value-of select="$corp_val"/>
                </xsl:when>
                <xsl:when test="./local-name() = 'Family'">
                    <xsl:value-of select="$fami_val"/>
                </xsl:when>
                <xsl:when test="./local-name() = 'Person'">
                    <xsl:value-of select="$pers_val"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message terminate="yes">
                        <xsl:text>Bad input root element: </xsl:text>
                        <xsl:value-of select="./local-name()"/>
                        <xsl:text>&#x0A;RecordID: &#x0A;</xsl:text>
                        <xsl:value-of select="./@RecordID"/>
                        <xsl:text>&#x0A;Exiting.&#x0A;</xsl:text>
                    </xsl:message>
                    <!-- <xsl:value-of select="./local-name()"/> -->
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="entity_tid" select="./@RecordID"/>

        <!--
            This xpath seems to be the same for all CPFs.
            .//ArchiveDescriptionNameAuthorityRelationships/RelatedArchiveDescriptionNamedAuthority/TargetRecordId

            radna is Related Archive Description Named Authority
        -->
        <xsl:variable name="radna">
            <xsl:for-each select=".//ArchiveDescriptionNameAuthorityRelationships/RelatedArchiveDescriptionNamedAuthority/TargetRecordId">
                <radna>
                    <xsl:value-of select="."/>
                </radna>
            </xsl:for-each>
        </xsl:variable>

        <xsl:variable name="descs_info">
            <xsl:for-each select="$radna/*">
                <!-- 
                     Context in this loop is the tid of the descs file. Get the file name here, and put it in
                     an attribute of the descs_container so we can easily get it later on.
                -->
                <xsl:variable name="tid" select="."/>
                <xsl:variable name="descs_file">
                    <xsl:for-each select="$file_target">
                        <xsl:value-of select="key('ft_key', $tid)"/>
                    </xsl:for-each>
                </xsl:variable>
                
                <descs_container tid="{.}" descs_file="{$descs_file}">
                    <!-- 
                         Var names: tid is target id, rid is record id, cf is called from.
                    -->
                    <xsl:call-template name="tpt_descs_info">
                        <xsl:with-param name="tid" select="."/>
                        <xsl:with-param name="rid" select="$record_id"/>
                        <xsl:with-param name="cf" select="'tpt_name_info'"/>
                        <xsl:with-param name="descs_file" select="$descs_file"/>
                    </xsl:call-template>
                </descs_container>
            </xsl:for-each>
        </xsl:variable>

        <!--
            The <radna> node set here is accessed later as eac:radna in order to create <rrel> elements that
            become resourceRelation elements in the CPF output.
        -->
        <dinfo>
            <xsl:copy-of select="$descs_info"/>
        </dinfo>
        <xsl:copy-of select="$radna"/>

        <geo_subj>
            <xsl:copy-of select="$descs_info/*/eac:place"/>
        </geo_subj>
        <topical_subj>
            <xsl:copy-of select="$descs_info/*/eac:localDescription[@localType = $av_associatedSubject]"/>
        </topical_subj>
        <!--
            Note1: The name values are create by concat()'ing all the fields together along with their
            separators as though every field always had a value. lib:name-cleanse() will remove extraneous
            separators due to empty fields. So, the code here is simple and clean, but lib:name-cleanse() has
            many small regular expressions.
            
            Note2: Important to use .// and not // because // is global using the document, ignores the context, and
            returns RelatedArchiveDescriptionNamedAuthority in all of the current "document". Only get the
            first matching record. There are duplicates, and that makes a mess of tot_ocfu_e which expects a
            single value.
        -->
        
        <xsl:variable name="tag_545">
            <!--
                aka biogHist
                
                The path ".//History/*|.//History/text()" seems to work to match <history><p>text</p></History> and
                <History>text</History>
            -->
            <tag_545>
                <xsl:for-each select=".//History/*|.//History/text()">
                    <p>
                        <xsl:value-of select="."/>
                    </p>
                </xsl:for-each>
                <xsl:call-template name="tpt_name_extras">
                    <xsl:with-param name="record_id" select="$record_id"/>
                </xsl:call-template>
            </tag_545>
        </xsl:variable>

        <xsl:variable name="descriptive_note">
            <!-- We are putting the name extras in biogHist aka tag_545. -->
            
            <!-- <descriptiveNote> -->
            <!--     <xsl:call-template name="tpt_name_extras"> -->
            <!--         <xsl:with-param name="record_id" select="$record_id"/> -->
            <!--     </xsl:call-template> -->
            <!-- </descriptiveNote> -->
        </xsl:variable>

        <!-- <xsl:message> -->
        <!--     <xsl:value-of select="concat('545: rid: ', $record_id, ' ')"/> -->
        <!--     <xsl:copy-of select="$tag_545"/> -->
        <!--     <xsl:text>&#x0A;</xsl:text> -->
        <!-- </xsl:message> -->

        <xsl:variable name="all_occ">
        <xsl:for-each select="$descs_info/eac:descs_container//RelatedArchiveDescriptionNamedAuthority[@TargetNumber = $entity_tid]/RelationshipType/text()">
            <xsl:variable name="rt" select="."/>
            <xsl:for-each select="bl:split-reltype(.)">
                <xsl:variable name="occ_element_name">
                    <xsl:choose>
                        <xsl:when test="$locn = $corp_val or $locn = $fami_val">
                            <xsl:value-of select="'function'"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>occupation</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <!-- 
                     tpt_ocfu_4 checks occupation name (or relator code) against the relators file.
                -->
                <occ>
                    <xsl:call-template name="tpt_ocfu_4">
                        <xsl:with-param name="sfield" select="."/>
                        <xsl:with-param name="cname" select="$occ_element_name"/>
                    </xsl:call-template>
                </occ>
            </xsl:for-each>
        </xsl:for-each>
        </xsl:variable>
        
        <!--
            De-duping in 6 lines. This is explained in a long comment near the end of template tpt_geo in
            lib.xsl. Note that the child element of eac:occ might be eac:occupation or eac:function.
        -->
        <occ>
            <xsl:for-each select="$all_occ/eac:occ/*[string-length(eac:term) > 0]">
                <xsl:variable name="curr" select="."/>
                <xsl:if test="not(preceding::eac:term[lib:pname-match(text(),  $curr/eac:term)])">
                    <xsl:copy-of select="$curr" />
                </xsl:if>
            </xsl:for-each>
        </occ>

        <xsl:choose>
            <xsl:when test="$locn = $corp_val"> <!-- Corporation -->
                <!-- <CorporationNames> -->
                <!--     <CorporationName> -->
                <!--         <CorporateName>Chapel of St Andrew on the new bridge</CorporateName> -->
                <!--         <Jurisdiction/> -->
                <!--         <AdditionalQualifiers>Elvet Hall</AdditionalQualifiers> -->
                <!--         <StartDate>-9999</StartDate> -->
                <!--         <DateRange>Unspecified</DateRange> -->
                <!--         <EndDate>-9999</EndDate> -->
                <!--         <NameType>Authorised</NameType> -->
                <!--         <NameLanguage>English</NameLanguage> -->
                <!--         <NameScript>Latin</NameScript> -->
                <!--     </CorporationName> -->
                <!-- </CorporationNames> -->
                <xsl:variable name="all_names">
                    <xsl:copy-of select="/Corporation/CorporationNames"/>
                </xsl:variable>
                <xsl:variable name="auth_name">
                    <xsl:copy-of select="/Corporation/CorporationNames/CorporationName[NameType = 'Authorised']"/>
                </xsl:variable>
                <xsl:variable name="parsed_date">
                    <xsl:call-template name="tpt_normalized_date">
                        <xsl:with-param name="date_range" select="$auth_name/CorporationName/DateRange"/>
                        <xsl:with-param name="descs_info" select="$descs_info"/>
                        <xsl:with-param name="locn" select="$locn"/>
                        <xsl:with-param name="auth_name" select="$auth_name"/>
                        <xsl:with-param name="is_active" select="true()"/>
                    </xsl:call-template>
                </xsl:variable>

                <e_name enid="{$entity_tid}"
                        record_id="{$record_id}"
                        fn_suffix="{$fn_suffix/eac:key[text() = $is_c_flag]/@value}"
                        is_c_flag="{$is_c_flag}" 
                        is_r_flag="{$is_r_flag}"
                        entity_type="{$corp_val}"
                        entity_type_cpf="{$cpf_corp_val}"
                        en_lang="{lib:get-lang($auth_name/*/NameLanguage)}">
                    <!--
                        Use for-each to set context. See lib.xsl for lib:name-cleanse. See
                        british_library/qa_file_target.xml comments.  Var name_entry eventually becomea
                        nameEntry in eac_cpf.xsl.
                    -->
                    <xsl:for-each select="$all_names/*/*">
                        <xsl:variable name="a_form">
                            <xsl:call-template name="tpt_a_form">
                                <xsl:with-param name="type" select="NameType"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <name_entry en_lang="{lib:get-lang(NameLanguage)}"
                                    a_form="{$a_form}">
                            <part>
                                <!-- See Note1 above. -->
                                <xsl:value-of select="lib:name-cleanse(
                                                      concat(
                                                      Jurisdiction, '. ',
                                                      CorporateName, ' (',
                                                      AdditionalQualifiers, ' : ',
                                                      $parsed_date/eac:parsed_date_range, ')')
                                                      )"/>
                            </part>
                        </name_entry>
                        <xsl:if test="$use_bl_alt_name">
                            <name_entry en_lang="{lib:get-lang(NameLanguage)}"
                                        localType="http://socialarchive.iath.virginia.edu/control/term#BLName"
                                        a_form="{$a_form}">
                                <xsl:for-each select="./*">
                                    <part localType="{concat('http://socialarchive.iath.virginia.edu/control/term#BL', local-name())}">
                                        <xsl:value-of select="."/>
                                    </part>
                                </xsl:for-each>
                            </name_entry>
                        </xsl:if>
                    </xsl:for-each>
                </e_name>
                <ark>
                    <xsl:value-of select=".//MDARK"/>
                </ark>
                <xsl:copy-of select="$parsed_date/eac:existDates"/>
                <xsl:copy-of select="$tag_545"/>
                <xsl:copy-of select="$descriptive_note"/>
            </xsl:when>

            <xsl:when test="$locn = $pers_val"> <!-- Person -->
                <!-- <PersonNames> -->
                <!--   <PersonName> -->
                <!--     <Surname>le Bretun</Surname> -->
                <!--     <FirstName>Robert</FirstName> -->
                <!--     <PreTitle/> -->
                <!--     <Title/> -->
                <!--     <Epithet>of Walton, Dominus/Sir</Epithet> -->
                <!--     <AdditionalInformation/> -->
                <!--     <Gender>Unspecified</Gender> -->
                <xsl:variable name="all_names">
                    <xsl:copy-of select="/Person/PersonNames"/>
                </xsl:variable>
                <xsl:variable name="auth_name">
                    <xsl:copy-of select="/Person/PersonNames/PersonName[NameType = 'Authorised']"/>
                </xsl:variable>
                
                <xsl:variable name="parsed_date">
                    <xsl:call-template name="tpt_normalized_date">
                        <xsl:with-param name="date_range" select="$auth_name/PersonName/DateRange"/>
                        <xsl:with-param name="descs_info" select="$descs_info"/>
                        <xsl:with-param name="locn" select="$locn"/>
                        <xsl:with-param name="auth_name" select="$auth_name"/>
                        <xsl:with-param name="is_active" select="false()"/>
                    </xsl:call-template>
                </xsl:variable>

                <!-- <xsl:message> -->
                <!--     <xsl:text>pers: </xsl:text> -->
                <!--     <xsl:copy-of select="$auth_name/DateRange"/> -->
                <!--     <xsl:text>&#x0A;</xsl:text> -->
                <!-- </xsl:message> -->

                <e_name enid="{$entity_tid}"
                        record_id="{$record_id}"
                        fn_suffix="{$fn_suffix/eac:key[text() = $is_c_flag]/@value}"
                        is_c_flag="{$is_c_flag}" 
                        is_r_flag="{$is_r_flag}"
                        entity_type="{$pers_val}"
                        entity_type_cpf="{$cpf_pers_val}"
                        en_lang="{lib:get-lang($auth_name/*/NameLanguage)}">
                    <!--
                        Use for-each to set context. See lib.xsl for lib:name-cleanse. See british_library/qa_file_target.xml comments.

                        Note the extra concat() to add a trailing dot to person names.
                    -->
                    <xsl:for-each select="$all_names/*/*">
                        <xsl:variable name="a_form">
                            <xsl:call-template name="tpt_a_form">
                                <xsl:with-param name="type" select="NameType"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <name_entry en_lang="{lib:get-lang(NameLanguage)}"
                                    a_form="{$a_form}">
                            <part>
                                <!-- See Note1 above. -->
                                <xsl:value-of select="concat(
                                                      lib:name-cleanse(
                                                      concat(
                                                      lib:capitalize(AdditionalInformation), ' ',
                                                      Surname, ', ',
                                                      FirstName, ', ',
                                                      PreTitle, ', ',
                                                      $parsed_date/eac:parsed_date_range)
                                                      ), '.')"/>
                            </part>
                        </name_entry>
                        <xsl:if test="$use_bl_alt_name">
                            <name_entry en_lang="{lib:get-lang(NameLanguage)}"
                                        localType="http://socialarchive.iath.virginia.edu/control/term#BLName" 
                                        a_form="{$a_form}">
                                <xsl:for-each select="./*">
                                    <part localType="{concat('http://socialarchive.iath.virginia.edu/control/term#BL', local-name())}">
                                        <xsl:value-of select="."/>
                                    </part>
                                </xsl:for-each>
                            </name_entry>
                        </xsl:if>
                    </xsl:for-each>
                </e_name>
                <ark>
                    <xsl:value-of select=".//MDARK"/>
                </ark>
                <xsl:copy-of select="$parsed_date/eac:existDates"/>
                <xsl:copy-of select="$tag_545"/>
                <xsl:copy-of select="$descriptive_note"/>
            </xsl:when>

            <xsl:when test="$locn = $fami_val"> <!-- Family -->
                <!-- <FamilyNames> -->
                <!--     <FamilyName> -->
                <!--         <AdditionalInformation/> -->
                <!--         <FamilySurname>Wood</FamilySurname> -->
                <!--         <FamilyEpithet>Family</FamilyEpithet> -->
                <!--         <TitleOccupation/> -->
                <!--         <TerritorialDesignation>Subject of Mss Eur F553</TerritorialDesignation> -->
                <!--         <StartDate>-9999</StartDate> -->
                <!--         <DateRange>Unspecified</DateRange> -->
                <!--         <EndDate>-9999</EndDate> -->
                <!--         <NameType>Authorised</NameType> -->
                <!--         <NameLanguage>English</NameLanguage> -->
                <!--         <NameScript>Latin</NameScript> -->
                <!--     </FamilyName> -->
                <!-- </FamilyNames> -->
                <xsl:variable name="all_names">
                    <xsl:copy-of select="/Family/FamilyNames"/>
                </xsl:variable>
                <xsl:variable name="auth_name">
                    <xsl:copy-of select="/Family/FamilyNames/FamilyName[NameType = 'Authorised']"/>
                </xsl:variable>
                <xsl:variable name="parsed_date">
                    <xsl:call-template name="tpt_normalized_date">
                        <xsl:with-param name="date_range" select="$auth_name/FamilyName/DateRange"/>
                        <xsl:with-param name="descs_info" select="$descs_info"/>
                        <xsl:with-param name="locn" select="$locn"/>
                        <xsl:with-param name="auth_name" select="$auth_name"/>
                        <xsl:with-param name="is_active" select="true()"/>
                    </xsl:call-template>
                </xsl:variable>
                
                <!-- <xsl:message> -->
                <!--     <xsl:text>fami: </xsl:text> -->
                <!--     <xsl:copy-of select="$auth_name/FamilyName/DateRange"/> -->
                <!--     <xsl:text>&#x0A;</xsl:text> -->
                <!-- </xsl:message> -->

                <e_name enid="{$entity_tid}"
                        record_id="{$record_id}"
                        fn_suffix="{$fn_suffix/eac:key[text() = $is_c_flag]/@value}"
                        is_c_flag="{$is_c_flag}" 
                        is_r_flag="{$is_r_flag}"
                        entity_type="{$fami_val}"
                        entity_type_cpf="{$cpf_fami_val}"
                        en_lang="{lib:get-lang($auth_name/*/NameLanguage)}">
                    <!--
                        Use for-each to set context. See Note1 above. See lib.xsl for lib:name-cleanse. See
                        british_library/qa_file_target.xml comments.
                    -->
                    <xsl:for-each select="$all_names/*/*">
                        <xsl:variable name="a_form">
                            <xsl:call-template name="tpt_a_form">
                                <xsl:with-param name="type" select="NameType"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <name_entry en_lang="{lib:get-lang(NameLanguage)}"
                                    a_form="{$a_form}">
                            <part>
                                <xsl:choose>
                                    <xsl:when test="matches(AdditionalInformation, 'al')">
                                        <!--
                                            When AdditionalInformation is used for alias or al. we don't use
                                            AdditionalInformation. Always ignore TitleOccupation.
                                            
                                            See Note1 above.
                                        -->
                                        <xsl:value-of select="lib:name-cleanse(
                                                              concat(
                                                              FamilySurname, ' (',
                                                              lib:capitalize(FamilyEpithet), ' : ',
                                                              $parsed_date/eac:parsed_date_range, ' : ',
                                                              TerritorialDesignation, ')'
                                                              ))"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <!--
                                            Otherwise AdditionalInformation is von, De La, D' or similar prefix.
                                            
                                            See Note1 above.
                                        -->
                                        <xsl:value-of select="lib:name-cleanse(
                                                              concat(
                                                              lib:capitalize(AdditionalInformation), ' ',
                                                              FamilySurname, ' (',
                                                              lib:capitalize(FamilyEpithet), ' : ',
                                                              $parsed_date/eac:parsed_date_range, ' : ',
                                                              TerritorialDesignation, ')'
                                                              ))"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </part>
                        </name_entry>
                        <xsl:if test="$use_bl_alt_name">
                            <name_entry en_lang="{lib:get-lang(NameLanguage)}"
                                        localType="http://socialarchive.iath.virginia.edu/control/term#BLName"
                                        a_form="{$a_form}">
                                <xsl:for-each select="./*">
                                    <part localType="{concat('http://socialarchive.iath.virginia.edu/control/term#BL', local-name())}">
                                        <xsl:value-of select="."/>
                                    </part>
                                </xsl:for-each>
                            </name_entry>
                        </xsl:if>
                    </xsl:for-each>
                </e_name>
                <ark>
                    <xsl:value-of select=".//MDARK"/>
                </ark>
                <xsl:copy-of select="$parsed_date/eac:existDates"/>
                <xsl:copy-of select="$tag_545"/>
                <xsl:copy-of select="$descriptive_note"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template> <!-- end tpt_name_info -->
    
    <xsl:template name="tpt_bl_date" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="date_range"/>
        <xsl:param name="allow_single" select="false()" />
        <xsl:param name="descs_info"/>
        <xsl:param name="entity_type"/>
        <xsl:param name="is_active" select="false()"/>
        
        <xsl:variable name="tokens">
            <xsl:call-template name="tpt_exist_dates">
                <xsl:with-param name="xx_tag" select="'not used'"/>
                <xsl:with-param name="entity_type" select="'not used'"/>
                <xsl:with-param name="rec_pos" select="'not used'"/>
                <xsl:with-param name="subfield_d">
                    <xsl:value-of select="$date_range"/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:variable>

        <!-- 
             Note: select="$entity_type = $fami_val or $entity_type = $corp_val" is a short way of saying if
             the entity type is family or corporation then true (else false). This controls is_active so it
             should be true for family and corporatebody. Different code makes active true for dates from
             $descs_info in the alt date parsing below.
        -->

        <xsl:variable name="show_date">
            <xsl:call-template name="tpt_show_date">
                <xsl:with-param name="tokens" select="$tokens"/>
                <xsl:with-param name="is_family" select="$is_active = true() or $entity_type = $fami_val or $entity_type = $corp_val"/>
                <xsl:with-param name="entity_type" select="$entity_type"/>
                <xsl:with-param name="rec_pos" select="'not_used'"/>
            </xsl:call-template>
        </xsl:variable>

        <!--
            (At one point it was decided that...) We never want to see suspicious alternative dates. I think
            extra logic prevented the really outlandish dates from showing up in WorldCat, but we don't have
            that logic here, and I can't see what value it would have. In the British Library the unparsable
            dates are nearly all not any sort of date.
            
            If we don't have a good date, then try to get a useful active date from descs_info.
        -->
        
        <xsl:choose>
            <xsl:when test="(count($show_date/*) > 0) and
                            (count($show_date//*[@localType = $av_suspiciousDate]) = 0)">
                <xsl:copy-of select="$show_date"/>
            </xsl:when>
            <xsl:when test="(count($descs_info//DateRange) = 0) and
                            (count($show_date//*[@localType = $av_suspiciousDate]) > 0)">
                <xsl:copy-of select="$show_date"/>
            </xsl:when>
            <xsl:otherwise>
                <!--
                    If only one $descs_info/* then use the date, else for multi parse each one, create a range
                    (using valid dates only), and re-parse the range via the alt date parser. Can we simply
                    use tpt_parse_alt, and tpt_simple_date_range.
                -->
                <xsl:choose>
                    <xsl:when test="count($descs_info//DateRange) = 1">
                        <xsl:variable name="tokens">
                            <xsl:call-template name="tpt_exist_dates">
                                <xsl:with-param name="xx_tag" select="'not used'"/>
                                <xsl:with-param name="entity_type" select="'not used'"/>
                                <xsl:with-param name="rec_pos" select="'not used'"/>
                                <xsl:with-param name="subfield_d">
                                    <xsl:value-of select="$descs_info//DateRange"/>
                                </xsl:with-param>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:variable name="show_date">
                            <xsl:call-template name="tpt_show_date">
                                <xsl:with-param name="tokens" select="$tokens"/>
                                <xsl:with-param name="is_family" select="true()"/> <!-- definitely is_active -->
                                <xsl:with-param name="entity_type" select="$entity_type"/>
                                <xsl:with-param name="rec_pos" select="'not_used'"/>
                            </xsl:call-template>
                        </xsl:variable>

                        <!--
                            This is an alternate, active date. If there are no localType = $av_suspiciousDate
                            attributes anywhere then we're ok, otherwise (maybe) we don't show anything. The
                            thinking was to not show alternate dates when they are suspicious, but we might
                            want dates which are only suspicious because the active range is longer than 60
                            years, which is unreasonable for a Person.
                        -->
                        <!-- <xsl:if test="not($show_date//*[@localType = $av_suspiciousDate])"> -->
                            <xsl:copy-of select="$show_date"/>
                        <!-- </xsl:if> -->
                    </xsl:when>

                    <xsl:otherwise>
                        <!-- 
                             If we get here, apparently we have multiple alternate date ranges in $descs_info,
                             so we need to parse them all then create a date from the min and max standardDate
                        -->
                        <xsl:variable name="multi_date">
                            <xsl:for-each select="$descs_info//DateRange">
                                <xsl:variable name="tokens">
                                    <xsl:call-template name="tpt_exist_dates">
                                        <xsl:with-param name="xx_tag" select="'not used'"/>
                                        <xsl:with-param name="entity_type" select="'not used'"/>
                                        <xsl:with-param name="rec_pos" select="'not used'"/>
                                        <xsl:with-param name="subfield_d">
                                            <xsl:value-of select="."/>
                                        </xsl:with-param>
                                    </xsl:call-template>
                                </xsl:variable>
                                <xsl:variable name="show_date">
                                    <xsl:call-template name="tpt_show_date">
                                        <xsl:with-param name="tokens" select="$tokens"/>
                                        <xsl:with-param name="is_family" select="true()"/> <!-- is_active -->
                                        <xsl:with-param name="entity_type" select="$entity_type"/>
                                        <xsl:with-param name="rec_pos" select="'not_used'"/>
                                    </xsl:call-template>
                                </xsl:variable>
                                <xsl:copy-of select="$show_date"/>
                            </xsl:for-each>
                        </xsl:variable>

                        <xsl:variable name="min" select="format-number(min($multi_date//@standardDate), '0000')"/>
                        <xsl:variable name="max" select="format-number(max($multi_date//@standardDate), '0000')"/>
                        
                        <xsl:if test="$min != 'NaN' and $max != 'NaN'">
                            <!-- See lib.xml Since this is active, change allow_single to be true. -->
                            <existDates>
                                <xsl:call-template name="tpt_simple_date_range">
                                    <xsl:with-param name="from" select="$min"/>
                                    <xsl:with-param name="from_type" select="$av_active"/>
                                    <xsl:with-param name="to" select="$max"/>
                                    <xsl:with-param name="to_type" select="$av_active" />
                                    <xsl:with-param name="allow_single" select="true()" />
                                </xsl:call-template>
                            </existDates>
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template> <!-- tpt_bl_date -->

    <xsl:template name="tpt_cpf_relation"  xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="all_xx"/>
        <!--
            For the BL data, is c flag are also 1xx, essentially. There are not .r records in BL since we read
            all the names out of files.

            Due to the inability to override type casting of attributes (@is_c_flag) to string, we must test
            explicitly against true().
        -->

        <xsl:variable name="is_1xx">
            <xsl:value-of select="eac:e_name/@is_c_flag"/>
        </xsl:variable>

        <xsl:if test="eac:e_name/@is_c_flag = true()">
            <xsl:for-each select="$all_xx/eac:container/eac:e_name[substring(@fn_suffix, 1, 1) = 'r']">
                <!--
                    Paths here are realtive to $all_xx/container/e_name. Note, here we are looking at $all_xx, not
                    the current record matching this template. 
                    
                    Note that relationEntry uses only the authorizedForm name and that the element path is
                    "eac:name_entry/eac:part" and that "name_entry" is intentionally not "nameEntry" for the
                    output since we are gathering data for output, not creating the exact format of the
                    output. The same is true for @a_form which is carried along as an attribute, but will
                    become an element in the output.
                    
                    Changes to relationEntry here should probably also be made to relationEntry below.
                    
                    Var et is used as a key, and the keys are $pers_val, etc. There are slight capitalization
                    differences between the two sets of entity type variables. @entity_type is normal and
                    @entity_type_cpf is only for entityType in eac_cpf.xsl. See lib.xsl.
                -->
                <xsl:variable name="et" select="@entity_type"/>

                <cpfRelation xlink:type="simple"
                             xlink:role="{$etype/eac:value[@key = $et]}"
                             xlink:arcrole="{$av_associatedWith}">
                    <relationEntry><xsl:value-of select="./eac:name_entry[@a_form = 'authorizedForm']/eac:part"/></relationEntry>
                    <descriptiveNote>
                        <p>
                            <span localType="{$av_extractRecordId}">
                                <xsl:value-of select="@record_id"/>
                            </span>
                        </p>
                    </descriptiveNote>
                </cpfRelation>
            </xsl:for-each>
        </xsl:if>

        <!--
            The following is probably true, but British Library has no .r records.

            For a local .r record which also has a 1xx being processed by this template, output
            the (global) single .c node. If this record did not have a 1xx, there would be no .c
            file to refer to.
            
            Due to the inability to override type casting of attributes (@is_r_flag) to string, we must test
            explicitly against true().
        -->
        <xsl:if test="(eac:e_name/@is_r_flag = true()) and $is_1xx">
            <!--
                We need some fields from the the main c record. Put that c e_name node set in a variable.  The
                c name is merely the "main" or central record that we're processing as a 1xx. The c and r
                designation is relative for the BL data.
                
                Note that relationEntry uses only the authorizedForm name and that the element path is
                "eac:name_entry/eac:part" and that "name_entry" is intentionally not "nameEntry" for the
                output since we are gathering data for output, not creating the exact format of the
                output. The same is true for @a_form which is carried along as an attribute, but will become
                an element in the output.
                
                Changes to relationEntry here should probably also be made to relationEntry above.
            -->
            <xsl:variable name="cmain">
                <xsl:copy-of select="$all_xx/eac:container/eac:e_name[@fn_suffix = 'c']"/>
            </xsl:variable>
            <cpfRelation xlink:type="simple"
                         xlink:role="{$etype/eac:value[@key = $cmain/eac:e_name/@entity_type]}"
                         xlink:arcrole="{$av_associatedWith}">
                <relationEntry><xsl:value-of select="$cmain/eac:e_name/eac:name_entry[@a_form = 'authorizedForm']/eac:part"/></relationEntry>
                <descriptiveNote>
                    <p>
                        <span localType="{$av_extractRecordId}">
                            <xsl:value-of select="$cmain/eac:e_name/@record_id"/>
                        </span>
                    </p>
                </descriptiveNote>
            </cpfRelation>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="tpt_radna" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="controlfield_001"/>
        <xsl:param name="entity_tid" />
        <xsl:param name="rid"/>
        <xsl:param name="entity_type"/>
        <!--
            Context is a single descs_info record.
            
            Name file:
            <ArchiveDescriptionNameAuthorityRelationships>
            <RelatedArchiveDescriptionNamedAuthority TargetNumber="040-002249496">
            <RelationshipType>Correspondent</RelationshipType>
            <TargetRecordId>040-002249496</TargetRecordId>
            </RelatedArchiveDescriptionNamedAuthority>
            <RelatedArchiveDescriptionNamedAuthority TargetNumber="040-002283419">
            <RelationshipType>Correspondent</RelationshipType>
            <TargetRecordId>040-002283419</TargetRecordId>
            </RelatedArchiveDescriptionNamedAuthority>
            </ArchiveDescriptionNameAuthorityRelationships>
            
            Descs file:
            <RelatedArchiveDescriptionNamedAuthority TargetNumber="045-002249500">
            <RelationshipType>Correspondent</RelationshipType>
            <TargetRecordId>045-002249500</TargetRecordId>
            </RelatedArchiveDescriptionNamedAuthority>
            
        -->
        <xsl:if test="./*">
            <rrel>
                <!--
                    Should we look at all the entity id matches, and not just the first one?
                    
                    Note that BL is different from MARC derived records. With BL, the cpf comes from Names*
                    and the resources that refer to the cpf are Descs*. Thus xlink:href is the Descs file for the BL data.
                    
                    We send the RelationshipType to tpt_bl_arc_role which filters the value, therefore we can
                    send multiple values. There are only two possible roles: $av_referencedIn, $av_creatorOf.
                -->
                <arc_role>
                    <xsl:call-template name="tpt_bl_arc_role">
                        <xsl:with-param
                            name="rel_type"
                            select=".//RelatedArchiveDescriptionNamedAuthority[@TargetNumber = $entity_tid]/RelationshipType"/>
                    </xsl:call-template>
                </arc_role>

                <xlink_role><xsl:value-of select="$xlink_role"/></xlink_role>
                
                <xlink_href>
                    <xsl:value-of
                        select="concat('http://searcharchives.bl.uk/primo_library/libweb/action/search.do?srt=rank&amp;ct=search&amp;mode=Basic&amp;indx=1&amp;vl(freeText0)=',
                                @tid,
                                '&amp;fn=search&amp;vid=IAMS_VU2')"/>
                </xlink_href>
                <controlfield_001><xsl:value-of select="$controlfield_001"/></controlfield_001>

                <!--
                    Both .//ScopeContent and .//Title may be empty elements, contain text, or contain child
                    nodes (usually p). Both may be very long. On the BL web site, they truncate at 250
                    characters, so we'll do the same when constructing a relationEntry aka title.
                    
                    string-length() can cope both single values and sequences and seems the most robust way to avoid
                    empty tags.
                    
                    This variable is used in at least two places, and the xpath to select only
                    text/nodes/sequences that aren't empty is tricky.
                -->

                <xsl:variable name="scope_content_norm">
                    <!--
                        Copy the scope content, leaving out empty elements at the top level. Also wrap any
                        naked text() nodes in <p>. All this work so there won't be an empty P tag at the
                        beginning of the abstract, which seems to result in aleading "; " on the relation
                        entry (although we have a regex below that fixes that issue).
                    -->

                    <xsl:choose>
                        <xsl:when test=".//ScopeContent/text()">
                            <p>
                                <xsl:copy-of select=".//ScopeContent/node()"/>
                            </p>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy-of select=".//ScopeContent//*[string-length() > 0]"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- <xsl:for-each select=".//ScopeContent/*"> -->
                    <!--     <xsl:if test="string-length() > 0"> -->
                    <!--         <xsl:copy-of select="."/> -->
                    <!--     </xsl:if> -->
                    <!-- </xsl:for-each> -->
                </xsl:variable>

                <xsl:variable name="rel_title_long">
                    <xsl:choose>
                        <xsl:when test=".//Title/* or .//Title/text()">
                            <xsl:value-of select=".//Title"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:variable name="tmp_title">
                                <!-- <xsl:for-each select=".//ScopeContent/*[not(./text() = '')]"> -->
                                <xsl:for-each select="$scope_content_norm">
                                    <xsl:value-of select="concat(., '; ')"/>
                                </xsl:for-each>
                            </xsl:variable>
                            <xsl:value-of select="replace(
                                                  replace(
                                                  $tmp_title
                                                  , ';\s*$', '')
                                                  , '^;\s*', '')"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="rel_title">
                    <xsl:choose>
                        <xsl:when test="string-length($rel_title_long) > 250">
                            <xsl:value-of select="concat(substring($rel_title_long, 1, 250), '...')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$rel_title_long"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                
                <!--
                    Only one of these copy-of will be true, so we should only end up with the value we want.
                    
                    We must only use the first element in $descs_info aka the current context.
                    
                    $descs_info has the original file element which is any of several archival
                    classifications: fonds, file, series, etc. followoed by zero or more: places, subjects.

                    <file>
                    ...
                    </file>
                    <places>...</places>


                -->

                <xsl:variable name="auth_name">
                    <!-- The current context is a descs_info record, so we do not have a Names record as usual for $auth_name. -->
                    <xsl:copy-of select="(./*)[1]"/>
                </xsl:variable>

                <!--
                    Since these are descs_info records, there is no locn as with Names records. All these
                    dates should be active, so for now we'll just tell the date parser we are a family.
                    
                    This works, but seems only marginally robust. Normally tpt_normalized_date parses a date
                    range from a Names record, and uses the descs_info for alternate date parsing. We don't
                    want any alternate date parsing, but since the context is a descs, and we're sending the
                    context as alternate, it seems unlikely anything alternative can be parsed.
                -->
                <xsl:variable name="parsed_date">
                    <xsl:call-template name="tpt_normalized_date">
                        <xsl:with-param name="date_range" select="./*/DateRange"/>
                        <xsl:with-param name="descs_info" select="."/>
                        <xsl:with-param name="locn" select="''"/> <!-- No locn for archival records because they are not entities. -->
                        <xsl:with-param name="is_active" select="true()"/>
                        <xsl:with-param name="auth_name" select="$auth_name"/>
                    </xsl:call-template>
                </xsl:variable>

                <!-- <xsl:message> -->
                <!--     <xsl:text>tpt_radna pd: </xsl:text> -->
                <!--     <xsl:text>date_range: </xsl:text> -->
                <!--     <xsl:copy-of select=".//DateRange"/> -->
                <!--     <xsl:text> entity_type: </xsl:text> -->
                <!--     <xsl:copy-of select="$entity_type"/> -->
                <!--     <xsl:copy-of select="$parsed_date"/> -->
                <!--     <xsl:text>&#x0A;</xsl:text> -->
                <!-- </xsl:message> -->

                <!--
                    Remove trailing ", " with a regex replace() since parsed date range is often empty.
                    The two outer replace() calls change "active 1837- 1897" to "1837-1897". 
                -->
                <rel_entry>
                    <xsl:value-of select="replace(
                                          replace(
                                          replace(
                                          normalize-space(concat($rel_title, ', ', $parsed_date/eac:parsed_date_range))
                                          , ',\s*$', '')
                                          , 'active\s*', '')
                                          , '-\s*', '-')"/>
                </rel_entry>
                <object_xml>
                    <objectXMLWrap>
                        <did xmlns="urn:isbn:1-931666-22-9">
                            <unittitle>
                                <xsl:value-of select="$rel_title"/>
                            </unittitle>
                            <unitdate era="{./*/CreationDateEra}">
                                <!-- BL:<DateRange> whatever it is; no normalizing. -->
                                <xsl:value-of select="./*/DateRange"/>
                            </unitdate>
                            <origination></origination>
                            <physdesc>
                                <xsl:for-each select="./*/Extent">
                                    <extent>
                                        <xsl:value-of select="."/>
                                    </extent>	
                                </xsl:for-each>
                            </physdesc>
                            <repository>
                                <corpname>
                                    <!-- BL:Repository -->
                                    <xsl:value-of select="./*/Repository"/>
                                </corpname>
                            </repository>
                            <abstract>
                                <!-- BL:<ScopeContent><P> REPEATABLE if necessary, for each <P> in <ScopeContent> -->
                                <!--
                                    Copy the scope content info into the EAD namespace used by this objectXMLWrap.
                                -->
                                <xsl:apply-templates mode="copy-no-ns" select="$scope_content_norm">
                                    <xsl:with-param name="ns" select="'urn:isbn:1-931666-22-9'"/>
                                </xsl:apply-templates>
                            </abstract>
                            <langmaterial>
                                <xsl:for-each select="./*/MaterialLanguages/MaterialLanguage">
                                    <language langcode="{@LanguageIsoCode}">
                                        <xsl:value-of select="."/>
                                    </language>
                                </xsl:for-each>
                            </langmaterial>
                        </did>
                    </objectXMLWrap>
                </object_xml>
            </rrel>
        </xsl:if>
    </xsl:template> <!-- end tpt_radna -->

    <xsl:template name="tpt_descs_info">
        <xsl:param name="tid"/> <!-- target id -->
        <xsl:param name="rid"/> <!-- original record id -->
        <xsl:param name="cf"/> <!-- called from -->
        <xsl:param name="descs_file"/>
        <!--
            Some cpfs have no descs, so deal with it. Saxon gets upset when asked to open a file that is
            an empty string. Opening a non-existant file is a recoverable error, aka a warning.
            
            Error on line 1 column 1 of file:/lv1/home/twl8n/eac_project/british_library/:
            SXXP0003: Error reported by XML parser: Content is not allowed in prolog.
            Recoverable error on line 734 of bl2cpf.xsl:
            FODC0002: org.xml.sax.SAXParseException: Content is not allowed in prolog.
            
            There are no multi tid messages in the log, so apparently, there are none of these records. It
            that possible? Why is there code testing for multi tids?
        -->

        <xsl:choose>
            <xsl:when test="string-length($descs_file) > 0">
                <xsl:variable name="descs_info">
                    <xsl:copy-of select="document(concat('british_library/', $descs_file))/*"/>
                </xsl:variable>
                <xsl:if test="count($descs_info//RelatedArchiveDescriptionNamedAuthority[@TargetNumber = $tid]/RelationshipType) > 1">
                    <xsl:message>
                        <xsl:text>multi tid: </xsl:text>
                        
                        <xsl:value-of select="$tid"/>
                        <xsl:text>&#x0A;</xsl:text>
                        
                        <xsl:value-of select="$descs_file"/>
                        <xsl:text>&#x0A;</xsl:text>
                        
                        <xsl:value-of separator=", " select="$descs_info//RelatedArchiveDescriptionNamedAuthority[@TargetNumber = $tid]/RelationshipType"/>
                        <xsl:text>&#x0A;</xsl:text>
                    </xsl:message>
                </xsl:if>

                <xsl:copy-of select="$descs_info"/>

                <!--
                    Send the entire node list of all tid's to the template. This is probably a good practice
                    in general, but is necessary here because we have to de-dupe the list, and we want all
                    that code hidden inside the template.
                -->
                <!-- <xsl:message> -->
                <!--     <xsl:text>tlist: </xsl:text> -->
                <!--     <xsl:copy-of select="$descs_info//ArchiveDescriptionPlaceRelationships/RelatedArchiveDescriptionPlace/TargetRecordId"/> -->
                <!--     <xsl:text>&#x0A;</xsl:text> -->
                <!-- </xsl:message> -->

                <xsl:call-template name="tpt_places_info">
                    <xsl:with-param name="tid_list" select="$descs_info//ArchiveDescriptionPlaceRelationships/RelatedArchiveDescriptionPlace/TargetRecordId"/>
                    <xsl:with-param name="rid" select="$rid"/>
                </xsl:call-template>

                <xsl:for-each select="$descs_info//ArchiveDescriptionSubjectRelationships/RelatedArchiveDescriptionSubject/TargetRecordId">
                    <xsl:call-template name="tpt_subject_info">
                        <xsl:with-param name="tid" select="."/>
                        <xsl:with-param name="rid" select="$rid"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>Missing Descs tid: </xsl:text>
                    <xsl:value-of select="$tid"/>
                    <xsl:value-of select="concat(' rid: ', $rid, ' Called from: ', $cf)"/>
                    <!-- <xsl:text>&#x0A;</xsl:text> -->
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template> <!-- end tpt_descs_info -->

    <xsl:template name="tpt_places_info">
        <xsl:param name="tid_list"/>
        <xsl:param name="rid"/>
        <!-- 
             Might be worthwhile cacheing these, or just reading all of them into a variable for quick lookup. 
             There are less than 20,000 of them. 
        -->

        <!-- 
        <Place RecordID="048-000000005">
          <Repository RepositoryId="10" CountryId="10">British Library</Repository>
          <ScriptName ScriptId="28" ScriptIsoCode="Latn">Latin</ScriptName>
          <LanguageName LanguageId="21" LanguageIsoCode="eng">English</LanguageName>
          <Name>Bengal</Name>
          <Longitude/>
          <Latitude/>
          <CivilParish/>
          <LocalAdminUnit/>
          <WiderAdminUnit/>
          <Country>Asia</Country>
          <DateRange/>
          <StartDate/>
          <EndDate/>
          <Sources/>

        <Place RecordID="048-001628962">
          <Repository RepositoryId="10" CountryId="10">British Library</Repository>
          <ScriptName ScriptId="28" ScriptIsoCode="Latn">Latin</ScriptName>
          <LanguageName LanguageId="21" LanguageIsoCode="eng">English</LanguageName>
          <Name>Aix</Name>
          <Longitude/>
          <Latitude/>
          <CivilParish/>
          <LocalAdminUnit>Charente Inf&#xE9;rieure</LocalAdminUnit>
          <WiderAdminUnit/>
          <Country>France</Country>
          <DateRange>Unspecified</DateRange>
          <StartDate>-9999</StartDate>
          <EndDate>-9999</EndDate>
          <Sources/>
        -->

        <xsl:variable name="raw_places">
            <xsl:for-each select="$tid_list">
                <xsl:variable name="tid" select="."/>
                <xsl:variable name="places_file">
                    <xsl:for-each select="$file_target">
                        <xsl:value-of select="key('ft_key', $tid)"/>
                    </xsl:for-each>
                </xsl:variable>

                <xsl:if test="string-length($places_file) > 0">
                    <xsl:variable name="place_info">
                        <xsl:copy-of select="document(concat('british_library/', $places_file))/*"/>
                    </xsl:variable>
                    <place localType="{$av_associatedPlace}">
                        <placeEntry>
                            <!-- I grep'd all the place entries, and there are no empty Name elements. -->
                            <xsl:value-of select="$place_info/Place/Name"/>
                            <xsl:if test="$place_info/Place/CivilParish/text()">
                                <xsl:value-of select="concat(', ', $place_info/Place/CivilParish)"/>
                                <!-- <xsl:message> -->
                                <!--     <xsl:text>cpa: (</xsl:text> -->
                                <!--     <xsl:value-of select="$rid"/> -->
                                <!--     <xsl:text>):</xsl:text> -->
                                <!--     <xsl:copy-of select="$place_info/Place/CivilParish"/> -->
                                <!--     <xsl:text>&#x0A;</xsl:text> -->
                                <!-- </xsl:message> -->
                            </xsl:if>
                            <xsl:if test="$place_info/Place/LocalAdminUnit/text()">
                                <xsl:value-of select="concat(', ', $place_info/Place/LocalAdminUnit)"/>
                                <!-- <xsl:message> -->
                                <!--     <xsl:text>lau: (</xsl:text> -->
                                <!--     <xsl:value-of select="$rid"/> -->
                                <!--     <xsl:text>):</xsl:text> -->
                                <!--     <xsl:copy-of select="$place_info/Place/LocalAdminUnit"/> -->
                                <!--     <xsl:text>&#x0A;</xsl:text> -->
                                <!-- </xsl:message> -->
                            </xsl:if>
                            <xsl:if test="$place_info/Place/WiderAdminUnit/text()">
                                <xsl:value-of select="concat(', ', $place_info/Place/WiderAdminUnit)"/>
                                <!-- <xsl:message> -->
                                <!--     <xsl:text>wau: (</xsl:text> -->
                                <!--     <xsl:value-of select="$rid"/> -->
                                <!--     <xsl:text>):</xsl:text> -->
                                <!--     <xsl:copy-of select="$place_info/Place/WiderAdminUnit"/> -->
                                <!--     <xsl:text>&#x0A;</xsl:text> -->
                                <!-- </xsl:message> -->
                            </xsl:if>
                            <xsl:if test="$place_info/Place/Country/text()">
                                <xsl:value-of select="concat(', ', $place_info/Place/Country)"/>
                                <!-- <xsl:message> -->
                                <!--     <xsl:text>cou: (</xsl:text> -->
                                <!--     <xsl:value-of select="$rid"/> -->
                                <!--     <xsl:text>):</xsl:text> -->
                                <!--     <xsl:copy-of select="$place_info/Place/Country"/> -->
                                <!--     <xsl:text>&#x0A;</xsl:text> -->
                                <!-- </xsl:message> -->
                            </xsl:if>
                        </placeEntry>
                    </place>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        <!--
            De-duping in 6 lines. This is explained in a long comment near the end of template tpt_geo
            in lib.xsl.
        -->
        <xsl:for-each select="$raw_places/eac:place[string-length(eac:placeEntry) > 0]">
            <xsl:variable name="curr" select="."/>
            <xsl:choose>
            <xsl:when test="not(preceding::eac:placeEntry[lib:pname-match(text(),  $curr/eac:placeEntry)])">
                <xsl:copy-of select="$curr" />
            </xsl:when>
            <xsl:otherwise>
                <!-- <xsl:message> -->
                <!--     <xsl:value-of select="concat('(', position(), ') ')"/> -->
                <!--     <xsl:text>dup-place (</xsl:text> -->
                <!--     <xsl:value-of select="$rid"/> -->
                <!--     <xsl:text>):</xsl:text> -->
                <!--     <xsl:copy-of select="$curr"/> -->
                <!--     <xsl:text>&#x0A;</xsl:text> -->
                <!-- </xsl:message> -->
            </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="tpt_subject_info">
        <xsl:param name="tid"/>
        <xsl:param name="rid"/>
        <!-- 
             Might be worthwhile cacheing these, or just reading all of them into a variable for quick lookup. 
             There are less than 20,000 of them. 

             <Subject RecordID="049-001001159">
               <ArchiveDescriptionSubjectRelationships>
                   ...
               </ArchiveDescriptionSubjectRelationships>
               <SubjectRelationships/>
               <Repository RepositoryId="10" CountryId="10">British Library</Repository>
               <Type SubjectTypeId="12">Term</Type>
               <Entry>Sufism</Entry>
               <Authority SubjectAuthorityId="11">LC/NACO</Authority>
               <IsPreferred>Preferred</IsPreferred>
               <MDARK>ark:/81055/vdc_100000000058.0x0000c8</MDARK>
               <LARK/>
             </Subject>
             
             There are only 3 values for Type:
             
             <Type SubjectTypeId="11">Event</Type>
             <Type SubjectTypeId="12">Term</Type>
             <Type SubjectTypeId="13">Title of Work</Type>
        -->

            <xsl:variable name="x_file">
                <xsl:for-each select="$file_target">
                    <xsl:value-of select="key('ft_key', $tid)"/>
                </xsl:for-each>
            </xsl:variable>

            <xsl:if test="string-length($x_file) > 0">
                <xsl:variable name="x_info">
                    <xsl:copy-of select="document(concat('british_library/', $x_file))/*"/>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="$x_info/Subject[Type = 'Title of Work']">
                        <!-- Do nothing. -->
                    </xsl:when>
                    <xsl:otherwise>
                        <localDescription localType="{$av_associatedSubject}">
                            <term>
                                <xsl:value-of select="normalize-space($x_info/Subject/Entry/text())"/>
                            </term>
                        </localDescription>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
    </xsl:template>

    <xsl:template name="tpt_a_form">
        <xsl:param name="type"/>
        <!-- 
             Possible values. I think as far as CPF is concerned anything not 'Authorised' is 'alternativeForm'.

             <NameType>Alternative</NameType>
             <NameType>Authorised</NameType>
             <NameType>Other</NameType>
             <NameType>Parallel</NameType>
        -->
        <xsl:choose>
            <xsl:when test="$type = 'Authorised'">
                <xsl:value-of select="'authorizedForm'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'alternativeForm'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:function name="bl:split-reltype">
        <xsl:param name="arg"/>
        <!-- 
             Tokens are "; " or end of string. Return a sequence of strings. Do we need to put the returned
             sequence into elements to make a node set?
        -->
        <xsl:analyze-string select="$arg"
                            regex="(.+?)(;\s*|$)">
            <xsl:matching-substring>
                <xsl:value-of select="regex-group(1)"/>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:function>

    <xsl:template name="tpt_normalized_date">
        <xsl:param name="date_range"/>
        <xsl:param name="descs_info"/>
        <xsl:param name="locn"/>
        <xsl:param name="auth_name"/>
        <xsl:param name="is_active" select="false()"/>
        
        <!-- <xsl:message> -->
        <!--     <xsl:text>tnd locn: </xsl:text> -->
        <!--     <xsl:copy-of select="$locn"/> -->
        <!--     <xsl:text> date_range: </xsl:text> -->
        <!--     <xsl:copy-of select="$date_range"/> -->
        <!--     <xsl:text>&#x0A;</xsl:text> -->
        <!-- </xsl:message> -->

        <!--
            Descs records are archival records, not corp, family, or person. However, for our purposes, they
            are most like corp and family.
        -->
        
        <xsl:variable name="norm_date">
            <xsl:choose>
                <xsl:when test="$locn = $corp_val or $locn = $fami_val or $locn = ''">
                    <xsl:variable name="parsed_date">
                        <xsl:for-each select="$auth_name/*"> <!-- one value only, set context -->
                            <xsl:call-template name="tpt_bl_date">
                                <!-- use family entity_type for corp -->
                                <xsl:with-param name="entity_type" select="$locn"/>
                                <xsl:with-param name="date_range" select="$date_range"/>
                                <xsl:with-param name="allow_single" select="false()" />
                                <xsl:with-param name="is_active" select="true()"/> <!-- always true for corp and fami -->
                                <xsl:with-param name="descs_info">
                                    <xsl:copy-of select="$descs_info"/>
                                </xsl:with-param>
                            </xsl:call-template>
                        </xsl:for-each>
                    </xsl:variable>

                    <xsl:variable name="parsed_date_range">
                        <xsl:variable name="pd_temp">
                            <!--
                                Corporation and Family dates are always active, so remove the word "active " which
                                is (in some sense) redundant.  We will only have one of existDates/date or
                                existDates/dateRange, so no need for an if statement.
                                
                                Q: Don't these need min() and max() because $parsed_date may contain multiple dates?
                                A: No, because the for-each above is context setting only. There is only one $auth_name.
                            -->
                            <xsl:value-of select="replace($parsed_date/eac:existDates/eac:date[@localType=$av_active], 'active ', '')"/>
                            <xsl:value-of select="replace(
                                                  $parsed_date/eac:existDates/eac:dateRange/eac:fromDate[@localType=$av_active],
                                                  'active\s*', '')"/>
                            <xsl:text>-</xsl:text>
                            <xsl:value-of select="replace(
                                                  $parsed_date/eac:existDates/eac:dateRange/eac:toDate[@localType=$av_active],
                                                  'active\s*', '')"/>
                        </xsl:variable>
                        <xsl:value-of select="replace($pd_temp, '-$', '')"/>
                    </xsl:variable>
                    
                    <!-- <xsl:message> -->
                    <!--     <xsl:text>tpt_norm corp/fami pdr: </xsl:text> -->
                    <!--     <xsl:copy-of select="$parsed_date_range"/> -->
                    <!--     <xsl:text>&#x0A;</xsl:text> -->
                    <!-- </xsl:message> -->
                    
                    <!-- the existDates CPF element -->
                    <xsl:copy-of select="$parsed_date/eac:existDates"/>
                    <parsed_date_range>
                        <xsl:value-of select="$parsed_date_range"/>
                    </parsed_date_range>

                </xsl:when>

                <xsl:when test="$locn = $pers_val">
                    <xsl:variable name="parsed_date">
                        <xsl:for-each select="$auth_name/*">
                            <xsl:call-template name="tpt_bl_date">
                                <xsl:with-param name="entity_type" select="$locn"/>
                                <xsl:with-param name="date_range" select="DateRange"/>
                                <xsl:with-param name="allow_single" select="false()" />
                                <xsl:with-param name="descs_info">
                                    <xsl:copy-of select="$descs_info"/>
                                </xsl:with-param>
                                <xsl:with-param name="is_active" select="$is_active"/>
                            </xsl:call-template>
                        </xsl:for-each>
                    </xsl:variable>
                    
                    <xsl:variable name="parsed_date_range">
                        <xsl:variable name="pd_temp">
                            <!--
                                Start using the word "active" in the date that is part of the cpf name
                                entry. Corporations and Families do use active, and at least for British Library,
                                we are adding active date to the name, but only for Corporations and Families.
                                
                                We use the value-of both eac:date and eac:fromDate because only one will have a value.
                                
                                Don't allow "active" before the toDate. This assumes that active is always a date
                                range or a single date, and that a "active" date is never only a toDate (like a
                                death date that is active).
                                
                                Allow a trailing hyphen when we have a birth date, otherwise remove it.
                            -->
                            <xsl:value-of select="$parsed_date/eac:existDates/eac:date"/>
                            <xsl:value-of select="$parsed_date/eac:existDates/eac:dateRange/eac:fromDate"/>
                            <xsl:text>-</xsl:text>
                            <xsl:value-of select="replace($parsed_date/eac:existDates/eac:dateRange/eac:toDate, 'active', '')"/>
                        </xsl:variable>

                        <xsl:choose>
                            <xsl:when test="$parsed_date/eac:existDates/eac:dateRange/eac:fromDate/@localType = $av_born">
                                <xsl:value-of select="$pd_temp"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="replace($pd_temp, '-$', '')"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>

                    <!-- <xsl:message> -->
                    <!--     <xsl:text>tpt_norm pers pd: </xsl:text> -->
                    <!--     <xsl:copy-of select="$parsed_date"/> -->
                    <!--     <xsl:text>&#x0A;</xsl:text> -->
                    <!--     <xsl:text>tpt_norm pers pdr: </xsl:text> -->
                    <!--     <xsl:copy-of select="$parsed_date_range"/> -->
                    <!--     <xsl:text>&#x0A;</xsl:text> -->
                    <!-- </xsl:message> -->

                    <!--
                        The existDates CPF element and <parsed_date_range>. We do not have a parsed_date_range if the date is suspicious.
                    -->
                    <xsl:copy-of select="$parsed_date/eac:existDates"/>
                    <parsed_date_range>
                        <xsl:if test="count($parsed_date//*[@localType = $av_suspiciousDate]) = 0">
                            <xsl:value-of select="$parsed_date_range"/>
                        </xsl:if>
                    </parsed_date_range>
                </xsl:when>
            </xsl:choose>
        </xsl:variable><!-- end norm_date -->
        <xsl:if test="count($norm_date//*[matches(., 'unspecified', 'i')]) = 0">
            <xsl:copy-of select="$norm_date"/>
        </xsl:if>
    </xsl:template><!-- end tpt_normalized_date -->

    <xsl:template name="tpt_name_extras">
        <xsl:param name="record_id"/>
        <xsl:for-each select=".//PersonName[NameType = 'Authorised']">
            <xsl:for-each select="./Epithet[string-length() > 0] ">
                <p>
                    <xsl:value-of select="concat('Epithet: ', .)"/>
                </p>
            </xsl:for-each>
            <xsl:for-each select="./Title[string-length() > 0]">
                <p>
                    <xsl:value-of select="concat('Title: ', .)"/>
                </p>
            </xsl:for-each>
        </xsl:for-each>
        <xsl:for-each select=".//FamilyName[NameType = 'Authorised']">
            <xsl:for-each select="./TitleOccupation[string-length() > 0] ">
                <p>
                    <xsl:value-of select="concat('TitleOccupation: ', .)"/>
                </p>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>

</xsl:stylesheet>
