QA Notes
--------

Copy and paste the "less" command into a terminal and verify appropriate parts of the cpf output. This
section needs more notes. Some QA examples towards the end have notes. The file name sometimes gives a cryptic
reminder. Some localType attributes here may not match updated reality.

At least one of these is non-1xx and does not generate output. Some have nothing
special and are either historical or negative result QA tests.

We want the output in the ./cpf directory because the files don't have the same prefix or a consistent enough
suffix to enable use to clean up with "rm -f" unless the output is in a separate directory.

# Preferred
saxon.sh qa_all.xml oclc_marc2cpf.xsl

# Newer, but still not preferred
find ./qa -name "*.xml" -exec saxon.sh {} oclc_marc2cpf.xsl \;

# Older
find ./qa -name "*.xml" -exec saxon.sh {} oclc_marc2cpf.xsl output_dir=cpf \;

  twl8n@shannon __ Fri Apr 26 09:49:51 EDT 2013 __   eta: 07:10:09   ps: zsh
  /lv1/home/twl8n/eac_project   
> ls cpf | wc -l
524


---

The 700 should be the creatorOf in the cpfRelation, which happens to be the
second datafield so it is the .r01 since not1xx records .r numbering starts
with .r00.

    <namePart>Sharps, Turney, Mrs.</namePart>
    <roleTerm valueURI="http://id.loc.gov/vocabulary/relators/cre">Creator</roleTerm>

    -rw-r--r-- 1 mst3k snac  1994 Dec  3 15:56 qa_11422625_not1xx_has_600_has_700.xml
    less cpf/*11422625.r00.xml
    less cpf/*11422625.r01.xml

---

Not creatorOf, but should have 6 .r files for the 6xx datafields

    -rw-r--r-- 1 mst3k snac  4146 Dec  3 15:52 qa_702172281_not1xx_multi_600.xml
    less cpf/*702172281.r00.xml
    ls -l cpf/*702172281.*

---

Washburn (F|f)amily should only occur once

    -rw-r--r-- 1 mst3k snac  4808 Sep 25 11:14 qa_11447242_case_dup.xml
    less cpf/*11447242.c.xml

---

multiple snac:associatedPlace, snac:associatedSubject, aka topicalSubject, geographicSubject

    -rw-r--r-- 1 mst3k snac  5373 Nov 19 16:39 qa_122456647_651_multi_a.xml
    less cpf/*122456647.c.xml

---

The 700 should be the creatorOf in the .r01. Uses the 245$f as active date only for the .r01 because Morrill
is 700 aka author therefore he was active on the 245$f date, but we can't be sure the subject (610) was active
on that date.

    <datafield tag="700" ind1="1" ind2=" ">
      <subfield code="a">Morrill, Dan L.</subfield>
    </datafield>

    <namePart>Morrill, Dan L.</namePart>
    <role>
      <roleTerm valueURI="http://id.loc.gov/vocabulary/relators/cre">Creator</roleTerm>
    </role>

         <existDates>
            <date localType="http://socialarchive.iath.virginia.edu/control/term#Active"
                  standardDate="1987"
                  notBefore="1984"
                  notAfter="1990">active approximately 1987</date>
         </existDates>


    -rw-r--r-- 1 mst3k snac  3527 Dec  3 15:51 qa_26891471_not1xx_has_700.xml
    less cpf/*26891471.r01.xml
    less cpf/*26891471.r00.xml
    less cpf/NKM-26891471.r00.xml
    less cpf/NKM-26891471.r01.xml

---

We only process 245$f as active for 1xx|7xx. Since the .rxx files are for 6xx, the 245$f does not apply to them.

    -rw-r--r-- 1 mst3k snac  2874 Oct 24 14:56 qa_122519914_corp_body_245_f_date.xml
    less cpf/*122519914.c.xml
    less cpf/n-122519914.r01.xml

---

    -rw-r--r-- 1 mst3k snac  5618 Nov 19 18:12 qa_122537190_sundown_escape_characters.xml
    less cpf/*122537190.c.xml

---

         <existDates>
            <date localType="http://socialarchive.iath.virginia.edu/control/term#SuspiciousDate">1735-1???.</date>
         </existDates>

    -rw-r--r-- 1 mst3k snac 20333 Nov 26 14:55 qa_122542862_date_nqqq.xml
    less cpf/*122542862.r76.xml
    less cpf/*122542862.c.xml


--- 

Agency code "C" returns two entries from the WorldCat registry.

    -rw-r--r-- 1 mst3k snac  7534 Nov 14 13:13 qa_122583172_marc_c_two_oclc_orgs.xml
    less cpf/*122583172.c.xml

---

Two 657 elements are identical. Tests the deduplicating code for functions. (Original XML was manually
modified.)

    <datafield tag="657" ind1=" " ind2="7">
        <subfield code="a">Administration of nonprofit organizations.</subfield>
        <subfield code="2">lcsh</subfield>
    </datafield>
    <datafield tag="657" ind1=" " ind2="7">
        <subfield code="a">Administration of nonprofit organizations.</subfield>
        <subfield code="2">lcsh</subfield>
    </datafield>

    <function>
        <term>Administration of nonprofit organizations</term>
    </function>
    
    -rw-r--r-- 1 twl8n snac 17768 Feb 20 15:46 qa/qa_123408061a_dupe_function_657.xml
    less cpf/*123408061a.c.xml

---

245$f dates are parsed for families. Has several cpfRelation elements, for Person and CorporateBody.

    <subfield code="f">1917-1960.</subfield>

         <existDates>
            <dateRange>
               <fromDate localType="http://socialarchive.iath.virginia.edu/control/term#Active"
                         standardDate="1917">active 1917</fromDate>
               <toDate localType="http://socialarchive.iath.virginia.edu/control/term#Active"
                       standardDate="1960">active 1960</toDate>
            </dateRange>
         </existDates>

    -rw-r--r-- 1 mst3k snac  5041 Oct 18 09:54 qa/qa_123410709_family_245f_date.xml
    less cpf/*123410709.c.xml


----

Date with "or" in the middle, and a trailing "?".

    <subfield code="d">1061 or 2-1121?</subfield>

         <existDates>
            <dateRange>
               <fromDate standardDate="1061"
                         localType="http://socialarchive.iath.virginia.edu/control/term#Birth"
                         notBefore="1061"
                         notAfter="1062">1061 or 1062</fromDate>
               <toDate standardDate="1121"
                       localType="http://socialarchive.iath.virginia.edu/control/term#Death"
                       notBefore="1120"
                       notAfter="1122">1121</toDate>
            </dateRange>
         </existDates>

    -rw-r--r-- 1 mst3k snac  3239 Oct  3 11:29 qa/qa_123415450_or_question.xml
    saxon.sh qa/qa_123415450_or_question.xml oclc_marc2cpf.xsl
    less cpf/*123415450.c.xml

---

d. 767 or 8.

         <existDates>
            <dateRange>
               <fromDate/>
               <toDate standardDate="0767"
                       localType="http://socialarchive.iath.virginia.edu/control/term#Death"
                       notBefore="0767"
                       notAfter="0768">0767 or 0768</toDate>
            </dateRange>
         </existDates>

    -rw-r--r-- 1 mst3k snac  4013 Oct  3 11:40 qa_123415456_died_or.xml
    saxon.sh qa/qa_123415456_died_or.xml oclc_marc2cpf.xsl
    less cpf/*123415456.c.xml

---

Test parsing of "?" to mean year-1 to year+1 for "1213?-1296?"

    <fromDate standardDate="1213" localType="born" notBefore="1212" notAfter="1214">1213</fromDate>
    <toDate standardDate="1296" localType="died" notBefore="1295" notAfter="1297">1296</toDate>
               
    -rw-r--r-- 1 mst3k snac  4073 Oct  3 11:52 qa_123415574_qmark.xml
    saxon.sh qa/qa_123415574_qmark.xml oclc_marc2cpf.xsl
    less cpf/*123415574.c.xml


---

I think this tests 100 and 700 creators in the same file. 

    <mods xmlns="http://www.loc.gov/mods/v3">
       <name>
          <namePart>Blackburn, Joyce.</namePart>
          <role>
             <roleTerm valueURI="http://id.loc.gov/vocabulary/relators/cre">Creator</roleTerm>
          </role>
       </name>
       <name>
          <namePart>Clayton, Stephanie,</namePart>
          <role>
             <roleTerm valueURI="http://id.loc.gov/vocabulary/relators/cre">Creator</roleTerm>
          </role>
       </name>

    -rw-r--r-- 1 mst3k snac  5153 Sep 25 15:30 qa_123439095_mods_leader.xml
    less cpf/*123439095.c.xml

---

Tests 1xx with multi 7xx which generate .rxx, and generate mods name entries.  Horowitz is duplicated in the
input (differentiated by 700$4 and we don't use the $4), but we only output Horowitz once.

    -rw-r--r-- 1 mst3k snac 3636 Jan 14 15:10 qa/qa_123452814_dup_700_name.xml
    less cpf/*123452814.r01.xml
    less cpf/*123452814.c.xml

---


Code update Mar 2013. This record has a function. 
As of dec 7 2012 the code clearly only processes $e (and $4) for 100, not for 110.  Apparently, that means
that this record does not have an occupation. 

    -rw-r--r-- 1 mst3k snac  3409 Nov  5 16:43 qa_155416763_110_e_occupation.xml
    less cpf/*155416763.c.xml

---

date 1865(approx.)-1944.

    -rw-r--r-- 1 mst3k snac  1561 Oct  3 12:13 qa_155438491_approx.xml
    saxon.sh qa/qa_155438491_approx.xml oclc_marc2cpf.xsl
    less cpf/*155438491.c.xml

---

date -1688

    -rw-r--r-- 1 mst3k snac  1904 Oct  4 11:56 qa_155448889_date_leading_hyphen.xml
    less cpf/*155448889.c.xml

---

dpt isn't in any of our authority lists, but col is.

    <subfield code="4">col</subfield>
    <subfield code="4">dpt</subfield>
         <occupation localType="snac:derivedFromRole">
            <term>Collectors.</term>
         </occupation>

     -rw-r--r-- 1 mst3k snac  4410 Nov  2 08:30 qa_17851136_no_e_two_4_occupation.xml
     less cpf/*17851136.c.xml

----    

    <languageDeclaration><language languageCode="swe">Swedish</language>

    -rw-r--r-- 1 mst3k snac  1375 Nov 13 10:51 qa_209838303_lang_040b_swe.xml
    less cpf/*209838303.c.xml

----

Has no existDates in output. New code Mar 2013. 245$f has a separate date parser, and only attempts to part 4
digit numbers out of dates since the dates will only be "active". This 245$f having no 4 digit dates is not
parsed, thus no existDates at all.
    
     <datafield tag="245" ind1="0" ind2="0">
        <subfield code="k">Papers,</subfield>
        <subfield code="f">????-????</subfield>
     </datafield>
    
    -rw-r--r-- 1 mst3k snac  2814 Nov 26 10:31 qa_210324503_date_all_question_marks.xml
    less cpf/*210324503.c.xml

---

This verifies that questionable dates display as suspiciousDate.

         <existDates>
            <date localType="http://socialarchive.iath.virginia.edu/control/term#SuspiciousDate">1912-0.</date>
         </existDates>

    -rw-r--r-- 1 mst3k snac  3542 Nov 26 14:48 qa_220227335_date_nnnn_hyphen-zero.xml
    less cpf/*220227335.c.xml

---


Has a good date and a bad date.  The name is a duplicate, except that the dates are not the same which causes
the names to be treated as unique. The .r01 has the questionable date.

         <existDates>
            <date localType="http://socialarchive.iath.virginia.edu/control/term#suspiciousDate">1?54-</date>
         </existDates>

    -rw-r--r-- 1 mst3k snac  4352 Nov 26 11:21 qa_220426543_date_1_q_54_hypen.xml
    less cpf/*220426543.r01.xml

---

Manually modified based on 222612265 so we would have a died ca date. The original two instances of
"b. ca. 1896" changed to "d. ca. 1896" (Manually modified.)

         <existDates>
            <dateRange>
               <fromDate/>
               <toDate standardDate="1986"
                       localType="http://socialarchive.iath.virginia.edu/control/term#Death"
                       notBefore="1983"
                       notAfter="1989">approximately 1986</toDate>
            </dateRange>
         </existDates>

    saxon.sh qa/qa_222612265x_fake_died_ca_date.xml oclc_marc2cpf.xsl
    less cpf/*222612265x.c.xml
    

---

(Manually modified) The "a" file has a born ca date. "b. ca. 1896" occurs twice. Dup 600 varies from 100 only
by a period (dot) at the end of the born date so this also tests de-duplicating ignores a trailing period (and
all trailing punctuation, I think).

         <existDates>
            <dateRange>
               <fromDate standardDate="1896"
                         localType="http://socialarchive.iath.virginia.edu/control/term#Birth"
                         notBefore="1893"
                         notAfter="1899">approximately 1896</fromDate>
               <toDate/>
            </dateRange>
         </existDates>

    -rw-r--r-- 1 twl8n snac 3324 Feb 20 16:12 qa/qa_222612265a_b_ca_date.xml
    less cpf/*222612265a.c.xml

---- 

The "x" file has duplicate died "d. ca. 1896" to exercise the died date code.

         <existDates>
            <dateRange>
               <fromDate/>
               <toDate standardDate="1986"
                       localType="http://socialarchive.iath.virginia.edu/control/term#Death"
                       notBefore="1983"
                       notAfter="1989">approximately 1986</toDate>
            </dateRange>
         </existDates>

    -rw-r--r-- 1 twl8n snac 3571 Feb 20 16:14 qa/qa_222612265x_fake_died_ca_date.xml
    saxon.sh qa/qa_222612265a_b_ca_date.xml oclc_marc2cpf.xsl
    less cpf/*222612265x.c.xml

---

Manually modified.

   <datafield tag="656" ind1=" " ind2="7">
      <subfield code="a">Academics.</subfield>
      <subfield code="2">local</subfield>
   </datafield>
   <datafield tag="656" ind1=" " ind2="7">
      <subfield code="a">Academics.</subfield>
      <subfield code="2">local</subfield>
   </datafield>

         <existDates>
            <dateRange>
               <fromDate standardDate="1893"
                         localType="http://socialarchive.iath.virginia.edu/control/term#Birth">1893</fromDate>
               <toDate standardDate="1981"
                       localType="http://socialarchive.iath.virginia.edu/control/term#Death">1981</toDate>
            </dateRange>
         </existDates>

    -rw-r--r-- 1 twl8n snac 3766 Feb 20 16:27 qa/qa_225810091a_600_family_date_dupe_occupation.xml
    less cpf/*225810091a.c.xml

---

The 651$v "Correspondence" doesn't match an occupation, but 656$a "Gold miners" is an occupation, albeit not
one that is looked up in an authority record.

    -rw-r--r-- 1 mst3k snac  3709 Sep 20 12:56 qa_225815320_651_v.xml
    less cpf/*225815320.c.xml
    
----

When taking into account topical subject concatenation, I'm not seeing a frank duplication. I'm not seeing
it for a geographical subject either. In any case, this example has many topical subjects and a geographical
subject.

    -rw-r--r-- 1 mst3k snac  5545 Oct 26 11:43 qa_225851373_dupe_places_with_dot_dupe_topical.xml
    less cpf/*225851373.c.xml

---

    <subfield code="d">fl. 2nd cent.</subfield>

         <existDates>
            <date standardDate="0101"
                  localType="http://socialarchive.iath.virginia.edu/control/term#Active"
                  notBefore="0101"
                  notAfter="0200">active 2nd century</date>
         </existDates>

    -rw-r--r-- 1 mst3k snac  2536 Oct 11 09:29 qa_233844794_fl_2nd_cent_date.xml
    less cpf/*233844794.c.xml

---

Multi 1xx has no output at this time.

    -rw-r--r-- 1 mst3k snac  3706 Sep 10 11:01 qa_270613908_multi_1xx.xml
    less cpf/*270613908.c.xml

---

    <subfield code="d">d. 1601/2.</subfield>
    <toDate standardDate="1601" localType="died" notBefore="1601" notAfter="1602">-1601 or 1602</toDate>

    -rw-r--r-- 1 mst3k snac  1508 Oct  4 15:49 qa_270617660_date_slash.xml
    less cpf/*270617660.c.xml

---

    <subfield code="d">fl. 1724/25.</subfield>

         <existDates>
            <date standardDate="1724"
                  localType="http://socialarchive.iath.virginia.edu/control/term#Active"
                  notBefore="1724"
                  notAfter="1725">active 1724 or 1725</date>
         </existDates>

    -rw-r--r-- 1 mst3k snac  1738 Oct  8 10:07 qa_270657317_fl_date_slash_n.xml
    less cpf/*270657317.c.xml

---

The questionable date is output in the .r01 file.

    <subfield code="d">1834-1876 or later.</subfield>

         <existDates>
            <date localType="http://socialarchive.iath.virginia.edu/control/term#SuspiciousDate">1834-1876 or later.</date>
         </existDates>
 
    -rw-r--r-- 1 mst3k snac  2573 Nov 26 10:40 qa_270873349_date_or_later.xml
    less cpf/*270873349.r01.xml

---

    <subfield code="d">19th/20th cent.</subfield>
    <date notBefore="1801" notAfter="2000">19th/20th century</date>

    -rw-r--r-- 1 mst3k snac  2428 Oct  3 08:58 qa/qa_281846814_19th_slash_20th.xml
    less cpf/*281846814.c.xml

---

    <subfield code="d">1837-[1889?]</subfield>

         <existDates>
            <dateRange>
               <fromDate standardDate="1837"
                         localType="http://socialarchive.iath.virginia.edu/control/term#Birth">1837</fromDate>
               <toDate standardDate="1889"
                       localType="http://socialarchive.iath.virginia.edu/control/term#Death"
                       notBefore="1888"
                       notAfter="1890">1889</toDate>
            </dateRange>
         </existDates>

    -rw-r--r-- 1 mst3k snac  4505 Oct  3 14:41 qa_313817562_sq_bracket_date.xml
    less cpf/*313817562.c.xml

---

That is an ell, not a one. one nine four ell.

    <subfield code="d">194l-</subfield>
         <existDates>
            <date localType="http://socialarchive.iath.virginia.edu/control/term#SuspiciousDate">194l-</date>
         </existDates>

    -rw-r--r-- 1 mst3k snac  1829 Oct  3 14:51 qa_3427618_date_194ell.xml
    less cpf/*3427618.c.xml

---

I think this test exists to make sure subfields are concatenated in order, even if that order is a, c, a, d,
as opposed to a, a, c, d as errant XSLT did at one point.

    <subfield code="a">Jones,</subfield>
    <subfield code="c">Mrs.</subfield>
    <subfield code="a">J.C.,</subfield>
    <subfield code="d">1854-</subfield>

results in:

    <part>Jones, Mrs. J.C., 1854-</part>

    -rw-r--r-- 1 mst3k snac 2112 Jan 14 15:14 qa/qa_367559635_100_acad_concat.xml
    less cpf/*367559635.c.xml

---

Tests proper de-duping that ignores trailing punctuation.

    <subfield code="a">Hachimonji, Kumezô.</subfield>
    <subfield code="a">Hachimonji, Kumezô</subfield>

    -rw-r--r-- 1 mst3k snac  6104 Oct 26 14:09 qa_39793761_punctation_name.xml
    less cpf/*39793761.c.xml

---

One of two examples of a 100 family with no 100$d date, so it uses the 245$f date as an "active" date.

    <datafield tag="245" ind1="1" ind2="0">
        <subfield code="a">Waterman family papers,</subfield>
        <subfield code="f">1839-1906.</subfield>
    </datafield>

         <existDates>
            <dateRange>
               <fromDate localType="http://socialarchive.iath.virginia.edu/control/term#Active"
                         standardDate="1839">active 1839</fromDate>
               <toDate localType="http://socialarchive.iath.virginia.edu/control/term#Active"
                       standardDate="1906">active 1906</toDate>
            </dateRange>
         </existDates>

    -rw-r--r-- 1 mst3k snac 3826 Dec 19 11:14 qa/qa_42714894_waterman_245f_date.xml
    less cpf/*42714894.c.xml

---

Has a lone comma in 700$a which broke the code at one point. I can't remember why I called it
"multi_sequence".

    <datafield tag="700" ind1="1" ind2=" ">
        <subfield code="a">,</subfield>
        <subfield code="e">interviewer.</subfield>
    </datafield>

         <existDates>
            <dateRange>
               <fromDate standardDate="1905"
                         localType="http://socialarchive.iath.virginia.edu/control/term#Birth">1905</fromDate>
               <toDate standardDate="1990"
                       localType="http://socialarchive.iath.virginia.edu/control/term#Death">1990</toDate>
            </dateRange>
         </existDates>

    -rw-r--r-- 1 mst3k snac  3589 Nov 19 21:03 qa_44529109_multi_sequence.xml
    less cpf/*44529109.c.xml

---

Only in the .r01 file.

         <existDates>
            <date localType="http://socialarchive.iath.virginia.edu/control/term#SuspiciousDate">date -</date>
         </existDates>

    -rw-r--r-- 1 mst3k snac  2912 Nov 26 14:46 qa_495568547_date_hyphen_only.xml
    less cpf/*495568547.r01.xml


---

We parse 1870s.

         <existDates>
            <dateRange>
               <fromDate standardDate="1870"
                         localType="http://socialarchive.iath.virginia.edu/control/term#Birth"
                         notBefore="1870"
                         notAfter="1879">1870s</fromDate>
               <toDate/>
            </dateRange>
         </existDates>

    -rw-r--r-- 1 mst3k snac  2615 Oct  9 10:24 qa/qa_505818582_date_1870s.xml
    saxon.sh qa/qa_505818582_date_1870s.xml  oclc_marc2cpf.xsl
    less cpf/*505818582.c.xml

---

Test that 1800s does the whole 100 years just as 1870s does an entire 10 years. Note the -1 offset between
"1800s" and "19th century"

         <existDates>
            <dateRange>
               <fromDate standardDate="1800"
                         localType="http://socialarchive.iath.virginia.edu/control/term#Birth"
                         notBefore="1800"
                         notAfter="1899">1800s</fromDate>
               <toDate/>
            </dateRange>
         </existDates>


    saxon.sh qa/qa_505818582a_date_1870s.xml oclc_marc2cpf.xsl
    less cpf/*GHT-505818582a.c.xml
    less cpf/*GHT-505818582a.r01.xml


---

    <datafield tag="100" ind1="1" ind2=" ">
        <subfield code="a">Whipple, John Adams,</subfield>
        <subfield code="d">1822-1891,</subfield>
        <subfield code="e">photographer.</subfield>
        <subfield code="4">att</subfield>
    </datafield>

         <existDates>
            <dateRange>
               <fromDate standardDate="1822"
                         localType="http://socialarchive.iath.virginia.edu/control/term#Birth">1822</fromDate>
               <toDate standardDate="1891"
                       localType="http://socialarchive.iath.virginia.edu/control/term#Death">1891</toDate>
            </dateRange>
         </existDates>
         <occupation localType="http://socialarchive.iath.virginia.edu/control/term#DerivedFromRole">
            <term>Photographers.</term>
         </occupation>

    -rw-r--r-- 1 mst3k snac  2662 Nov  2 08:25 qa_51451353_e4_occupation.xml
    less cpf/*51451353.c.xml

---

This may exist to exercise 650$b multiple values which maybe is supposed to be non-repeating. It does
repeat, so we concatenate. At one point it broke something, perhaps a string function by sending a sequence
instead of a single string.

    <datafield tag="650" ind1="1" ind2="7">
        <subfield code="a">CHILE</subfield>
        <subfield code="b">MINISTERIO DE TIERRAS Y COLONIZACION</subfield>
        <subfield code="b">DEPARTAMENTO JURIDICO Y DE INPECCION DE SERVICIOS.</subfield>
        <subfield code="2">renib</subfield>
    </datafield>

    <localDescription localType="http://socialarchive.iath.virginia.edu/control/term#associatedSubject">
        <term>CHILE--MINISTERIO DE TIERRAS Y COLONIZACION--DEPARTAMENTO JURIDICO Y DE INPECCION DE SERVICIOS</term>
    </localDescription>

    -rw-r--r-- 1 mst3k snac  2348 Nov 19 11:17 qa_55316797_650_multi_b.xml
    less cpf/*55316797.c.xml

---

This .r56 should be a questionable date. It broke the code by trying to turn a null string into a
number. Either it made 0000 which is questionable (wrong), or Saxon died with an error.
 
         <existDates>
            <date localType="http://socialarchive.iath.virginia.edu/control/term#SuspiciousDate">1714 or -15-1757.</date>
         </existDates>

    -rw-r--r-- 1 mst3k snac 14958 Nov 26 10:35 qa_611138843_date_or_hyphen_15_hyphen_1757.xml
    less cpf/*611138843.r56.xml

---

         <existDates>
            <dateRange>
               <fromDate standardDate="1834"
                         localType="http://socialarchive.iath.virginia.edu/control/term#Birth"
                         notBefore="1834"
                         notAfter="1835">1834 or 1835</fromDate>
               <toDate/>
            </dateRange>
         </existDates>

    -rw-r--r-- 1 mst3k snac  3278 Oct  8 10:27 qa_671812214_b_dot_or.xml
    saxon.sh qa/qa_671812214_b_dot_or.xml oclc_marc2cpf.xsl
    less cpf/*671812214.c.xml

---

Is (and should be) questionable, make sure it doesn't crash the script

         <existDates>
            <date localType="http://socialarchive.iath.virginia.edu/control/term#SuspiciousDate">16uu-17uu.</date>
         </existDates>

    -rw-r--r-- 1 mst3k snac  3801 Oct  9 11:57 qa_678631801_date_16uu.xml
    less cpf/*678631801.c.xml

---

         <existDates>
            <date standardDate="0001" notBefore="0001" notAfter="0100">1st century</date>
         </existDates>

    -rw-r--r-- 1 mst3k snac  3347 Nov 20 10:44 qa_702176575_date_1st_cent.xml
    less cpf/*702176575.c.xml

---

The 100$e doesn't hit any occupation, but I think at one point trying to resolve a string with a leading
comma caused it to process as a sequence and not as a string and that made Saxon die with an error.

    -rw-r--r-- 1 mst3k snac  6825 Nov 20 14:05 qa_733102265_comma_interviewee.xml
    less cpf/*733102265.c.xml

---

"Donors" is not an occupation in our authority files. "Authors" is.

    <datafield tag="100" ind1="1" ind2=" ">
        <subfield code="a">Jacobs, Jo,</subfield>
        <subfield code="d">1933-</subfield>
        <subfield code="e">donor</subfield>
        <subfield code="e">author.</subfield>
    </datafield>

         <occupation localType="http://socialarchive.iath.virginia.edu/control/term#derivedFromRole">
            <term>Authors.</term>
         </occupation>

    -rw-r--r-- 1 mst3k snac  2282 Nov  2 08:52 qa_768242927_multi_e_occupation.xml
    less cpf/*768242927.c.xml

---

verify that .r08 future date is questionable, even if it is probably a typo.

    <date localType="questionable">8030-1857.</date>

    -rw-r--r-- 1 mst3k snac  7190 Nov 26 10:45 qa_777390959_date_greater_than_2012.xml
    saxon.sh qa/qa_777390959_date_greater_than_2012.xml oclc_marc2cpf.xsl
    less cpf/*777390959.c.xml
    less cpf/*777390959.r08.xml


---

look for only one .r record for "Kane, Thomas Leiper,". He shows up in the MODS record as a (co)creator.

    -rw-r--r-- 1 mst3k snac  3197 Sep 18 09:15 qa_8560008_dup_600_700.xml
    less cpf/*8560008.c.xml
    less cpf/*8560008.r01.xml
    
    grep "part>Kane" cpf/*8560008.*.xml  

cpf/YWM-8560008.r01.xml:            <part>Kane, Thomas Leiper, 1822-1883.</part>


---

MODS abstract is all 520$a concatented with space.

    -rw-r--r-- 1 mst3k snac  4168 Nov 28 12:57 qa_8560380_multi_520a.xml
    less cpf/*8560380.c.xml

---

verify geo "Ohio--Ashtabula County" from concat 650 with multi $z

    <datafield tag="650" ind1=" " ind2="0">
        <subfield code="a">Real property</subfield>
        <subfield code="z">Ohio</subfield>
        <subfield code="z">Ashtabula County.</subfield>
    </datafield>

         <place localType="http://socialarchive.iath.virginia.edu/control/term#associatedPlace">
            <placeEntry>Ohio--Ashtabula County</placeEntry>
         </place>

    -rw-r--r-- 1 mst3k snac  5389 Sep 27 10:26 qa_8562615_multi_650_multi_z.xml
    saxon.sh qa/qa_8562615_multi_650_multi_z.xml oclc_marc2cpf.xsl
    less cpf/*8562615.c.xml

---

100 is the .c and dup in 600 should not make a .r file. Value is "Longfellow, Henry Wadsworth, 1807-1882."

    -rw-r--r-- 1 mst3k snac  2252 Sep 18 09:14 qa_8563535_dup_100_600.xml
    less cpf/*8563535.c.xml

---

Was a test for noRegistryResults, but that has changed. Maybe now a test for Unknown repository?

                  <name>
                     <namePart>Unknown</namePart>
                     <role>
                        <roleTerm valueURI="http://id.loc.gov/vocabulary/relators/rps">Repository</roleTerm>
                     </role>
                  </name>


    <maintenanceAgency>
      <agencyName>BANC</agencyName>
        <descriptiveNote>
          <p>
            <span localType="noRegistryResults"/>
            <span localType="original">BANC</span>
          </p>
      </descriptiveNote>
    </maintenanceAgency>
        
    -rw-r--r-- 1 mst3k snac  4192 Nov 15 12:44 qa_86132608_marc_040a_BANC_no_result.xml
    less cpf/*86132608.c.xml

---

Person with no 100$d uses 245$f as active date: active 1922-1949.

    -rw-r--r-- 1 twl8n snac 3429 Feb 20 12:50 qa/qa_8586125_person_245f_date_range.xml
    less cpf/*8586125.c.xml

---

Not parsed. The old date code did this, but the new 245$f specific active date code doesn't parse
century. Person with no 100$d uses 245$f, active 1st century (manually modified data)

    -rw-r--r-- 1 twl8n snac 3432 Feb 20 13:49 qa/qa_8586125a_person_245f_century.xml
    less cpf/*8586125a.c.xml
    
---

Not parsed by new code. Person with no 100$d uses 245$f, active 1st/2nd century
(manually modified data)

    -rw-r--r-- 1 twl8n snac 3436 Feb 20 13:51 qa/qa_8586125b_person_245f_two_century.xml
    less cpf/*8586125b.c.xml

---

Not parsed by new code. Person with no 100$d uses 245$f, single active 1st century - 2nd century (manually
modified data)

I don't think there is a rule to properly parse this, but I don't think we have any of these in the real
WorldCat data, so this might be a pointless QA test.

    -rw-r--r-- 1 twl8n snac 3446 Feb 20 13:53 qa/qa_8586125c_person_245f_range_century.xml
    less cpf/*8586125c.c.xml

---

Person with no 100$d uses 245$f, active 1980.

    -rw-r--r-- 1 twl8n snac 2245 Feb 20 13:02 qa/qa_8594295_person_single_245f_date.xml

    less cpf/*8594295.c.xml
    
    
-----

Multiple dates so we only capture min as fromDate and max as toDate since we only care about active.

    -rw-r--r-- 1 twl8n snac 3346 Mar  8 15:50 qa/qa_123410649_multi_date_245f.xml
    less cpf/WiMiJHS-123410649.c.xml
    less cpf/WiMiJHS-123410649.r01.xml


------

Multiple dates in two 245$f subfields, gets parsed as multi-date for fromDate and toDate. 

Also tests Worldcat agency code lookup. Should resolve to OCLC-UCB.

                  <recordInfo>
                     <recordOrigin>WorldCat:85037313a</recordOrigin>
                     <recordContentSource>ISIL:OCLC-UCB</recordContentSource>
                  </recordInfo>


    -rw-r--r-- 1 twl8n snac 2048 Mar  4 11:37 qa/qa_85037313a_two_245f_alt_dates.xml
    less cpf/OCLC-UCB-85037313a.c.xml
    less cpf/OCLC-UCB-85037313a.r01.xml
    less cpf/OCLC-UCB-85037313a.r02.xml


---

Manually modified. Is a "not1xx", although we now process not1xx. Also has one (or several?) fake az (perhaps
651 Maine Freeport.)  Does have a 600, therefore generates .r00, but the fake az values aren't used. Seems
pointless. (Maybe the fake $a$z were processed at some point. The tpt_geo code should be/is exercised
elsewhere.)

    <datafield tag="600" ind1="1" ind2="0">
        <subfield code="a">Cushing, E., Captain.</subfield>
    </datafield>

    <part>Cushing, E., Captain.</part>

    <datafield tag="651" ind1=" " ind2="0">
       <subfield code="a">Maine</subfield>
       <subfield code="z">Freeport.</subfield>
    </datafield>
    <datafield tag="651" ind1=" " ind2="0">
       <subfield code="a">Ohio</subfield>
       <subfield code="z">Dayton.</subfield>
       <subfield code="z">Main Street.</subfield>
    </datafield>
    <datafield tag="651" ind1=" " ind2="0">
       <subfield code="a">Freeport (Me.)</subfield>
       <subfield code="x">Commerce</subfield>
       <subfield code="z">Louisiana</subfield>
       <subfield code="z">New Orleans.</subfield>
    </datafield>

    -rw-r--r-- 1 twl8n snac 3033 Feb 20 16:00 qa/qa_128216482a_fake_az.xml
    less cpf/*128216482a.r00.xml

--- 

Has 100$e and 656. 

         <existDates>
            <date localType="http://socialarchive.iath.virginia.edu/control/term#Active"
                  standardDate="1976">active 1976</date>
         </existDates>
         <occupation localType="http://socialarchive.iath.virginia.edu/control/term#DerivedFromRole">
            <term>Compilers.</term>
         </occupation>
         <occupation>
            <term>Silversmiths.</term>
         </occupation>

    -rw-r--r-- 1 twl8n snac 3578 Mar 13 16:40 qa/qa_147444338_100e_different_occ_600_656a.xml
    less cpf/OCLC-DLH-147444338.c.xml

---

Has 110$e which should become a function.

                  <datafield tag="110" ind1="2" ind2=" ">
                     <subfield code="a">Allegany County (N.Y.).</subfield>
                     <subfield code="b">Historian's Office,</subfield>
                     <subfield code="e">collector.</subfield>
                  </datafield>

         <existDates>
            <dateRange>
               <fromDate localType="http://socialarchive.iath.virginia.edu/control/term#Active"
                         standardDate="1989">active 1989</fromDate>
               <toDate localType="http://socialarchive.iath.virginia.edu/control/term#Active"
                       standardDate="1994">active 1994</toDate>
            </dateRange>
         </existDates>
         <function localType="http://socialarchive.iath.virginia.edu/control/term#derivedFromRole">
            <term>Collectors.</term>
         </function>


    -rw-r--r-- 1 twl8n snac 3656 Jan 10 16:15 qa/qa_155416763_110_e_occupation.xml
    less cpf/OCLC-NYHVD-155416763.c.xml

---

100$4 "col" is becomes occupation.

                  <datafield tag="100" ind1="1" ind2=" ">
                     <subfield code="a">Herzog, George,</subfield>
                     <subfield code="d">1901-1983.</subfield>
                     <subfield code="4">col</subfield>
                     <subfield code="4">dpt</subfield>
                  </datafield>

         <existDates>
            <dateRange>
               <fromDate standardDate="1901"
                         localType="http://socialarchive.iath.virginia.edu/control/term#Birth">1901</fromDate>
               <toDate standardDate="1983"
                       localType="http://socialarchive.iath.virginia.edu/control/term#Death">1983</toDate>
            </dateRange>
         </existDates>
         <occupation localType="http://socialarchive.iath.virginia.edu/control/term#derivedFromRole">
            <term>Collectors.</term>
         </occupation>


    -rw-r--r-- 1 twl8n snac 4657 Jan 10 16:15 qa/qa_17851136_no_e_two_4_occupation.xml
    less cpf/OCLC-IJZ-17851136.c.xml

---

Manually modified. Dup 656 only outputs once, and only in the .c.xml file. Should be no occ in .r01.xml.

                  <datafield tag="656" ind1=" " ind2="7">
                     <subfield code="a">Academics.</subfield>
                     <subfield code="2">local</subfield>
                  </datafield>
                  <datafield tag="656" ind1=" " ind2="7">
                     <subfield code="a">Academics.</subfield>
                     <subfield code="2">local</subfield>
                  </datafield>

         <occupation>
            <term>Academics.</term>
         </occupation>

    -rw-r--r-- 1 twl8n snac 3766 Feb 20 16:27 qa/qa_225810091a_600_family_date_dupe_occupation.xml
    less cpf/*225810091a.c.xml
    less cpf/OCLC-AU064-225810091a.r01.xml

---

Another 100$e.

                  <datafield tag="100" ind1="1" ind2=" ">
                     <subfield code="a">Whipple, John Adams,</subfield>
                     <subfield code="d">1822-1891,</subfield>
                     <subfield code="e">photographer.</subfield>
                     <subfield code="4">att</subfield>
                  </datafield>

         <occupation localType="snac:derivedFromRole">
            <term>Photographers.</term>
         </occupation>

    -rw-r--r-- 1 twl8n snac 2909 Jan 10 16:15 qa/qa_51451353_e4_occupation.xml

    less cpf/OCLC-MAH-51451353.c.xml

---

Another 100$e. Multi $e, but only one is in our occupations file.

                  <datafield tag="100" ind1="1" ind2=" ">
                     <subfield code="a">Jacobs, Jo,</subfield>
                     <subfield code="d">1933-</subfield>
                     <subfield code="e">donor</subfield>
                     <subfield code="e">author.</subfield>
                  </datafield>

         <occupation localType="http://socialarchive.iath.virginia.edu/control/term#derivedFromRole">
            <term>Authors.</term>
         </occupation>

    -rw-r--r-- 1 twl8n snac 2529 Jan 10 16:15 qa/qa_768242927_multi_e_occupation.xml
    less cpf/OCLC-EXW-768242927.c.xml

---

Many 545 datafields for a long bioghist.

    -rw-r--r-- 1 twl8n snac 19777 Mar 14 16:25 qa/qa_123439230_multi_545_multi_b.xml
    less cpf/*123439230.c.xml
    less cpf/OCLC-COO-123439230.c.xml

---

After discussion, I think we're sure this is "active 1768 to 1792" and not "active 1768, died 1792".

    <datafield tag="100" ind1="1" ind2=" ">
       <subfield code="a">Meriwether, George,</subfield>
       <subfield code="d">fl. 1768-1792.</subfield>
    </datafield>

         <existDates>
            <dateRange>
               <fromDate standardDate="1768"
                         localType="http://socialarchive.iath.virginia.edu/control/term#Active">active 1768</fromDate>
               <toDate standardDate="1792"
                       localType="http://socialarchive.iath.virginia.edu/control/term#Active">active 1792</toDate>
            </dateRange>
         </existDates>

    -rw-r--r-- 1 twl8n snac 6482 Mar 19 16:40 qa/qa_14638716_fl_1768-1792_date_range.xml
    less cpf/OCLC-VCW-14638716.c.xml

---

Test "1980's" in alt date parsing. The "s" should be ignored, and not cause the script to crash. 

         <existDates>
            <dateRange>
               <fromDate localType="http://socialarchive.iath.virginia.edu/control/term#Active"
                         standardDate="1920"
                         notBefore="1917"
                         notAfter="1923">active approximately 1920</fromDate>
               <toDate localType="http://socialarchive.iath.virginia.edu/control/term#Active"
                       standardDate="1980">active 1980</toDate>
            </dateRange>
         </existDates>

    -rw-r--r-- 1 twl8n snac  4968 Mar 21 14:34 qa/qa_62173411_1980_quote_s_245f.xml
    saxon.sh qa/qa_62173411_1980_quote_s_245f.xml oclc_marc2cpf.xsl
    less cpf/OCLC-ALK-62173411.c.xml

---

Test that "18th cent.?" doesn't crash the script. The parser ignores ? when related to century values.

         <existDates>
            <date standardDate="1701" notBefore="1701" notAfter="1800">18th century</date>
         </existDates>

    saxon.sh qa/qa_85016803_cent_question_mark_date.xml oclc_marc2cpf.xsl
    less cpf/NNFr-85016803.c.xml


--- 

The 's is ignored, although it has to be removed internally to keep the script from crashing. fromDate and
toDate are both approx. This probably tests all necessary 2 date paths.

                  <datafield tag="245" ind1="1" ind2="0">
                     <subfield code="a">Fisheries and wildlife research in Alaska</subfield>
                     <subfield code="h">[graphic],</subfield>
                     <subfield code="f">ca. 1920's- ca. 1980's.</subfield>
                  </datafield>

         <existDates>
            <dateRange>
               <fromDate localType="http://socialarchive.iath.virginia.edu/control/term#Active"
                         standardDate="1920"
                         notBefore="1917"
                         notAfter="1923">active approximately 1920</fromDate>
               <toDate localType="http://socialarchive.iath.virginia.edu/control/term#Active"
                       standardDate="1980"
                       notBefore="1977"
                       notAfter="1983">active approximately 1980</toDate>
            </dateRange>
         </existDates>

    saxon.sh qa/qa_62173411b_todate_1980_quote_s_245f.xml oclc_marc2cpf.xsl
    less cpf/OCLC-ALK-62173411b.c.xml

---

The 's is ignored (as always for 245$f dates.) Only the fromDate is approx. Probably superceded by the b test above.

    saxon.sh qa/qa_62173411_1920_quote_s_245f.xml oclc_marc2cpf.xsl
    less cpf/OCLC-ALK-62173411.c.xml
    
---

Test the single date 245$f approximately execution path. The 's is ignored. Due to poor code
formatting/factoring (repeated sections not in functions or templates) separate tests are necessary.

                  <datafield tag="245" ind1="1" ind2="0">
                     <subfield code="a">Fisheries and wildlife research in Alaska</subfield>
                     <subfield code="h">[graphic],</subfield>
                     <subfield code="f">ca. 1920's.</subfield>
                  </datafield>

         <existDates>
            <date localType="http://socialarchive.iath.virginia.edu/control/term#Active"
                  standardDate="1920"
                  notBefore="1917"
                  notAfter="1923">active approximately 1920</date>
         </existDates>

    saxon.sh qa/qa_62173411c_single_1920_quote_s_245f.xml oclc_marc2cpf.xsl
    less cpf/OCLC-ALK-62173411c.c.xml

---

245$f future date with 5707 that we must ignore.

    saxon.sh qa/qa_54643931_245f_date_5707.xml oclc_marc2cpf.xsl
    less cpf/OCLC-YUS-54643931.c.xml

---

Test for "19th or 20th cent" which has caused problems. I think there's only one of these. Still...

    saxon.sh qa/qa_311261944_19th_or_20th_cent_date.xml oclc_marc2cpf.xsl
    less cpf/OCLC-UXG-311261944.c.xml

---

See the .r01. Discuss: fix trailing commas? from email "SNAC WorldCat extracts -- initial feedback" dec 21
  
We do not use the normative date as part of the name. Dates which are part of names are copied intact from the
original, thus the trailing comma with Edwin Abbey exists because it was part of the original 100$d and not
because we created a normative form for the name.

  <subfield code="d">1852-1911,</subfield>

We also do not currently remove period or comma from the end of names. (We might add period to the end of
names if it does not exist.) We could, but that leads to a larger discussion of formatting names for human
legibility vs formatting for machine actionable. I would consider a style sheet (CSS or XSLT) "machine
action".


    -rw-r--r-- 1 twl8n snac 2498 Apr  2 10:42 qa/qa_227009956_name_w_date_trailing_comma.xml
    saxon.sh qa/qa_227009956_name_w_date_trailing_comma.xml oclc_marc2cpf.xsl    
    less cpf/OCLC-SNN-227009956.r01.xml
    less cpf/OCLC-SNN-227009956.c.xml

---

Manually modified to remove second, reversed 651. Test 651 $a$x$z where $a and $z become separate places, not
concatenated places.

    -rw-r--r-- 1 twl8n snac  2670 Apr  8 09:20 qa/qa_123429932b_651_a_x_z_places_no_second_651.xml
    saxon.sh qa/qa_123429932b_651_a_x_z_places_no_second_651.xml oclc_marc2cpf.xsl
    less cpf/CSt-H-123429932b.c.xml


---

Test 651 $a$x$z where $a and $z become separate places, not concatenated places with the additional twist that
there is a second 651 with the same values in reversed order so the de-duping will result in only one each of
"United States" and "Soviet Union".

    -rw-r--r-- 1 twl8n snac  2853 Apr  8 09:04 qa/qa_123429932_651_a_x_z_places.xml
    saxon.sh qa/qa_123429932_651_a_x_z_places.xml oclc_marc2cpf.xsl
    less cpf/CSt-H-123429932.c.xml

--- 

Check correct concatenation of admin1Name, admin2Name, and name accounting for duplicate strings and empty
strings. Based on searching geonames manually with featureClass=P, I think it is simply "Ambridge" 5178228 and
not the "Borough of Ambridge" 5178236 which results from searching featureClass=A.

         <place localType="http://socialarchive.iath.virginia.edu/control/term#associatedPlace">
            <placeEntry latitude="40.59118" longitude="-80.22562"
                        vocabularySource="http://www.geonames.org/5178236"
                        countryCode="US">Pennsylvania--Beaver County--Borough of Ambridge</placeEntry>
         </place>

    saxon.sh qa/qa_609408959_ambridge_places.xml oclc_marc2cpf.xsl
    less cpf/OCLC-UPM-609408959.c.xml
    
    
---

The .r01 has a strange date "d. ca. 1534-1581." The parser does not handle this correctly, and fails to mark
this as suspicious. It is unclear what this date means. Nothing has been fixed.

    saxon.sh qa/qa_270613733_d_ca_1534-1581_odd_date.xml oclc_marc2cpf.xsl
    less cpf/US-SNAC-270613733.r01.xml






