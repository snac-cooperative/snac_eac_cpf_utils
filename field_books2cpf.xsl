<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.filemaker.com/fmpdsoresult"
                xmlns:fm="http://www.filemaker.com/fmpdsoresult"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:lib="http://example.com/"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:functx="http://www.functx.com"
                xmlns:eac="urn:isbn:1-931666-33-4"
                xmlns:xlink="http://www.w3.org/1999/xlink" 
                xmlns:frbr="http://rdvocab.info/uri/schema/FRBRentitiesRDA/"
                exclude-result-prefixes="#all"
                version="2.0"
                >

    <!--
        Author: Tom Laudeman, Daniel Pitti
        The Institute for Advanced Technology in the Humanities
        
        Copyright 2013 University of Virginia. Licensed under the Educational Community License, Version 2.0
        (the "License"); you may not use this file except in compliance with the License. You may obtain a
        copy of the License at
        
        http://opensource.org/licenses/ECL-2.0
        http://www.osedu.org/licenses/ECL-2.0
        
        Unless required by applicable law or agreed to in writing, software distributed under the License is
        distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
        implied. See the License for the specific language governing permissions and limitations under the
        License.
        
        This code has a really dreadful aspect in that it repeats some major sections of code 3 times, once
        each for expeditions, orgnazations, and persons. This breaks DRY and has caused no end of stupid bugs.

        Based on sia_field_books.xsl. Create EAC-CPF from Smithsonian fieldbooks data consisting of 3 XML files.
        
        Output based on exp_data, final_per, final_org. The action begins in template tpt_main.
        
        Person and organization data is read from in via the document() funtion. Expedition data is the XML
        input file to be transformed (so to speak).
        
        saxon.sh sia_field/eace.xml field_books2cpf.xsl > sia_fb_cpf.log 2>&1 &
        
        Typical settings are:
        
        Date today: 2013-09-19T11:24:07.082-04:00
        Number of geonames places read in: 0
        Writing output to: ./sia_fb_cpf
        Default authorizedForm: SIA
        Fallback (default) agency code: US-SIA-FB
        Default eventDescription: Derived from SIA fieldbook expedition, person, and organization records
        Default xlink href: http://siarchives.si.edu/fieldbooks/placeholder
        Default xlink role: http://socialarchive.iath.virginia.edu/control/term#ArchivalResource
        Include original record: yes
        
        The input XML is the expedition data sia_field/eace.xml

        This code requires Saxon 9.4he. Saxon version 9.2 doesn't seem to have path() in either of these
        namespaces:

        xmlns:fn="http://www.w3.org/2005/xpath-functions"
        xmlns:saxon="http://saxon.sf.net/"
    -->

    <xsl:param name="debug" select="false()"/>

    <xsl:param name="output_dir" select="'./sia_fb_cpf'"/>
    <xsl:param name="fallback_default" select="'US-SIA-FB'"/>
    <xsl:param name="auth_form" select="'SIA'"/>
    <xsl:param name="inc_orig" select="true()"  as="xs:boolean"/>

    <!-- These three params (variables) are passed to the cpf template eac_cpf.xsl via params to tpt_body. -->

    <xsl:param name="ev_desc" select="'Derived from SIA fieldbook expedition, person, and organization records'"/> <!-- eventDescription -->
    <!-- xlink:role The $av_ variables are in lib.xml. -->
    <xsl:param name="rr_xlink_role" select="$av_archivalResource"/> 
    <xsl:param name="rr_xlink_href" select="'http://siarchives.si.edu/fieldbooks/placeholder'"/> <!-- Not / terminated. Add the / in eac_cpf.xsl. xlink:href -->

    <xsl:include href="eac_cpf.xsl"/>
    <xsl:include href="lib.xsl"/>

    <!--
        We got this error message:
        XTDE1460: Requested output format xml has not been defined
        
        Solution: Must have attribut name="xml" in <xsl:output> because we tell result-document to use
        format="xml".
    -->
    <xsl:output name="xml" method="xml" indent="yes"/>

    <!-- Need this or every apply-templates emits a newline -->
    <xsl:strip-space elements="*"/>
    
    <xsl:variable name="is_cp" as="xs:boolean">
        <!-- 
             Field book data doesn't have any correspondents, yet.
        -->
        <xsl:value-of select="false()"/>
    </xsl:variable>

    <xsl:variable name="date" select="current-dateTime()"/>
    <xsl:variable name="xslt_vendor" select="system-property('xsl:vendor')"/>
    <xsl:variable name="xslt_version" select="system-property('xsl:version')"/>
    <xsl:variable name="xslt_script" select="'field_books2cpf.xsl'"/>
    <xsl:variable name="xslt_vendor_url" select="system-property('xsl:vendor-url')"/>

    <xsl:variable name="agency_info" xmlns="urn:isbn:1-931666-33-4">
        <agencyCode>
            <xsl:text>OCLC-SMISA</xsl:text>
        </agencyCode>
        <agencyName>
            <xsl:text>Smithsonian Institution Archives</xsl:text>
        </agencyName>
    </xsl:variable>

    <!--
        Instead of reading document into a var, then for-each'ing over the var, just directly for-each the
        document.
        
        Pull in the person and organization data. Later, when parsing the expedition data, create a new sets of
        person and organization. Each of them is de-duplicated. See notes in variables final_per, and final_org.
        
        Var do_not_early_dedup if true() we just read the data from the files (per and org), or if false() we
       de-duplicate the input files immediately. There is no point in deduping early since it is slow and
       since we have to dedup at then end of the whole process.
    -->

    <xsl:variable name="do_not_early_dedup" select="true()"/>
    
    <xsl:variable name="person">
        <xsl:choose>
            <xsl:when test="$do_not_early_dedup">
                <!-- <xsl:copy-of select="document('sia_field/EACP_11_26_12.xml')/fm:FMPDSORESULT/fm:ROW"/> -->
                <xsl:copy-of select="document('sia_field/eacp.xml')/fm:FMPDSORESULT/fm:ROW"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- <xsl:for-each select="document('sia_field/EACP_11_26_12.xml')/fm:FMPDSORESULT/fm:ROW"> -->
                <xsl:for-each select="document('sia_field/eacp.xml')/fm:FMPDSORESULT/fm:ROW">
                    <xsl:variable name="curr" select="."/>
                    <xsl:choose>
                        <xsl:when test="not(preceding::fm:p_primary_name[lib:pname-match(text(),  $curr/fm:p_primary_name)])">
                            <xsl:copy-of select="$curr" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message>
                                <xsl:text>Dup person: </xsl:text>
                                <xsl:copy-of select="$curr/fm:p_primary_name"/>
                                <xsl:text>&#x0A;</xsl:text>
                            </xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>


    <xsl:variable name="organization">
        <xsl:choose>
            <xsl:when test="$do_not_early_dedup">
                <xsl:copy-of select="document('sia_field/eaco.xml')/fm:FMPDSORESULT/fm:ROW"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="document('sia_field/eaco.xml')/fm:FMPDSORESULT/fm:ROW">
                    <xsl:variable name="curr" select="."/>
                    <xsl:choose>
                        <xsl:when test="not(preceding::fm:o_primary_name[lib:pname-match(text(),  $curr/fm:o_primary_name)])">
                            <xsl:copy-of select="$curr" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message>
                                <xsl:text>Dup org: </xsl:text>
                                <xsl:copy-of select="$curr/fm:o_primary_name"/>
                                <xsl:text>&#x0A;</xsl:text>
                            </xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
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
        Expedition only goes into a var once we're inside the main template. We have global vars above for
        person and organization.
    -->

    <xsl:template name="tpt_main" match="/fm:FMPDSORESULT" xmlns="http://www.filemaker.com/fmpdsoresult">
        <xsl:message>
            <xsl:value-of select="concat('Date today: ', current-dateTime(), '&#x0A;')"/>
            <xsl:value-of select="concat('Number of geonames places read in: ', count($places/*), '&#x0A;')"/>
            <xsl:value-of select="concat('Writing output to: ', $output_dir, '&#x0A;')"/>
            <xsl:value-of select="concat('Default authorizedForm: ', $auth_form, '&#x0A;')"/>
            <xsl:value-of select="concat('Fallback (default) agency code: ', $fallback_default, '&#x0A;')"/>
            <xsl:value-of select="concat('Default eventDescription: ', $ev_desc, '&#x0A;')"/>
            <xsl:value-of select="concat('Default xlink href: ', $rr_xlink_href, '&#x0A;')"/>
            <xsl:value-of select="concat('Default xlink role: ', $rr_xlink_role, '&#x0A;')"/>
            <xsl:choose>
                <xsl:when test="$inc_orig">
                    <xsl:value-of select="concat('Include original record: yes', '&#x0A;')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Include original record: no', '&#x0A;')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:message>

        <xsl:variable name="exp_data" >
            <!-- 
                 Allow the blank name for now. Later when we dedup we can filter for empty values as well as
                 dupes. Right now we have fairly rudimentary data. We eventually may want something like the
                 MODID and RECORDID so we can pull all the data from the original records.
                 
                 <expedition id="abc">
                 <person [from_code="eac123"]></person>
                 ...
                 <organization [from_code="eac123"]></organization>
                 ...
                 </expedition>
                 
                 In retrospect, I'm wondering why variable exp_data doesn't have the same internal structure
                 as $final_per and $final_org with an e_name and so on.
            -->
            <xsl:for-each select="fm:ROW">

                <xsl:variable name="edate">
                    <existDates xmlns="urn:isbn:1-931666-33-4">
                        <xsl:call-template name="tpt_simple_date_range">
                            <xsl:with-param name="from" select="fm:e_exist_date_start"/>
                            <xsl:with-param name="from_type" select="$av_active"/>
                            <xsl:with-param name="to" select="fm:e_exist_date_end"/>
                            <xsl:with-param name="to_type" select="$av_active"/>
                            <xsl:with-param name="allow_single" select="true()"/>
                        </xsl:call-template>
                    </existDates>
                </xsl:variable>
                
                <xsl:variable name="parsed_date_range">
                    <xsl:variable name="pd_temp">
                        <xsl:value-of select="$edate/eac:existDates/eac:date"/>
                        <xsl:value-of select="$edate/eac:existDates/eac:dateRange/eac:fromDate"/>
                        <xsl:text>-</xsl:text>
                        <xsl:value-of select="$edate/eac:existDates/eac:dateRange/eac:toDate"/>
                    </xsl:variable>
                    <xsl:value-of select="replace(
                                          replace($pd_temp, '-$', ''),
                                          '\-\s*active', '-')"/>
                </xsl:variable> <!-- end $parsed_date_range -->
                
                <xsl:variable name="tmp_name">
                    <xsl:choose>
                        <xsl:when test="matches(fm:e_primary_name, '\d{4}')">
                            <xsl:value-of select="normalize-space(fm:e_primary_name)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="lib:name-cleanse(concat(fm:e_primary_name, ' (', $parsed_date_range, ')'))"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>

                <expedition expedition_id="{fm:expeditionID}"
                            id="{@MODID}"
                            record_id="{@RECORDID}"
                            enid="{concat('rid_', @RECORDID, '_eid_', fm:expeditionID)}"
                            entity_name="{$tmp_name}">
                    <!--
                        name_entry here?
                        
                        mar 9 2015 add attribut fn_suffix in an attempt to make sure expeditions have a
                        suffix. Apparently they had none, and thus tpt_arc_role was not detecting is_c_flag.
                    -->
                    <e_name xmlns="urn:isbn:1-931666-33-4">
                        <xsl:attribute name="fn_suffix" select="'c'"/>
                        <xsl:value-of select="$tmp_name"/>
                        <name_entry en_lang="en-Latn"
                                    a_form="authorizedForm">
                            <part>
                                <xsl:value-of select="normalize-space($tmp_name)"/>
                            </part>
                        </name_entry>
                        <xsl:for-each select="fm:e_alt_name1|fm:e_alt_name2|fm:e_alt_name3">
                            <xsl:if test="string-length() > 0">
                                <name_entry en_lang="en-Latn"
                                            a_form="alternativeForm">
                                    <part>
                                        <xsl:choose>
                                            <xsl:when test="matches(., '\d{4}')">
                                                <xsl:value-of select="normalize-space(.)"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="lib:name-cleanse(
                                                                      concat(
                                                                      ., ' (', 
                                                                      $parsed_date_range, ')'
                                                                      ))"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                        <!-- <xsl:value-of select="."/> -->
                                    </part>
                                </name_entry>
                            </xsl:if>
                        </xsl:for-each>
                    </e_name>
                        
                    <topical_subject xmlns="urn:isbn:1-931666-33-4">
                        <xsl:for-each select="fm:e_subject/fm:DATA[string-length() > 0]">
                            <localDescription localType="{$av_associatedSubject}">
                                <term>
                                    <xsl:value-of select="normalize-space()"/>
                                </term>
                            </localDescription>
                        </xsl:for-each>
                    </topical_subject>
                    <geographic_subject xmlns="urn:isbn:1-931666-33-4">
                        <xsl:for-each select="fm:e_place/fm:DATA[string-length() > 0]">
                        <place localType="{$av_associatedPlace}">
                            <placeEntry>
                                <xsl:value-of select="normalize-space()"/>
                            </placeEntry>
                        </place>
                        </xsl:for-each>
                    </geographic_subject>
                    <orig>
                        <xsl:copy-of select="."/>
                    </orig>
                    <tag_545>
                        <p xmlns="urn:isbn:1-931666-33-4">
                            <xsl:value-of select="normalize-space(fm:e_description)"/>
                        </p>
                    </tag_545>
                    <e_exist_date_start>
                        <xsl:value-of select="fm:e_exist_date_start"/>
                    </e_exist_date_start>
                    <e_exist_date_end>
                        <xsl:value-of select="fm:e_exist_date_end"/>
                    </e_exist_date_end>
                    <xsl:copy-of select="$edate"/>

                    <!--
                        This looks like a list of participant persons, aka cpfRelations or people who would be .r files in WorldCat.
                        
                        The other person code uses the new e_name format, but I guess this can keep using the
                        old code where the value of the person element is the name.
                    -->
                    <xsl:for-each select="fm:e_participant_person/fm:DATA[string-length() > 0]/text()">
                        <xsl:variable name="curr" select="."/>
                        <xsl:choose>
                            <!--
                                mar 17 2015 This only checks person id values, but should probably check name
                                strings as well. What seems to happen is that names with no id are created and
                                later discovered to be dups and destroyed.
                            -->
                            <xsl:when test="matches(., '^EAC') and count($person/fm:ROW[fm:personID/text() = $curr]) > 0">
                                <xsl:variable name="loc_rid" select="$person/fm:ROW[fm:personID/text() = $curr]/@RECORDID"/>
                                <person>
                                    <xsl:attribute name="entity_type" select="$pers_val"/>
                                    <xsl:attribute name="entity_type_fc" select="$pers_val"/>
                                    <xsl:attribute name="from_code" select="."/>
                                    <xsl:attribute name="enid" select="concat('rid_', $loc_rid, '_pid_', normalize-space($curr))"/>
                                    <xsl:attribute name="record_id" select="$loc_rid"/>
                                    <xsl:attribute name="id" select="$person/fm:ROW[fm:personID/text() = $curr]/@MODID"/>
                                    <xsl:attribute name="person_id" select="normalize-space($curr)"/>
                                    <xsl:value-of select="$person/fm:ROW[fm:personID/text() = $curr]/fm:p_primary_name/normalize-space()"/>
                                </person>
                            </xsl:when>
                            <xsl:when test="not(matches(., '^EAC')) and .">
                                <person>
                                    <xsl:attribute name="entity_type" select="$pers_val"/>
                                    <xsl:attribute name="entity_type_fc" select="$pers_val"/>
                                    <!-- this attribute is fixed later on, or we don't have any examples of this in the data -->
                                    <xsl:attribute name="enid" select="'fixme'"/>
                                    <xsl:value-of select="normalize-space(.)"/>
                                </person>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- empty or EAC with no matching person record -->
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>

                    <xsl:for-each select="fm:e_participant_organization/fm:DATA[string-length() > 0]">
                        <xsl:variable name="curr" select="."/>
                        <organization>
                            <xsl:attribute name="entity_type" select="$corp_val"/>
                            <xsl:attribute name="entity_type_fc" select="$corp_val"/>
                            <xsl:choose>
                                <xsl:when test="matches(., '^EAC')">
                                    <xsl:variable name="loc_rid" select="$organization/fm:ROW[fm:organizationID/text() = $curr]/@RECORDID"/>
                                    <xsl:attribute name="from_code" select="."/>
                                    <xsl:attribute name="record_id" select="$loc_rid"/>
                                    <xsl:attribute name="organization_id" select="normalize-space($curr)"/>
                                    <xsl:attribute name="enid"
                                                   select="concat('rid_', $loc_rid, '_oid_', normalize-space($curr))"/>
                                    <xsl:value-of select="$organization/fm:ROW[fm:organizationID/text() = $curr]/fm:o_primary_name/normalize-space()"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="normalize-space(.)"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </organization>
                    </xsl:for-each>
                </expedition>
            </xsl:for-each>
        </xsl:variable> <!-- end exp_data -->

        <xsl:variable name="final_per" xmlns="urn:isbn:1-931666-33-4">
            <!-- 
                 Create a sequence of both lists in <person> elements. Attributes vary between the lists, and
                 not all person elements from the exp data have from_code. 
                 
                 all new elements are in the eac: namespace since they are output data.
                 
                 Copy the $person data from the file into the list so that our preferential names are the ones
                 with EACPxx id values.
                 
                 Yes, I know we are duplicating the primary name in an attribute, and as the value of <person>.
            -->
            <xsl:variable name="all_per">
                <container>
                    <!-- Person records -->
                    <xsl:for-each select="$person/fm:ROW">
                        <!--
                            xxx
                            born="{$life_dates/eac:birth}"
                            died="{$life_dates/eac:death}"
                            p_primary_name = "{lib:name-cleanse(concat($cn2, ', ', $life_dates/eac:birth, '-', $life_dates/eac:death))}"
                            <xsl:value-of select="lib:name-cleanse(concat($cn2, ', ', $life_dates/eac:birth, '-', $life_dates/eac:death))"/>
                            
                            Mar 17 2015 Unclear why person record internal attributes are prefixed with p_ but
                            regardless, we need non-prefixed (aka normative) attribute names to simplify
                            eac:best_xname() so add the extra attributes. This is not pretty.
                        -->
                        <person
                            born="{./fm:p_exist_date_b}"
                            died="{./fm:p_exist_date_d}"
                            id="{@ROWID}"
                            person_id="{./fm:personID}"
                            record_id="{@RECORDID}"
                            p_lastname = "{normalize-space(fm:p_lastname)}"
                            p_firstname = "{normalize-space(fm:p_firstname)}"
                            p_middle_initial = "{normalize-space(fm:p_middle_initial)}"
                            p_alt_name1 = "{normalize-space(fm:p_alt_name1)}"
                            p_alt_name2 = "{normalize-space(fm:p_alt_name2)}"
                            p_alt_name3 = "{normalize-space(fm:p_alt_name3)}"
                            p_std_name = "{lib:name-cleanse(concat(fm:p_lastname, ', ', fm:p_firstname, ' ', fm:p_middle_initial))}"
                            p_primary_name = "{normalize-space(fm:p_primary_name)}"
                            alt_name1 = "{normalize-space(fm:p_alt_name1)}"
                            alt_name2 = "{normalize-space(fm:p_alt_name2)}"
                            alt_name3 = "{normalize-space(fm:p_alt_name3)}"
                            std_name = "{lib:name-cleanse(concat(fm:p_lastname, ', ', fm:p_firstname, ' ', fm:p_middle_initial))}"
                            primary_name = "{normalize-space(fm:p_primary_name)}"
                            >
                            <!--
                                Should this be the same as p_std_name above? Must have a value because it is
                                used when deduping.
                            -->
                            <xsl:value-of select="normalize-space(fm:p_primary_name)"/>
                            <orig>
                                <xsl:copy-of select="."/>
                            </orig>
                            <tag_545>
                                <p xmlns="urn:isbn:1-931666-33-4">
                                    <xsl:value-of select="normalize-space(fm:p_bio_history)"/>
                                </p>
                            </tag_545>
                            <occ>
                                <xsl:for-each select="fm:p_occupation/fm:DATA[string-length() > 0]">
                                    <occupation>
                                        <term>
                                            <xsl:value-of select="normalize-space(.)"/>
                                        </term>
                                    </occupation>
                                </xsl:for-each>
                            </occ>
                        </person>
                    </xsl:for-each> <!-- end gathering persons with person records -->
                    <!-- 
                         Expedition participants. Get the persons who are listed as expedition
                         participants. These people may have existing person records, but the de-duping step
                         below will take care of duplicates.
                         
                         XSLT doesn't understand XPath attr='' to match a value attr="". Could be a side
                         effect of " and ' interpolation. This doesn't work:
                         select="$exp_data/expedition/person[from_code = '']"
                         
                         Not being derived from any person record, we have to make up an id, person_id and record_id for
                         these people that we find in expeditions. Filenames use record_id as rid, and person_id as the pid.
                         
                         Unfortunately, we don't gather dates here because people could be on several expeditions, and therefore could
                         have several active dates comprising a range from whic we will (below) select the min and max values.
                         
                         I really hate to use weird stuff for these id attribute values. record_id needs
                         to be unique across all person records. person_id is used in the file name so it
                         should be unique too. I don't know if id is even used.
                         
                         We must have an attribute p_primary_name here because later code uses this attribute and not the <person>
                         element value.
                         
                         Mar 17 2015 We must also have attribute primary_name because eac:best_xname() depends
                         on it. Unclear why orgs have normative attribute names, but person still has p_
                         prefix. Looking at this, the p_ prefix is a really bad idea. Oh well.
                         
                         pid_P changed to _pid_P
                         It looks like @enid is overwritten down around line 657.
                    -->
                    <xsl:for-each select="$exp_data/fm:expedition/fm:person[not(from_code/text())]">
                        <person person_id="{concat('P', position())}"
                                id="{concat('ID', position())}"
                                record_id="{concat('R', position())}"
                                enid="{concat('rid_R', position(), '_pid_P', position())}"
                                starting_enid="{concat('rid_R', position(), '_pid_P', position())}"
                                p_primary_name="{.}"
                                primary_name="{.}"
                                xmlns="urn:isbn:1-931666-33-4">
                            <!-- Must have a good value because this is used to dedup the name values. -->
                            <xsl:value-of select="."/>
                            <orig>
                                <xsl:text>Originally derived from expedition/e_participant.</xsl:text>
                            </orig>
                        </person>
                        <xsl:message>
                            <xsl:value-of select="concat('creating: ', ., ' rid_R', position(), '_pid_P', position())"/>
                            <!-- <xsl:apply-templates select="." mode="pretty"/> -->
                        </xsl:message>
                    </xsl:for-each> <!-- end gathering expedition participants -->
                </container>
            </xsl:variable> <!-- end all_per -->
            
            <!-- <xsl:message> -->
            <!--     <xsl:value-of select="concat('all_per: ', $cr)"/> -->
            <!--     <xsl:apply-templates select="$all_per" mode="pretty"/> -->
            <!-- </xsl:message> -->


            <!-- 
                 Copy and dedup. (Apparently) $all_per/eac:container/eac:person/eac:e_name Unclear why extra
                 element level eac:person which is not used in organizations below.
                 
                 Add in date info from expeditions and orgs. Create a node set sequence of the same
                 format as $all_xx in the marc2cpf code such as lib.xsl. See xsl:template name="tpt_all_xx" in
                 lib.xsl.
                 
                 We check names for dates, and create a new, normalized name if necessary here (below) instead
                 of above where there are two name sources (persons and expedition participants). Better to do
                 something once rather than twice. It would be nice to build the final names above, then
                 dedup, but that would realisitically require a new template to hold the name normalization
                 serializing code.
            -->
            <xsl:for-each select="$all_per/eac:container/eac:person">
                <xsl:variable name="curr" select="."/>

                <xsl:variable name="exp_list">
                    <exp_list>
                        <xsl:for-each select="$exp_data/fm:expedition/fm:person[@record_id = $curr/@record_id or text() = $curr/text()]">
                            <exp_info
                                id="{parent::fm:expedition/@id}"
                                expedition_id="{parent::fm:expedition/@expedition_id}"
                                enid="{parent::fm:expedition/@enid}"
                                record_id="{parent::fm:expedition/@record_id}"
                                date_start="{parent::fm:expedition/fm:e_exist_date_start}"
                                date_end="{parent::fm:expedition/fm:e_exist_date_end}"
                                entity_type="{$corp_val}"
                                entity_type_fc="{$corp_val}"
                                entity_name="{parent::fm:expedition/@entity_name}"
                                >
                                <xsl:value-of select="parent::fm:expedition/@exp_name"/>
                            </exp_info>
                        </xsl:for-each>
                    </exp_list>
                </xsl:variable>

                <!--
                    Notice that below we (suddenly) switch from eac:container/eac:person to
                    eac:container/eac:e_name as persons are done in all the other CPF code.
                -->
                <xsl:choose>
                    <xsl:when test="not(preceding::eac:person[lib:pname-match(text(),  $curr/text()) or
                                    lib:pname-match(@p_std_name, $curr/text())])">

                        <xsl:variable name="initial_parsed_date">
                            <xsl:call-template name="tpt_pd">
                                <xsl:with-param name="curr" select="$curr"/>
                                <xsl:with-param name="exp_list" select="$exp_list"/>
                            </xsl:call-template>
                        </xsl:variable>

                        <xsl:variable name="parsed_date">
                            <xsl:call-template name="tpt_pd_scheck">
                                <xsl:with-param name="parsed_date" select="$initial_parsed_date"/>
                            </xsl:call-template>
                        </xsl:variable>

                        <xsl:variable name="parsed_date_range">
                            <xsl:choose>
                                <xsl:when test="$parsed_date/eac:existDates[@localType = $av_suspiciousDate]">
                                    <!-- Do nothing. If the date is suspicious, we don't have a parsed date range. -->
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:variable name="pd_temp">
                                        <!--
                                            Q: Don't these need min() and max() because $parsed_date may contain multiple dates?
                                            
                                            A: No, there are not multiple dates. The for-each above is context setting
                                            only. There is only one $auth_name.
                                        -->
                                        <xsl:value-of select="$parsed_date/eac:existDates/eac:date"/>
                                        <xsl:value-of select="$parsed_date/eac:existDates/eac:dateRange/eac:fromDate"/>
                                        <xsl:text>-</xsl:text>
                                        <xsl:value-of select="$parsed_date/eac:existDates/eac:dateRange/eac:toDate"/>
                                    </xsl:variable>
                                    <!--
                                        Older code was removing a trailing -, but that - is necessary for
                                        born-died, so unclear why it was being removed.
                                        
                                        <xsl:value-of select="replace(replace($pd_temp, '-$', ''), '\-\s*active ', '-')"/>
                                    -->
                                    <xsl:value-of select="replace(replace(replace($pd_temp, '^-$', ''), '\-\s*active ', '-'), '(active.+)\-$', '$1')"/>
                                    <!-- <xsl:value-of select="replace($pd_temp, '\-\s*active ', '-')"/> -->
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable> <!-- end $parsed_date_range -->

                        <!-- 
                             Remove any dates from the name. We have already parsed them and put them back
                             later on.  Mar 17 2015: I wonder if adding @primary_name and not applying the
                             p_primary_name cleaning below will make a mess of things? Perhaps not because the
                             cleaned version goes into $tmp_name which becomes name_entry/part, as well as the
                             value of <e_name>.
                        -->
                        <xsl:variable name="cn1">
                            <xsl:value-of select="replace($curr/@p_primary_name, 'or \d+', '')"/>
                        </xsl:variable>

                        <xsl:variable name="cn12">
                            <xsl:value-of select="replace($cn1, '(c\.*|b\.*|d\.*)*\s*\d{4}\?*\s*\-*', '')"/>
                        </xsl:variable>

                        <xsl:variable name="cn2">
                            <xsl:value-of select="replace(replace(replace($cn12, '\([\-\s]*\)', ''), '&#8206;', ''), '[,\s]+$', '')"/>
                        </xsl:variable>
                        <!-- 
                             xxx
                             Date selection should happen here. Before this, all the dates are not known for all people.
                        -->
                        <container>
                            <e_name>
                                <!--
                                    Copy all the attributes from e_name in $curr to this new copy of
                                    e_name. This copies all the name parts as well as p_primary_name.
                                -->
                                <xsl:for-each select="$curr/@*">
                                    <xsl:attribute name="{local-name()}">
                                        <xsl:value-of select="."/>
                                    </xsl:attribute>
                                </xsl:for-each>
                                <xsl:attribute name="tag" select="'100'"/>
                                <!-- Expeditions need enid, and I don't want to build the pid in two places. -->
                                <xsl:attribute name="enid" select="concat('rid_', $curr/@record_id, '_pid_', $curr/@person_id)"/>
                                <xsl:attribute name="entity_type" select="$pers_val"/>
                                <xsl:attribute name="entity_type_fc" select="$pers_val"/>
                                <xsl:attribute name="fn_suffix" select="'c'"/>
                                <xsl:attribute name="expanded_suffix" select="'P'"/>
                                <xsl:attribute name="is_creator" select="true()"/> <!-- only sort of accurate -->

                                <xsl:message>
                                    <xsl:value-of
                                        select="concat('final_per copy: enid: ',
                                                'rid_', $curr/@record_id, '_pid_', $curr/@person_id)"/>
                                </xsl:message>

                                <!-- see the e_name element value below -->
                                
                                <xsl:variable name="tmp_name">
                                    <!--
                                        Only for person (that is: not corp or family), 
                                        
                                        The name values are create by concat()'ing all the fields together along with their
                                        separators as though every field always had a value. lib:name-cleanse() will remove extraneous
                                        separators due to empty fields. So, the code here is simple and clean, but lib:name-cleanse() has
                                        many small regular expressions.
                                    -->
                                    <xsl:choose>
                                        <xsl:when test="matches(@p_primary_name, '\d{4}') or string-length(@p_lastname) = 0">
                                            <xsl:value-of select="lib:name-cleanse(
                                                                  concat(
                                                                  $cn2, ', ',
                                                                  $parsed_date_range
                                                                  ))"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="lib:name-cleanse(
                                                                  concat(
                                                                  @p_lastname, ', ',
                                                                  @p_firstname, ' ',
                                                                  @p_middle_initial, ', ',
                                                                  $parsed_date_range
                                                                  ))"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:variable><!-- end $tmp_name -->

                                <!-- <xsl:message> -->
                                <!--     <xsl:text>fp: </xsl:text> -->
                                <!--     <xsl:value-of select="concat($tmp_name, ' pdr: ', $parsed_date_range)"/> -->
                                <!-- </xsl:message> -->

                                <name_entry en_lang="en-Latn" a_form="authorizedForm">
                                    <part>
                                        <xsl:value-of select="normalize-space($tmp_name)"/>
                                    </part>
                                </name_entry>

                                <xsl:for-each select="@p_alt_name1|@p_alt_name2|@p_alt_name3">
                                    <xsl:if test="string-length() > 0">
                                        <name_entry en_lang="en-Latn" a_form="alternativeForm">
                                            <part>
                                                <xsl:choose>
                                                    <xsl:when test="matches(., '\d{4}')">
                                                        <xsl:value-of select="normalize-space(.)"/>
                                                    </xsl:when>
                                                    <xsl:otherwise>
                                                        <xsl:value-of select="lib:name-cleanse(
                                                                              concat(
                                                                              ., ', ', 
                                                                              $parsed_date_range
                                                                              ))"/>
                                                    </xsl:otherwise>
                                                </xsl:choose>
                                            </part>
                                        </name_entry>
                                    </xsl:if>
                                </xsl:for-each>
                                <!--
                                    Here is the value for e_name, same as the <part> element value above.
                                    Why is this here? Is there another dedup step later?
                                --> 
                                <xsl:value-of select="normalize-space($tmp_name)"/>
                            </e_name>
                            <xsl:copy-of select="$parsed_date"/>
                            <xsl:copy-of select="./eac:occ"/>
                            <xsl:copy-of select="$exp_list"/>
                            <orig>
                                <xsl:copy-of select="./eac:orig"/>
                            </orig>
                            <tag_545>
                                <xsl:copy-of select="./eac:tag_545/*"/>
                            </tag_545>
                            <xsl:copy-of select="eac:occ_container"/>
                        </container>
                    </xsl:when>
                    <xsl:otherwise>
                        <!--
                            Must be a duplicate, do nothing. A duplicate in this sense can be the result of a
                            few normal cases. For example, a person being on two expeditions. I think.
                        -->
                        <xsl:message>
                            <xsl:text>dup: </xsl:text>
                            <xsl:copy-of select="$curr/text()"/>
                            <xsl:apply-templates select="$curr" mode="pretty"/>
                        </xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable> <!-- end final_per -->

        <!-- <xsl:message> -->
        <!--     <xsl:value-of select="concat('final_per: ', $cr)"/> -->
        <!--     <xsl:apply-templates select="$final_per" mode="pretty"/> -->
        <!-- </xsl:message> -->

        <!-- Beede is a non-coded person found in an expedition, so this is a good QA check. -->
        <!-- <xsl:message> -->
        <!--     <xsl:text>Beede: </xsl:text> -->
        <!--     <xsl:copy-of select="$final_per/eac:container[matches(eac:e_name, 'Beede')]"/> -->
        <!--     <xsl:text>&#x0A;</xsl:text> -->
        <!-- </xsl:message> -->

        <!-- Eklund tag_545 didn't make it into biogHist in the output. -->
        <!-- <xsl:message> -->
        <!--     <xsl:text>Eklund: </xsl:text> -->
        <!--     <xsl:copy-of select="$final_per/eac:container[matches(eac:e_name, 'Eklund')]"/> -->
        <!--     <xsl:text>&#x0A;</xsl:text> -->
        <!-- </xsl:message> -->
        
        <xsl:variable name="final_org" xmlns="urn:isbn:1-931666-33-4">
            <!-- 
                 Create a sequence of both lists in <organization> elements. Attributes vary between the lists, and
                 not all person elements from the exp data have from_code.
                 
                 Copy the $organization data from the file into the list so that our preferential names are the ones
                 with EACOxx id values.
            -->
            <xsl:variable name="all">
                <xsl:for-each select="$organization/fm:ROW">
                    <container>
                        <xsl:variable name="curr" select="."/>

                        <e_name tag="100"
                                organization_id="{./fm:organizationID}"
                                record_id="{@RECORDID}"
                                enid="{concat('rid_', @RECORDID, '_oid_', fm:organizationID)}"
                                id="{@MODID}"
                                entity_type="{$corp_val}"
                                entity_type_fc="{$corp_val}"
                                fn_suffix="c"
                                is_creator="{true()}"
                                alt_name1 = "{normalize-space(fm:o_alt_name1)}"
                                alt_name2 = "{normalize-space(fm:o_alt_name2)}"
                                alt_name3 = "{normalize-space(fm:o_alt_name3)}"
                                primary_name = "{normalize-space(fm:o_primary_name)}">
                            <xsl:value-of select="normalize-space(fm:o_primary_name)"/>
                        </e_name>
                        <orig>
                            <xsl:copy-of select="."/>
                        </orig>
                        <tag_545>
                            <p xmlns="urn:isbn:1-931666-33-4">
                                <xsl:value-of select="normalize-space(fm:o_description)"/>
                            </p>
                        </tag_545>
                        <xsl:variable name="exp_list">
                            <!--
                                Create exp_list as a variable so we can pass it to a call-template. Then a
                                little later we'll put a copy of it into the node set. Remember, $curr is in
                                the fm: namespace, as is $exp_data, although the elements in $exp_data have
                                been made a bit more normative than the original input.
                            -->
                            <exp_list>
                                <xsl:for-each select="$exp_data/fm:expedition/fm:organization[text() = $curr/fm:o_primary_name
                                                      or text() = $curr/fm:organizationID]">
                                    <exp_info
                                        expedition_id="{parent::fm:expedition/@expedition_id}"
                                        id="{parent::fm:expedition/@id}"
                                        record_id="{parent::fm:expedition/@record_id}"
                                        enid="{parent::fm:expedition/@enid}"
                                        date_start="{parent::fm:expedition/fm:e_exist_date_start}"
                                        date_end="{parent::fm:expedition/fm:e_exist_date_end}"
                                        entity_type="{$expe_val}"
                                        entity_type_fc="{$corp_val}"
                                        entity_name="{parent::fm:expedition/@entity_name}"
                                        >
                                        <xsl:value-of select="parent::fm:expedition/@exp_name"/>
                                    </exp_info>
                                </xsl:for-each>
                            </exp_list>
                        </xsl:variable>
                        <!-- Must have at least one date to have an existDates element. -->
                        <xsl:choose>
                            <xsl:when test="string-length(normalize-space(fm:exist_date1)) &gt; 0">
                                <existDates>
                                    <xsl:call-template name="tpt_simple_date_range">
                                        <xsl:with-param name="from" select="fm:exist_date1"/>
                                        <xsl:with-param name="from_type" select="$av_active"/>
                                        <xsl:with-param name="to" select="fm:exist_date2"/>
                                        <xsl:with-param name="to_type" select="$av_active"/>
                                        <xsl:with-param name="allow_single" select="true()"/>
                                    </xsl:call-template>
                                </existDates>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:call-template name="tpt_fb_date">
                                    <xsl:with-param name="exp_info" select="$exp_list"/>
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:copy-of select="$exp_list"/>
                    </container>
                </xsl:for-each>

                <!--
                    Include simple orgs (found in expedition e_participant_organization, but not in the EACO
                    file). Invent data for required fields that are missing. This presumes that every org in
                    an expedition record that can be looked up from the EACO org file has been looked up and
                    has a @from_code.
                -->
                <xsl:for-each select="$exp_data/fm:expedition/fm:organization[not(@from_code)]">
                    <!-- 
                         Not being derived from any organization record, we have to make up some attribute values. 
                    -->
                    <xsl:variable name="curr" select="."/>

                    <xsl:variable name="exp_list">
                        <!--
                            Create exp_list as a variable so we can pass it to a call-template. Then a
                            little later we'll put a copy of it into the node set. Remember, $curr is in
                            the fm: namespace, as is $exp_data, although the elements in $exp_data have
                            been made a bit more normative than the original input.
                        -->
                        <exp_list>
                            <xsl:for-each select="$exp_data/fm:expedition/fm:organization[text() = $curr]">
                                <exp_info
                                    expedition_id="{parent::fm:expedition/@expedition_id}"
                                    id="{parent::fm:expedition/@id}"
                                    record_id="{parent::fm:expedition/@record_id}"
                                    enid="{parent::fm:expedition/@enid}"
                                    date_start="{parent::fm:expedition/fm:e_exist_date_start}"
                                    date_end="{parent::fm:expedition/fm:e_exist_date_end}"
                                    entity_type="{$expe_val}"
                                    entity_type_fc="{$corp_val}"
                                    entity_name="{parent::fm:expedition/@entity_name}"
                                    >
                                    <xsl:value-of select="parent::fm:expedition/@exp_name"/>
                                </exp_info>
                            </xsl:for-each>
                        </exp_list>
                    </xsl:variable>

                    <container xmlns="urn:isbn:1-931666-33-4">
                        <e_name organization_id="{concat('O', position())}"
                                id="{concat('ID', position())}"
                                record_id="{concat('R', position())}"
                                enid="{concat('rid_R', position(), '_oid_O', position())}"
                                entity_type="{$corp_val}"
                                entity_type_fc="{$corp_val}"
                                fn_suffix="c"
                                is_creator="{true()}"
                                primary_name = "{.}">
                            <xsl:value-of select="."/>
                        </e_name>
                        <orig>
                            <xsl:text>Originally derived from expedition/e_participant_organization.</xsl:text>
                        </orig>

                        <!--
                            There's no record to get a date directly from, so try to get active dates from the expedition(s).
                        -->
                        <xsl:call-template name="tpt_fb_date">
                            <xsl:with-param name="exp_info" select="$exp_list"/>
                        </xsl:call-template>
                        <xsl:copy-of select="$exp_list"/>
                    </container>
                </xsl:for-each>
            </xsl:variable>
            <!-- 
                 Copy and dedup. $all/eac:container/eac:e_name
            -->
            <xsl:for-each select="$all/eac:container">
                <xsl:variable name="curr" select="."/>
                <xsl:choose>
                    <xsl:when test="not(preceding::eac:e_name[lib:pname-match(text(),  $curr/eac:e_name/text())])">

                        <xsl:variable name="parsed_date_range">
                            <xsl:variable name="pd_temp">
                                <xsl:value-of select="./eac:existDates/eac:date"/>
                                <xsl:value-of select="./eac:existDates/eac:dateRange/eac:fromDate"/>
                                <xsl:text>-</xsl:text>
                                <xsl:value-of select="./eac:existDates/eac:dateRange/eac:toDate"/>
                            </xsl:variable>
                            <xsl:value-of select="replace(
                                                  replace($pd_temp, '-$', ''),
                                                  '\-\s*active', '-')"/>
                        </xsl:variable> <!-- end $parsed_date_range -->

                        <container>
                            <e_name>
                                <xsl:for-each select="$curr/eac:e_name/@*">
                                    <xsl:attribute name="{local-name()}">
                                        <xsl:value-of select="."/>
                                    </xsl:attribute>
                                </xsl:for-each>
                                <xsl:value-of select="lib:name-cleanse(
                                                      concat(
                                                      eac:e_name, ' (', 
                                                      $parsed_date_range, ')'
                                                      ))"/>
                                <xsl:variable name="tmp_name">
                                    <!--
                                        The name values are create by concat()'ing all the fields together along with their
                                        separators as though every field always had a value. lib:name-cleanse() will remove extraneous
                                        separators due to empty fields. So, the code here is simple and clean, but lib:name-cleanse() has
                                        many small regular expressions.
                                    -->
                                    <xsl:choose>
                                        <xsl:when test="matches(eac:e_name/@primary_name, '\d{4}')">
                                            <xsl:value-of select="normalize-space(@primary_name)"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="lib:name-cleanse(
                                                                  concat(eac:e_name/@primary_name, ' (', $parsed_date_range, ')'))"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:variable><!-- end $tmp_name -->

                                <name_entry en_lang="en-Latn"
                                            a_form="authorizedForm">
                                    <part>
                                        <xsl:value-of select="normalize-space($tmp_name)"/>
                                    </part>
                                </name_entry>

                                    <!-- <xsl:message> -->
                                    <!--     <xsl:text>oa: </xsl:text> -->
                                    <!--     <xsl:copy-of select="."/> -->
                                    <!-- </xsl:message> -->
                                    
                                <xsl:for-each select="$curr/eac:e_name/@alt_name1|$curr/eac:e_name/@alt_name2|$curr/eac:e_name/@alt_name3">
                                    <xsl:if test="string-length() > 0">
                                        <name_entry en_lang="en-Latn"
                                                    a_form="alternativeForm">
                                            <part>
                                                <xsl:choose>
                                                    <xsl:when test="matches(., '\d{4}')">
                                                        <xsl:value-of select="normalize-space(.)"/>
                                                    </xsl:when>
                                                    <xsl:otherwise>
                                                        <xsl:value-of select="lib:name-cleanse(
                                                                              concat(., ' (', $parsed_date_range, ')'))"/>
                                                    </xsl:otherwise>
                                                </xsl:choose>
                                                <!-- <xsl:value-of select="."/> -->
                                            </part>
                                        </name_entry>
                                    </xsl:if>
                                </xsl:for-each>
                            </e_name>
                            <xsl:copy-of select="*[local-name() != 'e_name']"/>
                        </container>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- <xsl:message select="concat('dup: ', $curr, '&#x0A;')"/> -->
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable> <!-- end of var final_org -->

        <xsl:if test="false()">
            <xsl:message>
                <xsl:for-each select="$exp_data/expedition">
                    <xsl:text>expid: </xsl:text>
                    <xsl:value-of select="@id"/>
                    <xsl:text> record_id: </xsl:text>
                    <xsl:value-of select="@record_id"/>
                    <xsl:text>&#x0A;</xsl:text>
                    <xsl:for-each select="node()">
                        <xsl:text>    </xsl:text>
                        <xsl:copy-of select="."/>
                        <xsl:text>&#x0A;</xsl:text>
                    </xsl:for-each>
                    <xsl:text>&#x0A;</xsl:text>
                </xsl:for-each>

                <xsl:value-of select="substring($final_per, 0, 0)"/>
                <xsl:text>final_per: </xsl:text>
                <xsl:text>&#x0A;</xsl:text>
                <xsl:for-each select="$final_per/node()">
                    <xsl:copy-of select="."/>
                    <xsl:text>&#x0A;</xsl:text>
                </xsl:for-each>

                <xsl:value-of select="substring($final_org, 0, 0)"/>
                <xsl:text>final_org: </xsl:text>
                <xsl:text>&#x0A;</xsl:text>
                <xsl:for-each select="$final_org/node()">
                    <xsl:copy-of select="."/>
                    <xsl:text>&#x0A;</xsl:text>
                </xsl:for-each>
            </xsl:message>
        </xsl:if>

        <xsl:call-template name="tpt_person_output">
            <xsl:with-param name="all" select="$final_per"/>
        </xsl:call-template>

        <xsl:call-template name="tpt_exp_output">
            <xsl:with-param name="exp_data" select="$exp_data"/>
            <xsl:with-param name="final_per" select="$final_per"/>
            <xsl:with-param name="final_org" select="$final_org"/>
        </xsl:call-template>

        <xsl:call-template name="tpt_org_output">
            <xsl:with-param name="all" select="$final_org"/>
        </xsl:call-template>

    </xsl:template> <!-- end of template tpt_main -->

    <xsl:template name="tpt_pd" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="curr"/>
        <xsl:param name="exp_list"/>
        <!--
            This is a template for person dates (pd). We have 3 kinds of dates: born/died, single active, multi active. The
            born/died comes from the original EAC record file. Entities that are only
            known from an association with an expedition use the expedition date or dates
            as active.
        -->

        <!-- <xsl:message> -->
        <!--     <xsl:text>band: </xsl:text> -->
        <!--     <xsl:copy-of select="$curr"/> -->
        <!-- </xsl:message> -->

        <xsl:variable name='life_dates'>
            <xsl:choose>
                <xsl:when test="string-length($curr/@born) > 0 or string-length($curr/@died)">
                        <xsl:value-of select="concat($curr/@born, '-', $curr/@died)"/>
                </xsl:when>
                <xsl:when test="matches($curr/@p_primary_name, '\d{4}')">
                    <!--
                        Presumably only one of these will match. Might be good to wrap them up
                        in choose/when to make that certain.
                    -->
                    <!-- <xsl:variable name="re1" select="'((c\.*|b\.*|d\.*)*\s*\d{4}\?*)\s*\-\s*((c\.*|b\.*|d\.*)*\s*\d{4}\?*)'"/> -->
                    <xsl:variable name="re1" select="'(c\.*|b\.*|d\.*)*\s*\d{4}\?*.*(c\.*|b\.*|d\.*)*\s*\d{4}\?*'"/>
                    <xsl:variable name="re2" select="'((c\.*|b\.*|d\.*)*\s*\d{4}\?*)\s*\-'"/>
                    <xsl:variable name="re4" select="'((c\.*|b\.*|d\.*)*\s*\d{4}\?*)'"/>
                    <xsl:choose>
                        <xsl:when test="matches($curr/@p_primary_name, $re1)">
                            <xsl:analyze-string select="$curr/@p_primary_name" regex="{$re1}">
                                <xsl:matching-substring>
                                    <xsl:value-of select="regex-group(0)"/>
                                </xsl:matching-substring>
                            </xsl:analyze-string>
                        </xsl:when>
                        <xsl:when test="matches($curr/@p_primary_name, $re2)">
                            <xsl:analyze-string select="$curr/@p_primary_name" regex="{$re2}">
                                <xsl:matching-substring>
                                        <xsl:value-of select="concat('2 ', regex-group(1))"/>
                                </xsl:matching-substring>
                            </xsl:analyze-string>
                        </xsl:when>
                        <xsl:when test="matches($curr/@p_primary_name, $re4)">
                            <xsl:analyze-string select="$curr/@p_primary_name" regex="{$re4}">
                                <xsl:matching-substring>
                                        <xsl:value-of select="concat('3 ', regex-group(1))"/>
                                </xsl:matching-substring>
                            </xsl:analyze-string>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- No date string. -->
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
            </xsl:choose>
        </xsl:variable><!-- end life_dates -->

        <!-- <xsl:message> -->
        <!--     <xsl:text>band: </xsl:text> -->
        <!--     <xsl:value-of select="concat($curr/@id, ' ', $curr/@person_id, ' x', $curr/@p_primary_name, 'x ' )"/> -->
        <!--     <xsl:copy-of select="$life_dates"/> -->
        <!-- </xsl:message> -->
        

        <xsl:choose>
            <!-- <xsl:when test="string-length(normalize-space($curr/@born))=4  or string-length(normalize-space($curr/@died))=4"> -->
            <xsl:when test="string-length($life_dates)>=4">
                <xsl:variable name="tokens">
                    <xsl:call-template name="tpt_exist_dates">
                        <xsl:with-param name="xx_tag" select="'not used'"/>
                        <xsl:with-param name="entity_type" select="'not used'"/>
                        <xsl:with-param name="rec_pos" select="'not used'"/>
                        <xsl:with-param name="subfield_d">
                            <!-- <xsl:value-of select="concat($curr/@born, '-', $curr/@died)"/> -->
                            <xsl:value-of select="$life_dates"/>
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
                        <xsl:with-param name="is_family" select="false()"/>
                        <xsl:with-param name="entity_type" select="$pers_val"/>
                        <xsl:with-param name="rec_pos" select="'not_used'"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:copy-of select="$show_date"/>



                <!-- <existDates xmlns="urn:isbn:1-931666-33-4"> -->
                <!--     <xsl:call-template name="tpt_simple_date_range"> -->
                <!--         <xsl:with-param name="from" select="$curr/@born"/> -->
                <!--         <xsl:with-param name="from_type" select="$av_born"/> -->
                <!--         <xsl:with-param name="to" select="$curr/@died"/> -->
                <!--         <xsl:with-param name="to_type" select="$av_died"/> -->
                <!--         <xsl:with-param name="allow_single" select="false()"/> -->
                <!--     </xsl:call-template> -->
                <!-- </existDates> -->
            </xsl:when>
            <xsl:when test="count($exp_list/eac:exp_list/eac:exp_info) = 1">
                <existDates xmlns="urn:isbn:1-931666-33-4">
                    <!-- for-each only sets the context, since we only have a single item. -->
                    <xsl:for-each select="$exp_list/eac:exp_list/eac:exp_info">
                        <xsl:call-template name="tpt_simple_date_range">
                            <xsl:with-param name="from" select="@date_start"/>
                            <xsl:with-param name="from_type" select="$av_active"/>
                            <xsl:with-param name="to" select="@date_end"/>
                            <xsl:with-param name="to_type" select="$av_active"/>
                            <xsl:with-param name="allow_single" select="true()"/>
                        </xsl:call-template>
                    </xsl:for-each>
                </existDates>
            </xsl:when>
            <xsl:when test="count($exp_list/eac:exp_list/eac:exp_info/@date_start) > 1 and
                            (
                            min($exp_list/eac:exp_list/eac:exp_info/@date_start) !=
                            max($exp_list/eac:exp_list/eac:exp_info/@date_start)
                            )">
                <existDates xmlns="urn:isbn:1-931666-33-4">
                    <dateSet>
                        <xsl:for-each select="$exp_list/eac:exp_list/eac:exp_info">
                            <xsl:call-template name="tpt_simple_date_range">
                                <xsl:with-param name="from" select="@date_start"/>
                                <xsl:with-param name="from_type" select="$av_active"/>
                                <xsl:with-param name="to" select="@date_end"/>
                                <xsl:with-param name="to_type" select="$av_active"/>
                                <xsl:with-param name="allow_single" select="true()"/>
                            </xsl:call-template>
                        </xsl:for-each>
                    </dateSet>
                </existDates>
            </xsl:when>
            <!-- otherwise we don't have a date -->
        </xsl:choose>

    </xsl:template>

    <xsl:template name="tpt_pd_scheck" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="parsed_date"/>
        <!--
            Parsed date (pd) suspicious check (scheck). 
        -->
        <xsl:variable name="fd" select="$parsed_date/eac:existDates/eac:dateRange/eac:fromDate"/>
        <xsl:variable name="td" select="$parsed_date/eac:existDates/eac:dateRange/eac:toDate"/>
        
        <xsl:choose>
            <xsl:when test="number($fd) > number($td)">
            <existDates localType="{$av_suspiciousDate}">
                <xsl:copy-of select="$parsed_date/eac:existDates/*"/>
            </existDates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$parsed_date"/>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <xsl:template match="*">
        <!-- There must be a reason for this. Does the default * template do something we don't like? -->
    </xsl:template>

    <xsl:template name="tpt_person_output" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="all"/>

        <xsl:for-each select="$all/eac:container">

            <xsl:variable name="unused" select="''"/>

            <xsl:variable name="file_name" select="concat($output_dir, '/', eac:e_name/@enid, '.c.xml')"/>

            <xsl:variable name="cpf_relation">
                <!--
                    Related expeditions. Use to be: frbr:{@entity_type_fc}
                -->
                <!-- <xsl:message> -->
                <!--     <xsl:value-of select="concat('exp_list:', $cr)"/> -->
                <!--     <xsl:apply-templates select="eac:exp_list" mode="pretty"/> -->
                <!-- </xsl:message> -->

                <xsl:for-each select="eac:exp_list/eac:exp_info">
                    
                    <xsl:message>
                        <xsl:value-of select="concat('person: cpf_relation:', $cr)"/>
                        <xsl:apply-templates select="." mode="pretty"/>
                    </xsl:message>
                    
                    <xsl:variable name="et" select="@entity_type"/>
                    <cpfRelation xlink:type="simple"
                                 xlink:role="{$etype/eac:value[@key = $et]}"
                                 xlink:arcrole="{$av_associatedWith}">
                        <relationEntry><xsl:value-of select="@entity_name"/></relationEntry>
                        <descriptiveNote>
                            <p>
                                <span localType="{$av_extractRecordId}">
                                    <!-- <xsl:value-of select="concat('rid_', @record_id, '_eid_', @expedition_id, '.c')"/> -->
                                    <xsl:value-of select="@enid"/>
                                </span>
                            </p>
                        </descriptiveNote>
                    </cpfRelation>
                </xsl:for-each>
            </xsl:variable>

            <xsl:variable name="original" select="eac:orig"/>
            <xsl:variable name="lang_decl">
                <languageDeclaration>
                    <language languageCode="eng">English</language>
                    <script scriptCode="Latn">Latin</script>
                </languageDeclaration>
            </xsl:variable>
            <xsl:variable name="topical_subject" select="''"/>
            <xsl:variable name="geographic_subject" select="''"/>
            <!--
                Hard code these to English for now. They all seem to be English and there's no apparent data
                field.
            -->
            <xsl:variable name="language">
                <languageUsed>
                    <language languageCode="eng">English</language>
                    <script scriptCode="Latn">Latin</script>
                </languageUsed>
            </xsl:variable>

            <xsl:variable name="mods">
                <!-- There isn't much logic to a MODS record for field books data, but I've left the source
                     commented here for easy reading. See tpt_mods in lib.xsl. -->

                <!-- 
	        <objectXMLWrap>
                    <mods xmlns="http://www.loc.gov/mods/v3">
                        <xsl:for-each select="$all_xx/eac:container/eac:e_name[matches(@tag, '1(00|10|11)') or @is_creator=true()]">
                            <name>
                                <namePart><xsl:value-of select="."/></namePart>
                                <role>
                                    <roleTerm valueURI="http://id.loc.gov/vocabulary/relators/cre">Creator</roleTerm>
                                </role>
                            </name>
                        </xsl:for-each>
                        <titleInfo>
                            <title><xsl:value-of select="$title"/></title>
                        </titleInfo>
                        <xsl:if test="count(marc:datafield[@tag = '520']/marc:subfield[@code = 'a']) >= 1">
                            <abstract>
                                <xsl:for-each select="marc:datafield[@tag = '520']/marc:subfield[@code = 'a']">
                                    <xsl:value-of select="."/>
                                    <xsl:text> </xsl:text>
                                </xsl:for-each>
                            </abstract>
                        </xsl:if>
                        <xsl:if test="string-length($agency_info/eac:agencyName) > 0">
                            <name>
                                <namePart><xsl:value-of select="$agency_info/eac:agencyName"/></namePart>
                                <role>
                                    <roleTerm valueURI="http://id.loc.gov/vocabulary/relators/rps">Repository</roleTerm>
                                </role>
                            </name>
                        </xsl:if>
                    </mods>
                </objectXMLWrap>
                -->
            </xsl:variable>

            <xsl:variable name="is_c_flag" as="xs:boolean">
                <xsl:value-of select="eac:e_name/@fn_suffix = 'c'"/>
            </xsl:variable>
            
            <xsl:variable name="is_r_flag" as="xs:boolean">
                <xsl:value-of select="substring(eac:e_name/@fn_suffix, 1, 1) = 'r'"/>
            </xsl:variable>

            <xsl:message>
                <!-- <xsl:apply-templates select="." mode="pretty"/> -->
                <xsl:value-of select="concat('name: ', eac:e_name/eac:name_entry[1]/eac:part, ' suffix: ', eac:e_name/@fn_suffix)"/>
            </xsl:message>

            <!--
                <resourceRelation xlink:arcrole="{$wcrr_arc_role}" aka WorldCat resource relation
            -->
            <xsl:variable name="wcrr_arc_role">
                <xsl:call-template name="tpt_arc_role">
                    <xsl:with-param name="is_c_flag" select="$is_c_flag"/>
                    <xsl:with-param name="is_r_flag" select="$is_r_flag"/>
                </xsl:call-template>
            </xsl:variable>

            <!--
                Var rel_entry becomes relationEntry which is a link to the archival record describing
                ourself. Currently person and org name is the value of e_name, although for consistency (and
                robustness) it might better be an attribute.
                
                Don't use eac:e_name because text() and the child element values will be concatenated.

                Var $controlfield_001 is part of the resourceRelation, and also used in the source xlink:href.
            -->
            <xsl:variable name="rel_entry" select="eac:e_name/text()"/>
            <xsl:variable name="controlfield_001" select="eac:e_name/@enid"/>

            <!--
                Title statement. We might be able to fudge something for this.
            -->
            <xsl:variable name="tag_245" select="'Person'"/>

            <!-- 
                 New params to tpt_body are in a variable nodeset which is easier to update,
                 modify, add to, and delete from than hard coded params. It should have been like
                 this from the start.
                 
                 Remember to change the other 2 param_data variables!
            -->
            
            <xsl:variable name="param_data">
                <use_source_href  as="xs:boolean">
                    <xsl:value-of select="false()"/>
                </use_source_href>
                <use_rrel as="xs:boolean">
                    <xsl:value-of select="true()"/>
                </use_rrel>
                <xsl:copy-of select="eac:e_name"/>
                <citation>
                    <xsl:value-of select="'Smithsonian Institution Archives Field Book Project: '"/>
                    <xsl:value-of select="lib:capitalize(eac:e_name/@entity_type)"/>
                    <xsl:text> : Description : </xsl:text>
                    <xsl:value-of select="eac:e_name/@enid"/>
                </citation>
                <inc_orig>
                    <xsl:copy-of select="$inc_orig" />
                </inc_orig>
                <xsl:copy-of select="$tc_data/eac:agency_info"/>
                <xsl:copy-of select="$tc_data/eac:snac_info"/>
                <ev_desc>
                    <xsl:value-of select="$ev_desc"/>
                </ev_desc>
                <rules>
                    <xsl:value-of select="$auth_form"/>
                </rules>
                <rr_xlink_href>
                    <xsl:value-of select="$rr_xlink_href"/>
                </rr_xlink_href>
                <rr_xlink_role>
                    <xsl:value-of select="$rr_xlink_role"/>
                </rr_xlink_role>
                <!-- legacy resourceRelation uses xlink_role -->
                <xlink_role>
                    <xsl:value-of select="$rr_xlink_role"/>
                </xlink_role>
                <!--
                    This sends over the current eac:container wrapper element, which has all kinds of info about
                    the current entity. Currently it is used for occupation and function.
                -->
                <xsl:copy-of select="."/>
            </xsl:variable>

            <!--
                Note: the context is a <container> node set. <container><e_name>...</e_name><existDates>...</existDates></container>
            -->
            <xsl:if test="true()"> <!-- "position() &lt; 1000"> -->
                <xsl:result-document href="{$file_name}" format="xml" >
                    <xsl:call-template name="tpt_body">
                        <xsl:with-param name="exist_dates" select="./eac:existDates" as="node()*" />
                        <xsl:with-param name="entity_type" select="$cpf_pers_val"/>
                        <!-- <xsl:with-param name="entity_name" select="eac:e_name"/> -->
                        <xsl:with-param name="leader06" select="$unused"/>
                        <xsl:with-param name="leader07" select="$unused"/>
                        <xsl:with-param name="leader08" select="$unused"/>
                        <xsl:with-param name="mods" select="$mods"/>
                        <xsl:with-param name="rel_entry" select="$rel_entry"/>
                        <xsl:with-param name="wcrr_arc_role" select="$wcrr_arc_role"/>
                        <xsl:with-param name="controlfield_001" select="$controlfield_001"/>
                        <xsl:with-param name="is_c_flag" select="true()"/>
                        <xsl:with-param name="is_r_flag" select="false()"/>
                        <xsl:with-param name="fn_suffix" select="'c'" />
                        <xsl:with-param name="cpf_relation" select="$cpf_relation" />
                        <xsl:with-param name="record_id" select="eac:e_name/@enid" />
                        <xsl:with-param name="date" select="$date" />
                        <xsl:with-param name="xslt_vendor" select="$xslt_vendor"/>
                        <xsl:with-param name="xslt_version" select="$xslt_version"/>
                        <xsl:with-param name="xslt_vendor_url" select="$xslt_vendor_url"/>
                        <!--
                            Don't use xpath eac:tag_545/text() because the child node is not a text node, but a <p>
                            node. text() is empty.
                        -->
                        <xsl:with-param name="tag_545" select="eac:tag_545/*"/>
                        <xsl:with-param name="tag_245" select="normalize-space($tag_245)"/>
                        <xsl:with-param name="xslt_script" select="$xslt_script"/>
                        <xsl:with-param name="original" select="$original"/>
                        <xsl:with-param name="lang_decl" select="$lang_decl"/>
                        <xsl:with-param name="topical_subject" select="$topical_subject"/>
                        <xsl:with-param name="geographic_subject" select="$geographic_subject"/>
                        <xsl:with-param name="language" select="$language"/>
                        <xsl:with-param name="param_data" select="$param_data"/>
                    </xsl:call-template>
                </xsl:result-document>
            </xsl:if>
        </xsl:for-each>
    </xsl:template> <!-- end tpt_person_output -->


    <xsl:template name="tpt_org_output" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="all"/>

        <xsl:for-each select="$all/eac:container">

            <xsl:variable name="unused" select="''"/>

            <xsl:variable name="file_name" select="concat('sia_fb_cpf/', eac:e_name/@enid, '.c.xml')"/>

            <xsl:variable name="cpf_relation">
                <!--
                    Related expeditions. Used to be "frbr:{@entity_type_fc}". $etype is a simple node set for
                    key/value lookup. Typically this would be person=$av_Person,
                    corporateBody=$av_CorporateBody, family=$av_Family
                -->
                <!-- <xsl:message> -->
                <!--     <xsl:value-of select="concat('exp_list:', $cr)"/> -->
                <!--     <xsl:apply-templates select="eac:exp_list" mode="pretty"/> -->
                <!-- </xsl:message> -->
                <xsl:for-each select="eac:exp_list/eac:exp_info">
                    <xsl:variable name="et" select="@entity_type"/>
                    <cpfRelation xlink:type="simple"
                                 xlink:role="{$etype/eac:value[@key = $et]}"
                                 xlink:arcrole="{$av_associatedWith}">
                        <relationEntry><xsl:value-of select="@entity_name"/></relationEntry>
                        <descriptiveNote>
                            <p>
                                <span localType="{$av_extractRecordId}">
                                    <!-- <xsl:value-of select="concat('rid_', @record_id, '_eid_', @expedition_id, '.c')"/> -->
                                    <xsl:value-of select="@enid"/>
                                </span>
                            </p>
                        </descriptiveNote>
                    </cpfRelation>
                </xsl:for-each>
            </xsl:variable>
            
            <xsl:variable name="original" select="eac:orig"/>
            <xsl:variable name="lang_decl">
                <languageDeclaration>
                    <language languageCode="eng">English</language>
                    <script scriptCode="Latn">Latin</script>
                </languageDeclaration>
            </xsl:variable>
            <xsl:variable name="topical_subject" select="''"/>
            <xsl:variable name="geographic_subject" select="''"/>

            <!--
                Hard code these to English for now. They all seem to be English and there's no apparent data
                field.
            -->
            <xsl:variable name="language">
                <languageUsed>
                    <language languageCode="eng">English</language>
                    <script scriptCode="Latn">Latin</script>
                </languageUsed>
            </xsl:variable>

            <xsl:variable name="mods">
                <!--
                    There isn't much logic to a MODS record for field books data.  See tpt_mods in lib.xsl.
                -->
            </xsl:variable>

            <xsl:variable name="is_c_flag" as="xs:boolean">
                <xsl:value-of select="eac:e_name/@fn_suffix = 'c'"/>
            </xsl:variable>
            
            <xsl:variable name="is_r_flag" as="xs:boolean">
                <xsl:value-of select="substring(eac:e_name/@fn_suffix, 1, 1) = 'r'"/>
            </xsl:variable>

            <xsl:message>
                <!-- <xsl:apply-templates select="." mode="pretty"/> -->
                <xsl:value-of select="concat('name: ', eac:e_name/eac:name_entry[1]/eac:part, ' suffix: ', eac:e_name/@fn_suffix)"/>
            </xsl:message>

            <!--
                <resourceRelation xmlns:xlink="http://www.w3.org/1999/xlink"
                xlink:arcrole="{$wcrr_arc_role}"
            -->
            <xsl:variable name="wcrr_arc_role">
                <xsl:call-template name="tpt_arc_role">
                    <xsl:with-param name="is_c_flag" select="$is_c_flag"/>
                    <xsl:with-param name="is_r_flag" select="$is_r_flag"/>
                </xsl:call-template>
            </xsl:variable>

            <!--
                Var rel_entry is relationEntry may work for expedition with persons listed as "creatorOf" or
                perhaps the canonical equivalent of "participantIn". Historically I wasn't sure what to put
                here. It is a link to the archival record describing ourself. Currently person and org name is
                the value of e_name, although for consistency (and robustness) it might better be an
                attribute.
                
                Var controlfield_001 is a record id that is part of the resourceRelation
                xlink:href="{$param_data/eac:rr_xlink_href}/{$controlfield_001}">
                
                Also used in the source xlink:href.
            -->
            <xsl:variable name="rel_entry" select="eac:e_name/text()"/>
            <xsl:variable name="controlfield_001" select="eac:e_name/@enid"/>

            <!--
                Title statement. We might be able to fudge something for this.
            -->
            <xsl:variable name="tag_245" select="'CorporateBody'"/>


            <!-- 
                 param_data is a node set used to pass the equivalent of multiple parameters to a template. It
                 is cleaner, easier to modify than the big list of explicit params.
                 
                 Remember to change the other 2 param_data variables!
            -->
            <xsl:variable name="param_data">
                <use_source_href  as="xs:boolean">
                    <xsl:value-of select="false()"/>
                </use_source_href>
                <use_rrel as="xs:boolean">
                    <xsl:value-of select="true()"/>
                </use_rrel>
                <xsl:copy-of select="eac:e_name"/>
                <citation>
                    <xsl:value-of select="'Smithsonian Institution Archives Field Book Project: '"/>
                    <xsl:value-of select="lib:capitalize(eac:e_name/@entity_type)"/>
                    <xsl:text> : Description : </xsl:text>
                    <xsl:value-of select="eac:e_name/@enid"/>
                </citation>
                <inc_orig>
                    <xsl:copy-of select="$inc_orig" />
                </inc_orig>
                <xsl:copy-of select="$tc_data/eac:agency_info"/>
                <xsl:copy-of select="$tc_data/eac:snac_info"/>
                <ev_desc>
                    <xsl:value-of select="$ev_desc"/>
                </ev_desc>
                <rules>
                    <xsl:value-of select="$auth_form"/>
                </rules>
                <rr_xlink_href>
                    <xsl:value-of select="$rr_xlink_href"/>
                </rr_xlink_href>
                <rr_xlink_role>
                    <xsl:value-of select="$rr_xlink_role"/>
                </rr_xlink_role>
                <!-- legacy resourceRelation uses xlink_role -->
                <xlink_role>
                    <xsl:value-of select="$rr_xlink_role"/>
                </xlink_role>
            </xsl:variable>

            <!--
                Note: the context is a <container> node set. <container><e_name>...</e_name><existDates>...</existDates></container>
            -->
            <xsl:if test="true()"> <!-- "position() &lt; 1000"> -->
                <xsl:result-document href="{$file_name}" format="xml" >
                    <xsl:call-template name="tpt_body">
                        <xsl:with-param name="exist_dates" select="./eac:existDates" as="node()*" />
                        <xsl:with-param name="entity_type" select="$cpf_corp_val" />
                        <!-- <xsl:with-param name="entity_name" select="eac:e_name"/> -->
                        <xsl:with-param name="leader06" select="$unused"/>
                        <xsl:with-param name="leader07" select="$unused"/>
                        <xsl:with-param name="leader08" select="$unused"/>
                        <xsl:with-param name="mods" select="$mods"/>
                        <xsl:with-param name="rel_entry" select="$rel_entry"/>
                        <xsl:with-param name="wcrr_arc_role" select="$wcrr_arc_role"/>
                        <xsl:with-param name="controlfield_001" select="$controlfield_001"/>
                        <xsl:with-param name="is_c_flag" select="true()"/>
                        <xsl:with-param name="is_r_flag" select="false()"/>
                        <xsl:with-param name="fn_suffix" select="'c'" />
                        <xsl:with-param name="cpf_relation" select="$cpf_relation" />
                        <xsl:with-param name="record_id" select="eac:e_name/@enid" />
                        <xsl:with-param name="date" select="$date" />
                        <xsl:with-param name="xslt_vendor" select="$xslt_vendor"/>
                        <xsl:with-param name="xslt_version" select="$xslt_version"/>
                        <xsl:with-param name="xslt_vendor_url" select="$xslt_vendor_url"/>
                        <!--
                            Don't use xpath eac:tag_545/text() because the child node is not a text node, but a <p>
                            node. text() is empty.
                        -->
                        <xsl:with-param name="tag_545" select="eac:tag_545/*"/>
                        <xsl:with-param name="tag_245" select="normalize-space($tag_245)"/>
                        <xsl:with-param name="xslt_script" select="$xslt_script"/>
                        <xsl:with-param name="original" select="$original"/>
                        <xsl:with-param name="lang_decl" select="$lang_decl"/>
                        <xsl:with-param name="topical_subject" select="$topical_subject"/>
                        <xsl:with-param name="geographic_subject" select="$geographic_subject"/>
                        <xsl:with-param name="language" select="$language"/>
                        <xsl:with-param name="param_data" select="$param_data"/>
                    </xsl:call-template>
                </xsl:result-document>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="tpt_exp_output" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="exp_data"/>
        <xsl:param name="final_per"/>
        <xsl:param name="final_org"/>

        <!-- 
             The data in $exp_data is is slightly different from $final_per and $final_org. both of which have
             an eac:e_name, but expedition does not.  So expedition uses "@enid" but person and organzation
             use "eac:e_name/@enid".
        -->
        <xsl:for-each select="$exp_data/fm:expedition">

            <xsl:variable name="unused" select="''"/>

            <!-- <xsl:variable name="record_id" select="concat('rid_', @record_id, '_eid_', @expedition_id)"/> -->
            <xsl:variable name="file_name" select="concat('sia_fb_cpf/', @enid, '.c.xml')"/>
            
            <xsl:variable name="cpf_relation">
                <!--
                    Build a cpfRelation for every person. Since persons without a record_id will get their id
                    during person processing, we have to look that up.

                    $etype is a simple node set for key/value
                    lookup. Typically this would be person=$av_Person, corporateBody=$av_CorporateBody,
                    family=$av_Family
                -->
                <!-- <xsl:message> -->
                <!--     <xsl:value-of select="concat('exp_list: person:', $cr)"/> -->
                <!--     <xsl:apply-templates select="fm:person" mode="pretty"/> -->
                <!-- </xsl:message> -->
                <xsl:for-each select="fm:person">
                    <xsl:variable name="et" select="@entity_type"/>
                    <xsl:variable name="curr" select="."/>

                    <!--
                        If the person has a @from_code then there's no doubt about the cpfRelation identity
                        and we need to use that @from_code.
                    -->
                    <xsl:variable name="xname">
                        <xsl:choose>
                            <xsl:when test="string-length(@from_code) > 0">
                                <xsl:variable name="from_code" select="@from_code"/>
                                <entity_name>
                                    <xsl:value-of select="$final_per/eac:container/eac:e_name[@person_id = $from_code]/text()"/>
                                </entity_name>
                                <enid>
                                    <xsl:value-of select="$final_per/eac:container/eac:e_name[@person_id = $from_code]/@enid"/>
                                </enid>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:copy-of select="eac:best_xname($final_per, $curr)"/>

                                <!-- disable old code -->
                                <xsl:if test="false()">
                                    <xsl:for-each select="$final_per/eac:container/eac:e_name">
                                        <xsl:variable name="en_context" select="."/>
                                        <xsl:variable name="cname" select="text()"/>
                                        <!--
                                            This use to be "@*" and worked because of the many attributes in an e_name,
                                            there are p_primary_name, p_alt_name1, p_alt_name2, p_alt_name3, and
                                            p_std_name. We create p_std_name based on p_lastname, p_firstname p_middle
                                            initial. Attributes that didn't match just used extra cpu, but didn't cause problems.
                                        -->
                                        <!-- <xsl:for-each select="@p_primary_name|@p_alt_name1|@p_alt_name2|@p_alt_name3|@p_std_name"> -->
                                        <!-- <xsl:if test=". = $curr/text()"> -->
                                        <xsl:if test="(@p_primary_name|@p_alt_name1|@p_alt_name2|@p_alt_name3|@p_std_name) = $curr/text()">
                                            <entity_name>
                                                <xsl:value-of select="$cname"/>
                                            </entity_name>
                                            <enid>
                                                <xsl:value-of select="$en_context/@enid"/>
                                            </enid>
                                        </xsl:if>
                                        <!-- </xsl:for-each> -->
                                    </xsl:for-each>
                                </xsl:if>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>

                    <xsl:message>
                        <xsl:value-of select="'xname: '"/>
                        <xsl:apply-templates select="$xname" mode="pretty"/>
                    </xsl:message>

                    <cpfRelation xlink:type="simple"
                                 xlink:role="{$etype/eac:value[@key = $et]}"
                                 xlink:arcrole="{$av_associatedWith}">
                        <relationEntry><xsl:value-of select="$xname/eac:entity_name"/></relationEntry>
                        <descriptiveNote>
                            <p>
                                <span localType="{$av_extractRecordId}">
                                    <xsl:value-of select="$xname/eac:enid"/>
                                </span>
                            </p>
                        </descriptiveNote>
                    </cpfRelation>
                </xsl:for-each>

                <xsl:for-each select="fm:organization">
                    <xsl:variable name="et" select="@entity_type"/>
                    <xsl:variable name="curr" select="."/>
                    <xsl:variable name="curr_text_lc" select="lower-case(.)"/>
                    <xsl:variable name="xname">
                        <!--
                            Same as person above. Search them all and try to match against all possible
                            attributes that have various forms of the name.
                        -->
                        
                        <xsl:message>
                            <xsl:value-of select="concat('xname: org: context:', $cr)"/>
                            <xsl:apply-templates select="." mode="pretty"/>
                        </xsl:message>

                        <xsl:choose>
                            <xsl:when test="string-length(@from_code) > 0">
                                <xsl:variable name="from_code" select="@from_code"/>
                                <entity_name>
                                    <xsl:value-of select="$final_org/eac:container/eac:e_name[@organization_id = $from_code]/text()"/>
                                </entity_name>
                                <enid>
                                    <xsl:value-of select="$final_org/eac:container/eac:e_name[@organization_id = $from_code]/@enid"/>
                                </enid>
                            </xsl:when>
                            <xsl:otherwise>
                                <!--
                                    mar 9 2015
                                    
                                    Unfortunately, we might have a name that doesn't have a match in the list
                                    of orgs. So first look for a match in the orgs. If found, use it, else use
                                    $curr/text().
                                -->
                                <xsl:copy-of select="eac:best_xname($final_org, $curr)"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>

                    <!-- <xsl:message> -->
                    <!--     <xsl:value-of select="concat('org: xname:', $cr)"/> -->
                    <!--     <xsl:apply-templates select="$xname" mode="pretty"/> -->
                    <!--     <xsl:value-of select="concat('curr: text:', $curr/text(), $cr)"/> -->
                    <!-- </xsl:message> -->

                    <cpfRelation xlink:type="simple"
                                 xlink:role="{$etype/eac:value[@key = $et]}"
                                 xlink:arcrole="{$av_associatedWith}">
                        <relationEntry><xsl:value-of select="$xname/eac:entity_name"/></relationEntry>
                        <descriptiveNote>
                            <p>
                                <span localType="{$av_extractRecordId}">
                                    <xsl:value-of select="$xname/eac:enid"/>
                                </span>
                            </p>
                        </descriptiveNote>
                    </cpfRelation>
                </xsl:for-each>

            </xsl:variable>

            <xsl:variable name="original" select="fm:orig"/>
            <xsl:variable name="lang_decl">
                <languageDeclaration>
                    <language languageCode="eng">English</language>
                    <script scriptCode="Latn">Latin</script>
                </languageDeclaration>
            </xsl:variable>

            <xsl:variable name="topical_subject" select="eac:topical_subject/*"/>
            <xsl:variable name="geographic_subject" select="eac:geographic_subject/*"/>

            <!--
                Hard code these to English for now. They all seem to be English and there's no apparent data
                field.
            -->
            <xsl:variable name="language">
                <languageUsed>
                    <language languageCode="eng">English</language>
                    <script scriptCode="Latn">Latin</script>
                </languageUsed>
            </xsl:variable>

            <xsl:variable name="mods">
                <!--
                    There isn't much logic to a MODS record for field books data.  See tpt_mods in lib.xsl.
                -->
            </xsl:variable>

            <!--
                relationEntry may work for expedition with persons listed as "creatorOf" or perhaps the
                canonical equivalent of "participantIn". I'm not sure what to put here.
            -->
            <xsl:variable name="rel_entry" select="@entity_name"/>

            <xsl:variable name="is_c_flag" as="xs:boolean">
                <xsl:value-of select="eac:e_name/@fn_suffix = 'c'"/>
            </xsl:variable>
            
            <xsl:variable name="is_r_flag" as="xs:boolean">
                <xsl:value-of select="substring(eac:e_name/@fn_suffix, 1, 1) = 'r'"/>
            </xsl:variable>

            <xsl:message>
                <!-- <xsl:apply-templates select="." mode="pretty"/> -->
                <xsl:value-of select="concat('name: ', eac:e_name/eac:name_entry[1]/eac:part, ' suffix: ', eac:e_name/@fn_suffix)"/>
            </xsl:message>

            <!--
                <resourceRelation xmlns:xlink="http://www.w3.org/1999/xlink"
                xlink:arcrole="{$wcrr_arc_role}"
            -->
            <xsl:variable name="wcrr_arc_role">
                <xsl:call-template name="tpt_arc_role">
                    <xsl:with-param name="is_c_flag" select="$is_c_flag"/>
                    <xsl:with-param name="is_r_flag" select="$is_r_flag"/>
                </xsl:call-template>
            </xsl:variable>

            <!--
                Var $controlfield_001 is part of the resourceRelation, and also used in the source xlink:href.
                Exp doesn't have a container wrapper so enid is simply @enid.
            -->
            <xsl:variable name="controlfield_001" select="@enid"/>

            <!--
                Title statement. We might be able to fudge something for this.
            -->
            <xsl:variable name="tag_245" select="'CorporateBody'"/>

            <!-- 
                 param_data is a node set used to pass the equivalent of multiple parameters to a template. It
                 is cleaner, easier to modify than the big list of explicit params.
                 
                 Remember to change the other 2 param_data variables!
            -->
            <xsl:variable name="param_data">
                <use_source_href  as="xs:boolean">
                    <xsl:value-of select="false()"/>
                </use_source_href>
                <use_rrel as="xs:boolean">
                    <xsl:value-of select="true()"/>
                </use_rrel>
                <xsl:copy-of select="eac:e_name"/>
                <citation>
                    <xsl:value-of select="'Smithsonian Institution Archives Field Book Project: '"/>
                    <xsl:value-of select="'CorporateBody'"/>
                    <xsl:text> : Description : </xsl:text>
                    <xsl:value-of select="@enid"/>
                </citation>
                <inc_orig>
                    <xsl:copy-of select="$inc_orig" />
                </inc_orig>
                <xsl:copy-of select="$tc_data/eac:agency_info"/>
                <xsl:copy-of select="$tc_data/eac:snac_info"/>
                <ev_desc>
                    <xsl:value-of select="$ev_desc"/>
                </ev_desc>
                <rules>
                    <xsl:value-of select="$auth_form"/>
                </rules>
                <rr_xlink_href>
                    <xsl:value-of select="$rr_xlink_href"/>
                </rr_xlink_href>
                <rr_xlink_role>
                    <xsl:value-of select="$rr_xlink_role"/>
                </rr_xlink_role>
                <!-- legacy resourceRelation uses xlink_role -->
                <xlink_role>
                    <xsl:value-of select="$rr_xlink_role"/>
                </xlink_role>
            </xsl:variable>

            <!--
                Note: the context is a <container> node set. <container><e_name>...</e_name><existDates>...</existDates></container>
            -->
            <xsl:if test="true()"> <!-- position() &lt; 1000"> -->
                <xsl:result-document href="{$file_name}" format="xml" >
                    <xsl:call-template name="tpt_body">
                        <xsl:with-param name="exist_dates" select="./eac:existDates" as="node()*" />
                        <xsl:with-param name="entity_type" select="$cpf_corp_val" />
                        <!-- <xsl:with-param name="entity_name" select="@exp_name"/> -->
                        <xsl:with-param name="leader06" select="$unused"/>
                        <xsl:with-param name="leader07" select="$unused"/>
                        <xsl:with-param name="leader08" select="$unused"/>
                        <xsl:with-param name="mods" select="$mods"/>
                        <xsl:with-param name="rel_entry" select="$rel_entry"/>
                        <xsl:with-param name="wcrr_arc_role" select="$wcrr_arc_role"/>
                        <xsl:with-param name="controlfield_001" select="$controlfield_001"/>
                        <xsl:with-param name="is_c_flag" select="true()"/>
                        <xsl:with-param name="is_r_flag" select="false()"/>
                        <xsl:with-param name="fn_suffix" select="'c'" />
                        <xsl:with-param name="cpf_relation" select="$cpf_relation" />
                        <xsl:with-param name="record_id" select="@enid" />
                        <xsl:with-param name="date" select="$date" />
                        <xsl:with-param name="xslt_vendor" select="$xslt_vendor"/>
                        <xsl:with-param name="xslt_version" select="$xslt_version"/>
                        <xsl:with-param name="xslt_vendor_url" select="$xslt_vendor_url"/>
                        <!--
                            Don't use xpath eac:tag_545/text() because the child node is not a text node, but a <p>
                            node. text() is empty.
                        -->
                        <xsl:with-param name="tag_545" select="fm:tag_545/*"/>
                        <xsl:with-param name="tag_245" select="normalize-space($tag_245)"/>
                        <xsl:with-param name="xslt_script" select="$xslt_script"/>
                        <xsl:with-param name="original" select="$original"/>
                        <xsl:with-param name="lang_decl" select="$lang_decl"/>
                        <xsl:with-param name="topical_subject" select="$topical_subject"/>
                        <xsl:with-param name="geographic_subject" select="$geographic_subject"/>
                        <xsl:with-param name="language" select="$language"/>
                        <xsl:with-param name="param_data" select="$param_data"/>
                    </xsl:call-template>
                </xsl:result-document>
            </xsl:if>
        </xsl:for-each>
    </xsl:template> <!-- end tpt_exp_output --> 


    <xsl:template name="tpt_fb_date" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="exp_info"/>
        <!--
            We have 3 kinds of dates: born/died, single active, multi active. The
            born/died comes from the original EAC record file. Entities that are only
            known from an association with an expedition use the expedition date or dates
            as active.
        -->


        <xsl:choose>
            <xsl:when test="count($exp_info/eac:exp_list/eac:exp_info) = 1">
                <existDates>
                    <!-- Only set the context, since we only have a single item. -->
                    <xsl:for-each select="$exp_info/eac:exp_list/eac:exp_info">
                        <xsl:call-template name="tpt_simple_date_range">
                            <xsl:with-param name="from" select="@date_start"/>
                            <xsl:with-param name="from_type" select="$av_active"/>
                            <xsl:with-param name="to" select="@date_end"/>
                            <xsl:with-param name="to_type" select="$av_active"/>
                            <xsl:with-param name="allow_single" select="true()"/>
                        </xsl:call-template>
                    </xsl:for-each>
                </existDates>
            </xsl:when>
            <xsl:when test="count($exp_info/eac:exp_list/eac:exp_info) > 1">
                <existDates>
                    <dateSet>
                        <xsl:for-each select="$exp_info/eac:exp_list/eac:exp_info">
                            <xsl:call-template name="tpt_simple_date_range">
                                <xsl:with-param name="from" select="@date_start"/>
                                <xsl:with-param name="from_type" select="$av_active"/>
                                <xsl:with-param name="to" select="@date_end"/>
                                <xsl:with-param name="to_type" select="$av_active"/>
                                <xsl:with-param name="allow_single" select="true()"/>
                            </xsl:call-template>
                        </xsl:for-each>
                    </dateSet>
                </existDates>
            </xsl:when>
            <!-- otherwise we don't have a date -->
        </xsl:choose>
    </xsl:template>

    <xsl:function name="eac:best_xname" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="final_identity"/>
        <xsl:param name="curr"/>
        <xsl:variable name="curr_text_lc" select="lower-case($curr)"/>
        
        <xsl:variable name ="other_possible">
            <xsl:for-each select="$final_identity/eac:container/eac:e_name">
                <xsl:variable name="en_context" select="."/>
                <xsl:variable name="cname" select="text()"/>
                <xsl:if test="lower-case(@primary_name) = $curr_text_lc or
                              lower-case(@alt_name1) = $curr_text_lc or
                              lower-case(@alt_name2) = $curr_text_lc or
                              lower-case(@alt_name3) = $curr_text_lc or
                              lower-case(@std_name) = $curr_text_lc or
                              lib:pname-match(text(),  $curr_text_lc)">
                    <entity_name>
                        <xsl:value-of select="$cname"/>
                    </entity_name>
                    <enid>
                        <xsl:value-of select="$en_context/@enid"/>
                    </enid>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="string-length($other_possible) > 0">
                <xsl:copy-of select="$other_possible"/>
            </xsl:when>
            <xsl:otherwise>
                <!--
                    Mar 17 2015 Every name found has a snac id created, so there should never be a missing
                    name. Anything that getes here is an error. The bug was (mostly) related to dupes being
                    removed based on matching lib:pname_match(), but then using a weaker match here in
                    eac:best_xname(). 
                -->
                <xsl:message>
                    <xsl:value-of select="concat('Error: no cpfRel match, using raw name: ', $curr/text())"/>
                </xsl:message>
                <entity_name>
                    <xsl:value-of select="$curr/text()"/>
                </entity_name>
                <enid>
                </enid>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>

</xsl:stylesheet>
