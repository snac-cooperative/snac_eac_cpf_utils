<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="2.0"
                xmlns:lib="http://example.com/"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:saxon="http://saxon.sf.net/"
                xmlns:functx="http://www.functx.com"
                xmlns:marc="http://www.loc.gov/MARC21/slim"
                xmlns:eac="urn:isbn:1-931666-33-4"
                xmlns:madsrdf="http://www.loc.gov/mads/rdf/v1#"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:mads="http://www.loc.gov/mads/"
                exclude-result-prefixes="eac lib xs saxon xsl madsrdf rdf mads functx marc"
                >
    <!-- 
         Author: Tom Laudeman
         The Institute for Advanced Technology in the Humanities

         Copyright 2013 University of Virginia. Licensed under the Educational Community License, Version 2.0 (the
         "License"); you may not use this file except in compliance with the License. You may obtain a copy of the
         License at
         
         http://www.osedu.org/licenses/ECL-2.0
         
         Unless required by applicable law or agreed to in writing, software distributed under the License is
         distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
         the License for the specific language governing permissions and limitations under the License.

         This is a library of xml templates and functions shared by several XSLT scripts.
         
         xsl:function name="lib:edate_core"
         xsl:template name="tpt_file_suffix"
         xsl:template name="tpt_all_xx" xmlns:marc="http://www.loc.gov/MARC21/slim"
         xsl:template name="tpt_exist_dates"
         xsl:template name="tpt_show_date"
         xsl:function name="lib:date_cat" as="xs:string" 
         xsl:function name="lib:tokenize"
         xsl:function name="lib:pass_1b"
         xsl:function name="lib:pass_2"
         xsl:function name="lib:pass_3"
         xsl:function name="lib:ordinal_number"
         xsl:function name="lib:min_ess" as="xs:string"
         xsl:function name="lib:max_ess" as="xs:string"
         xsl:template mode="copy-no-ns" match="*"
         xsl:template name="tpt_entity_type" xmlns:ns="http://www.loc.gov/MARC21/slim">
         xsl:function name="functx:is-node-in-sequence-deep-equal" as="xs:boolean"
         xsl:function name="functx:distinct-deep" as="node()*"
         xsl:function name="functx:escape-for-regex" as="xs:string"

         match_record -> tpt_all_xx -> lib:edate_core -> tpt_exist_dates returns tokens
                                       '             '-> tpt_show_dates takes tokens and returns exist_dates
                                       '-> var tokens returned by lib:edate_core)
                                       '-> var exist_dates returned by lib:edate_core)
                                       
         Template match_record is in try_date_regex.xsl or oclc_marc2cpf.xsl.                                       
                                       
         Template name="match_record" calls template tpt_all_xx to create a node
         set that is later used to create the .c and .r output files.
         tpt_all_xx builds a node set of the .c and .r nameEntry/part. Inside
         tpt_all_xx, the var temp_node includes a exist dates which it gets by
         calling lib:edate_core().  lib:edate_core() calls tpt_exist_dates when
         it has something it wants a date for.
         
         I suggest changing lib: to eac: maybe so that all the code and
         functions are in the same namespace. I'm not sure it makes any
         difference since it seems necessary to explicitly set the namespace
         since it is difficult to know the current context namespace. Using the
         current context namespace broke this code when it was refactored into a
         more-or-less portable set of templates and functions.

         match_record -> tpt_all_xx -> edate_core -> tpt_exist_dates
                                       '-> var exist_dates-> tpt_show_dates
    -->

    <!-- <xsl:output method="xml" /> -->
    <xsl:variable name="occupations" select="document('occupations.xml')/*"/>
    <xsl:variable name="relators" select="document('vocabularyrelators.rdf')/*"/>
    <xsl:variable name="languages" select="document('vocabularylanguages.rdf')/*"/>
    <xsl:variable name="org_codes" select="document('worldcat_code.xml')/*"/>

    
    <xsl:template mode="get_lang" match="*">
         <xsl:choose>
             <xsl:when test="madsrdf:authoritativeLabel">
                 <xsl:value-of select="madsrdf:authoritativeLabel"/>
             </xsl:when>
             <xsl:when test="madsrdf:deprecatedLabel">
                 <xsl:value-of select="madsrdf:deprecatedLabel"/>
                 <!-- <xsl:text> (deprecated) </xsl:text> -->
             </xsl:when>
         </xsl:choose>
     </xsl:template>
     
     <xsl:template name="tpt_lang_decl" xmlns="urn:isbn:1-931666-33-4">
         <!--
             This is control/languageDeclaration. I'm pretty sure there is only a single
             040$b per record, but for-each sets the context, so that is
             good. When we have an 040$b, use it, otherwise default to English.
             
             (description/languageUsed is derived from the 041$a; see tpt_language)
         -->
         <xsl:choose>
             <xsl:when test="boolean(marc:datafield[@tag='040']/marc:subfield[@code='b'])">
                 <xsl:for-each select="marc:datafield[@tag='040']/marc:subfield[@code='b']">
                     <xsl:variable name="lang_code" select="."/>
                     <xsl:element name="languageDeclaration" xmlns:eac="urn:isbn:1-931666-33-4">
                         <xsl:element name="language" xmlns:eac="urn:isbn:1-931666-33-4">
                             <xsl:attribute name="languageCode" select="$lang_code"/>
                             <xsl:apply-templates mode="get_lang" select="$languages/madsrdf:Topic[madsrdf:code = $lang_code]"/>
                         </xsl:element>
                         <xsl:element name="script" xmlns:eac="urn:isbn:1-931666-33-4">
                             <xsl:attribute name="scriptCode" select="'Zyyy'"/>
                             <xsl:text>Unknown</xsl:text>
                         </xsl:element>
                     </xsl:element>
                 </xsl:for-each>
             </xsl:when>
             <xsl:otherwise>
                 <xsl:element name="languageDeclaration" xmlns:eac="urn:isbn:1-931666-33-4">
                     <xsl:element name="language" xmlns:eac="urn:isbn:1-931666-33-4">
                         <xsl:attribute name="languageCode" select="'eng'"/>
                         <xsl:text>English</xsl:text>
                     </xsl:element>
                     <xsl:element name="script" xmlns:eac="urn:isbn:1-931666-33-4">
                         <xsl:attribute name="scriptCode" select="'Zyyy'"/>
                         <xsl:text>Unknown</xsl:text>
                     </xsl:element>
                 </xsl:element>
             </xsl:otherwise>
         </xsl:choose>
     </xsl:template>

     <xsl:template name="tpt_is_cp">
         <xsl:variable name="temp">
             <xsl:for-each select="marc:datafield[@tag='600' or @tag='610' or @tag='611' or @tag='700' or @tag='710' or @tag='711']/marc:subfield[@code='v']">
                 <val>
                     <xsl:value-of select="matches(., 'correspondence', 'i')"/>
                 </val>
             </xsl:for-each>
         </xsl:variable>
         <!--
             Use boolean() so that true returns true, and "" returns false. XSLT will not automatically cast "" to
             false. We will get true if there is at least one true value.
         -->
         <xsl:value-of select="boolean($temp/val[.=true()][1])"/>
     </xsl:template>
     

     <xsl:template name="tpt_geo" xmlns="urn:isbn:1-931666-33-4">
         <!--
             Build a node set regardless of empty placeEntry values or duplicates. Then copy removing empties
             and duplicates. The elements are for output, so we create them in the eac namespace.
         -->
         <xsl:variable name="geo_651">
             <!--
                 Create a temporary node set in variable $df with a prev
                 attribute so we can check for $a followed by ($z
                 repeating). Template mode do_subfield is below. Call
                 do_subfield with a sequence of all the subfield elements of the
                 current datafield. 
             -->
             <xsl:variable name="df">
                 <xsl:for-each select="marc:datafield[@tag='651']">
                     <datafield xmlns="http://www.loc.gov/MARC21/slim">
                         <xsl:copy-of select="@*" />
                         <xsl:text>&#x0A;</xsl:text>
                         <xsl:call-template name="do_subfield">
                             <xsl:with-param name="sub" select="marc:subfield"/>
                             <xsl:with-param name="prev" select="''"/>
                         </xsl:call-template>
                     </datafield>
                     <xsl:text>&#x0A;</xsl:text>
                 </xsl:for-each>
             </xsl:variable>

             <!--
                 With the proper meta-data, building the geo subject is possible.
                 Three cases: $a regardless of following, $a with contiguous
                 following $z (repeating), $z repeating not contiguous with $a.
                 
                 $df has been forced to be namespace ns as all input from the marc records, so continue using
                 the marc: prefix here. Must use xsl:element to force <place> and <placeEntry> are output into
                 the eac: namespace. Literals inherit the "current namespace", but "current" has some odd,
                 non-current characteristics.
             -->
             <xsl:for-each select="$df/marc:datafield">
                 <xsl:if test="marc:subfield[@code='a' or (@code='z' and @prev='a')]">
                     <xsl:element name="place" xmlns:eac="urn:isbn:1-931666-33-4">
                         <xsl:attribute name="localType" select="'geographicSubject'"/>
                         <xsl:element name="placeEntry">
                             <xsl:for-each select="marc:subfield[@code='a' or (@code='z' and @prev='a')]">
                                 <xsl:if test="not(position()=1)">
                                     <xsl:text>--</xsl:text>
                                 </xsl:if>
                                 <xsl:value-of select="lib:norm-punct(.)"/>
                             </xsl:for-each>
                         </xsl:element>
                     </xsl:element>
                     <xsl:text>&#x0A;</xsl:text>
                 </xsl:if>
                 
                 <xsl:if test="marc:subfield[@code='z' and (@prev='' or @prev='z')]">
                     <xsl:element name="place" xmlns:eac="urn:isbn:1-931666-33-4">
                         <xsl:attribute name="localType" select="'geographicSubject'"/>
                         <xsl:element name="placeEntry" xmlns:eac="urn:isbn:1-931666-33-4">
                             <xsl:for-each select="marc:subfield[@code='z' and (@prev='' or @prev='z')]">
                                 <xsl:if test="not(position()=1)">
                                     <xsl:text>--</xsl:text>
                                 </xsl:if>
                                 <xsl:value-of select="lib:norm-punct(.)"/>
                             </xsl:for-each>
                         </xsl:element>
                     </xsl:element>
                     <xsl:text>&#x0A;</xsl:text>
                 </xsl:if>
                 
             </xsl:for-each>
         </xsl:variable>

         <xsl:variable name="geo1">
             <xsl:call-template name="tpt_65x_geo">
                 <xsl:with-param name="tag" select="650"/>
             </xsl:call-template>
             <xsl:call-template name="tpt_65x_geo">
                 <xsl:with-param name="tag" select="656"/>
             </xsl:call-template>
             <xsl:call-template name="tpt_65x_geo">
                 <xsl:with-param name="tag" select="657"/>
             </xsl:call-template>
             <xsl:copy-of select="$geo_651"/>
         </xsl:variable>
         
         <!--
             Deduping a node set in 6 lines of code, but subtle. We need to
             compare each node to every other node in the node set. That is
             impossible in a single conditional because pname-match() takes
             string args, not node set args. Looking at it another way, we have
             two separate contexts to compare, so one of them will have to be
             saved to a variable. somepath[] will implicitly for-each over nodes
             in the []. We must use a variable for the outer context (an explicit
             for-each) since the context inside the [] is different. The xsl:if
             will map all preceding placeEntry values through pname-match()
             against the current $geo1 node in $curr. To state the problem
             another way, we can only have one implicit loop in [], so that loop
             must be the preceding nodes. We need to loop through $geo1 comparing
             the current node to all (by looping over) the preceding nodes.
             
             We are deduping a list against itself. We loop over each node while
             implicitly looping over all preceding nodes. The outer loop is an
             (explicit) for-each. The inner loop is an implicit mapping of values
             inside preceding::placeEntry[].
             
             The final confusing part is that the preceding::placeEntry will
             return 0 or more matching nodes, as opposed to returing true or
             false. If there are any matching nodes then we have a
             duplicate. Thus we put not() around the whole preceding::placeEntry expression.
             
             This short method (the 6 line deduping algorighm) requires an outer container element. In this
             case I suppose the outer element is <place> and we are deduping <placeEntry>. (Or it could be
             that I didn't understand how to use /* to for-each over nodes in a variable without referring to
             a root node.)
         -->
         
         <xsl:for-each select="$geo1/eac:place[string-length(eac:placeEntry) > 0]">
             <xsl:variable name="curr" select="."/>
             <xsl:if test="not(preceding::eac:placeEntry[lib:pname-match(text(),  $curr/eac:placeEntry)])">
                 <xsl:copy-of select="$curr" />
             </xsl:if>
         </xsl:for-each>
     </xsl:template> <!-- end tpt_geo -->

     
     <xsl:template name="do_subfield" xmlns="http://www.loc.gov/MARC21/slim">
         <xsl:param name="sub"/>
         <xsl:param name="prev"/>
         <!-- 
              This recursively builds a node set that tells us when 'a' or 'z'
              immediately precedes 'z'. Each node in the node set has the code
              and $prev as well as the value of the subfield.
         -->
         <xsl:variable name="code" select="$sub[1]/@code"/>
         
         <subfield code="{$code}" prev="{$prev}">
             <xsl:value-of select="$sub" />
         </subfield>

         <!--
             $ancestral_a is the state of the current node that we're passing to
             the next recursive iteration. The variable name fits since it could
             be restated as "do I have a direct 'a' ancestral lineage?".
         -->
         <xsl:variable name="ancestral_a">
             <xsl:choose>
                 <xsl:when test="$code = 'a' or ($code = 'z' and $prev = 'a')">
                     <xsl:value-of select="'a'"/>
                 </xsl:when>
                 <xsl:when test="$code = 'z' or $prev = 'z'">
                     <xsl:value-of select="'z'"/>
                 </xsl:when>
                 <xsl:otherwise>
                     <xsl:value-of select="''"/>
                 </xsl:otherwise>
             </xsl:choose>
         </xsl:variable>

         <!--
             Recurse on the remaining sibling subfields.
         -->
         <xsl:if test="boolean($sub/following-sibling::marc:subfield)">
             <xsl:call-template name="do_subfield">
                 <xsl:with-param name="sub" select="$sub/following-sibling::marc:subfield"/>
                 <xsl:with-param name="prev" select="$ancestral_a"/>
             </xsl:call-template>
         </xsl:if>
     </xsl:template>


     <xsl:template name="tpt_arc_role">
         <xsl:param name="is_c_flag"/>
         <xsl:param name="is_cp"/>
         <xsl:param name="is_r_flag"/>
         <xsl:choose>
             <xsl:when test="$is_c_flag or (eac:e_name/@is_creator=true())">
                 <xsl:text>creatorOf</xsl:text>
             </xsl:when>
             <xsl:when test="$is_cp">
                 <xsl:text>correspondedWith</xsl:text>
             </xsl:when>
             <xsl:when test="$is_r_flag">
                 <xsl:text>referencedIn</xsl:text>
             </xsl:when>
             <xsl:otherwise>
                 <!-- This can't happen given current logic. -->
                 <xsl:text>associatedWith</xsl:text>
             </xsl:otherwise>
         </xsl:choose>
     </xsl:template>
     
     <xsl:template name="tpt_rules">
	 <xsl:choose>
	     <xsl:when test="substring(marc:controlfield[@tag='008'],11,1)='b'">
		 <xsl:text>aacr1</xsl:text>
	     </xsl:when>
	     <xsl:when test="substring(marc:controlfield[@tag='008'],11,1)='c'">
		 <xsl:text>aacr2</xsl:text>
	     </xsl:when>
	     <xsl:when test="substring(marc:controlfield[@tag='008'],11,1)='d'">
		 <xsl:text>aacr2compatible</xsl:text>
	     </xsl:when>
	     <xsl:otherwise>unknown</xsl:otherwise>
	 </xsl:choose>
     </xsl:template>

    <xsl:template name="tpt_65x_geo" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="tag"/>
        <!--
            Deal with mutiple elements with the same tag value. For example,
            multiple 650$z elements. Simply join all $z, contiguous or not.
        -->
        <xsl:for-each select="marc:datafield[@tag=$tag]" >
            <!-- removed xmlns="urn:isbn:1-931666-33-4" and moved to enclosing template element. -->
            <xsl:element name="place" xmlns:eac="urn:isbn:1-931666-33-4">
                <xsl:attribute name="localType" select="'geographicSubject'"/>
                <xsl:element name="placeEntry">
                    <xsl:for-each select="marc:subfield[@code='z']">
                        <xsl:if test="not(position() = 1)">
                            <xsl:text>--</xsl:text>
                        </xsl:if>
                        <xsl:value-of select="lib:norm-punct(.)"/>
                    </xsl:for-each>
                </xsl:element>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>


    <xsl:template name="tpt_topical_subject"  xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="record_position"/>
        <xsl:param name="record_id"/>
        <!-- 
             Removing the xmlns above may break this, and the name of the namespace must be "eac" as required
             by the deduping loop at the end of this template.

             Originally, some subfields were captured based on non-repeating or
             repeating, but the data is bad for a few records, so now we capture
             all the desired subfields as though they are repeating. Assume that
             XSLT XPath "or" clauses are processed in order, and have short
             circuit optimization.
             
             Must use xsl:element for localDescription with xmlns. Also need to use xsl:element for term, but
             it inherits eac: which is a tiny bit odd because xsl:element is not supposed to inherit, but I
             guess it doesn't inherit the current namespace, but an explicit namespace is subtly different
             from "current namespace". Current namespace in the for-each is marc:. As a shortcut, the marc:
             can be turned off in the output by putting marc into the exclude-result-prefixes, but that
             masquerades potential problems. While it is not necessary to put an explicit namespace on
             xsl:element term, I did anyway because namespace inheritance is clearly not clear.
        -->
        <xsl:variable name="all_ts">
            <xsl:for-each select="marc:datafield[@tag='650']">
                <xsl:element name="localDescription"  xmlns:eac="urn:isbn:1-931666-33-4">
                    <xsl:attribute name="localType" select="'topicalSubject'"/>
                    <xsl:element name="term" xmlns:eac="urn:isbn:1-931666-33-4">
                        <xsl:for-each select="marc:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='v' or @code='x' or @code='y']">
                            <xsl:if test="not(position() = 1)">
                                <xsl:text>--</xsl:text>
                            </xsl:if>
                            <xsl:value-of select="lib:norm-punct(.)"/>
                        </xsl:for-each>
                    </xsl:element>
                </xsl:element>
            </xsl:for-each>
        </xsl:variable>
        <!-- 
             The node-set dedup idiom. See extensive comments with tpt_geo.
             
             Context is localDescription so paths below are term being relative to the context node.
        -->
        <xsl:for-each select="$all_ts/eac:localDescription[string-length(eac:term) > 0]">
            <xsl:variable name="curr" select="."/>

            <xsl:if test="not(preceding::eac:term[lib:pname-match(text(), $curr/eac:term)])">
                <xsl:copy-of select="$curr"/>
            </xsl:if>
        </xsl:for-each>

    </xsl:template> <!-- end tpt_topical_subject -->
     
     <xsl:template name="tpt_language"
                   xmlns="urn:isbn:1-931666-33-4">
        <!-- 
             This is description/languageUsed. First put each 041$a lang into var $all, then dedup $all and
             wrap each lang with languageUsed to go into description.
             
             (control/languageDeclaration is derived 040$b; see tpt_lang_decl)

             <subfield code="a">gereng</subfield>
             
             This is in the <description> element in the cpf template.

             <languageUsed>
             <language languageCode="ger">German</language>
             <language languageCode="eng">English</language>
             <script scriptCode="Zyyy">Unknown</script>
             </languageUsed>
             
             An empty sequence is not allowed as the @select attribute of xsl:analyze-string.
             
             Use for-each to make sure the context is something non-empty.
        -->
        <xsl:variable name="all">
            <xsl:for-each select="marc:datafield[@tag='041']/marc:subfield[@code='a']">
                <xsl:analyze-string select="." regex="...">
                    <xsl:matching-substring>
                        <xsl:variable name="lang_code" select="regex-group(0)"/>
                        <language languageCode="{$lang_code}">
                            <xsl:apply-templates mode="get_lang" select="$languages/madsrdf:Topic[madsrdf:code = $lang_code]"/>
                        </language>
                    </xsl:matching-substring>
                </xsl:analyze-string>
            </xsl:for-each>
        </xsl:variable>
        <!-- 
             The node-set dedup idiom. See extensive comments with tpt_geo. This is a little different since
             $all has no container element, so we for-each on $all/* rather than $all/container. Also, our
             test is = instead of lib:pname-match() or some other function. Apparently /* is perfectly legal
             and robust.  http://www.dpawson.co.uk/xsl/sect2/root.html
        -->
        <xsl:for-each select="$all/*[string-length() > 0]">
            <xsl:variable name="curr" select="."/>
            <xsl:if test="not(preceding::eac:language[text() = $curr/text()])">
                <languageUsed>
                    <xsl:copy-of select="$curr"/>
                    <script scriptCode="Zyyy">
                        <xsl:text>Unknown</xsl:text>
                    </script>
                </languageUsed>
            </xsl:if>
        </xsl:for-each>
    </xsl:template> <!-- end tpt_language -->
        

    <xsl:template name="tpt_occupation" xmlns:eac="urn:isbn:1-931666-33-4">
        <xsl:param name="tag"/>
        <!--
            If we have a 656 occupation then use it, else try to use 100$e or
            100$4 via some lookups in the relator and occupations xml authority
            files.
        -->
        <xsl:variable name="all">
            <xsl:choose>
                <xsl:when test="boolean(marc:datafield[@tag='656'])">
                    <xsl:apply-templates mode="tpt_occ_656" select="marc:datafield[@tag='656']"/>
                </xsl:when>
                <xsl:when test="$tag='100'">
                    <xsl:apply-templates mode="tpt_occ_e" select="marc:datafield[@tag=$tag]/marc:subfield[@code='e']"/>
                    <xsl:apply-templates mode="tpt_occ_4" select="marc:datafield[@tag=$tag]/marc:subfield[@code='4']"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <!-- 
             The node-set dedup idiom. See extensive comments with tpt_geo.
        -->
        <xsl:for-each select="$all/eac:occupation[string-length(eac:term) > 0]">
            <xsl:variable name="curr" select="."/>
            <xsl:if test="not(preceding::eac:term[lib:pname-match(text(), $curr/eac:term)])">
                <xsl:copy-of select="$curr"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:template> <!-- end tpt_occupation -->

    <xsl:template mode="tpt_occ_4" match="*" xmlns:eac="urn:isbn:1-931666-33-4">
        <!-- 
             For any matching mads relator code, get the sibling authoritative
             label and test it against the occupations.
             
             Use a double test [[]] on the for-each to find the single matching <mads> element. We're using
             the for-each to set the context of a record where the singular variant matches our unpunctuated
             value. Once we have the context, just get the authority/occupation name as usual.
        -->
        <xsl:variable name="test_code" select="lib:unpunct(text())"/>
        <xsl:for-each select="$relators/madsrdf:Authority[madsrdf:code = $test_code]">
            <xsl:variable name="unp" select="lower-case(lib:unpunct(madsrdf:authoritativeLabel/text()))"/>
            <xsl:element name="occupation" namespace="urn:isbn:1-931666-33-4" >
                <xsl:for-each select="$occupations/mads:mads[mads:variant[@otherType='singular']/mads:occupation[text() = $unp]]">
                    <xsl:element name="term" namespace="urn:isbn:1-931666-33-4">
                        <xsl:value-of select="mads:authority/mads:occupation"/>
                    </xsl:element>
                </xsl:for-each>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>


    <xsl:template mode="tpt_occ_e" match="*" xmlns:eac="urn:isbn:1-931666-33-4">
        <!--
            See comment with tpt_occ_4 above.

            Test the lowercase, un-punctuated text of the $e (context) against
            the occupation list.
            
            Use a variable to hold the current 100$e, since the context changes once we are inside the
            for-each. It was a mistake to do lib:unpunct(text()) below in the for-each where $unp is, because
            at that point the context is the occupations record, not our marc 100$e value.
        -->
        <xsl:variable name="unp" select="lower-case(lib:unpunct(.))"/>

        <xsl:element name="occupation" namespace="urn:isbn:1-931666-33-4" >
            <xsl:for-each select="$occupations/mads:mads[mads:variant[@otherType='singular']/mads:occupation[text() = $unp]]">
                <xsl:element name="term" namespace="urn:isbn:1-931666-33-4">
                    <xsl:value-of select="mads:authority/mads:occupation"/>
                </xsl:element>
            </xsl:for-each>
        </xsl:element>
    </xsl:template>


    <xsl:template mode="tpt_occ_656" match="*" xmlns:eac="urn:isbn:1-931666-33-4">
        <xsl:element name="occupation" namespace="urn:isbn:1-931666-33-4" >
            <xsl:element name="term" namespace="urn:isbn:1-931666-33-4">
                <xsl:if test="marc:subfield[@code='a']">
                    <xsl:value-of select="marc:subfield[@code='a']"/>
                </xsl:if>
                
                <xsl:for-each select="marc:subfield[@code='x']">
                    <xsl:text>--</xsl:text>
                    <xsl:value-of select="."/>
                </xsl:for-each>

                <xsl:for-each select="marc:subfield[@code='y']">
                    <xsl:text>--</xsl:text>
                    <xsl:value-of select="."/>
                </xsl:for-each>

                <xsl:for-each select="marc:subfield[@code='z']">
                    <xsl:text>--</xsl:text>
                    <xsl:value-of select="."/>
                </xsl:for-each>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <xsl:template name="tpt_show_date" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="tokens"/> 
        <xsl:param name="is_family"/> 
        <xsl:param name="rec_pos"/> 
        <!--
            Date determination logic is here, using the tokenized date. Some of
            this code is a bit dense. existDates must have same namespace as its
            parent element eac-cpf.
            
            We start of with several tests to determine dates that we cannot
            parse, and put them in a variable to neaten up the code and allow us
            to only have a single place where the unparsed date node set is
            constructed. Anything that makes it through these tests should be
            parse-able, although there is a catch-all otherwise at the end of
            the parsing choose.
        -->
        <!-- <xsl:message> -->
        <!--     <xsl:text>tokens: </xsl:text> -->
        <!--     <xsl:copy-of select="$tokens" /> -->
        <!--     <xsl:text>&#x0A;</xsl:text> -->
        <!-- </xsl:message> -->


        <xsl:variable name="is_unparsed" as="xs:boolean">
            <xsl:choose>
                <!-- 
                     If there are no numeric tokens, the date is unparsed. Note
                     that since we only support integer values for years, we are
                     not checking all valid XML formats for numbers, only
                     [0-9]. Century numbers are a special case, so we have to
                     check them too.
                -->
                <xsl:when test="count($tokens/tok[matches(text(), '^\d+$|\d+.*century')]) = 0">
                    <xsl:value-of select="true()"/>
                </xsl:when>
                <!--
                    If there are two adjacent number tokens, then unparsed. Due to
                    the declarative nature of xpath, position() will be relative to
                    the context which will change as xpath iterates through the
                    first half of the xpath.
                -->
                <xsl:when test="$tokens/tok[matches(text(), '^\d+$')]/following-sibling::tok[position()=1 and matches(text(), '^\d+$')]">
                    <xsl:value-of select="true()"/>
                </xsl:when>
                <!--
                    Alphabetic tokens that aren't our known list must be unparsed dates.
                -->
                <xsl:when test="$tokens/tok[matches(text(), '[A-Za-z]+') and not(matches(text(), 'approximately|or|active|century|b|d|st|nd|rd|th'))]">
                    <xsl:value-of select="true()"/>
                </xsl:when>
                <!--
                    Unrecognized tokens should only be year numbers. Any
                    supposed-year-numbers that are NAN or numbers > 2012 are errors
                    are unparsed dates. Also, notBefore and notAfter should never be
                    NaN.
                -->
                <xsl:when test="$tokens/tok[@notBefore='NaN' or
                                @notBefore='0' or
                                @notAfter='NaN' or
                                @notAfter='0' or
                                (not(matches(text(), 'approximately|or|active|century|b|d|st|nd|rd|th|-')) and string(number()) = 'NaN') or
                                number() > 2012 or 
                                number() = 0 ]">
                    <xsl:value-of select="true()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="false()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:choose>
            <!-- There is another unparsed "questionable" date below in the otherwise element of this choose. -->
            <xsl:when test="$is_unparsed">
                <xsl:element name="existDates" namespace="urn:isbn:1-931666-33-4">
                    <xsl:element name="date" namespace="urn:isbn:1-931666-33-4">
                        <xsl:attribute name="localType" select="'questionable'"/>
                        <xsl:value-of select="$tokens/odate"/>
                    </xsl:element>
                </xsl:element>
            </xsl:when>

            <xsl:when test="$tokens/tok[matches(text(), 'century')]">
                <xsl:element name="existDates" namespace="urn:isbn:1-931666-33-4">
                    <xsl:element name="date" namespace="urn:isbn:1-931666-33-4">
                        <!-- if we have an 'active' token, then then make the subject 'active'. -->
                        <xsl:if test="$tokens/tok[matches(text(), 'active')] or $is_family">
                            <xsl:attribute name="localType">
                                <xsl:text>active </xsl:text>
                            </xsl:attribute>
                        </xsl:if>

                        <!-- Add attributes notBefore, notAfter.  -->
                        <xsl:for-each select="$tokens/tok[matches(text(), '\d+')]/@*[matches(name(), '^not')]">
                            <xsl:attribute name="{name()}">
                                <xsl:value-of select="format-number(., '0000')"/>
                            </xsl:attribute>
                        </xsl:for-each>

                        <!-- all tokens before the first date -->
                        <xsl:for-each select="$tokens/tok[matches(text(), '\d+')][1]/preceding-sibling::tok">
                            <xsl:value-of select="concat(., ' ')"/>
                        </xsl:for-each>

                        <!-- is_family doesn't have an active token so we need
                             to add it here. Maybe it should have been added
                             earlier. -->
                        <xsl:if test="$is_family">
                            <xsl:text>active </xsl:text>
                        </xsl:if>

                        <xsl:value-of select="$tokens/tok[matches(text(), '\d+')][1]"/>
                    </xsl:element>
                </xsl:element>
            </xsl:when>

            <!--
                Except for century, we don't like any token that mixes digits and non-digits. We
                also to not like strings of 5 or more digits.
            -->

            <xsl:when test="$tokens/tok[(matches(text(), '\d+[^\d]+|[^\d]+\d+') or matches(text(), '\d{5}')) and not(matches(text(), 'century'))]">
                <xsl:element name="existDates" namespace="urn:isbn:1-931666-33-4">
                    <xsl:element name="date" namespace="urn:isbn:1-931666-33-4">
                        <xsl:attribute name="localType" select="'questionable'"/>
                        <xsl:value-of select="$tokens/odate"/>
                    </xsl:element>
                </xsl:element>
            </xsl:when>

            <xsl:when test="$tokens/tok = 'b'  or (($tokens/tok)[last()] = '-')">
                <!-- No active since that is illogical with 'born' for persons. -->
                <xsl:variable name="loc_type">
                    <xsl:if test="$is_family">
                        <xsl:text>active</xsl:text>
                    </xsl:if>
                    <xsl:if test="not($is_family)">
                        <xsl:text>born</xsl:text>
                    </xsl:if>
                </xsl:variable>
                <xsl:variable name="curr_tok" select="$tokens/tok[matches(text(), '\d+')][1]"/>
                <xsl:variable name="std_date"
                              select="format-number($curr_tok, '0000')"/>
                <xsl:element name="existDates" namespace="urn:isbn:1-931666-33-4">
                    <xsl:element name="dateRange" namespace="urn:isbn:1-931666-33-4">
                        <xsl:element name="fromDate" namespace="urn:isbn:1-931666-33-4">
                            <xsl:attribute name="standardDate" select="$std_date"/>
                            <xsl:attribute name="localType" select="$loc_type"/>
                            <!-- Add attributes notBefore, notAfter.  -->
                            <xsl:for-each select="$tokens/tok[matches(text(), '\d+')][1]/@*[matches(name(), '^not')]">
                                <xsl:choose>
                                    <xsl:when test="string-length(.)>0">
                                        <xsl:attribute name="{name()}">
                                            <xsl:value-of select="format-number(., '0000')"/>
                                        </xsl:attribute>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:message>
                                            <xsl:copy-of select="$rec_pos" />
                                            <xsl:text> line 395 fromDate empty attr: </xsl:text>
                                            <xsl:copy-of select="." />
                                        </xsl:message>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:for-each>
                            
                            <!-- is_family doesn't have an active token so we need
                                 to add it here. Maybe it should have been added
                                 earlier. -->
                            <xsl:if test="$is_family">
                                <xsl:text>active </xsl:text>
                            </xsl:if>

                            <!-- all tokens before the first date, this includes things like "approximately" -->
                            <xsl:for-each select="$tokens/tok[matches(text(), '\d+')][1]/preceding-sibling::tok">
                                <xsl:choose>
                                    <xsl:when test="text() = 'b'">
                                        <!-- Skip. We already added human readable "born" above. -->
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="concat(., ' ')"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:for-each>
                            
                            <!--
                                We know this is a birth date so make that clear in the human
                                readable part of the date by putting a '-' after the date. 
                            -->

                            <!-- Put @sep in. If it is blank that's fine, but if not blank, we need it -->
                            <xsl:value-of select="normalize-space(concat($std_date, '- ', $curr_tok/@sep))"/>
                        </xsl:element>
                        <xsl:element name="toDate" namespace="urn:isbn:1-931666-33-4"/>
                    </xsl:element>
                </xsl:element>
            </xsl:when>
            
            <xsl:when test="($tokens/tok = 'd') or ($tokens/tok[1] = '-')">
                <!-- No active since that is illogical with 'died', unless $is_family in which case this is "active" and not "died". -->
                <xsl:variable name="loc_type">
                    <xsl:if test="$is_family">
                        <xsl:text>active</xsl:text>
                    </xsl:if>
                    <xsl:if test="not($is_family)">
                        <xsl:text>died</xsl:text>
                    </xsl:if>
                </xsl:variable>
                <xsl:variable name="curr_tok" select="$tokens/tok[matches(text(), '\d+')][1]"/>
                <xsl:variable name="std_date"
                              select="format-number($curr_tok, '0000')"/>
                <xsl:element name="existDates" namespace="urn:isbn:1-931666-33-4">
                    <xsl:element name="dateRange" namespace="urn:isbn:1-931666-33-4">
                        <xsl:element name="fromDate" namespace="urn:isbn:1-931666-33-4"/>
                        <xsl:element name="toDate" namespace="urn:isbn:1-931666-33-4">
                            <xsl:attribute name="standardDate" select="$std_date"/>
                            <xsl:attribute name="localType" select="$loc_type"/>
                            <!-- Add attributes notBefore, notAfter.  -->
                            <xsl:for-each select="$tokens/tok[matches(text(), '\d+')][1]/@*[matches(name(), '^not')]">
                                <xsl:attribute name="{name()}">
                                    <xsl:value-of select="format-number(., '0000')"/>
                                </xsl:attribute>
                            </xsl:for-each>

                            <!-- is_family doesn't have an active token so we need
                                 to add it here. Maybe it should have been added
                                 earlier. -->
                            <xsl:if test="$is_family">
                                <xsl:text>active </xsl:text>
                            </xsl:if>
                            
                            <!-- all tokens before the first date, this includes things like "approximately" -->
                            <xsl:for-each select="$tokens/tok[matches(text(), '\d+')][1]/preceding-sibling::tok">
                                <xsl:choose>
                                    <xsl:when test="text() = 'd' or text() = '-'">
                                        <!-- Skip. We already added human readable "died" above. -->
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="concat(., ' ')"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:for-each>

                            <!--
                                Add the leading '-' manually. There is a token
                                for it, but tokens are concatenated with space
                                around them, and the '-' is a special token, not
                                unlike 'd' or 'b'.
                            -->
                            <xsl:value-of select="normalize-space(concat('-', $std_date, ' ', $curr_tok/@sep))"/>
                        </xsl:element>
                    </xsl:element>
                </xsl:element>
            </xsl:when>

            <xsl:when test="count($tokens/tok[text() = '-']) > 0 and count($tokens/tok[matches(text(), '\d+')]) > 1">
                <!--
                    We have a hyphen and two numbers so it must be from-to.
                    
                    Works but seems very frail: element with xslns,
                    oclc_marc2cpf.xsl line 663 existDates, and eac_cpf.xsl
                    line 102 copy-of.
                    
                    I was unable to get this to work without a namespace,
                    although other node sets with no namespace work fine.
                -->
                <xsl:element name="existDates" xmlns:eac="urn:isbn:1-931666-33-4" >
                    <xsl:element name="dateRange" >
                        <xsl:element name="fromDate" >
                            <xsl:variable name="curr_tok" select="$tokens/tok[matches(text(), '\d+')][1]"/>
                            <xsl:attribute name="standardDate" select="format-number($curr_tok, '0000')"/>
                            <!-- if we have an 'active' token before the hyphen, then then make the subject 'active'. -->
                            <xsl:choose>
                                <xsl:when test="($tokens/tok[text() = '-']/preceding-sibling::tok = 'active') or $is_family">
                                    <xsl:attribute name="localType">
                                        <xsl:text>active</xsl:text>
                                    </xsl:attribute>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:attribute name="localType">
                                        <xsl:text>born</xsl:text>
                                    </xsl:attribute>
                                </xsl:otherwise>
                            </xsl:choose>

                            <!-- Add attributes notBefore, notAfter.  -->
                            <xsl:for-each select="$tokens/tok[matches(text(), '\d+')][1]/@*[matches(name(), '^not')]">
                                <xsl:attribute name="{name()}">
                                    <xsl:value-of select="format-number(., '0000')"/>
                                </xsl:attribute>
                            </xsl:for-each>

                            <!-- all tokens before the first date -->
                            <xsl:for-each select="$tokens/tok[matches(text(), '\d+')][1]/preceding-sibling::tok">
                                <xsl:value-of select="concat(., ' ')"/>
                            </xsl:for-each>
                            
                            <!-- is_family doesn't have an active token so we need
                                 to add it here. Maybe it should have been added
                                 earlier. -->
                            <xsl:if test="$is_family">
                                <xsl:text>active </xsl:text>
                            </xsl:if>

                            <xsl:value-of select="concat($curr_tok, $curr_tok/@sep)"/>
                        </xsl:element>

                        <xsl:element name="toDate" namespace="urn:isbn:1-931666-33-4">
                            <xsl:variable name="curr_tok" select="$tokens/tok[matches(text(), '\d+')][2]"/>
                            <xsl:attribute name="standardDate" select="format-number($curr_tok, '0000')"/>
                            <!-- if we have an 'active' token anywhere  or $is_family then 'active' else 'died' -->
                            <xsl:choose>
                                <xsl:when test="($tokens/tok[text() = 'active']) or $is_family">
                                    <xsl:attribute name="localType">
                                        <xsl:text>active</xsl:text>
                                    </xsl:attribute>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:attribute name="localType">
                                        <xsl:text>died</xsl:text>
                                    </xsl:attribute>
                                </xsl:otherwise>
                            </xsl:choose>

                            <!-- Add attributes notBefore, notAfter.  -->
                            <xsl:for-each select="$curr_tok/@*[matches(name(), '^not')]">
                                <xsl:attribute name="{name()}">
                                    <xsl:value-of select="format-number(., '0000')"/>
                                </xsl:attribute>
                            </xsl:for-each>

                            <!-- All tokens after the hyphen. Assume that anything in @sep of a token should be in the output. -->
                            <xsl:for-each select="$tokens/tok[matches(text(), '-')]/following-sibling::tok">
                                <xsl:value-of select="concat(.,@sep)"/>
                                <xsl:if test="not(matches(., '\d+'))">
                                    <xsl:text> </xsl:text>
                                </xsl:if>
                                <!-- no @sep or active here. It would look odd to humans. -->
                            </xsl:for-each>
                        </xsl:element>
                    </xsl:element>
                </xsl:element>
            </xsl:when>

            <xsl:when test="count($tokens/tok[text() = '-']) = 0 and count($tokens/tok[matches(text(), '\d+')]) = 1">
                <!--
                    No hyphen and only one number so this is a single date.
                -->
                <xsl:element name="existDates" namespace="urn:isbn:1-931666-33-4">
                    <xsl:element name="date" namespace="urn:isbn:1-931666-33-4">
                        <xsl:variable name="curr_tok" select="$tokens/tok[matches(text(), '\d+')]"/>
                        <xsl:attribute name="standardDate" select="format-number($curr_tok, '0000')"/>
                        <!-- if we have an 'active' token 'active'. -->
                        <xsl:if test="($tokens/tok[text() = 'active']) or $is_family">
                            <xsl:attribute name="localType">
                                <xsl:text>active</xsl:text>
                            </xsl:attribute>
                        </xsl:if>

                        <!-- Add attributes notBefore, notAfter.  -->
                        <xsl:for-each select="$tokens/tok[matches(text(), '\d+')]/@*[matches(name(), '^not')]">
                            <xsl:choose>
                                <xsl:when test="string-length(.)>0">
                                    <xsl:attribute name="{name()}">
                                        <xsl:value-of select="format-number(., '0000')"/>
                                    </xsl:attribute>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:message>
                                        <xsl:copy-of select="$rec_pos" />
                                        <xsl:text> line 576 date empty attr: </xsl:text>
                                        <xsl:copy-of select="." />
                                        <xsl:text>&#x0A;</xsl:text>
                                        <xsl:copy-of select="$tokens" />
                                    </xsl:message>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>

                        <!-- is_family doesn't have an active token so we need
                             to add it here. Maybe it should have been added
                             earlier. -->
                        <xsl:if test="$is_family">
                            <xsl:text>active </xsl:text>
                        </xsl:if>

                        <!-- all tokens before the first date -->
                        <xsl:for-each select="$tokens/tok[matches(text(), '\d+')][1]/preceding-sibling::tok">
                            <xsl:value-of select="concat(., ' ')"/>
                        </xsl:for-each>
                        
                        <!-- the date itself, with @sep. -->
                        <xsl:value-of select="concat($curr_tok, $curr_tok/@sep)"/>
                        <!-- <xsl:if test="$tokens/tok[matches(text(), '\d+')][1]/@sep"> -->
                        <!--     <xsl:text> </xsl:text> -->
                        <!--     <xsl:value-of select="$tokens/tok[matches(text(), '\d+')][1]/@sep"/> -->
                        <!-- </xsl:if> -->
                    </xsl:element>
                </xsl:element>
            </xsl:when>

            <xsl:otherwise>
                <xsl:element name="existDates" namespace="urn:isbn:1-931666-33-4">
                    <xsl:element name="date" namespace="urn:isbn:1-931666-33-4">
                        <xsl:attribute name="localType" select="'questionable'"/>
                        <xsl:value-of select="$tokens/odate"/>
                    </xsl:element>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template> <!-- end tpt_show_date -->

    
    <xsl:template name="simple_date_range" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="from" />
        <xsl:param name="from_type"/>
        <xsl:param name="to" />
        <xsl:param name="to_type" />
        <dateRange>
            <xsl:if test="string-length($from) > 0">
                <fromDate standardDate="{$from}" localType="{$from_type}"><xsl:value-of select="$from"/></fromDate>
            </xsl:if>
            <xsl:if test="string-length($to) > 0">
                <toDate standardDate="{$to}" localType="{$to_type}"><xsl:value-of select="$to"/></toDate>
            </xsl:if>
        </dateRange>
    </xsl:template>


    <xsl:template name="tpt_exist_dates">
        <xsl:param name="xx_tag"/>
        <xsl:param name="entity_type"/>
        <xsl:param name="rec_pos"/>
        <xsl:param name="subfield_d"/>
        <!-- 
             MARC date parsing. Normalize various abbreviations and short
             hand. Support 1st, 2nd, 3rd, 4th century,
             
             1) Chew input string one token at a time with using a regular expression character class
             as separator. Put the tokens into a node set.
             
             2) Make several tranformation passes, each time copying "good" data to a new node set.
             
             3) Return the node set so that tpt_show_date can run rules on the
             final node set of tokens to build date elements.
             
             Examples: NNNN-NNNN, NNNN or N, NNNN(approx.), fl. NNNN, b. NNNN,
             d. NNNN, b. ca. NNNN, d. ca. NNNN, Nth cent., fl. Nth cent., Nth
             cent./Mth cent.
        -->
        <xsl:if test="boolean(normalize-space($subfield_d))">
            <xsl:variable name="token_1">
                <xsl:copy-of select="lib:tokenize(normalize-space($subfield_d))"/>
            </xsl:variable>
            
            <xsl:variable name="pass_1b">
                <xsl:copy-of select="lib:pass_1b($token_1)"/>
            </xsl:variable>
            
            <xsl:variable name="pass_2">
                <xsl:copy-of select="lib:pass_2($pass_1b)"/>
            </xsl:variable>
            
            <xsl:copy-of select="lib:pass_3($pass_2)"/>
        </xsl:if>
    </xsl:template>


   <xsl:function name="lib:edate_core">
        <xsl:param name="record_id"/>
        <xsl:param name="record_position"/>
        <xsl:param name="entity_type"/>
        <xsl:param name="df"/>
        <xsl:param name="alt_date"/>
        <!-- 
             $df only contains a single marc:datafield.
        -->
        <xsl:variable name="is_1xx" 
                      select="boolean($df/marc:datafield[@tag='100' or @tag='110' or @tag='111'])"/>
        
        <xsl:variable name="is_67xx"
                      select="boolean($df/marc:datafield[@tag='600' or @tag='610' or @tag='611' or @tag='700' or @tag='710' or @tag='711'])"/>
        
        <xsl:variable name="xx_tag">
            <xsl:value-of select="$df/marc:datafield/@tag"/>
        </xsl:variable>
        
        <xsl:variable name="rec_pos"
                      select="concat('offset: ', $record_position, ' id:', $record_id)"/>

        <xsl:variable name="tokens">
            <xsl:choose>
                <!--
                    Get date tokens. Below we pass these to tpt_show_date to
                    generate actual normative dates as a node set.  Any person
                    is equivalent as long as $df contains that person's info,
                    whether 1xx or 6xx/7xx.
                -->
                <xsl:when test="$entity_type = 'person' and (count($df/marc:datafield/marc:subfield[@code = 'd']) = 1)">
                    <xsl:call-template name="tpt_exist_dates">
                        <xsl:with-param name="xx_tag" select="$xx_tag"/>
                        <xsl:with-param name="entity_type" select="$entity_type"/>
                        <xsl:with-param name="rec_pos" select="$rec_pos"/>
                        <xsl:with-param name="subfield_d">
                            <xsl:copy-of select="$df/marc:datafield/marc:subfield[@code = 'd']"/>
                        </xsl:with-param>
                    </xsl:call-template>
                </xsl:when>

                <xsl:when test=" $is_1xx and $entity_type = 'family' and (count($df/marc:datafield/marc:subfield[@code = 'd']) = 1)">
                    <xsl:call-template name="tpt_exist_dates">
                        <xsl:with-param name="xx_tag" select="$xx_tag"/>
                        <xsl:with-param name="entity_type" select="$entity_type"/>
                        <xsl:with-param name="rec_pos" select="$rec_pos"/>
                        <xsl:with-param name="subfield_d">
                            <xsl:copy-of select="$df/marc:datafield/marc:subfield[@code = 'd']"/>
                        </xsl:with-param>
                    </xsl:call-template>
                </xsl:when>

                <xsl:when test=" $is_1xx and $entity_type = 'family' and $alt_date">
                    <!-- Family with no $d but which does have a 245$f aka alt_date. -->
                    <xsl:call-template name="tpt_exist_dates">
                        <xsl:with-param name="xx_tag" select="$xx_tag"/>
                        <xsl:with-param name="entity_type" select="$entity_type"/>
                        <xsl:with-param name="rec_pos" select="$rec_pos"/>
                        <xsl:with-param name="subfield_d">
                            <xsl:copy-of select="$alt_date"/>
                        </xsl:with-param>
                    </xsl:call-template>
                </xsl:when>

                <xsl:when test=" $is_67xx and $entity_type = 'family' and (count($df/marc:datafield/marc:subfield[@code = 'd']) = 1)">
                    <xsl:call-template name="tpt_exist_dates">
                        <xsl:with-param name="xx_tag" select="$xx_tag"/>
                        <xsl:with-param name="entity_type" select="$entity_type"/>
                        <xsl:with-param name="rec_pos" select="$rec_pos"/>
                        <xsl:with-param name="subfield_d">
                            <xsl:copy-of select="$df/marc:datafield/marc:subfield[@code = 'd']"/>
                        </xsl:with-param>
                    </xsl:call-template>
                </xsl:when>

                <xsl:otherwise>
                    <!-- <xsl:element name="no_date"> -->
                    <!--     <xsl:copy-of select="$df"/> -->
                    <!-- </xsl:element> -->
                </xsl:otherwise>

            </xsl:choose>
        </xsl:variable> <!-- end tokens -->
        
        <!--
            Test the string-length() since boolean() of a valid but empty variable is still true.
        -->

        <xsl:variable name="exist_dates">
            <xsl:if test="string-length($tokens) > 0">
                <xsl:call-template name="tpt_show_date">
                    <xsl:with-param name="tokens" select="$tokens"/>
                    <xsl:with-param name="is_family" select="$entity_type = 'family'"/>
                    <xsl:with-param name="rec_pos" select="$rec_pos"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:variable>
        
        <xsl:if test="$debug">
            <xsl:message>
                <xsl:value-of select="$rec_pos"/>
                <xsl:text> et: </xsl:text>
                <xsl:value-of select="$entity_type"/>
                <xsl:text> alt_date: </xsl:text>
                <xsl:value-of select="$alt_date"/>
                <xsl:text> is_1xx: </xsl:text>
                <xsl:value-of select="$is_1xx"/>
                <xsl:text> is_67xx: </xsl:text>
                <xsl:value-of select="$is_67xx"/>
                <xsl:text> 1xx: </xsl:text>
                <xsl:apply-templates mode="copy-no-ns" select="$df"/>
                <xsl:text>&#x0A;</xsl:text>
                <xsl:copy-of select="$exist_dates"/>
                <xsl:text>&#x0A;</xsl:text>
            </xsl:message>
        </xsl:if>

        <xsl:copy-of select="$tokens"/>
        <xsl:copy-of select="$exist_dates"/>
    </xsl:function> <!-- lib:edate_core -->

    <xsl:template name="tpt_file_suffix">
        <xsl:param name="xx_tag"/>
        <xsl:param name="count"/>
        <xsl:choose>
            <xsl:when test="$xx_tag = '100' or $xx_tag = '110' or $xx_tag = '111'">
                <xsl:text>c</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>r</xsl:text>
                <xsl:value-of select="format-number($count, '00')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="tpt_expanded_suffix">
        <xsl:param name="xx_tag"/>
        <xsl:param name="count"/>
        <xsl:param name="status"/>
        <!--
            context is the full marc record, so we should have access to anything we need.
        -->
        <xsl:choose>
            <xsl:when test="$status='a' or $status='c' or $status='n' or $status='C'">
                <xsl:text>A</xsl:text>
            </xsl:when>
            <xsl:when test="$xx_tag = '600'">
                <xsl:text>P</xsl:text>
            </xsl:when>
            <xsl:when test="$xx_tag = '610' or $xx_tag = '611'">
                <xsl:text>C</xsl:text>
            </xsl:when>
            <xsl:when test="marc:datafield[@tag='774' and matches(marc:subfield[@code='o'],'\(SIA\sAH\d+\)')]">
                <xsl:text>S</xsl:text>
            </xsl:when>
            <xsl:when test="marc:datafield[@tag='780' or @tag='785']">
                <xsl:text>EL</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>r</xsl:text>
                <xsl:value-of select="format-number($count, '00')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <xsl:template name="tpt_tens">
        <xsl:param name="xx_tag"/>
        <!--
            Create variable for tens positions of the n00 n10 and n11 for 100 600 700. Could probably use substring,
            modulo or a regex, but this is simple and clear even if it isn't very elegant.
        -->
        <xsl:choose>
            <xsl:when test="$xx_tag = '100' or $xx_tag = '600' or $xx_tag = '700'">
                <xsl:text>00</xsl:text>
            </xsl:when>
            <xsl:when test="$xx_tag = '110' or $xx_tag = '610' or $xx_tag = '710'">
                <xsl:text>10</xsl:text>
            </xsl:when>
            <xsl:when test="$xx_tag = '111' or $xx_tag = '611' or $xx_tag = '711'">
                <xsl:text>11</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    

    
    <xsl:template name="tpt_name_entry">
        <xsl:param name="xx_tag"/>
        <xsl:param name="record_position"/>
        <xsl:param name="record_id"/>
        <!-- 
             The "name entry" is the name in $a plus other fields. Thus
             "Lansdown, Andrew, 1954-" is considred different from "Lansdown,
             Andrew, 1?54-". There could be even more extreme examples that
             differ by only one subfield, rather than differing by a date-typo
             as in this example.
        -->

        <xsl:variable name="has_n">
            <xsl:value-of select="count(marc:subfield[@code = 'n'])" />
        </xsl:variable>

        <xsl:variable name='t167_tens'>
            <xsl:call-template name="tpt_tens">
                <xsl:with-param name="xx_tag" select="$xx_tag"/>
            </xsl:call-template>
        </xsl:variable>
        <!-- 
             The $a subfield is not out here by itself (that is: outside the
             for-each loops below). Even though $a is common to all the loops
             below simply because heaven forbid that $a wasn't the first
             subfield. The cleanest, most reliable algorithm treats the $a like
             the rest of the subfields and retains the original subfield order
             of the original XML record.
        -->
        <xsl:if test="$t167_tens = '00'">
            <xsl:for-each
                select="./marc:subfield[@code = 'a' or @code = 'b' or @code = 'c' or @code='d'  or @code='j'  or @code='q']">
                <xsl:text> </xsl:text>
                <xsl:value-of select="normalize-space(.)"/>
            </xsl:for-each>
        </xsl:if>

        <xsl:if test="$t167_tens = '10'">
            <!-- Get the @code preceding a $n and use that code to test for not $t and not $k.-->
            <xsl:variable name="pre_n">
                <xsl:value-of select="marc:subfield[@code = 'n'][1]/preceding-sibling::*[1]/@code" />
            </xsl:variable>

            <xsl:for-each select="marc:subfield">
                <xsl:if test="@code = 'a' or @code = 'b' or @code = 'c' or @code='d' or (@code='n' and not($pre_n = 't') and not($pre_n = 'k'))">
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="normalize-space(.)"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>

        <xsl:if test="$t167_tens = '11'">
            <!-- Get the @code preceding a $n and use that code to test for not $t and not $k.-->
            <xsl:variable name="pre_n">
                <xsl:value-of select="marc:subfield[@code = 'n'][1]/preceding-sibling::*[1]/@code" />
            </xsl:variable>

            <xsl:for-each select="marc:subfield">
                <xsl:if test="@code = 'a' or @code = 'c' or @code = 'd' or @code='e' or @code='q' or @code='n'">
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="normalize-space(.)"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
    </xsl:template> <!-- end tpt_name_entry -->


    <xsl:template name="tpt_mods" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="all_xx"/>
        <xsl:param name="agency_info"/>
        <!--
            We assume that we have at least one 1xx or 7xx name in
            $all_xx/container/ename. Title from MARC 245 (all subfields
            except $6 and $8). If 245 lacks $f and $g then append space 260
            $c (Doing the usual "if present" test first.)
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
                      boolean(marc:datafield[@tag = '245']/marc:subfield[not(@code = 'f') and
                      not(@code = 'g')])">
                <xsl:text> </xsl:text>
                <xsl:value-of select="marc:datafield[@tag = '260']/marc:subfield[@code = 'c']"/>
            </xsl:if>
        </xsl:variable>

        <!-- 
             In the code below, we include an e_name in the MODS <name> if it is 1xx or
             is_creator(). It turns out that over in tpt_all_xx (lib.xsl) we set is_creator true
             for 7xx, or for a 6xx that is a duplicate of a 7xx. tpt_all_xx also sets is_creator
             for 1xx, and while that is probably redundant, is it consistent. In the code below
             we could probably use is_creator or match against [17]xx and get the same
             effect. This all seems somewhat un-robust, but it was necessary as a workaround to
             completely rewriting tpt_all_xx.
        -->
	<xsl:element name="objectXMLWrap" xmlns:eac="urn:isbn:1-931666-33-4">
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
        </xsl:element>
    </xsl:template> <!-- end tpt_mods -->


    <xsl:template name="tpt_agency_info" xmlns="urn:isbn:1-931666-33-4">
        <!-- 
             If there is a single marc query result then use it. When there are two records for a give
             marc_query, use literal "OCLC" for org code, no name, and add a descriptive note. When no result,
             no org code, name is original query, add descriptive note. The only allowed attribute is
             localType so use span tags inside p for all the data. Elements p and descptiveNote do not allow
             localType, so everything must be in span.
        -->
        <xsl:variable name="org_query" select="normalize-space(marc:datafield[@tag='040']/marc:subfield[@code='a'])"/>
        <xsl:variable name="ainfo" select="$org_codes/marc:container[marc:marc_query = $org_query]"/>
        <xsl:choose>
            <xsl:when test="count($ainfo)=1 and string-length($ainfo/marc:isil)>0">
                <xsl:element name="agencyCode" xmlns:eac="urn:isbn:1-931666-33-4">
                    <xsl:value-of select="$ainfo/marc:isil"/>
                </xsl:element>
                <xsl:element name="agencyName" xmlns:eac="urn:isbn:1-931666-33-4">
                    <xsl:value-of select="$ainfo/marc:name"/>
                </xsl:element>
            </xsl:when>
            <xsl:when test="count($ainfo)>1">
                <xsl:element name="agencyCode" xmlns:eac="urn:isbn:1-931666-33-4">
                    <xsl:text>OCLC-AO#</xsl:text>
                </xsl:element>
                <xsl:element name="agencyName" xmlns:eac="urn:isbn:1-931666-33-4">
                    <xsl:text>New York State Archives</xsl:text>
                </xsl:element>
                <xsl:element name="descriptiveNote" xmlns:eac="urn:isbn:1-931666-33-4">
                    <xsl:for-each select="$org_codes/marc:container[marc:marc_query = $org_query]">
                        <p>
                            <span localType="multipleRegistryResults"/>
                            <span localType="original"><xsl:value-of select="$org_query"/></span>
                            <span localType="inst"><xsl:value-of select="marc:name"/></span>
                            <span localType="isil"><xsl:value-of select="marc:isil"/></span>
                        </p>
                    </xsl:for-each>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <agencyName xmlns:eac="urn:isbn:1-931666-33-4">
                    <xsl:value-of select="$org_query"/>
                </agencyName>
                    <xsl:element name="descriptiveNote" xmlns:eac="urn:isbn:1-931666-33-4">
                        <xsl:element name="p" xmlns:eac="urn:isbn:1-931666-33-4">
                            <xsl:element name="span" xmlns:eac="urn:isbn:1-931666-33-4">
                                <xsl:attribute name="localType" select="'noRegistryResults'"/>
                            </xsl:element>
                            <xsl:element name="span">
                                <xsl:attribute name="localType" select="'original'"/>
                                <xsl:value-of select="$org_query"/>
                            </xsl:element>
                        </xsl:element>
                    </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="tpt_tag_545" xmlns="urn:isbn:1-931666-33-4">
        <!-- 
             biogHist. Remove newlines. After some discussion, we're keeping all
             the subfields.  Historically, that this only used the 545$a (which
             could be repeating), so if there were any 545$b they would have
             been ignored (lost).
        -->
        <!-- <xsl:for-each select="marc:datafield[@tag='545']/marc:subfield[@code='a']" > -->
        <xsl:for-each select="marc:datafield[@tag='545']/marc:subfield" >
            <p>
                <xsl:value-of select="normalize-space(replace(self::node(), '&#x0A;', ''))"/>
            </p>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="tpt_function">
        <xsl:variable name="all">
            <xsl:for-each select="marc:datafield[@tag='657']">
                <function xmlns="urn:isbn:1-931666-33-4">
                    <term>
                        <xsl:if test="marc:subfield[@code='a']">
                            <xsl:value-of select="lib:norm-punct(marc:subfield[@code='a'])"/>
                        </xsl:if>
                        
                        <xsl:for-each select="marc:subfield[@code='x' or @code='y' or @code='z']">
                            <xsl:text>--</xsl:text>
                            <xsl:value-of select="lib:norm-punct(.)"/>
                        </xsl:for-each>
                    </term>
                </function>
            </xsl:for-each>
        </xsl:variable>
        <!-- 
             The node-set dedup idiom. See extensive comments with tpt_geo.
             Context is function so paths below are term being relative to the context node.
        -->
        <xsl:for-each select="$all/eac:function[string-length(eac:term) > 0]">
            <xsl:variable name="curr" select="."/>
            <xsl:if test="not(preceding::eac:term[lib:pname-match(text(), $curr/eac:term)])">
                <xsl:copy-of select="$curr"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>


    <xsl:template name="tpt_all_xx" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="record_id"/>
        <xsl:param name="index"/>
        <xsl:param name="tag"/>
        <xsl:param name="curr" /><!-- forcing data type seems to be optional as="node()*" -->
        <xsl:param name="unique_count" as="xs:integer"/>
        <xsl:param name="record_position"/>
        <xsl:param name="creator_info"/>
        <xsl:param name="status"/>
        <!-- 
             Recurse over all the [167]xx records creating a var containing a node set we will eventually use
             to create potentially multiple output files. We de-duplicate (dedupe) during the recursion by
             checking the current value against values we have already accumulated. Unfortunately, this
             recusive algorithm prevents us from looking ahead for things like a 700 record to use as a
             creatorOf arcrole. The non-recursive method with post-node-set-creation de-duplication is more
             flexible.
             
             Var $df is working because the context is the original record for all depths of recursion. (At
             least in this case since we don't change the context.)
             
             http://stackoverflow.com/questions/10324122/explicitly-typed-variables-in-xsl
             XSLT 1.0 does not have explicit types for variables and params. XTLT 2.0 uses the "as" attribute.
             
             This template generates info that is destined for output, so it is explicitly in the eac
             namespace, which means that $all_xx is in the eac namespace.
        -->
        <xsl:variable name="df">
            <xsl:copy-of
                select="marc:datafield[@tag='100' or
                        @tag='110' or @tag='111' or
                        @tag='600' or @tag='610' or
                        @tag='611' or @tag='700' or
                        @tag='710' or @tag='711'][$index]"/>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="string($df) and matches($df/marc:datafield/marc:subfield[@code='a'][1], '[A-Za-z0-9]+')">
                <!--
                    We need to have some value in $df, and it needs to include
                    some alpha numeric values. A single comma as the value is
                    not good. There is at least one 700$a that is "," and that
                    kind of thing upsets XSLT's regex engine, and is not a sensible name entry.
                    
                    Build the full name entity name entry. Use for-each to set
                    $df as the context. tpt_name_entry relies on the context.
                -->
                <xsl:variable name="ne_temp">
                    <xsl:for-each select="$df/marc:datafield">
                        <xsl:call-template name="tpt_name_entry">
                            <xsl:with-param name="xx_tag" select="$tag"/>
                            <xsl:with-param name="record_position" select="$record_position"/>
                            <xsl:with-param name="record_id" select="$record_id"/>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:variable>

                <!-- Determine the entity type. -->
                <xsl:variable name="temp_et">
                    <xsl:call-template name="tpt_entity_type">
                        <xsl:with-param name="df">
                            <xsl:copy-of select="$df"/>
                        </xsl:with-param>
                    </xsl:call-template>
                </xsl:variable>
                
                <!-- 
                     New: count of unique entries is totally separate from position().
                -->
                <xsl:variable name="fn_suffix">
                    <xsl:call-template name="tpt_file_suffix">
                        <xsl:with-param name="xx_tag" select="$df/marc:datafield/@tag"/>
                        <xsl:with-param name="count" select="$unique_count - 1"/>
                    </xsl:call-template>
                </xsl:variable>

                <xsl:variable name="expanded_suffix">
                    <xsl:call-template name="tpt_expanded_suffix">
                        <xsl:with-param name="xx_tag" select="$df/marc:datafield/@tag"/>
                        <xsl:with-param name="count" select="$unique_count - 1"/>
                        <xsl:with-param name="status" select="$status"/>
                    </xsl:call-template>
                </xsl:variable>
                
                <!--
                    Mnemonic for "entity type first capital" since the http://RDVocab.info/uri/schema/FRBRentitiesRDA/ uses
                    first letter capitalization.
                -->
                <xsl:variable name="entity_type_fc">
                    <xsl:if test="$temp_et = 'person'">
                        <xsl:text>Person</xsl:text>
                    </xsl:if>
                    <xsl:if test="$temp_et = 'family'">
                        <xsl:text>Family</xsl:text>
                    </xsl:if>
                    <xsl:if test="$temp_et = 'corporateBody'">
                        <xsl:text>CorporateBody</xsl:text>
                    </xsl:if>
                </xsl:variable>
                
                <xsl:variable name="temp_node">
                    <!-- 
                         See variable creator_info in oclc_marc2cpf.xsl. There can be non-7xx duplicate
                         names. Changing the de-duplicating code here would require a full rewrite of
                         tpt_all_xx, so when there is a matching 7xx, I just mark the first occurance (whether
                         6xx or 7xx) as is_creator="true()", no matter what the $df tag value. Also, if the
                         current tag is 7xx, then is_creator="true()".
                    -->
                    <xsl:variable name="alt_date" select="marc:datafield[@tag = '245']/marc:subfield[@code = 'f']"/>
                    <container> <!-- namespace is eac due to xmlns in xsl:template above xmlns="urn:isbn:1-931666-33-4" -->
                        <e_name>
                            <xsl:attribute name="tag" select="$df/marc:datafield/@tag"/>
                            <xsl:attribute name="record_id" select="$record_id"/>
                            <xsl:attribute name="entity_type" select="$temp_et"/>
                            <xsl:attribute name="entity_type_fc" select="$entity_type_fc"/>
                            <xsl:attribute name="fn_suffix" select="$fn_suffix"/>
                            <xsl:attribute name="expanded_suffix" select="$expanded_suffix"/>
                            <xsl:attribute name="is_creator">
                                <xsl:choose>
                                    <xsl:when test="lib:pname-match($creator_info/marc:creator_name, $ne_temp)">
                                        <xsl:value-of  select="true()"/>
                                    </xsl:when>
                                    <xsl:when test="$df/marc:datafield[matches(@tag, '[17]{1}(00|10|11)')]">
                                        <xsl:value-of  select="true()"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="false()"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:attribute>
                            <xsl:value-of select="normalize-space($ne_temp)"/>
                        </e_name>

                        <xsl:copy-of select="lib:edate_core($record_id, $record_position, $temp_et, $df, $alt_date)"/>

                        <xsl:element name="subordinateAgency">
		            <xsl:for-each select="marc:datafield[@tag='774']">
		                <xsl:if test="matches(marc:subfield[@code='o'],'\(SIA\sAH\d+\)')">
			            <xsl:copy-of select="."/>
		                </xsl:if>
		            </xsl:for-each>
                        </xsl:element>

	                <xsl:element name="earlierLaterEntries">
		            <xsl:for-each select="marc:datafield[@tag='780' or @tag='785']">
		                <xsl:copy-of select="."/>
		            </xsl:for-each>
                        </xsl:element>
                    </container>
                    <xsl:text>&#x0A;</xsl:text>
                </xsl:variable>
                <!-- 
                     Return either true or false, explicitly. In order to get the
                     $unique_count working, we need a variable to carry the
                     unique-ness due to scoping problems. Failure to explicitly
                     type cast is_unique_flag to boolean will cause all tests
                     against it to be evaluated as strings, even though it is being
                     assigned a boolean value. test="" will silently evaluate its
                     argument, often contrary to how testing variables works in
                     other programming languages.
                     
                     Must check for zero length strings first, or we get a data
                     type error. If (not ( $curr and $curr already has the value
                     of $temp_node)) then add $temp_node to our node set. In
                     other words, if $curr is empty then add $temp_node. If
                     $temp_node is not a duplicate then add $temp_node.
                     
                     XPTY0019: Required item type of first operand of '/' is
                     node(); supplied value has item type xs:string
                     
                     New: Use regex matches() to do case insensitive
                     comparison. Escape the regular expression (the second arg)
                     since things like . / - [ ] ( ) etc. in a string are regex
                     special characters. If we only wanted lower-case() matching, we
                     could lower-case() both arguments. In this instance we want a
                     special name/puncutation match, so this demonstrates how we can
                     do regex matching. This may be about the same speed as
                     lower-casing both strings and then comparing.
                     
                     Note that we must use the eac: namespace here with $curr and $temp_node since all_xx is
                     explicitly in the eac namespace.
                -->
                
                <xsl:variable name="is_unique_flag" as="xs:boolean" >
                    <xsl:choose>
                        <xsl:when test="not(boolean($curr))">
                            <xsl:value-of select="true()"/>
                        </xsl:when>
                        <xsl:when
                            test="$curr/eac:container/eac:e_name[lib:pname-match(text(), $temp_node/eac:container/eac:e_name/text())]">
                            <!-- skip a duplicate -->
                            <xsl:value-of select="false()"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="true()"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>

                <xsl:variable name="new_uc">
                    <xsl:choose>
                        <xsl:when test="$is_unique_flag">
                            <xsl:value-of select="$unique_count + 1"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$unique_count"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>

                <xsl:variable name="new_curr">
                    <xsl:copy-of select="$curr"/>
                    <xsl:if test="boolean($is_unique_flag)">
                        <xsl:copy-of select="$temp_node"/>
                    </xsl:if>
                </xsl:variable>

                <!--
                    Recurse. Use "as" to be sure that curr and
                    unique_count have the proper type. The default
                    behavior seems to be to convert anything to a string,
                    rather than using the thing's data type.
                -->
                <xsl:call-template name="tpt_all_xx">
                    <xsl:with-param name="record_id" select="$record_id"/>
                    <xsl:with-param name="index" select="$index+1"/>
                    <xsl:with-param name="tag" select="$tag"/>
                    <xsl:with-param name="curr" as="node()*">
                        <xsl:copy-of select="$new_curr"/>
                    </xsl:with-param>
                    <xsl:with-param name="unique_count" select="$new_uc" as="xs:integer"/>
                    <xsl:with-param name="record_position" select="$record_position"/>
                    <xsl:with-param name="creator_info" select="$creator_info"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <!-- 
                     When we run out of Zxx datafields, stop recursing (by not
                     calling template tpt_all_xx) and return a copy of $curr
                     which we have been building all along through the
                     recursion.
                -->
                <xsl:copy-of select="$curr"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template> <!-- end tpt_all_xx -->
      
      
    <xsl:function name="lib:date_cat" as="xs:string" >
        <xsl:param name="date" as="xs:string?"/> 
        <xsl:param name="cat" as="xs:string?"/> 
        <xsl:sequence select="concat(substring($date, 1, string-length($date) - string-length($cat)), $cat)"/>
    </xsl:function>


    <xsl:function name="lib:tokenize">
        <xsl:param name="subfield_d" as="xs:string?"/> 
        <!--
            For the purposes of initial tokenizing, everything is either
            separator or not-separator. If separator matches '-' then create a
            "-" token. If separator matches '/' then create an "or"
            token. "1601/2" is conceptually "1601 or 2". If - or / occur in some
            other context, bad things may happen. All other separators are
            discarded.
        -->
        <xsl:element name="odate">
            <!-- <xsl:value-of select="lower-case(normalize-space(marc:datafield[@tag = $xx_tag]/marc:subfield[@code = 'd']))"/> -->
            <xsl:value-of select="lower-case(normalize-space($subfield_d))"/>
        </xsl:element>
        <xsl:analyze-string select="$subfield_d"
                            regex="([ ;/,\.\-\?:\(\)\[\]]+)|([^ ;/,\.\-\?:\(\)\[\]]+)">
            <xsl:matching-substring>
                <xsl:choose>

                    <xsl:when test="matches(regex-group(1), '-') or matches(regex-group(1), '\?')">
                        <!--
                            Separators can be '?', '-', or '?-' so we need a
                            couple of if statements. Note that the '?' if
                            statement must be first. We do not support '-?'
                            because it seems wrong. It could be accomodated by
                            creating tokens in order with a for-each based on
                            the chars in regex-group(1).
                        -->
                        <xsl:if test="matches(regex-group(1), '\?')">
                            <xsl:element name="tok">?</xsl:element>
                        </xsl:if>
                        <xsl:if  test="matches(regex-group(1), '-')">
                            <xsl:element name="tok">-</xsl:element>
                        </xsl:if>
                    </xsl:when>

                    <xsl:when test="matches(regex-group(1), '/')">
                        <xsl:element name="tok">or</xsl:element>
                    </xsl:when>

                    <xsl:when test="matches(regex-group(2), 'approx')">
                        <!--
                            This is not a keyword, but simply a normalized
                            token. The token is 'approx'. Do not change to
                            'approximately' unless you are prepared to change
                            and fix all the other code relying on 'approx'. In
                            fact, if you want to change it, change it to
                            'aprx_tok' or something distinctly token-ish.
                        -->
                        <xsl:element name="tok">approx</xsl:element>
                    </xsl:when>

                    <xsl:when test="string-length(regex-group(2)) > 0">
                        <!-- <tok> -->
                        <xsl:element name="tok">
                            <xsl:value-of select="lower-case(normalize-space(regex-group(2)))"/>
                        </xsl:element>
                        <!-- </tok> -->
                    </xsl:when>

                </xsl:choose>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:element name="untok">
                    <xsl:value-of select="normalize-space(.)"/>
                </xsl:element>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function> <!-- end lib:tokenize -->


    <xsl:function name="lib:pass_1b">
        <xsl:param name="tokens" as="node()*"/> 
        <!-- 
             Disambiguate (normal "or") and (century "or") by making (century "or") into a token "cyr".
        -->
        <xsl:copy-of select="$tokens/odate"/>
        <xsl:copy-of select="$tokens/untok"/>
        <xsl:for-each select="$tokens/tok">
            <xsl:choose>

                <xsl:when test="text() = 'or' and following-sibling::tok[matches(text(), 'cent')]">
                    <xsl:element name="tok">
                        <xsl:text>cyr</xsl:text>
                    </xsl:element>
                </xsl:when>

                <xsl:otherwise>
                    <xsl:copy-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:function>

    <xsl:function name="lib:pass_2">
        <xsl:param name="tokens" as="node()*"/> 
        <!-- 
             Process NNNNs (1870s) and "or N".
        -->
        <xsl:copy-of select="$tokens/odate"/>
        <xsl:copy-of select="$tokens/untok"/>
        <xsl:for-each select="$tokens/tok">
            <xsl:variable name="p_tok"
                          select="preceding-sibling::tok[1]"/>
            <xsl:variable name="f_tok"
                          select="following-sibling::tok[1]"/>
            <xsl:choose>

                <!-- Make sure this won't match 1st -->
                <xsl:when test="matches(., '\d+s[^t]')">
                    <xsl:analyze-string select="."
                                        regex="(\d+)s">
                        <xsl:matching-substring>
                            <xsl:element name="tok">
                                <xsl:attribute name="notBefore"><xsl:value-of select="lib:min_ess(regex-group(1))"/></xsl:attribute>
                                <xsl:attribute name="notAfter"><xsl:value-of select="lib:max_ess(regex-group(1))"/></xsl:attribute>
                                <xsl:attribute name="sep"><xsl:text>s</xsl:text></xsl:attribute>
                                <xsl:value-of select="lib:min_ess(regex-group(1))"/>
                            </xsl:element>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:when>

                <xsl:when test="$f_tok = 'or'">
                    <!-- if following is '-' (or whatever) we want that since it is used during analysis later. -->
                    <xsl:variable name="or_date"
                                  select="format-number(number(lib:date_cat(text(), following-sibling::tok[2])), '0000')"/>
                    <xsl:element name="tok">
                        <xsl:attribute name="notBefore"><xsl:value-of select="."/></xsl:attribute>
                        <xsl:attribute name="notAfter"><xsl:value-of select="$or_date"/></xsl:attribute>
                        <!-- <xsl:attribute name="sep"><xsl:value-of select="concat('or ', following-sibling::tok[2])"/></xsl:attribute> -->
                        <xsl:attribute name="sep"><xsl:value-of select="concat(' or ', $or_date)"/></xsl:attribute>
                        <xsl:value-of select="."/>
                    </xsl:element>
                </xsl:when>

                <xsl:when test="($p_tok = 'or') or (text() = 'or')">
                    <!--
                        Does first preceding tok match 'or'? For example "or 2"
                        and this is token "2". If so, we processed this already
                        so we do not want to see it again. Same if this token
                        matches 'or'. 
                    -->
                </xsl:when>

                <xsl:when test="$f_tok = '?'">
                    <!-- If the following token is ? then do a date range. -->
                    <xsl:element name="tok">
                        <xsl:attribute name="notBefore"><xsl:value-of select="number(.) -1"/></xsl:attribute>
                        <xsl:attribute name="notAfter"><xsl:value-of select="number(.) + 1"/></xsl:attribute>
                        <!-- <xsl:attribute name="sep"><xsl:value-of select="'?'"/></xsl:attribute> -->
                        <xsl:value-of select="."/>
                    </xsl:element>
                </xsl:when>

                <xsl:when test="text() = '?'">
                    <!--
                        ? tokens have already been processed so throw them away.
                    -->
                </xsl:when>

                <xsl:when test="$p_tok = 'ca' or $p_tok = 'c' or $p_tok = 'circa' or $f_tok = 'approx'">
                    <!--
                        If the preceding token is circa (in any form) then +3 -3
                        date range. Ditto if following token is 'approx'. If the
                        following token is 'approx' then insert a 'circa' token
                        before our date so this date will be just like a normal
                        circa date.
                    -->
                    <xsl:if test="$f_tok = 'approx'">
                        <xsl:element name="tok">
                            <xsl:text>approximately</xsl:text>
                        </xsl:element>
                    </xsl:if>
                    <xsl:element name="tok">
                        <xsl:attribute name="notBefore"><xsl:value-of select="number(.) - 3"/></xsl:attribute>
                        <xsl:attribute name="notAfter"><xsl:value-of select="number(.) + 3"/></xsl:attribute>
                        <xsl:value-of select="."/>
                    </xsl:element>
                </xsl:when>

                <xsl:when test="text() = 'approx'">
                    <!--
                        Do nothing for approx since they will be converted into
                        leading 'approximately' tokens by the code above.
                    -->
                </xsl:when>

                <xsl:when test="text() = 'ca' or text() = 'c' or text() = 'circa'">
                    <xsl:element name="tok">
                        <xsl:text>approximately</xsl:text>
                    </xsl:element>
                </xsl:when>

                <xsl:when test="matches(., 'fl', 'i')">
                    <xsl:element name="tok">
                        <xsl:value-of select="'active'"/>
                    </xsl:element>
                </xsl:when>

                <xsl:otherwise>
                    <xsl:copy-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:function>
                        
    <xsl:function name="lib:pass_3">
        <xsl:param name="tokens" as="node()*"/> 
        <xsl:copy-of select="$tokens/odate"/>
        <xsl:copy-of select="$tokens/untok"/>

        <xsl:for-each select="$tokens/tok">
            <xsl:choose> 
                <!-- Remember that "cyr" is the token for century "or", usually
                     a "/" char in the original string. -->
                <xsl:when test="matches(text(),
                                '\d+(st|nd|rd|th)') and following-sibling::tok[1] = 'cyr' and matches(following-sibling::tok[2],
                                '\d+(st|nd|rd|th)')">
                    <xsl:variable name="cent1"
                        select="lib:ordinal_number(text())"/>
                    
                    <xsl:variable name="cent2"
                        select="lib:ordinal_number(following-sibling::tok[2])"/>
                    
                    <!-- The algebraic formula is only slightly confusing. In
                         XSLT / is a path and div is the division operator. No
                         division here. -->

                    <xsl:element name="tok">
                        <xsl:attribute name="notBefore"><xsl:value-of select="(($cent1/num -1) * 100) + 1"/></xsl:attribute>
                        <xsl:attribute name="notAfter"><xsl:value-of select="$cent2/num * 100"/></xsl:attribute>
                        <xsl:value-of select="concat($cent1/num, $cent1/suffix)"/>
                        <xsl:value-of select="concat('/', $cent2/num, $cent2/suffix)"/>
                        <xsl:value-of select="' century'"/>
                    </xsl:element>
                </xsl:when>

                <xsl:when test="text() = 'cyr' or preceding-sibling::tok[1] = 'cyr'">
                    <!-- Skip, ignore. This is ignoring the "cyr" token as well
                         as the following token. If the tokens are 19th, cyr,
                         20th, we utilize cyr and 20th in other steps, so we
                         ignore them here. -->
                </xsl:when>

                <xsl:when test="matches(text(), '\d+(st|nd|rd|th)') and matches(following-sibling::tok[1], 'cent')">
                    <xsl:analyze-string select="text()"
                                        regex="(\d+)(st|nd|rd|th)">
                        <xsl:matching-substring>
                            <xsl:variable name="cent">
                                <xsl:value-of select="number(regex-group(1))"/>
                            </xsl:variable>
                            <xsl:element name="tok">
                                <xsl:attribute name="notBefore"><xsl:value-of select="(($cent -1) * 100) + 1"/></xsl:attribute>
                                <xsl:attribute name="notAfter"><xsl:value-of select="$cent * 100"/></xsl:attribute>
                                <xsl:value-of select="concat($cent, regex-group(2), ' century')"/>
                            </xsl:element>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:when>

                <xsl:when test="matches(text(), 'cent')">
                    <!-- nothing, skip -->
                </xsl:when>

                <xsl:otherwise>
                    <xsl:copy-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:function>


    <xsl:function name="lib:ordinal_number">
        <xsl:param name="date" as="xs:string?"/>
        <!--
            Get the digits from 1st 2nd 3rd 4th, etc. Must have an outer element
            or xpath for the inner elements is tricky. For input "20th" output
            is <ord><num>20</num><suffix>th</suffix></ord>.
        -->
        <xsl:analyze-string select="$date" regex="(\d+)(.*)">
            <xsl:matching-substring>
                <xsl:element name="ord">
                    <xsl:element name="num">
                        <xsl:value-of select="regex-group(1)"/>
                    </xsl:element>
                    <xsl:element name="suffix">
                        <xsl:value-of select="regex-group(2)"/>
                    </xsl:element>
                </xsl:element>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:function>


    <xsl:function name="lib:min_ess" as="xs:string">
        <xsl:param name="date" as="xs:string?"/>
        <!--
            Return the minimum number for 1800s. This is trivial now, but it
            seems like it might need future complexity, so it is here in a
            function. Companion to max_ess() below.
        -->
        <xsl:value-of select="$date"/>
    </xsl:function>


    <xsl:function name="lib:max_ess" as="xs:string">
        <xsl:param name="date" as="xs:string?"/>
        <!--
            Return the max number for 1800s. For now we only handle 100s or 10s, for example 1800s or
            1820s. Companion to min_ess() above. Returning zero upon failure is dubious, and I don't think it
            will ever happen. Saxon 8 didn't care, but 9he knows when there's no xsl:otherwise.
        -->
        <xsl:choose>
            <xsl:when test="(number($date) mod 100) = 0">
                <xsl:value-of select="number($date) + 99"/>
            </xsl:when>
            <xsl:when test="(number($date) mod 10) = 0">
                <xsl:value-of select="number($date) + 9"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>0</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>


    <xsl:template mode="copy-no-ns" match="*" >
        <!--
            Using local-name() works way better than name(). In fact, if you ask
            this template to print something with a namespace unknown to this
            file, it throws an error when using name().

            Print elements withtout the pesky namespace. This is mostly for
            debugging where the namespace is just extraneous text that
            interferes with legibility. Seems that we need to replace this line to
            prevent namespace from printing.  <xsl:element name="{name(.)}"
            namespace="{namespace-uri(.)}">

            Interestingly, having a namespace such as the following in the
            stylesheet header causes that namespace to output regardless of the
            tricks below.
            
            xmlns="http://www.loc.gov/MARC21/slim"

            Also interesting is that if we put xmlns="urn:isbn:1-931666-33-4"
            into the opening template element above, that problem goes
            away. Putting the xmlns into the apply-templates or the outer
            template in eac-cpf.xsl changes nothing.
            -->
        <xsl:element name="{local-name(.)}">
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="copy-no-ns"/>
        </xsl:element>
    </xsl:template>

    <xsl:template name="tpt_entity_type" xmlns:ns="http://www.loc.gov/MARC21/slim"> 
        <xsl:param name="df"/>
        <!--
            Determine the entity type. Give the template a name so we can talk about it in the documentataion and
            comments. The input param $df must be a copy-of node set, not a value-of string.
        -->
        <xsl:choose>
            <xsl:when test="$df/marc:datafield[(@tag='100' or @tag='600' or @tag='700') and @ind1 = '3']">
                <xsl:text>family</xsl:text>
            </xsl:when >
            <xsl:when test="$df/marc:datafield[(@tag='100' or @tag='600' or @tag='700') and not(@ind1 = '3')]">
                <xsl:text>person</xsl:text>
            </xsl:when>
            <xsl:when test="$df/marc:datafield[@tag='110' or @tag='111' or @tag='610' or @tag='611' or @tag='710' or @tag='711']">
                <xsl:text>corporateBody</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>


    <!-- 
         Deep copy via identity replacing the existing namespace with a new one. This is not a common thing to
         do since usually you would want to use the value of the input document element as an element with a
         new name in the output. This does want people wish copy-namespace="no" or something similar would do,
         but does not. 

         <xsl:call-template name="renamespace">
         <xsl:with-param name="ns" select="'urn:isbn:1-931666-33-4'" />
         </xsl:call-template>
    -->
    <xsl:template name="renamespace" >
        <xsl:param name="ns"/>
        <xsl:element name="{local-name(.)}" namespace="{$ns}">
            <xsl:copy-of select="@*"/>	
            <!--
                Use for-each to set the context to the children elements of '.'. It iterates once for each
                child.
            -->
            <xsl:for-each select="./*">
                <xsl:call-template name="renamespace"/>
            </xsl:for-each>
        </xsl:element>
    </xsl:template>


    <xsl:function name="functx:is-node-in-sequence-deep-equal" as="xs:boolean" 
                  xmlns:functx="http://www.functx.com" >
        <xsl:param name="node" as="node()?"/> 
        <xsl:param name="seq" as="node()*"/> 
        <xsl:sequence select=" 
                              some $nodeInSeq in $seq satisfies deep-equal($nodeInSeq,$node)
                              "/>
    </xsl:function>
    
    <xsl:function name="functx:distinct-deep" as="node()*" 
                  xmlns:functx="http://www.functx.com" >
        <xsl:param name="nodes" as="node()*"/> 
        <xsl:sequence select=" 
                              for $seq in (1 to count($nodes))
                              return $nodes[$seq][not(functx:is-node-in-sequence-deep-equal(
                              .,$nodes[position() &lt; $seq]))]
                              "/>
    </xsl:function>
    
    <xsl:function name="functx:escape-for-regex" as="xs:string" 
                  xmlns:functx="http://www.functx.com" >
        <xsl:param name="arg" as="xs:string?"/> 
        <!--
            I wonder why this is a sequence and not value of? Blindly copied
            from other functions.
        -->
        <xsl:value-of select="
                              replace($arg,
                              '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1')
                              "/>
    </xsl:function>

    <xsl:function name="lib:norm-punct" as="xs:string">
        <xsl:param name="str" as="xs:string?"/>
        <!--
            Normalize space and remove trailing punctuation. So far only period
            and comma.  Do a second replace to normalize "etc" to "etc.". There
            are probably other abbreviations lurking in the data.
        -->
        <xsl:value-of select="replace(replace(normalize-space($str), '[\.,]+$', ''), 'etc$', 'etc.')"/>
    </xsl:function>

    <xsl:function name="lib:pname-match" as="xs:boolean">
        <xsl:param name="str1" as="xs:string?"/>
        <xsl:param name="str2" as="xs:string?"/>
        <!--
            Punctuation-normalized name match. Preserve leading comma. If the
            length is different after un-punctuating the strings must be
            different then return false. Else return the results of
            matches(). Order of arguments to matches() doesn't matter because
            the two un-punctuated strings are the same length.
            
            No need to lower case both strings because we're using a regex with 'i'.
            
            Add an additional replace() around the lib:unpunct() call because
            there is one record with '\&', but after hours of trying to get xslt
            to take that in some escaped form in a regex, I've given up, and
            just delete it from both strings. We only care about comparing
            punctuation-clean strings, so we only need to clean both strings the
            same way. We cannot modify/break lib:unpunct() because that is used
            elsewhere to unpunctuate strings that are real data in the cpf
            output.
        -->
        <!-- <xsl:variable name="clean1" select="replace(lib:unpunct($str1),'\\&#x26;', '')"/> -->
        <!-- <xsl:variable name="clean2" select="replace(lib:unpunct($str2),'\\&#x26;', '')"/> -->
        <xsl:variable name="clean1" select="lower-case(lib:unpunct($str1))"/>
        <xsl:variable name="clean2" select="lower-case(lib:unpunct($str2))"/>
        <xsl:choose>
            <xsl:when test="not(string-length($clean1) = string-length($clean2))">
                <xsl:value-of select="false()"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- <xsl:value-of select="matches(functx:escape-for-regex($clean1), $clean2, 'i')"/> -->
                        <!-- <xsl:message> -->
                        <!--     <xsl:text>clean1: </xsl:text> -->
                        <!--     <xsl:copy-of select="$clean1"/> -->
                        <!--     <xsl:text> clean2: </xsl:text> -->
                        <!--     <xsl:copy-of select="$clean2"/> -->
                        <!--     <xsl:text>&#x0A;</xsl:text> -->
                        <!-- </xsl:message> -->

                <xsl:value-of select="$clean1 = $clean2"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>


    <xsl:function name="lib:unpunct" as="xs:string*" >
        <xsl:param name="str" as="xs:string?"/>
        <!--
            Forcing return type does not prevent error "A sequence of more than
            one item..."
            
            Replace some chars with space, then delete some chars,
            then normalize-space().  Preserve leading comma. We are only
            implementing the relevant parts. LOC has details. The key thing is
            that some chars are converted to space, while other chars are
            deleted.  http://www.loc.gov/aba/pcc/naco/normrule-2.html

            ampersand is &#x26; " is &#x22; The list we care about: ,.(){}[]:;?/&#x22;[]#!=@
            We have to do &#x27;&#x27; to get a single quote. Unclear why '' doesn't work.
            
           Need a special pass for '\&' that occurs in one place. Remove it for unpunctuated text.
        -->
        <xsl:variable name="pass_1">
            <xsl:value-of select="replace($str, '[\{\}\(\):,!>\-&lt;\.\?&#x22;]', ' ')"/>
        </xsl:variable>

        <xsl:variable name="pass_2">
            <xsl:value-of select="replace($pass_1, '[&#x27;&#x27;\[\]]', '')"/>
        </xsl:variable>

        <!-- 
             Carefully return a string, not a sequence.
        -->

        <xsl:choose>
            <xsl:when test="substring($str,1,1) = ','">
                <xsl:value-of select="concat(',',normalize-space($pass_2))"/> 
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="normalize-space($pass_2)"/> 
            </xsl:otherwise>
        </xsl:choose>
   </xsl:function>

    <xsl:function name="lib:unpluralize">
        <xsl:param name="str" as="xs:string?"/>
        <xsl:variable name="pass_1">
            <xsl:value-of select="replace($str, 'ies$', 'y')"/>
        </xsl:variable>

        <xsl:variable name="pass_2">
            <xsl:value-of select="replace($pass_1, 's$', '')"/>
        </xsl:variable>

        <xsl:variable name="pass_3">
            <xsl:value-of select="replace($pass_2, 'men$', 'man')"/>
        </xsl:variable>

        <xsl:value-of select="normalize-space($pass_3)"/>
    </xsl:function>


</xsl:stylesheet>
