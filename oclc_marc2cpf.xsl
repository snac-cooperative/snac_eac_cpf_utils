<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="2.0"
                xmlns:marc="http://www.loc.gov/MARC21/slim"
                xmlns:date="http://exslt.org/dates-and-times"
                extension-element-prefixes="date"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:functx="http://www.functx.com"
                xmlns:lib="http://example.com/"
                xmlns:eac="urn:isbn:1-931666-33-4"
                xmlns="urn:isbn:1-931666-33-4"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:saxon="http://saxon.sf.net/"
                exclude-result-prefixes="xsl date xs functx marc lib eac saxon xlink"
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
    -->

    <!--
        In practice, this file is never directly run. See exec_record.pl which reads a configuration file, and
        appropriately runs this xslt script.
        
        ./exec_record.pl config=all_eac.cfg &
        ./exec_record.pl config=config_files/foo_all.cfg &

        oclc_marc2cpf.xsl creates EAC-CPF from MARC21/slim XML. Has some special cases for MARC from the LDS.
        
        saxon.sh marc.xml oclc_marc2cpf.xsl
        
        This script can be called directly, but is normally called via exec_record.pl using one of the
        configuration files to determine the various run-time parameters.

        For large batches of records, it relies one either of 2 small Perl scripts to turn the WorldCat XML
        into well-formed XML, and more importantly a chunk of well-formed MARC records. The following will
        write the results of the first 40 records into a directory ./devx_1/.
        
        get_record.pl file=snac.xml offset=1 limit=40 | saxon.sh -s:- oclc_marc2cpf.xsl chunk_prefix=devx output_dir=. 2>&1
        
        It is recommended that you use exec_record.pl for real work. It is more efficient, and uses a
        configuration file which allows better historical tracking of how data was transformed or generated.
        
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
        
        variable $cr declared in lib.xsl
    -->

    <!--
        Odd. '&apos;' does not work, although some web sites give that as an example.
        '''' is too weird to read, so I went with the define a var solution.
    -->
    <xsl:variable name="apos">'</xsl:variable>

    <xsl:param name="debug" select="false()"/>

    <xsl:param name="output_dir" select="'./cpf'"/>
    <xsl:param name="fallback_default" select="'US-SNAC'"/>
    <xsl:param name="auth_form" select="'WorldCat'"/>
    <xsl:param name="inc_orig" select="true()"  as="xs:boolean"/>
    <xsl:param name="archive_name" select="'WorldCat'"/>

    <!-- These three params (variables) are passed to the cpf template eac_cpf.xsl via params to tpt_body. -->

    <xsl:param name="ev_desc" select="'Derived from MARC'"/> <!-- eventDescription -->
    <!--
        xlink:role The $av_ variables are in lib.xsl.
        
        Note: All (except maybe the original OCLC WorldCat) should use $param_data/eac:rrel or
        $param_data/eac:use_rrel with $param_data/eac:rr_xlink_href.

        Note: these variable names should reflect the different usages cpfRelation/@xlink:role and
        resourceRelation/@xlink:role. There have been bugs related to mixing these up.
        
        It appears that both of the vars rr_xlink_role and rr_xlink_href are used by resourceRelation.
        
        Also note: rr_xlink_href is not / terminated. We add the / and record ID in eac_cpf.xsl. tag: xlink:href

    -->
    <xsl:param name="rr_xlink_role" select="$av_archivalResource"/> 
    <xsl:param name="rr_xlink_href" select="'http://www.worldcat.org/oclc'"/> 

    <xsl:include href="eac_cpf.xsl"/>
    <xsl:include href="lib.xsl"/>
    <xsl:output name="xml" method="xml" indent="yes" omit-xml-declaration="no"/>
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

    <xsl:variable name="xslt_script" select="'oclc_marc2cpf.xsl'"/>
    <xsl:variable name="xslt_version" select="system-property('xsl:version')" />
    <xsl:variable name="xslt_vendor" select="system-property('xsl:vendor')" />
    <xsl:variable name="xslt_vendor_url" select="system-property('xsl:vendor-url')" />

    <!-- 
         Invoke tpt_match_record via a call-template from a match on <record> only when there is a single 1xx. Only called
         for 100, 110, 111. All templates have a canonical name or mode.
         
         The method used here can serve as an example for other "only match on single/multi" cases. This is similar but
         not identical to try_multi_1xx.xsl.

         position() works sort-of but some (many) numbers are skipped due since we filter out multi-1xx records.
    -->
    
    <xsl:template name="tpt_match_record">
        <xsl:param name="xx_tag"/>

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
                <xsl:when test="string-length(normalize-space(marc:controlfield[@tag='001']))>0">
                    <xsl:value-of select="normalize-space(marc:controlfield[@tag='001'])"/>
                    <xsl:message>
                        <xsl:text>001 ok: </xsl:text>
                        <xsl:value-of select="marc:controlfield[@tag='001']"/>
                    </xsl:message>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('missing001_', position())"/>
                    <xsl:message>
                        <xsl:text>001 missing: </xsl:text>
                        <xsl:value-of select="concat('pos: ', position(), $cr)"/>
                        <xsl:for-each select="marc:controlfield">
                            <xsl:value-of select="concat('cf: ', ., ' tag: ', ./@tag)"/>
                        </xsl:for-each>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:if test="count(marc:datafield[@tag='555']/marc:subfield[@code='u']) > 1">
            <xsl:message>
                <xsl:text>multiple urls: </xsl:text>
                <xsl:copy-of select="marc:datafield[@tag='555']/marc:subfield[@code='u']"/>
            </xsl:message>
        </xsl:if>

        <!--
            Only use the first URL. Unclear why there would be multiple. Logging above will answer that.
        -->
        <xsl:variable name="rr_href">
            <xsl:choose>
                <xsl:when test="$auth_form='lds' and string-length(marc:datafield[@tag='555'][1]/marc:subfield[@code='u']) > 0">
                    <xsl:value-of select="normalize-space(marc:datafield[@tag='555'][1]/marc:subfield[@code='u'])"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="agency_info">
            <!--
                See tpt_agency_info in lib.xsl. Unknowns default to agencyCode $fallback_default.
            -->
            <xsl:call-template name="tpt_agency_info"/>
        </xsl:variable>

        <xsl:variable name="record_id"
                      select="concat($agency_info/eac:agencyCode,'-', $controlfield_001)"/>

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

        <xsl:variable name="name_entry">
            <!-- 
                 Interestingly, I don't think this is used. It may be a historical artifact. All the entities
                 are in the $all_xx variable as a node list where each node has all the entity info necessary
                 to fill in the CPF template.

                 The context here is <record>, but tpt_name_entry wants to be called with the single 1xx marc:datafield
                 as context. Applying templates here without a select results in a log of extra (wrong) data in the name
                 entry.
                 
                 Use an intermediate temporary variable so we can normalize it. I can't see any other obvious way to
                 normalize the results of apply-templates. Normalizing now is better for any uses of the variable later.
            -->
            <xsl:variable name="ne_temp">
                <xsl:apply-templates mode="tpt_name_entry" select="marc:datafield[@tag = $xx_tag]">
                    <xsl:with-param name="xx_tag" select="$xx_tag"/>
                    <xsl:with-param name="record_position" select="$record_position"/>
                    <xsl:with-param name="record_id" select="$record_id"/>
                </xsl:apply-templates>
            </xsl:variable>
            <!-- normalize space and remove trailing puncutation. -->
            <xsl:value-of select="lib:norm-punct($ne_temp)"/>
        </xsl:variable>

        <xsl:variable name="entity_type">
            <!--
                This template invokes tpt_entity_type template below. Use a specific node match and we won't need
                matches elsewhere to catch other marc:datafield and marc:subfield nodes.
                
                The returned values are not for use in cpf identities. The values are only for use internally
                for things like etype and entity type comparisons (conditionals, if, when, test).
            -->
            <xsl:call-template name="tpt_entity_type">
                <xsl:with-param name="df">
                    <xsl:copy-of select="marc:datafield[@tag=$xx_tag]"/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="t167_tens">
            <xsl:call-template name="tpt_tens">
                <xsl:with-param name="xx_tag" select="$xx_tag"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="local_affiliation">
            <xsl:variable name="u_value">
                <xsl:value-of select="marc:datafield[@tag=$xx_tag]/marc:subfield[@code = 'u']"/>
            </xsl:variable>
            <xsl:if test="boolean($u_value)">
                <xsl:if test="$t167_tens = '10'">
                    <localDescription localType="affiliationOrAddress">
                        <term><xsl:value-of select="lib:norm-punct($u_value)"/></term>
                    </localDescription>
                </xsl:if>
                <xsl:if test="$t167_tens = '11'  or $t167_tens = '00'">
                    <localDescription localType="affiliation">
                        <term><xsl:value-of select="lib:norm-punct($u_value)"/></term>
                    </localDescription>
                </xsl:if>
            </xsl:if>
        </xsl:variable>

        <xsl:variable name="tag_545">
            <!-- biogHist, see lib.xsl -->
            <xsl:call-template name="tpt_tag_545"/>
        </xsl:variable>

        <!--
            Later we'll add the [167]xx as a prefix to tag_245 for resourceRelation/relationEntry.
        -->
        <xsl:variable name="tag_245">
            <xsl:for-each select="marc:datafield[@tag='245']/marc:subfield">
                <xsl:if test="not(position() = 1)">
                    <xsl:text> </xsl:text>
                </xsl:if>
                <xsl:value-of select="."/>
            </xsl:for-each>
        </xsl:variable>

        <!--
            authorizedForm has been replaced by $rules.
        -->
        
        <xsl:variable name="topical_subject">
            <xsl:call-template name="tpt_topical_subject">
                <xsl:with-param name="record_position" select="$record_position"/>
                <xsl:with-param name="record_id" select="$record_id"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:if test="$debug">
            <xsl:message>
                <xsl:text>topsubj: </xsl:text>
                <xsl:copy-of select="$topical_subject" />
                <xsl:text>&#x0A;</xsl:text>
            </xsl:message>
        </xsl:if>

        <xsl:variable name="geographic_subject">
            <xsl:call-template name="tpt_geo"/>
        </xsl:variable>

        <xsl:if test="$debug">
            <xsl:message>
                <xsl:text>geosubj: </xsl:text>
                <xsl:copy-of select="$geographic_subject" />
                <xsl:text>&#x0A;</xsl:text>
            </xsl:message>
        </xsl:if>

        <xsl:variable name="all_xx">
            <!--
                Either of these works to pass in the initial empty node set, but the second statement seems
                more obvious. It is critical to pass in a node set. Not specifying the data type defaults to
                some string-ish data type which fails with an error when used with xpath outside boolean().
                
                <xsl:with-param name="curr" select="/.."/>
                <xsl:with-param name="curr" as="node()*"/>
            -->

            <xsl:variable name="creator_info">
                <!-- 
                     Used for non-1xx records. If a 7xx exists, then use it as a resourceRelation arcrole
                     creatorOf. Force the namespace of this node set to be marc: since this is essentially input
                     (MARC) and not output (EAC). This gets messy in tpt_all_xx where there can be non-7xx
                     duplicate names. Changing the de-duplicating code would require a full rewrite of
                     tpt_all_xx, so when there is a matching 7xx, I just mark the first occurance (whether 6xx
                     or 7xx) as is_creator, no matter what the tag value.
                -->
                <xsl:choose>
                    <xsl:when test="marc:datafield[(@tag='700' or @tag='710' or @tag='711') and marc:subfield[@code='a']][1]">
                        <is_creator xmlns="http://www.loc.gov/MARC21/slim"><xsl:value-of select="true()"/></is_creator>
                        <creator_name xmlns="http://www.loc.gov/MARC21/slim">
                            <xsl:for-each select="marc:datafield[@tag='700' or @tag='710' or @tag='711'][1]">
                                <xsl:call-template name="tpt_name_entry">
                                    <xsl:with-param name="xx_tag" select="@tag"/>
                                    <xsl:with-param name="record_position" select="$record_position"/>
                                    <xsl:with-param name="record_id" select="$record_id"/>
                                </xsl:call-template>
                            </xsl:for-each>
                        </creator_name>
                    </xsl:when>
                    <xsl:otherwise>
                        <is_creator xmlns="http://www.loc.gov/MARC21/slim"><xsl:value-of select="false()"/></is_creator>
                        <creator_name xmlns="http://www.loc.gov/MARC21/slim"></creator_name>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            
            <xsl:call-template name="tpt_all_xx">
                <xsl:with-param name="record_id" select="$record_id"/>
                <xsl:with-param name="index" select="1"/>
                <xsl:with-param name="tag" select="$xx_tag"/>
                <xsl:with-param name="curr" as="node()*"/>
                <xsl:with-param name="unique_count" select="1" as="xs:integer"/>
                <xsl:with-param name="record_position" select="$record_position"/>
                <xsl:with-param name="creator_info" select="$creator_info"/>
            </xsl:call-template>
        </xsl:variable>
        
        <!--
            control/languageDeclaration. I'm pretty sure there is only a single
            040$b per record, but for-each sets the context, so that is
            good. When we have an 040$b, use it, otherwise default to English.
        -->
        <xsl:variable name="lang_decl">
            <xsl:call-template name="tpt_lang_decl"/>
        </xsl:variable>
        
        <xsl:variable name="language">
            <!--
                This is the description/languageUsed and reads the 041$a. See tpt_language in lib.xsl.
            -->
            <xsl:call-template name="tpt_language"/>
        </xsl:variable>

        <xsl:variable name="original">
            <xsl:copy-of select="."/>
        </xsl:variable>
        
        <!-- leader character numbering is zero based, although xslt substring is one based. -->
        <!-- <leader>00000cpcaa  00000La     </leader> -->
        <!-- marc    012345678901234567890123 -->
        <!-- xstl    123456789012345678901234 -->
        
	<xsl:variable name="status">
	    <xsl:value-of select="substring(marc:leader,6,1)"/>
	</xsl:variable>

        <xsl:variable name="leader06">
            <xsl:value-of select="substring(marc:leader, 7, 1)"/>
        </xsl:variable>
        <xsl:variable name="leader07">
            <xsl:value-of select="substring(marc:leader, 8, 1)"/>
        </xsl:variable>
        <xsl:variable name="leader08">
            <xsl:value-of select="substring(marc:leader, 9, 1)"/>
        </xsl:variable>

	<xsl:variable name="rules">
            <!-- 
                 See lib.xsl. It uses substring(marc:controlfield[@tag='008'],11,1).
            -->
            <xsl:call-template name="tpt_rules"/>
	</xsl:variable>

        <!-- <xsl:message> -->
        <!--     <xsl:text>all_xx: </xsl:text> -->
        <!--     <xsl:copy-of select="$all_xx" /> -->
        <!--     <xsl:text>&#x0A;</xsl:text> -->
        <!-- </xsl:message> -->
        
        <xsl:variable name="is_1xx" as="xs:boolean">
            <!--
                Are we a 1xx record or not 1xx (aka not_1xx)?
            -->
            <xsl:value-of select="boolean($xx_tag='100' or $xx_tag='110' or $xx_tag='111')"/>
        </xsl:variable>


        <xsl:variable name="mods">
            <!-- See lib.xsl -->
            <xsl:call-template name="tpt_mods">
                <xsl:with-param name="all_xx" select="$all_xx"/>
                <xsl:with-param name="agency_info" select="$agency_info"/>
                <xsl:with-param name="controlfield_001" select="$controlfield_001"/>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:variable name="rel_entry">
            <!-- 
                 Rather than checking $is_1xx which would be sort of pointless, just get the 1xx
                 from $all_xx if one exists, else get the first 7xx from $all_xx, else
                 nothing. Since we can't modify variables, we will just have to create 2 temporary
                 variables so we can be sure of not trying to output something that doesn't exist,
                 or add extra '.'. Since this field is human readable, we are including punctuation
                 which is a trailing dot at the end of the name, except when the name is empty. It
                 is possible for this $rel_entry to be '' (empty string) after all this, but I'm
                 pretty sure every record has a tag 245.
            -->
            
            <xsl:variable name="temp_name">
                <xsl:choose>
                    <xsl:when test="$all_xx/eac:container[matches(eac:e_name/@tag, '1(00|10|11)')][1]">
                        <xsl:value-of select="$all_xx/eac:container[matches(eac:e_name/@tag, '1(00|10|11)')][1]/eac:e_name"/>
                    </xsl:when>
                    <xsl:when test="boolean($all_xx/eac:container[matches(eac:e_name/@tag, '7(00|10|11)')][1])">
                        <xsl:value-of select="$all_xx/eac:container[matches(eac:e_name/@tag, '7(00|10|11)')][1]/eac:e_name"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text></xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <!--
                Error message: Cast does not allow an empty sequence

                Known bug. The optimizer calculates the static cardinality of an xsl:if instruction
                incorrectly, discounting the possibility that it may return an empty
                sequence. http://sourceforge.net/p/saxon/bugs/674/
                
                Happened in the xsl:if in xsl:variable trailing_dot below. The workaround seems to
                be to access the variable in question with copy-of. That seems to prevent the error
                from occuring. value-of doesn't prevent the problem, and simply using the variable
                in a concat() was no good. Oddly, alternate forms of the xsl:if test="" didn't
                provide a workaround.
            -->
            <xsl:variable name="trailing_dot">
                <xsl:if test="string-length($temp_name)>0 and not(matches($temp_name, '\.$'))">
                    <xsl:text>.</xsl:text>
                </xsl:if>
            </xsl:variable>

            <xsl:variable name="bug_workaround">
                <xsl:copy-of select="$trailing_dot"/>
            </xsl:variable>

            <xsl:value-of select="normalize-space(concat($temp_name, $trailing_dot, ' ', $tag_245))"/>
        </xsl:variable> <!-- end rel_entry -->
        
        <xsl:variable name="citation">
            <!--
                See tpt_mods in lib.xml. The agency name will be (Unknown) if we can't look up the MARC agency
                code, or if there are multiple entries in the WorldCat registry for a given MARC agency code
                such as "CSt-H".
            -->
            <xsl:variable name="title">
                <xsl:for-each select="marc:datafield[@tag = '245']/marc:subfield[not(@code = '6') and not(@code = '8')]">
                    <xsl:if test="not(position() = 1)">
                        <xsl:text> </xsl:text>
                    </xsl:if>
                    <xsl:value-of select="."/>
                </xsl:for-each>
                <xsl:if
                    test="boolean(marc:datafield[@tag = '260']/marc:subfield[@code = 'c']) and
                          boolean(marc:datafield[@tag = '245']/marc:subfield[not(@code = 'f') and not(@code = 'g')])">
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="marc:datafield[@tag = '260']/marc:subfield[@code = 'c']"/>
                </xsl:if>
            </xsl:variable>

            <xsl:choose>
                <xsl:when test="$auth_form='lds'">
                    <citation>
                        <xsl:value-of select="concat('From the guide to the ',
                                              marc:datafield[@tag='090']/marc:subfield[@code='a'],
                                              ' ', 
                                              $title,
                                              ' ',
                                              '(Church of Jesus Christ of Latter-Day Saints, Church History Library)')"/>
                    </citation>
                </xsl:when>
                <xsl:otherwise>
                    <citation>
                        <xsl:text>From the description of </xsl:text>
                        <xsl:value-of select="$title"/>
                        <xsl:text> (</xsl:text>
                        <xsl:value-of select="$agency_info/eac:agencyName"/>
                        <xsl:value-of select="concat('). ', $archive_name, ' record id: ')"/>
                        <xsl:value-of select="$controlfield_001"/>
                    </citation>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!--
            tc_data to be consistent with usage inside tpt_container. SNAC is the maintenanceAgency for the CPF data.
            
            This is not the same as the maintenanceAgency of the data that the CPF was extracted from.
            
            As far as I can tell, this data gets passed down the template chain, and eventually ends up deep
            in the code where the final call to result-document() lives. We can put things here we want to go
            all the way to the final template. The "tc" refers to data that goes into tpt_container, which is
            a container for each of the entites in the original data, along with necessary meta data.
        -->
        <xsl:variable name="tc_data">
            <snac_info>
                <xsl:call-template name="tpt_snac_info"/>
            </snac_info>
            <agency_info>
                <xsl:copy-of select="$agency_info"/>
            </agency_info>
            <xsl:copy-of select="$citation"/>
            <rr_href>
                <xsl:value-of select="$rr_href"/>
            </rr_href>
            <auth_form>
                <xsl:value-of select="$auth_form"/>
            </auth_form>
        </xsl:variable>

        <xsl:apply-templates select="$all_xx/eac:container">
            <!--
                See tpt_container below. Important to select $all_xx/container so that we only operate on /container
                elements, otherwise XSLT tries to apply to //e_name as well. That makes a mess of the position() inside
                tpt_container.
            -->
            <xsl:with-param name="tc_data" select="$tc_data"/>
            <xsl:with-param name="rel_entry" select="$rel_entry"/>
            <xsl:with-param name="is_1xx" select="$is_1xx"/>
            <xsl:with-param name="name_entry" select="$name_entry"/>
            <xsl:with-param name="mods" select="$mods"/>
            <xsl:with-param name="leader06" select="$leader06"/>
            <xsl:with-param name="leader07" select="$leader07"/>
            <xsl:with-param name="leader08" select="$leader08"/>
            <xsl:with-param name="local_affiliation" select="$local_affiliation"/>
            <xsl:with-param name="controlfield_001" select="$controlfield_001"/>
            <xsl:with-param name="all_xx" select="$all_xx" />
            <xsl:with-param name="chunk_dir" select="$chunk_dir" />
            <xsl:with-param name="record_id" select="$record_id" />
            <xsl:with-param name="date" select="$date" />
            <xsl:with-param name="xslt_vendor" select="$xslt_vendor"/>
            <xsl:with-param name="xslt_version" select="$xslt_version"/>
            <xsl:with-param name="xslt_vendor_url" select="$xslt_vendor_url"/>
            <xsl:with-param name="tag_545" select="$tag_545"/>
            <xsl:with-param name="tag_245" select="normalize-space($tag_245)"/>
            <xsl:with-param name="xslt_script" select="$xslt_script"/>
            <xsl:with-param name="original" select="$original"/>
            <xsl:with-param name="lang_decl" select="$lang_decl"/>
            <xsl:with-param name="topical_subject" select="$topical_subject"/>
            <xsl:with-param name="geographic_subject" select="$geographic_subject"/>
            <xsl:with-param name="language" select="$language"/>
            <xsl:with-param name="rules" select="$rules"/>
            <!-- unused -->
            <!-- <xsl:with-param name="is_cp" select="$is_cp"/> -->
        </xsl:apply-templates>
    </xsl:template> <!-- end tpt_match_record -->
    
    <!-- tpt_geo, tpt_65x_geo moved to lib.xsl -->

    <xsl:template name="tpt_container" match="/eac:container" xmlns="urn:isbn:1-931666-33-4">
        <!-- 
             Generate files via result-document(). The <container> has an <e_name> for each unique [167]xx entry. Each
             <e_name> has necessary attributes to generate the file with all elements properly populated. Called via
             apply-templates select="$all_xx". We depend on param data type being the same type here as in with-param
             where the template was called from. Apparently, that is standard, but I couldn't find explicit docs.
             
             The single .c gets links to all the .rNN files. Each .rNN gets a link to the single .c;
        -->
        <xsl:param name="tc_data"/>
        <xsl:param name="rel_entry"/>
        <xsl:param name="is_1xx"/>
        <xsl:param name="name_entry"/>
        <xsl:param name="mods"/>
        <xsl:param name="leader06"/>
        <xsl:param name="leader07"/>
        <xsl:param name="leader08"/>
        <xsl:param name="local_affiliation"/>
        <!-- <xsl:param name="is_cp" /> -->
        <xsl:param name="controlfield_001"/>
        <xsl:param name="all_xx"/>
        <xsl:param name="chunk_dir"/>
        <xsl:param name="record_id"/>
        <xsl:param name="date" />
        <xsl:param name="xslt_vendor" />
        <xsl:param name="xslt_version" />
        <xsl:param name="xslt_vendor_url" />
        <xsl:param name="tag_545" />
        <xsl:param name="tag_245" />
        <xsl:param name="xslt_script" />
        <xsl:param name="original" />
        <xsl:param name="topical_subject" />
        <xsl:param name="geographic_subject" />
        <xsl:param name="lang_decl" />
        <xsl:param name="language" />
        <xsl:param name="rules" />

        <xsl:variable name="file_name">
            <xsl:value-of select="concat($chunk_dir, '/', $record_id, '.', eac:e_name/@fn_suffix, '.xml')"/>
        </xsl:variable>
        
        <xsl:variable name="is_c_flag" as="xs:boolean">
            <xsl:value-of select="eac:e_name/@fn_suffix = 'c'"/>
        </xsl:variable>
        
        <xsl:variable name="is_r_flag" as="xs:boolean">
            <xsl:value-of select="substring(eac:e_name/@fn_suffix, 1, 1) = 'r'"/>
        </xsl:variable>
        
        <!--
            Renamed arc_role to wcrr_arc_role (WorldCat Resource Relation) since this is for
            resourceRelation ONLY. It is impossible to correspond with an archival record.
            
            Note that even with multiple resourceRelations, all of them have the same xlink:arcrole
            value. (This is not true for the nara das2cpf extraction.)
        -->
        <xsl:variable name="wcrr_arc_role">
            <xsl:call-template name="tpt_arc_role">
                <xsl:with-param name="is_c_flag" select="$is_c_flag" as="xs:boolean"/>
                <xsl:with-param name="is_r_flag" select="$is_r_flag"/>
            </xsl:call-template>
        </xsl:variable>

        <!-- 
             We could probably just set the eac: namespace in the template element above and that would
             take care of all this. Maybe do that and test this some day. In the meantime, the extra xmlns
             namespace assignments may be redundant, but they are working.
        -->

        <!-- <xsl:message> -->
        <!--     <xsl:text>pc: </xsl:text> -->
        <!--     <xsl:copy-of select="."/> -->
            <!-- <xsl:text>&#x0A;</xsl:text> -->
        <!-- </xsl:message> -->

        <xsl:variable name="cpf_relation" xmlns="urn:isbn:1-931666-33-4">
            <xsl:if test="$is_c_flag">
                <xsl:for-each select="$all_xx/eac:container/eac:e_name[substring(@fn_suffix, 1, 1) = 'r']">
                    <!--
                        Paths here are realtive to $all_xx/container/e_name. Note, here we are looking at $all_xx, not
                        the current record matching this template. 
                    -->
                    <xsl:variable name="cpf_arc_role" select="lib:cpf_arc_role(.)"/>
                    <xsl:variable name="et" select="@entity_type"/>

                    <cpfRelation xlink:type="simple"
                                 xlink:role="{$etype/eac:value[@key = $et]}"
                                 xlink:arcrole="{$cpf_arc_role}">
                        <relationEntry><xsl:value-of select="."/></relationEntry>
                        <descriptiveNote>
                            <p>
                                <span localType="{$av_extractRecordId}">
                                    <xsl:value-of select="concat(./@record_id, '.', ./@fn_suffix)"/>
                                </span>
                            </p>
                        </descriptiveNote>
                    </cpfRelation>
                </xsl:for-each>
            </xsl:if>

            <!--
                Context note: The context root in this template is eac:container thus lib:cpf_arc_role() must
                have an eac:e_name path. Above lib:cpf_arc_role() is inside a for-each which sets the (new,
                inner) context to eac:e_name. In the code below, we have to call it explicitly with the
                correct xpath.

                For a local .r record which also has a 1xx being processed by this template, output
                the (global) single .c node. If this record did not have a 1xx, there would be no .c
                file to refer to.
                
                We need some fields from the the main C record. Put that C e_name node set in a variable cmain.

                If the .c corresponded with .r, then the reverse is true, thus it is valid to use
                lib:cpf_arc_role() here.
            -->
            <xsl:if test="$is_r_flag and $is_1xx">
                <xsl:variable name="cmain">
                    <xsl:copy-of select="$all_xx/eac:container/eac:e_name[@fn_suffix = 'c']"/>
                </xsl:variable>
                <xsl:variable name="cpf_arc_role" select="lib:cpf_arc_role(eac:e_name)"/>
                <cpfRelation xlink:type="simple"
                             xlink:role="{$etype/eac:value[@key = $cmain/eac:e_name/@entity_type]}"
                             xlink:arcrole="{$cpf_arc_role}">
                    <relationEntry><xsl:value-of select="$cmain/eac:e_name"/></relationEntry>
                    <descriptiveNote>
                        <p>
                            <span localType="{$av_extractRecordId}">
                                <xsl:value-of select="concat($cmain/eac:e_name/@record_id,
                                                      '.',
                                                      $cmain/eac:e_name/@fn_suffix)"/>
                            </span>
                        </p>
                    </descriptiveNote>
                </cpfRelation>
            </xsl:if>
        </xsl:variable> <!-- end cpf_relation -->
        
        <!-- 
             New params to tpt_body are in a variable nodeset which is easier to update,
             modify, add to, and delete from, than hard coded params. It should have been like
             this from the start.
             
             use_rrel was invented for Smithsonian data (and used somewhat by British Library). It has been
             ported here to support LDS which seems close enough to OCLC to only need minor changes.
        -->
        
        <xsl:variable name="param_data" xmlns="urn:isbn:1-931666-33-4">
            <xsl:choose>
                <xsl:when test="$tc_data/eac:auth_form='lds'">
                    <use_rrel as="xs:boolean">
                        <xsl:value-of select="true()"/>
                    </use_rrel>
                    <xsl:variable name="ead_fn" select="eac:file_name"/>
                    <xsl:message>
                        <xsl:text>recordID: 001: </xsl:text>
                        <xsl:value-of select="$controlfield_001"/>
                    </xsl:message>
                    <xsl:for-each select="$original/marc:record/marc:datafield[@tag='555' and marc:subfield[@code='u']]">
                        <xsl:variable name="link_base"
                                      select="normalize-space(
                                              concat($original/marc:record/marc:datafield[@tag='090']/marc:subfield[@code='a'],
                                              ', ',
                                              $rel_entry))"/>
                        <xsl:variable name="link_text">
                            <xsl:choose>
                                <xsl:when test="position() = 1">
                                    <xsl:value-of select="$link_base"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <!--
                                        <subfield code="a">View Register for Supplement 4</subfield> Log all
                                        of these so we can verify that the all will match the
                                        replace(). Humans tend to make typographical errors.
                                    -->
                                    <xsl:value-of select="normalize-space(
                                                          concat($link_base,
                                                          ' (',
                                                          normalize-space(
                                                          replace(./marc:subfield[@code='a'], 'view register for', '', 'i')
                                                          ),
                                                          ')'))"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        <xsl:variable name="link_href" select="./marc:subfield[@code='u']"/>
                        <xsl:message>
                            <xsl:text>linktext: </xsl:text>
                            <xsl:value-of select="./marc:subfield[@code='a']"/>
                            <xsl:value-of select="$cr"/>
                            <xsl:text>href: </xsl:text>
                            <xsl:value-of select="$link_href"/>
                        </xsl:message>
                        <rrel>
                            <!--
                                Note that even with multiple resourceRelations, all of them have the same xlink:arcrole value.
                            -->
                            <rrel_arc_role><xsl:value-of select="$wcrr_arc_role"/></rrel_arc_role>
                            <rr_xlink_role><xsl:value-of select="$rr_xlink_role"/></rr_xlink_role>
                            <rr_xlink_href>
                                <xsl:value-of select="$link_href"/>
                            </rr_xlink_href>
                            <controlfield_001><xsl:value-of select="$controlfield_001"/></controlfield_001>
                            <leader06><xsl:value-of select="$leader06"/></leader06>
                            <leader07><xsl:value-of select="$leader07"/></leader07>
                            <leader08><xsl:value-of select="$leader08"/></leader08>
                            <!-- <rel_entry><xsl:value-of select="concat($auth_form, ' ', $ead_fn)"/></rel_entry> -->
                            <!-- <rel_entry><xsl:value-of select="$rel_entry"/></rel_entry> -->
                            <rel_entry><xsl:value-of select="$link_text"/></rel_entry>
                            <mods>
                                <!--
                                    See lib.xsl for tpt_mods. I think this is a mods record for related resources and
                                    thus the controlfield_001 is the record id of the .c record, or whatever the
                                    related record is. For all the marc extracts, the controlfield_001 aka record_id
                                    is the same for .c and .rxx files.
                                -->
                                <xsl:call-template name="tpt_mods">
                                    <xsl:with-param name="all_xx" select="$all_xx"/>
                                    <!-- jan 9 2015 I hope $tc_data/eac:agency_info is the same as $agency_info -->
                                    <!-- <xsl:with-param name="agency_info" select="$agency_info"/> -->
                                    <xsl:with-param name="agency_info" select="$tc_data/eac:agency_info"/>
                                    <xsl:with-param name="controlfield_001" select="$ead_fn"/>
                                    <xsl:with-param name="archive_agency" select="$auth_form"/>
                                </xsl:call-template>
                            </mods>
                        </rrel>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <rr_xlink_href>
                        <xsl:value-of select="$rr_xlink_href"/>
                    </rr_xlink_href>
                </xsl:otherwise>
            </xsl:choose>
            <inc_orig>
                <xsl:copy-of select="$inc_orig" />
            </inc_orig>
            <xsl:copy-of select="$tc_data/eac:agency_info"/>
            <xsl:copy-of select="$tc_data/eac:snac_info"/>
            <xsl:copy-of select="$tc_data/eac:citation"/>
            <ev_desc>
                <xsl:value-of select="$ev_desc"/>
            </ev_desc>
            <rules>
                <xsl:value-of select="$rules"/>
            </rules>
            <xlink_role>
                <xsl:value-of select="$rr_xlink_role"/>
            </xlink_role>
            <av_Leader06>
                <xsl:value-of select="$av_Leader06"/>
            </av_Leader06>
            <av_Leader07>
                <xsl:value-of select="$av_Leader07"/>
            </av_Leader07>
            <av_Leader08>
                <xsl:value-of select="$av_Leader08"/>
            </av_Leader08>
            <!--
                This sends over the current eac:container wrapper element, which has all kinds of info about
                the current entity. Currently it is used for occupation and function.
            -->
            <xsl:copy-of select="."/>
        </xsl:variable>

        <!--
            Note: the context is a <container> node set. <container><e_name>...</e_name><existDates>...</existDates></container>
        -->
        <xsl:result-document href="{$file_name}" format="xml" >
            <xsl:call-template name="tpt_body">
                <xsl:with-param name="exist_dates" select="./eac:existDates" as="node()*" />
                
                <xsl:with-param name="entity_type" select="eac:e_name/@cpf_entity_type" />
                <xsl:with-param name="entity_name" select="eac:e_name"/>

                <xsl:with-param name="leader06" select="$leader06"/>
                <xsl:with-param name="leader07" select="$leader07"/>
                <xsl:with-param name="leader08" select="$leader08"/>
                <xsl:with-param name="mods" select="$mods"/>
                <xsl:with-param name="rel_entry" select="$rel_entry"/>
                <xsl:with-param name="wcrr_arc_role" select="$wcrr_arc_role"/>
                <xsl:with-param name="controlfield_001" select="$controlfield_001"/>
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
                <xsl:with-param name="tag_245" select="normalize-space($tag_245)"/>
                <xsl:with-param name="xslt_script" select="$xslt_script"/>
                <xsl:with-param name="original" select="$original"/>
                <xsl:with-param name="lang_decl" select="$lang_decl"/>
                <xsl:with-param name="topical_subject" select="$topical_subject"/>
                <xsl:with-param name="geographic_subject" select="$geographic_subject"/>
                <xsl:with-param name="language" select="$language"/>
                <xsl:with-param name="param_data" select="$param_data" />
            </xsl:call-template>
        </xsl:result-document>
    </xsl:template> <!-- end tpt_container -->

    <xsl:template name="not_1xx" >
        <!-- 
             Keep track of non 1xx and send a message to stderr.
        -->
        <xsl:message terminate="no">
            <xsl:text>Not 1xx; </xsl:text>
            <xsl:text>record id: </xsl:text>
            <xsl:value-of select="marc:controlfield[@tag='001']"/>
        </xsl:message>
        <!--
            Do not apply-templates here unless we're processing the non 1xx records. 
        -->
    </xsl:template>

    <!--
        http://stackoverflow.com/questions/3360017/why-does-xslt-output-all-text-by-default 
        Add a catch all template so we know if any other matches are leaking.
    -->

    <xsl:template name="catch_all" match="*">
        <xsl:message terminate="no">
            <xsl:text>Warning: unmatched element: </xsl:text>
            <xsl:value-of select="namespace-uri()"/>
            <xsl:text>:</xsl:text>
            <xsl:value-of select="local-name()"/>
            <xsl:text>. pos: </xsl:text>
            <xsl:value-of select="position()"/>
        </xsl:message>
    </xsl:template>


    <xsl:template name="match_subfield">
        <xsl:for-each select="marc:subfield">
            <xsl:value-of select="."/>
            <xsl:text> </xsl:text>
        </xsl:for-each>
    </xsl:template>


    <xsl:template name="top_record" match="marc:record">
        <!-- 
             Match a <record> then branch on multi 1xx vs >=1 [167]xx. We want to choose our xx_tag
             with a priority of 1xx first, then 7xx (both of which are author-ish) then 6xx which
             are related to the current record. If we are not multi_1xx, then call-template for
             tpt_match_record, which is the starting point for all the work of creating then eac-cpf
             output.
        -->
        <xsl:variable name="precord_id">
            <!-- 
                 Printable record_id. Some data may have missing/duplicate 001. Using position() should be sufficient to make a
                 unique 001 value. 005 seems to be duplicated so we can't use that as our unique id either.
            -->
            <xsl:choose>
                <xsl:when test="string-length(normalize-space(marc:controlfield[@tag='001']))>0">
                    <xsl:value-of select="normalize-space(marc:controlfield[@tag='001'])"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('missing001_', position())"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!--
            Jan 13 2015 This exists primarily so we can run grep | wc -l on the log to make sure the count of
            records processed matches the expected number.
        -->
        <xsl:message>
            <xsl:value-of select="concat('printable recordID: ', $precord_id)"/>
        </xsl:message>

        <xsl:choose>
            <xsl:when test="count(marc:datafield[matches(@tag, '1(00|10|11)')]) &gt; 1">
                <xsl:message>
                    <xsl:text>multi_1xx: </xsl:text>
                    <xsl:value-of select="$precord_id"/>
                    <xsl:text>&#x0A;</xsl:text>
                </xsl:message>
            </xsl:when>
            <xsl:when test="count(marc:datafield[matches(@tag, '1(00|10|11)') or matches(@tag, '7(00|10|11)') or matches(@tag, '6(00|10|11)')]) &gt;= 1">
                <xsl:variable name="xx_tag">
                    <xsl:choose>
                        <xsl:when test="marc:datafield[matches(@tag, '1(00|10|11)')][1]">
                            <xsl:value-of select="marc:datafield[matches(@tag, '1(00|10|11)')][1]/@tag"/>
                        </xsl:when>
                        <xsl:when test="marc:datafield[matches(@tag, '7(00|10|11)')][1]">
                            <xsl:value-of select="marc:datafield[matches(@tag, '7(00|10|11)')][1]/@tag"/>
                        </xsl:when>
                        <xsl:when test="marc:datafield[matches(@tag, '6(00|10|11)')]">
                            <xsl:value-of select="marc:datafield[matches(@tag, '6(00|10|11)')][1]/@tag"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:variable>
                <xsl:call-template name="tpt_match_record">
                    <xsl:with-param name="xx_tag" select="$xx_tag"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>not_167xx: </xsl:text>
                    <xsl:value-of select="$precord_id"/>
                    <xsl:text>&#x0A;</xsl:text>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!--
        The container element is <collection>.
        
        Without this we have an unmatched element. However, when we match it, we must apply-templates in order
        for <record> to match. Output a newline because we are printing messages to stderr and we often
        combine stdout and stderr (via io redirection 2>&1), so we need a newline after the xml declaration
        which can't be turned off. (See comment with xsl:output.)
    -->

    <xsl:template name="tpt_collection" match="marc:collection">
        <xsl:text>&#x0A;</xsl:text>
        <xsl:apply-templates />
    </xsl:template>

    <!-- 
         Main root template start here.
    -->
    <xsl:template name="tpt_main" match="/">
        <xsl:message>
            <xsl:value-of select="concat('                       Date today: ', current-dateTime(), $cr)"/>
            <xsl:value-of select="concat('Number of geonames places read in: ', count($places/*), $cr)"/>
            <xsl:value-of select="concat('                Writing output to: ', $output_dir, $cr)"/>
            <xsl:value-of select="concat('           Default authorizedForm: ', $auth_form, $cr)"/>
            <xsl:value-of select="concat('   Fallback (default) agency code: ', $fallback_default, $cr)"/>
            <xsl:value-of select="concat('         Default eventDescription: ', $ev_desc, $cr)"/>
            <xsl:value-of select="concat('               Default xlink href: ', $rr_xlink_href, $cr)"/>
            <xsl:value-of select="concat('               Default xlink role: ', $rr_xlink_role, $cr)"/>
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
        <xsl:if test="not(boolean(marc:collection))">
            <xsl:text>&#x0A;Warning: Collection element not found.&#x0A;</xsl:text>
        </xsl:if>
        <xsl:apply-templates />
    </xsl:template>

</xsl:stylesheet>
