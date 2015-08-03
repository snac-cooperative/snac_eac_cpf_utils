<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
                xmlns:eac="urn:isbn:1-931666-33-4"
                xmlns:lib="http://example.com/"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:saxon="http://saxon.sf.net/"
                xmlns:marc="http://www.loc.gov/MARC21/slim"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:madsrdf="http://www.loc.gov/mads/rdf/v1#"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:mads="http://www.loc.gov/mads/"
                xmlns:xlink="http://www.w3.org/1999/xlink" 
                xpath-default-namespace="http://www.loc.gov/MARC21/slim"
                exclude-result-prefixes="#all"
                >
    <!-- 
         Author: Tom Laudeman, Daniel Pitti
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
         
         Used only for agency history files. This XSL script is used to extract EAC-CPF from MARC12/slim
         agency histories. There are two data sets: Smithsonian Institute Archive, and New York State Archives
         
         Note: Do not remove the directory nysa_ead, and do not remove nysa_ead/NYSAFindingAidsByAgency.xml
         since this file is used to translate between marc id values and the finding aid xml file name. The
         EAD files in nysa_ead are duplicates of /data/source/findingAids/nysa and the /data/source should be
         considered the definitive versions.
         
         NYSA:
         saxon.sh nysa.xml si_marc2cpf.xsl auth_form=NYSA ev_desc="Derived from NYSA agency history MARC" rerel_file=nysa_ead/NYSAFindingAidsByAgency.xml > nysa.log 2>&1 &
         

         SIA agency histories:
         saxon.sh sia_ag_hist.xml si_marc2cpf.xsl output_dir=sia_agencies fallback_default=US-SIA ev_desc="Derived from SIA Agency History MARC" rr_xlink_href="http://sia.org/agency_history/placeholder/" agency_name="SIA Agency Histories" auth_form=SIA  > sia_agencies.log 2>&1 &
         
         The simplest form works, but lacks important param settings:
         saxon.sh nysa.xml si_marc2cpf.xsl 2>&1
         
         > ls -l nysa.xml 
         lrwxrwxrwx 1 twl8n snac 70 Dec 11 09:13 nysa.xml -> /lv1/data/source/authorityFiles/NYStateArchive/NYSAagencyHistories.xml
         
         QA tpt_function the function code with less nysa_cpf/NYSV86-A380.c.xml
         
         QA function, topicalSubject, geographicaSubject with less nysa_cpf/NYSV94-A9.c.xml
         
         QA multiple (4) geographicSubject elements with less nysa_cpf/NYSV2123851-a.c.xml
         
    -->

    <!--
        Odd. '&apos;' does not work, although some web sites give that as an example.
        '''' is too weird to read, so I went with the define a var solution.
    -->
    <xsl:variable name="apos">'</xsl:variable>
    <xsl:param name="auth_form" select="'SIA'"/>
    
    <!--
        (Chunking is not used with agency history data.) The following params are mostly chunking related. The
        chunk_prefix (essentially a directory name) does not include trailing '_' (underscore) or '/'
        (slash). Both of those are added at the time file names are dynamically created.
    -->
    <xsl:param name="chunk_size" select="100"/>
    <xsl:param name="chunk_prefix" select="'zzz'"/>
    <xsl:param name="offset" select="1"/>
    <xsl:param name="output_dir" select="'nysa_cpf'"/>

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

    <!--
        The maintenanceAgency is SNAC, so this info would show up in resourceRelation, maybe MODS, but not in
        the CPF.
        
        Intially this was a placeholder, but maybe it is simple not necessary.
    -->
    <xsl:param name="fallback_default" select="'US-NYSA'"/>
    <xsl:param name="agency_name" select="'New York State Archives'"/>

    <!-- NYSA only has rr_xlink_href when there is an ead-marc match, so this feature is no longer relevant. -->
    <!-- <xsl:param name="always_rr_xlink_href" select="false()"/> -->

    <!-- These three params (variables) are sent over to the cpf template eac_cpf.xsl. -->

    <xsl:param name="ev_desc" select="'Derived from agency history MARC'"/>
    <xsl:param name="rr_xlink_role" select="$av_archivalResource"/> <!-- xlink:role -->

    <!--
        Not / terminated. We often need special behavior, so do that in rrel. Special is multiple
        resourceRelation or no added slash character between the URI and the controlfield_001 when creating
        the URI of the record describing the entity referred to by the CPF record. See eac_cpf.xsl around line
        213 "The classic ..."
    -->
    <xsl:param name="rr_xlink_href" select="'http://iarchives.nysed.gov/xtf/view?docId='"/> 

    <xsl:param name="debug" select="false()"/>
    <xsl:param name="inc_orig" select="true()"  as="xs:boolean"/>

    <xsl:variable name="xslt_script" select="'si_marc2cpf.xsl Saxon9HE'"/>
    <xsl:variable name="xslt_version" select="system-property('xsl:version')" />
    <xsl:variable name="xslt_vendor" select="system-property('xsl:vendor')" />
    <xsl:variable name="xslt_vendor_url" select="system-property('xsl:vendor-url')" />
    <xsl:variable name="xslt_desc">
        <xsl:text>XSLT </xsl:text>
        <xsl:value-of select="$xslt_script"/>
        <xsl:text> creates EAC-CPF from MARC21/slim XML </xsl:text>
        <xsl:text>(bibl with agency history)</xsl:text>
    </xsl:variable>

    <!-- 
         EAD-to-MARC (yes, EAD not EAC). Data from an Excel spreadsheeet turned into an XML node set that we
         can use to create resourceRelations for a few of the NYSA MARC records. This (tmp_ead_marc) is not a
         great variable name. Also, the data has no indication as to why it is EAD or even how EAD is
         involved.
         
         In case you a wondering where that symlink goes:
         nysa_ead -> /data/source/authorityFiles/archftp
    -->
    <xsl:variable name="rerel_file" select="'nysa_ead/NYSAFindingAidsByAgency.xml'"/>
    <xsl:variable name="tmp_ead_marc" select="document($rerel_file)/*"/>

    <xsl:variable name="ead_marc" xmlns="urn:isbn:1-931666-33-4">
        <!-- 
             Copy the finding aid data so we can use a non-empty namespace, specificially eac: rather than
             having to use *: which always seems odd to me.
        -->
        <container>
            <!-- <xsl:for-each select="$tmp_ead_marc/*/entry"> -->
            <xsl:for-each select="$tmp_ead_marc[local-name() = 'container']/*[local-name() = 'entry']">
                <entry>
                    <file_name>
                        <xsl:value-of select="*[local-name() = 'file_name']"/>
                    </file_name>
                    <marc_id>
                        <xsl:value-of select="*:marc_id"/>
                    </marc_id>
                </entry>
            </xsl:for-each>
        </container>
    </xsl:variable>

    <xsl:include href="eac_cpf.xsl"/>
    <xsl:include href="lib.xsl"/>
    
    <xsl:output indent="yes" method="xml" />

    <xsl:preserve-space elements="marc:record"/>

    <!-- 
         This now shares eac_xpf.xsl (template tpt_body) with oclc_marc2cpf.xsl. The variables may differ, but
         the xsl output template is the same.
    -->

    <xsl:template name="tpt_main" match="/">
        <xsl:message>
            <xsl:value-of select="concat('Date today: ', current-dateTime(), '&#x0A;')"/>
            <xsl:value-of select="concat('Number of geonames places read in: ', count($places/*), '&#x0A;')"/>
            <xsl:value-of select="concat('Writing output to: ', $output_dir, '&#x0A;')"/>
            <xsl:value-of select="concat('Default authorizedForm: ', $auth_form, '&#x0A;')"/>
            <xsl:value-of select="concat('Fallback (default) agency code: ', $fallback_default, '&#x0A;')"/>
            <xsl:value-of select="concat('Default agency name: ', $agency_name, '&#x0A;')"/>
            <xsl:value-of select="concat('Default eventDescription: ', $ev_desc, '&#x0A;')"/>
            <xsl:value-of select="concat('Default xlink href: ', $rr_xlink_href, '&#x0A;')"/>
            <xsl:value-of select="concat('Default xlink role: ', $rr_xlink_role, '&#x0A;')"/>
            <!-- <xsl:value-of select="concat('Always use xlink href: ', $always_rr_xlink_href, '&#x0A;')"/> -->
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
            <xsl:value-of select="concat('Relationship resource file (only used by NYSA): ', $rerel_file, '&#x0A;')"/>
            <xsl:value-of select="concat('Count of rerel entries (only used by NYSA): ', count($ead_marc/eac:container/eac:entry), '&#x0A;')"/>
        </xsl:message>
        
	<xsl:for-each select="//marc:record">
            <!--
                authorizedForm has been replaced by $rules.
            -->

            <xsl:variable name="original">
                <xsl:copy-of select="."/>
            </xsl:variable>
            
            <!--
                Using format-number() with picture string '0' seems to convince it to save the number as a
                string representation which prevents it from to switching to scientific notation when
                outputting large numbers.
            -->
            <xsl:variable
                name="record_position"
                select="format-number(position()+$offset, '0')"/>
            
            <!--
                Use the 001 if it exists. Most records don't have a 001, however, the 035$a has some values
                that repeat, so the 035$a can't be used exclusively. Here is an example 035:

                <marc:datafield tag="035" ind1=" " ind2=" ">
                        <marc:subfield code="a">(N-Ar)NYSV2168353-a</marc:subfield>
                </marc:datafield>
                
                Use an exciting regex that allows the leading (N-Ar) to be optional since one record is
                missing it. And I generalized to (.+?) so the value in the parens doesn't have to be "N-Ar".
            -->
	    <xsl:variable name="record_id">
                <xsl:choose>
                    <xsl:when test="marc:controlfield[@tag='001']">
	                <xsl:value-of select="marc:controlfield[@tag='001']"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:analyze-string select="marc:datafield[@tag='035']/subfield[@code='a']"
                                            regex="(\(.+?\))*(.+)">
                            <xsl:matching-substring>
                                <xsl:value-of select="regex-group(2)"/>
                            </xsl:matching-substring>
                        </xsl:analyze-string>
                    </xsl:otherwise>
                </xsl:choose>
	    </xsl:variable>

            <xsl:variable name="normalized001" select="$record_id"/>
            
            <xsl:variable name="is_multi_1xx">
                <xsl:choose>
                    <xsl:when test="count(marc:datafield[matches(@tag, '1(00|10|11)')]) &gt; 1">
                        <xsl:value-of select="true()"/>
                        <xsl:message>
                            <xsl:text>multi_1xx: </xsl:text>
                            <xsl:value-of select="$record_id"/>
                            <xsl:text>&#x0A;</xsl:text>
                        </xsl:message>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="false()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>


            <xsl:variable name="xx_tag">
                <xsl:choose>
                    <xsl:when test="count(marc:datafield[matches(@tag, '1(00|10|11)') or
                                    matches(@tag, '7(00|10|11)') or
                                    matches(@tag, '6(00|10|11)')]) &gt;= 1">
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
                    </xsl:when>
                </xsl:choose>
            </xsl:variable>
            
            <xsl:variable name="is_not_167xx">
                <xsl:if test="string-length($xx_tag) > 0">
                    <xsl:value-of select="true()"/>
                    <xsl:message>
                        <xsl:text>not_167xx: </xsl:text>
                        <xsl:value-of select="$record_id"/>
                        <xsl:text>&#x0A;</xsl:text>
                    </xsl:message>
                </xsl:if>
            </xsl:variable>

            <!--
                function substring() is one based in xslt, and marc:leader is zero based.
                
                rid: NYSV89-A101 status: n
                x       0000000001111111111
                x       1234567890123456789
                leader: 02003npc a2200313u  4500
            -->

	    <xsl:variable name="status">
		<xsl:value-of select="substring(marc:leader,6,1)"/>
	    </xsl:variable>

	    <xsl:variable name="rules">
                <xsl:call-template name="tpt_rules"/>
	    </xsl:variable>

            <xsl:variable name="all_545">
                <!--
                    This variable holds a new node set with each 545 subfield categorized as "", "function", or
                    "organizational". Once this challenge is done, it is easy to use an xpath to get the nodes
                    we want into the proper variables.
                -->
                <xsl:call-template name="tpt_do_545">
                    <xsl:with-param name="etype"/> 
                    <xsl:with-param name="the_nodes" select="marc:datafield[@tag='545']/marc:subfield"/>
                </xsl:call-template>
            </xsl:variable>

            <!-- 
                 Use /* to get the children of the document element (aka (wrongly) root) of $all_545 since
                 $all_545 does not have a root container element. Apparently /* is perfectly legal and robust.
                 http://www.dpawson.co.uk/xsl/sect2/root.html
                 
                 These <p> elements are going into the output, so give them the output namespace.
            -->
            <xsl:variable name="tag_545" xmlns="urn:isbn:1-931666-33-4">
                <xsl:for-each select="$all_545/*[@etype = 'organizational' or @etype = '' or @etype='history']">
                    <p>
                        <xsl:value-of select="."/>
                    </p>
                </xsl:for-each>
            </xsl:variable>

            <!-- 
                 The SI data may have additional function data. See tpt_function in lib.xsl which gets values
                 from tag 657.
            -->

            <!-- SixXXPerson is $all_xx/container/e_name/@tag = '600', -->

            <!-- SixXXCorporateBody is $all_xx/container/e_name/@tag = '610' or '611' -->

	    <xsl:variable name="relatedEntry">
                <!-- 
                     Used for the relationEntry in the non .A. files. The other files have the arcrole
                     associatedWith.
                -->
		<xsl:for-each select="marc:datafield[@tag='100' or @tag='110' or @tag='111']">
		    <relationEntry>
			<xsl:for-each select="marc:subfield">
			    <xsl:value-of select="."/>
			    <xsl:if test="position() != last()">
				<xsl:text> </xsl:text>
			    </xsl:if>
			</xsl:for-each>
		    </relationEntry>
		</xsl:for-each>
	    </xsl:variable>

	    <xsl:variable name="subordinateAgency">
                <!-- this test is also appears in tpt_expanded_suffix. -->
		<xsl:for-each select="marc:datafield[@tag='774']">
		    <xsl:if test="matches(marc:subfield[@code='o'],'\(SIA\sAH\d+\)')">
			<xsl:copy-of select="."/>
		    </xsl:if>
		</xsl:for-each>
	    </xsl:variable>

	    <xsl:variable name="relatedSeries">
		<xsl:for-each select="marc:datafield[@tag='774']">
		    <xsl:if test="matches(marc:subfield[@code='o'],'\(SIA\sRS\d+\)')">
			<xsl:copy-of select="."/>
		    </xsl:if>
		</xsl:for-each>
	    </xsl:variable>
            
	    <xsl:variable name="earlierLaterEntries">
                <!-- this test is also appears in tpt_expanded_suffix. -->
		<xsl:for-each select="marc:datafield[@tag='780' or @tag='785']">
		    <xsl:copy-of select="."/>
		</xsl:for-each>
	    </xsl:variable>
            
	    <xsl:choose>
                
		<xsl:when test="marc:datafield[@tag='151']">
		    <xsl:message>
			<xsl:text>Record no. </xsl:text>
			<xsl:number/>
			<xsl:text> is a geographic name</xsl:text>
		    </xsl:message>
		</xsl:when>

		<xsl:when
		    test="marc:datafield[@tag='100' or @tag='110' or @tag='111']/marc:subfield[@code='t'] | marc:datafield[@tag='130']">
		    <xsl:message>
			<xsl:text>Record no. </xsl:text>
			<xsl:number/>
			<xsl:text> uniform title record</xsl:text>
		    </xsl:message>
		</xsl:when>
                
                <!--
                    There are two records with a space in leader position 6, and they appear to be just fine,
                    so I've taken the liberty of adding ' ' to a status that we like.
                -->
		<xsl:when test="$status='a' or $status='c' or $status='n' or $status='C' or $status=' '">
                    
                    <!-- leader character numbering is zero based and we're only interested in position 6. -->
                    <!-- <leader>00000cpcaa  00000La     </leader> -->
                    <!--         12345678901234567890123456789 -->
                    
                    <!-- Copied from oclc_marc2cpf.xsl. -->

                    <xsl:variable name="leader06">
                        <xsl:value-of select="substring(marc:leader, 7, 1)"/>
                    </xsl:variable>
                    <xsl:variable name="leader07">
                        <xsl:value-of select="substring(marc:leader, 8, 1)"/>
                    </xsl:variable>
                    <xsl:variable name="leader08">
                        <xsl:value-of select="substring(marc:leader, 9, 1)"/>
                    </xsl:variable>

                    <xsl:variable name="all_xx">
                        <!--
                            $xx_tag is always (used to be?) 100, 110, or 111, so it is mostly only good for
                            debugging here.
                            
                            Either of these works to pass in the initial empty node set, but the second
                            statement seems more obvious. It is critical to pass in a node set. Not
                            specifying the data type defaults to some string-ish data type which fails with
                            an error when used with xpath outside boolean().
                            
                            <xsl:with-param name="curr" select="/.."/>
                            <xsl:with-param name="curr" as="node()*"/>
                        -->
                        <xsl:variable name="creator_info">
                            <!-- 
                                 Used for non-1xx records. If a 7xx exists, then use it as a resourceRelation
                                 arcrole creatorOf. Force the namespace of this node set to be ns since this
                                 is essentially input (MARC) and not output (EAC). This gets messy in
                                 tpt_all_xx where there can be non-7xx duplicate names. Changing the
                                 de-duplicating code would require a full rewrite of tpt_all_xx, so when there
                                 is a matching 7xx, I just mark the first occurance (whether 6xx or 7xx) as
                                 is_creator, no matter what the tag value.
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
                            <xsl:with-param name="status" select="$status"/>
                        </xsl:call-template>
                    </xsl:variable>

                    <xsl:variable name="cmain">
                        <xsl:copy-of select="$all_xx/eac:container/eac:e_name[@fn_suffix = 'c']"/>
                    </xsl:variable>
                    
                    <xsl:variable name="agency_info">
                        <!-- See lib.xsl for tpt_agency_info. -->
                        <xsl:call-template name="tpt_agency_info"/>
                    </xsl:variable>

                    <xsl:variable name="function_545" xmlns="urn:isbn:1-931666-33-4">
                        <!--
                            Not biogHist. This relies on previously categorized data in $all_545. These are
                            extra function descriptions, specific to NYSA data.
                        -->
                        <xsl:if test="$all_545/*[@etype = 'function']">
                            <function>
                                <descriptiveNote>
                                    <xsl:for-each select="$all_545/*[@etype = 'function']">
                                        <p>
                                            <xsl:value-of select="."/>
                                        </p>
                                    </xsl:for-each>
                                </descriptiveNote>
                            </function>
                        </xsl:if>
                    </xsl:variable>

                    <!--
                        Later we'll add the [167]xx as a prefix to tag_245 for resourceRelation/relationEntry.
                        
                        Copied from oclc_marc2cpf.xsl.
                    -->
                    <xsl:variable name="tag_245">
                        <xsl:for-each select="marc:datafield[@tag='245']/marc:subfield">
                            <xsl:if test="not(position() = 1)">
                                <xsl:text> </xsl:text>
                            </xsl:if>
                            <xsl:value-of select="."/>
                        </xsl:for-each>
                    </xsl:variable>
                    
                    <xsl:variable name="rel_entry">
                        <!-- 
                             Note: This is not used the same way for agency history as for MARC archival
                             records.

                             relationEntry which is the entity name (for MARC derived records it also includes
                             the 245 field.) Rather than checking $is_1xx which would be sort of pointless,
                             just get the 1xx from $all_xx if one exists, else get the first 7xx from $all_xx,
                             else nothing. Since we can't modify variables, we will just have to create 2
                             temporary variables so we can be sure of not trying to output something that
                             doesn't exist, or add extra '.'. Since this field is human readable, we are
                             including punctuation which is a trailing dot at the end of the name, except when
                             the name is empty. It is possible for this $rel_entry to be '' (empty string)
                             after all this, but I'm pretty sure every record has a tag 245.
                             
                             This must follow tag_545. (Why?)
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

                    <!-- 
                         Note: this file is si_marc2cpf.xsl. Some of these comments only apply to
                         oclc_marc2cpf.xsl

                         For WorldCat MARC we can use select="normalize-space(marc:controlfield[@tag='001'])",
                         but NYSA doesn't have 001, so just use the rcord id.
                         
                         For WorldCat, this becomes the end of the resourceRelation xlink:href permanent href
                         of this resource and the source xlink:href. LDS has their href in the 555$u.
                    -->
                    <xsl:variable name="controlfield_001" select="$record_id" />

                    <xsl:variable name="date" 
                                  select="current-dateTime()"/>

                    <!--
                        control/languageDeclaration. I'm pretty sure there is only a single
                        040$b per record, but for-each sets the context, so that is
                        good. When we have an 040$b, use it, otherwise default to English.
                        
                        See lib.xsl for tpt_lang_decl.
                    -->
                    <xsl:variable name="lang_decl">
                        <xsl:call-template name="tpt_lang_decl"/>
                    </xsl:variable>

                    <xsl:variable name="topical_subject">
                        <xsl:call-template name="tpt_topical_subject">
                            <xsl:with-param name="record_position" select="$record_position"/>
                            <xsl:with-param name="record_id" select="$record_id"/>
                        </xsl:call-template>
                    </xsl:variable>
                    
                    <xsl:variable name="geographic_subject">
                        <!-- See lib.xsl for tpt_geo. -->
                        <xsl:call-template name="tpt_geo"/>
                    </xsl:variable>

                    <!--
                        See lib.xml. tpt_function, tpt_occupation now called from within tpt_all_xx and the
                        occupation is part of the per-entity data.
                    -->
                    
                    <xsl:variable name="language">
                        <!--
                            This is the description/languageUsed and reads the 041$a. See tpt_language in lib.xsl.
                        -->
                        <xsl:call-template name="tpt_language"/>
                    </xsl:variable>
                    
                    <!--
                        tc_data to be consistent with usage inside tpt_container. SNAC is the maintenanceAgency for the CPF data.
                        
                        This is not the same as the maintenanceAgency of the data that the CPF was extracted from.
                    -->
                    <xsl:variable name="tc_data" xmlns="urn:isbn:1-931666-33-4">
                        <snac_info>
                            <xsl:call-template name="tpt_snac_info"/>
                        </snac_info>
                        <agency_info>
                            <xsl:copy-of select="$agency_info"/>
                        </agency_info>
                    </xsl:variable>
                    


                    <!--
                        Loop through $all_xx/container and create an output file for each container element.
                    -->
                    <xsl:for-each select="$all_xx/eac:container">

                        <xsl:variable name="name_entry">
                            <!-- I'm pretty sure for-each is only being used to set the context node. -->
                            <xsl:for-each select="marc:datafield[@tag = $xx_tag]">
                                <xsl:call-template name="tpt_name_entry">
                                    <xsl:with-param name="xx_tag" select="$xx_tag"/>
                                    <xsl:with-param name="record_position" select="$record_position"/>
                                    <xsl:with-param name="record_id" select="$record_id"/>
                                </xsl:call-template>
                            </xsl:for-each>
                        </xsl:variable>

                        <xsl:variable name="is_1xx" as="xs:boolean">
                            <!--
                                Are we a 1xx record or not 1xx (aka not_1xx)?
                            -->
                            <xsl:value-of select="boolean($xx_tag='100' or $xx_tag='110' or $xx_tag='111')"/>
                        </xsl:variable>
                        
                        <xsl:variable name="is_c_flag" as="xs:boolean">
                            <!-- 
                                 Important to call boolean() here because a null string causes error messages
                                 (incorrectly) many, many lines above this. (Like around line 200.) "The string ""
                                 cannot be cast to a boolean".
                            -->
                            <xsl:value-of select="eac:e_name/@fn_suffix = 'c'"/>
                        </xsl:variable>
                        
                        <!--
                            I suspect we need more. Instead of is_c_flag and is_r_flag, we probably need
                            record_type or something, for the A, P, C, S, and EL. P and C could both be the
                            same as oclc_marc2cpf.xsl ".rxx" is_r_flag.
                        -->
                        <xsl:variable name="is_r_flag" as="xs:boolean">
                            <xsl:value-of select="substring(eac:e_name/@fn_suffix, 1, 1) = 'r'"/>
                        </xsl:variable>

                        <xsl:variable name="cpf_relation" xmlns="urn:isbn:1-931666-33-4">
                            <!--
                                arcrole="associatedWith" for both .c and .r records.
                                For a local .c record being processed by this template, output all the (global) .rNN nodes;
                                (What is a "local" .c record? What is a "global" .c record?)
                                
                                The OCLC WorldCat data determines the cpf arc role from xsl:variable
                                name="cpf_arc_role" select="lib:cpf_arc_role(.)"
                            -->
                            <xsl:if test="$is_c_flag">
                                <xsl:for-each select="$all_xx/eac:container/eac:e_name[substring(@fn_suffix, 1, 1) = 'r']">
                                    <!--
                                        Paths here are realtive to $all_xx/container/e_name. Note, here we are
                                        looking at $all_xx, not the current record matching this template. See
                                        lib.xml for variable $etype. It is a simple node set for key/value
                                        lookup. Typically this would be person=$av_Person,
                                        corporateBody=$av_CorporateBody, family=$av_Family
                                    -->
                                    <xsl:variable name="et" select="@entity_type"/>
                                    <cpfRelation xlink:type="simple"
                                                 xlink:role="{$etype/eac:value[@key = $et]}"
                                                 xlink:arcrole="{$av_associatedWith}">
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
                                For a local .r record which also has a 1xx being processed by this template,
                                output the (global) single .c node. If this record did not have a 1xx, there
                                would be no .c file to refer to. See lib.xml for variable $etype. It is a
                                simple node set for key/value lookup.
                            -->
                            <xsl:if test="$is_r_flag and $is_1xx">
                                <!--
                                    We need some fields from the the main C record. We used to put that C
                                    e_name node set in a variable here, but now we have a var cmain with wider
                                    scope.
                                -->
                                <cpfRelation xlink:type="simple"
                                             xlink:role="{$etype/eac:value[@key = $cmain/eac:e_name/@entity_type]}"
                                             xlink:arcrole="{$av_associatedWith}">
                                    <relationEntry><xsl:value-of select="$all_xx/eac:container/eac:e_name[@fn_suffix = 'c']"/></relationEntry>
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
                        </xsl:variable>
                        
                        <xsl:variable name="arc_role">
                            <!--
                                See lib.xsl for template tpt_arc_role. This is the resourceRelation arcrole.
                            -->
                            <xsl:call-template name="tpt_arc_role">
                                <xsl:with-param name="is_c_flag" select="$is_c_flag"/>
                                <xsl:with-param name="is_r_flag" select="$is_r_flag"/>
                            </xsl:call-template>
                        </xsl:variable>

                        <!-- 
                             New params to tpt_body are in a variable nodeset which is easier to update,
                             modify, add to, and delete from than hard coded params. It should have been like
                             this from the start.
                        -->

                        <xsl:variable name="param_data"  xmlns="urn:isbn:1-931666-33-4">
                            <xsl:if test="false()">
                                <!-- 
                                    Mar 30 2015 unclear where this citation format came from. It is not
                                    standard for CPF formats in use elsewhere, so I've created a new
                                    format. The info we have from MARC records is limited.
                                -->
                                <citation>
                                    <xsl:value-of select="concat($agency_name, ': ')"/>
                                    <xsl:value-of select="lib:capitalize(eac:e_name/@entity_type)"/>
                                    <xsl:text> : Description : </xsl:text>
                                    <xsl:value-of select="$record_id"/>
                                </citation>
                            </xsl:if>
                            <!--
                                http://shannon.village.virginia.edu:8087/xtf/view?docId=nysa/NYSV86-A312.c.xml
                                http://shannon.village.virginia.edu:8088/xtf/view?docId=sia_agencies/217776.c.xml
                            -->
                            <citation>
                                <xsl:choose>
                                    <xsl:when test="matches($agency_name, 'New York')">
                                        <xsl:value-of select="'From the New York State Archives, Cultural Education Center, Albany, NY. '"/>
                                        <xsl:value-of select="concat('Agency record ', $record_id)"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="'Smithsonian Institution Archives, Agency History. '"/>
                                        <xsl:value-of select="concat('Record ', $record_id)"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </citation>
                            <inc_orig>
                                <xsl:copy-of select="$inc_orig" />
                            </inc_orig>
                            <xsl:copy-of select="$tc_data/eac:agency_info"/>
                            <xsl:copy-of select="$tc_data/eac:snac_info"/>
                            <xsl:copy-of select="$function_545"/>
                            <ev_desc>
                                <xsl:value-of select="$ev_desc"/>
                            </ev_desc>
                            <rules>
                                <xsl:value-of select="$rules"/>
                            </rules>

                            <!--
                                Mar 30 2015 I'm pretty sure all resourceRelations in agency histories are
                                disabled, except a few for NYSA. Apparently, this code got mixed up with some
                                parts of resourceRelation re-enabled (incorrectly). See the rrel xsl:choose
                                below.
                            -->

                            <!-- <rr_xlink_href> -->
                            <!--     <xsl:value-of select="$rr_xlink_href"/> -->
                            <!-- </rr_xlink_href> -->
                            <!-- <rr_xlink_role> -->
                                <!-- When using rrel, this value is also in each rrel element, and that is correct -->
                            <!--     <xsl:value-of select="$rr_xlink_role"/> -->
                            <!-- </rr_xlink_role> -->
                            <!-- <rrel_arc_role> -->
                            <!--     <xsl:value-of select="$arc_role"/> -->
                            <!-- </rrel_arc_role> -->


                            <av_Leader06>
                                <xsl:value-of select="$av_Leader06"/>
                            </av_Leader06>
                            <av_Leader07>
                                <xsl:value-of select="$av_Leader07"/>
                            </av_Leader07>
                            <av_Leader08>
                                <xsl:value-of select="$av_Leader08"/>
                            </av_Leader08>

                            <use_source_href as="xs:boolean">
                                <xsl:value-of select="false()"/>
                            </use_source_href>

                            <use_rrel as="xs:boolean">
                                <xsl:value-of select="true()"/>
                            </use_rrel>

                            <!--
                                Always use rrel. The "when" originally allowed possible multi resourceRelation
                                elements in output, and the "otherwise" was normal but allowed for non-slash
                                inclusion in the href domain name/path.
                                
                                We need to do a more flexible rr_xlink_href since it won't always have an added
                                "/", so move the string concat here instead of in eac_cpf.xsl.
                                
                                Mar 30 2015 There was a false() test here, but it could not have possibly
                                disabled the entire xsl:choose and was pointless. Unclear, confused, and
                                confusing.
                            -->

                            <xsl:choose>
                                <!-- 
                                     When we have a match against the list of finding aids, create one or more
                                     resourceRelation elements. Right now we only have finding aids for NYSA.
                                -->
                                <xsl:when test="count($ead_marc/eac:container/eac:entry[matches(eac:marc_id, $controlfield_001)]) > 0">
                                    <xsl:for-each select="$ead_marc/eac:container/eac:entry[matches(eac:marc_id, $controlfield_001)]">
                                        <xsl:variable name="ead_fn" select="eac:file_name"/>
                                        <rrel>
                                            <rrel_arc_role><xsl:value-of select="$arc_role"/></rrel_arc_role>
                                            <rr_xlink_role><xsl:value-of select="$rr_xlink_role"/></rr_xlink_role>
                                            <rr_xlink_href><xsl:value-of select="concat($rr_xlink_href, $ead_fn)"/></rr_xlink_href>
                                            <controlfield_001><xsl:value-of select="$controlfield_001"/></controlfield_001>
                                            <leader06><xsl:value-of select="$leader06"/></leader06>
                                            <leader07><xsl:value-of select="$leader07"/></leader07>
                                            <leader08><xsl:value-of select="$leader08"/></leader08>
                                            <rel_entry><xsl:value-of select="concat($auth_form, ' ', $ead_fn)"/></rel_entry>
                                            <mods>
                                                
                                                <!--
                                                    See lib.xsl for tpt_mods. I think this is a mods record for related resources and
                                                    thus the controlfield_001 is the record id of the .c record, or whatever the
                                                    related record is. For all the marc extracts, the controlfield_001 aka record_id
                                                    is the same for .c and .rxx files.
                                                -->
                                                <xsl:call-template name="tpt_mods">
                                                    <xsl:with-param name="all_xx" select="$all_xx"/>
                                                    <xsl:with-param name="agency_info" select="$agency_info"/>
                                                    <xsl:with-param name="controlfield_001" select="$ead_fn"/>
                                                    <xsl:with-param name="archive_agency" select="$auth_form"/>
                                                </xsl:call-template>
                                            </mods>
                                        </rrel>
                                    </xsl:for-each>
                                </xsl:when>
                                <xsl:otherwise>
                                    <!--
                                        If not match to archival material outside CPF, then there is no resourceRelation.
                                    -->
                                </xsl:otherwise>
                            </xsl:choose>
                            <!--
                                This sends over the current eac:container wrapper element, which has all kinds of info about
                                the current entity. Currently it is used for occupation and function.
                            -->
                            <xsl:copy-of select="."/>
                        </xsl:variable> <!-- end param_data -->

                        <!--
                            Create output .c and .rxx records just like the other marc2cpf XSLT. Daniel's
                            original prototype had loops for each $SixXXPerson, $SixXXCorporateBody,
                            $subordinateAgency, and $earlierLaterEntries. Now we have variables with node sets
                            for the data that was in those loops.
                            
                            The old @expanded_suffix is gone. In this standard implementation, it is not easy
                            to have a numerical suffix such as P001, P002 because tpt_all_xx (variable
                            $all_xx) doesn't carry counts of those suffixes. Carrying that suffix count would
                            require tpt_all_xx to have more params passed to each succeeding level of
                            recursion. Alternately, we could for-each on $all_xx A, then for each on P, then
                            for each on C, and so on. That creates code duplication.
                            
                            See variable output_dir at the top of the script.
                        -->

	                <xsl:result-document href="{$output_dir}/{$record_id}.{eac:e_name/@fn_suffix}.xml">
                            <!-- need vars for all the relation entries that used to be in for-each loops -->
                            <xsl:call-template name="tpt_body">
                                <xsl:with-param name="exist_dates" select="./eac:existDates" as="node()*"/>
                                <xsl:with-param name="entity_type" select="./eac:e_name/@cpf_entity_type" />
                                <xsl:with-param name="entity_name" select="eac:e_name"/>
                                <xsl:with-param name="leader06" select="$leader06"/>
                                <xsl:with-param name="leader07" select="$leader07"/>
                                <xsl:with-param name="leader08" select="$leader08"/>
                                <xsl:with-param name="mods" select="'legacy mods disabled'"/>
                                <xsl:with-param name="rel_entry" select="$rel_entry"/>
                                <xsl:with-param name="wcrr_arc_role" select="$arc_role"/>
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
                                <!--
                                    NYSA data doesn't use a 545 in the traditional way. See also function_545.
                                -->
                                <xsl:with-param name="tag_545" select="$tag_545"/>
                                <xsl:with-param name="tag_245" select="normalize-space($tag_245)"/>
                                <xsl:with-param name="xslt_script" select="$xslt_script"/>
                                <xsl:with-param name="original" select="$original"/>
                                <!-- agency_info replaced by $tc_data/eac:agency_info which has <agency_info> in $param_data -->
                                <!-- <xsl:with-param name="agency_info" select="$agency_info"/> -->
                                <xsl:with-param name="lang_decl" select="$lang_decl"/>
                                <xsl:with-param name="topical_subject" select="$topical_subject"/>
                                <xsl:with-param name="geographic_subject" select="$geographic_subject"/>
                                <!-- <xsl:with-param name="occupation" select="$occupation"/> -->
                                <xsl:with-param name="language" select="$language"/>
                                <!-- <xsl:with-param name="function" select="$function"/> -->
                                <xsl:with-param name="param_data" select="$param_data" />
                            </xsl:call-template>
		        </xsl:result-document>
                    </xsl:for-each>
		</xsl:when>

		<xsl:when test="$status='d'">
		    <xsl:message>
			<xsl:text>Record no. </xsl:text>
                        <xsl:value-of select="$record_id"/>
			<xsl:text> position: </xsl:text>
			<xsl:value-of select="position()"/>
			<xsl:text> status is "Deleted"</xsl:text>
		    </xsl:message>
		</xsl:when>
		<xsl:when test="$status='o'">
		    <xsl:message>
			<xsl:text>Record no. </xsl:text>
                        <xsl:value-of select="$record_id"/>
			<xsl:text> position: </xsl:text>
			<xsl:value-of select="position()"/>
			<xsl:text> status is "Obsolete"</xsl:text>
		    </xsl:message>
		</xsl:when>
		<xsl:when test="$status='s'">
		    <xsl:message>
			<xsl:text>Record no. </xsl:text>
                        <xsl:value-of select="$record_id"/>
			<xsl:text> position: </xsl:text>
			<xsl:value-of select="position()"/>
			<xsl:text> status is "Deleted; heading split into two or more headings"</xsl:text>
		    </xsl:message>
		</xsl:when>
		<xsl:when test="$status='x'">
		    <xsl:message>
			<xsl:text>Record no. </xsl:text>
                        <xsl:value-of select="$record_id"/>
			<xsl:text> position: </xsl:text>
			<xsl:value-of select="position()"/>
			<xsl:text> status is "Deleted; heading replaced by another heading"</xsl:text>
		    </xsl:message>
		</xsl:when>
		<xsl:otherwise>
                    <xsl:message>
		        <xsl:text>Record no. </xsl:text>
                        <xsl:value-of select="$record_id"/>
		        <xsl:text> record position: </xsl:text>
		        <xsl:value-of select="position()"/>
		        <xsl:text> status is unknown. value not recognized (string position 6): '</xsl:text>
                        <xsl:value-of select="$status"/>
		        <xsl:text>'&#x0A;        0000000001111111111</xsl:text>
		        <xsl:text>&#x0A;        1234567890123456789</xsl:text>
		        <xsl:text>&#x0A;leader: </xsl:text>
                        <xsl:value-of select="marc:leader"/>
                    </xsl:message>
                </xsl:otherwise>
	    </xsl:choose>
            <!-- 
                 In the normal processing "when" far above, we do the ' ' records as normal, but it seems wise
                 to print a warning here.
            -->
            <xsl:if test="$status = ' '">
                <xsl:message>
		    <xsl:text>Status is unknown; processing this record as normal.</xsl:text>
		    <xsl:text>&#x0A;</xsl:text>
		    <xsl:text>Record no. </xsl:text>
                    <xsl:value-of select="$record_id"/>
		    <xsl:text>&#x0A;</xsl:text>
		    <xsl:text>Value not recognized (string position 6): </xsl:text>
                    <!--
                        Odd. '&apos;' does not work, although some web sites give that as an example.
                        '''' is too weird to read, so I went with the define a var solution.
                    -->
                    <xsl:value-of select="concat($apos, $status, $apos)"/>
		    <xsl:text>&#x0A;        0000000001111111111</xsl:text>
		    <xsl:text>&#x0A;        1234567890123456789</xsl:text>
		    <xsl:text>&#x0A;leader: </xsl:text>
                    <xsl:value-of select="marc:leader"/>
                </xsl:message>
            </xsl:if>
	</xsl:for-each>
    </xsl:template>

    <xsl:template name="tpt_do_545">
        <xsl:param name="etype"/>
        <xsl:param name="the_nodes"/>
        <!--
            Parse 545 data into "CURRENT" or "ORGANIZATIONAL". 

            This template is intended to follow the xsl idiom for "recursively traverse all nodes allowing a
            state variable to change values". The xsl idiom for "a variable with changing value" is a variable
            in recursion.
            
            $etype is a state variable from the previous iteration. It will hold its value from one iteration
            to the next, but since we are using recursion, we can pass a new value to the next level of
            recursion, which it will then hold until changed. The passed variable is always $new_type which
            may have the previous iteration's value of $etype, or a new state value determined by the current
            node.
        -->
        <xsl:variable name="curr" select="$the_nodes[1]"/>

        <xsl:variable name="new_etype">
            <xsl:choose>
                <xsl:when test="matches($curr/text(), '^CURRENT |^FUNCTIONS')">
                    <xsl:text>function</xsl:text>
                </xsl:when>
                <xsl:when test="matches($curr/text(), '^ORGANIZATIONAL ')">
                    <xsl:text>organizational</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$etype"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- 
             The real core of the recursion is here, where we will recurse as long as we have some remaining
             input.
        -->
        <xsl:choose>
            <xsl:when test="$the_nodes">
                <entry xmlns="" etype="{$new_etype}">
                    <xsl:value-of select="normalize-space(replace($curr, '^(HISTORY|ORGANIZATIONAL|CURRENT|FUNCTIONS| )+[:\.]*',''))" />
                </entry>
                <xsl:call-template name="tpt_do_545">
                    <xsl:with-param name="etype" select="$new_etype"/>
                    <xsl:with-param name="the_nodes" select="$the_nodes[position() > 1]"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <!-- nothing, we're done -->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template><!-- tpt_do_545 -->

</xsl:stylesheet>
