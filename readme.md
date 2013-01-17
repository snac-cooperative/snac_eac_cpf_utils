

Table of contents
-----------------
* [Where is the code?](#where_is_the_code)
* [Overview](#overview)
* [Creating or obtaining the XML data files](#Creating_or_obtaining_the_XML_data_files)
* [What are the other files?](#What_are_the_other_files)
* [What is the easy way to run the code?](#What_is_the_easy_way_to_run_the_code)
* [How do I get a block of records from the MARC input?](#How_do_I_get_a_block_of_records_from_the_MARC_input)
* [How do I manually run the xsl?](#How_do_I_manually_run_the_xsl)
* [Example config file](#Example_config_file)
* [QA notes](#QA_notes)


<a id="where_is_the_code"/>
Where is the code?
------------------

Stable code is on GitHub at:

[https://github.com/twl8n/ead_cpf_utils]()

<a id="overview"/>
Overview
--------

Due to the length of the absolute path of the input file, I created symbolic link, and use that throughout the
code and configuration files.

    > ls -l snac.xml  
    lrwxrwxrwx 1 twl8n snac 30 Aug 20 13:31 snac.xml -> /data/source/WorldCat/snac.xml


    > ls -l exec_record.pl oclc_marc2cpf.xsl eac_cpf.xsl lib.xsl session_lib.pm extract_040a.xsl agency.cfg all_eac.cfg
    -rw-r--r-- 1 twl8n snac   1057 Jan 15 14:06 agency.cfg
    -rw-r--r-- 1 twl8n snac   1044 Jan  8 15:07 all_eac.cfg
    -rw-r--r-- 1 twl8n snac   7938 Jan 11 14:15 eac_cpf.xsl
    -rwxr-xr-x 1 twl8n snac   9386 Jan 10 15:37 exec_record.pl
    -rw-r--r-- 1 twl8n snac   2366 Jan 15 11:38 extract_040a.xsl
    -rw-r--r-- 1 twl8n snac 113162 Jan 11 16:55 lib.xsl
    -rw-r--r-- 1 twl8n snac  35629 Jan 11 14:09 oclc_marc2cpf.xsl
    -rw-r--r-- 1 twl8n snac  58583 Nov 28 12:32 session_lib.pm


    > ls -l *.rdf occupations.xml worldcat_code.xml 
    -rw-r--r-- 1 twl8n snac   54936 Nov  5 09:17 occupations.xml
    -rw-r--r-- 1 twl8n snac 2217050 Nov  6 11:03 vocabularylanguages.rdf
    -rw-r--r-- 1 twl8n snac  674261 Nov  5 09:53 vocabularyrelators.rdf
    -rw-r--r-- 1 twl8n snac  819145 Jan 15 14:14 worldcat_code.xml
           
Useful, but not required. File agency_test.txt has some select agency codes that exercise parts of the code,
or are known to have various issues such as not found, or multiple agencies for the same code.

    > ls -l test_eac.cfg agency_test.txt
    -rw-r--r-- 1 twl8n snac   32 Nov  8 14:47 agency_test.txt
    -rw-r--r-- 1 twl8n snac 1055 Jan  8 15:13 test_eac.cfg



An example command line is:

    ./exec_record.pl config=test_eac.cfg &

The Perl script exec_record.pl pulls records from the original WorldCat data and pipes those records to a
saxon command. Before output, the set of records is surrounded by a `<collection>` element in order to create valid
XML. The WorldCat data as it exists is not valid XML (no surrounding element), but the Perl code deals with
that. The script exec_record.pl uses a combination of regular expressions and state variables to find a 
`<record>` element regardless of intervening whitespace (or not).

An XSLT script, oclc_marc2cpf.xsl reads marc each record, extracting relevant information and putting it into
variables which are put into parameters for a final template that renders the EAD-CPF output. Each eac-cpf
output is sent to a separate file. Files are put into a single depth directory hierarchy via some chunking
code. The script oclc_marc2cpf.xsl includes a two files, eac_cpf.xsl and lib.xsl. The file eac_cpf.xsl is
which is mostly just an eac-cpf template. It is wrapped in a XSLT named template with parameters, and has only
the necessary XSL to fill in field values. All the programming logic is in oclc_marc2cpf.xsl and lib.xsl.

The Perl module session_lib.pm has supporting functions, expecially config file reading.

All the xsl is currently 2.0 due to use of several XSLT 2.0 features.

See the extensive comments in the source code files.

The second, older system uses get_record.pl in place of exec_record.pl. This system is works in batches and
lacks the automated chunking of exec_record.pl. This older system does not use a config file, so tracking
history is more of a challenge. Necessary configuration is handled via command line arguments.

    get_record.pl file=snac.xml offset=1 limit=1000 | saxon - oclc_marc2cpf.xsl chunk_size=100 offset=1 chunk_prefix=test output_dir=/uva-working/twl8n

    > ls -l get_record.pl oclc_marc2cpf.xsl eac_cpf.xsl lib.xsl 
    -rw-r--r-- 1 twl8n snac   7885 Jan  7 11:16 eac_cpf.xsl
    -rwxr-xr-x 1 twl8n snac   4970 Sep  4 09:25 get_record.pl
    -rw-r--r-- 1 twl8n snac 108638 Jan  7 16:12 lib.xsl
    -rw-r--r-- 1 twl8n snac  36795 Jan  8 15:05 oclc_marc2cpf.xsl

The Perl script get_record.pl pulls back one or more records from the original
WorldCat data and pipes those records to stdout. Before output, the set of
records is surrounded by a `<collection>...</collection>` in order to create valid XML. 

All the xsl is currently 2.0 due to use of several XSLT 2.0 features.

See the extensive comments in the source code files.



<a id="Creating_or_obtaining_the_XML_data_files"/>
Creating or obtaining the XML data files
----------------------------------------

You must make the Perl scripts executable, if that has not already been done. Running chmod a second time
won't hurt.

    chmod +x exec_record.pl get_record.pl worldcat_code.pl

First we need to create worldcat_code.xml by getting all the 040$a from the MARC records and run a script
that will look up those values up via the WorldCat web API.

Edit agency.cfg for your MARC input records, and run it to obtain agency_code.log which has all of the 040$a
values from your data.

    ./exec_record.pl config=agency.cfg &

Get the values from the log file and create a unique list. This exciting command with a Perl one-liner is
fairly standard practice in the Linux world.

    cat agency_code.log | perl -ne 'if ($_ =~ m/040\$a: (.*)/) { print "$1\n";} ' | sort -fu > agency_unique.txt

The script worldcat_code.pl reads agency_unique.txt and writes worldcat_code.xml. It also creates a
directory of cached results "./wc_data". Results from http requests to the WorldCat web API are cached as
files in ./wc_data and therefore if you repeat a run, it will be much, much faster the second time.

    ./worldcat_code.pl > tmp.log

The log file contains entries for codes that have multiple entries. Grep the log for 'multi mc:'.

The files agency_code.log and agency_unique.txt are essentially temporary, and you may delete them after
running worldcat_code.pl and verifying the results.

    > ls -l agency.cfg worldcat_code.* extract_040a.xsl
    -rw-r--r-- 1 twl8n snac   1057 Jan 15 14:06 agency.cfg
    -rw-r--r-- 1 twl8n snac   2366 Jan 15 11:38 extract_040a.xsl
    -rwxr-xr-x 1 twl8n snac  10427 Jan 15 11:42 worldcat_code.pl
    -rw-r--r-- 1 twl8n snac 819145 Jan 15 14:14 worldcat_code.xml


The file "occupations.xml" was created by Daniel Pitti from a spreadsheet supplied by the LoC. The XML was
subsequently modified by Tom Laudeman to add singular forms to simplify name matching.

[http://id.loc.gov/static/data/vocabularylanguages.rdfxml.zip]()

[http://id.loc.gov/static/data/vocabularyrelators.rdfxml.zip]()


    > ls -l *.rdf occupations.xml worldcat_code.xml 
    -rw-r--r-- 1 twl8n snac   54936 Nov  5 09:17 occupations.xml
    -rw-r--r-- 1 twl8n snac 2217050 Nov  6 11:03 vocabularylanguages.rdf
    -rw-r--r-- 1 twl8n snac  674261 Nov  5 09:53 vocabularyrelators.rdf
    -rw-r--r-- 1 twl8n snac  819145 Jan 15 14:14 worldcat_code.xml





<a id="What_are_the_other_files"/>
What are the other files?
-------------------------

The try_*.xsl files are examples from algorithm development. Some of them are
handy for QA, especially try_date_regex.xsl which relies on lib.xsl.




<a id="What_is_the_easy_way_to_run_the_code"/>
What is the easy way to run the code?
-------------------------------------

Copy the config file test_eac.cfg to a new config file (or not, as appropriate). Choose a small value for
config options "iterations", and "chunk". test_eac.cfg will process the first 5000 records, in other words 1000
* 5.

    chunk = 1000

    iterations = 5

    ./exec_record.pl config=test_eac.cfg &

Output EAD-CPF will be in the directory specified by config optios "output_dir", and "chunk_prefix" with
numeric suffixes. For example ./devx_1, ./devx_2 and so on. Messages from the scripts will be in "log_file",
which is tmp_test_er.log for test_eac.cfg. You can monitor the progress of the run with "tail" and the log file.

    watch tail tmp_test_er.log


The older, alternative method uses get_record.pl, and to run all the data requires several commands.

The command below starts with record 1. Get 1000 records. Start a new directory every 1000 records. Start counting with record 1
(since offset change for later chunks). Work goes in directories named "test_nnn" where _nnn is a numerical
suffix. Put the output directories in /uva-working/twl8n.

    get_record.pl file=snac.xml offset=1 limit=1000 | saxon - oclc_marc2cpf.xsl chunk_size=100 offset=1 chunk_prefix=test output_dir=/uva-working/twl8n

During debugging it may help to not use chunking. This command runs a single QA xml file and creates a single
.c output file.

    > saxon qa_155448889_date_leading_hyphen.xml oclc_marc2cpf.xsl use_chunks=0
    <?xml version="1.0" encoding="UTF-8"?>
    > ls -l OCLC*
    -rw-r--r-- 1 twl8n snac 5893 Oct  8 14:48 OCLC-155448889.c.xml

The command below starts with record 1001. Get 20000 records. Start a new directory every 1000 records. Start
counting with record 1 (since offset change for later chunks). Work goes in directories named "test_nnn" where
_nnn is a numerical suffix. Put the output directories in /uva-working/twl8n.

    get_record.pl file=snac.xml offset=1001 limit=2000 | saxon - oclc_marc2cpf.xsl chunk_size=1000 offset=1001 chunk_prefix=test output_dir=/uva-working/twl8n

Below is one form of a command used to run jing. Note the + in "find" instead of the very slow and traditional
"\;".

    find /uva-working/twl8n/test_* -name "*.xml" -exec java -jar /usr/share/jing/bin/jing.jar /projects/socialarchive/published/shared/cpf.rng {} + > test_validation.txt

    > ls -l snac.xml
    lrwxrwxrwx 1 twl8n snac 30 Aug 20 13:31 snac.xml -> /data/source/WorldCat/snac.xml

    > ls -l test_validation.txt
    -rw-r--r-- 1 twl8n snac 0 Sep 7 08:52 test_validation.txt



<a id="How_do_I_get_a_block_of_records_from_the_MARC_input"/>
How do I get a block of records from the MARC input?
----------------------------------------------------

Get_record.pl simply gets some marc records, and we redirect into a temporary xml file.

    ./get_record.pl file=snac.xml offset=1 limit=10 > tmp.xml

This is also handy to pulling out a single record into a separate file, often used for testing. Here we
retrieve the record 235.

    ./get_record.pl file=snac.xml offset=235 limit=1 > record_235.xml


<a id="How_do_I_manually_run_the_xsl"/>
How do I manually run the xsl?
------------------------------

    saxon tmp.xml oclc_marc2cpf.xsl > tmp_eac.xml



<a id="Example_config_file"/>
Example config file
-------------------

    # Use with exec_record.pl. Must have oclc_marc2cpf.xsl, (and included files
    # lib.xsl, and eac_cpf.xsl).

    ./exec_record.pl config=test_eac.cfg &

    # the file name of the xslt script to run
    xsl_script = oclc_marc2cpf.xsl
    
    # 1 or 0. When we're running oclc_marc2cpf.xsl, we need a bunch of args (params)
    # for the saxon command line.
    use_args = 1

    # input xml file. 
    file = snac.xml

    # Starting offset into $file. Usually 1.
    offset = 1

    # Size of chunk we send to the xslt processor. After this chunk size we close
    # the pipe to the xslt processor, and open a new pipe to the xslt processor for
    # the next chunk.
    chunk = 1000

    # Number of times we send a chunk of data to the xslt processor. Usually 'all'.
    iterations = 5

    # Where this script writes log output.
    log_file = tmp_test_er.log

    # Prefix of the xslt processor output directory name. 
    chunk_prefix = devx

    # Top level directory where xslt processor writes its output.
    output_dir = .

    # Number of records xslt processor handles before it creates a new output directory.
    xsl_chunk_size = 500




<a id="QA_Notes"/>
QA Notes
--------

Copy and paste the "less" command into a termainal and verify appropriate parts of the cpf output. This
section needs more notes. Some QA examples towards the end have notes. The file name sometimes gives a cryptic
reminder.

At least one of these is non-1xx and does not generate output. Some have nothing
special and are either historical or negative result QA tests.

find ./qa -maxdepth 1 -name "qa_*.xml" -exec saxon {} oclc_marc2cpf.xsl \;

---

The 700 should be the creatorOf in the cpfRelation, which happens to be the
second datafield so it is the .r01 since not1xx records .r numbering starts
with .r00.
<namePart>Sharps, Turney, Mrs.</namePart>
<roleTerm valueURI="http://id.loc.gov/vocabulary/relators/cre">Creator</roleTerm>

    -rw-r--r-- 1 twl8n snac  1994 Dec  3 15:56 qa_11422625_not1xx_has_600_has_700.xml
    less OCLC-11422625.r00.xml
    less OCLC-11422625.r01.xml

---

Not creatorOf, but should have 6 .r files for the 6xx datafields

    -rw-r--r-- 1 twl8n snac  4146 Dec  3 15:52 qa_702172281_not1xx_multi_600.xml
    less OCLC-702172281.r00.xml

---

The 700 should be the creatorOf in the .r01
<datafield tag="700" ind1="1" ind2=" ">
  <subfield code="a">Morrill, Dan L.</subfield>
</datafield>

<namePart>Morrill, Dan L.</namePart>
<role>
  <roleTerm valueURI="http://id.loc.gov/vocabulary/relators/cre">Creator</roleTerm>
</role>

    -rw-r--r-- 1 twl8n snac  3527 Dec  3 15:51 qa_26891471_not1xx_has_700.xml
    less OCLC-26891471.r01.xml
    less OCLC-26891471.r00.xml

---

Washburn (F|f)amily should only occur once

    -rw-r--r-- 1 twl8n snac  4808 Sep 25 11:14 qa_11447242_case_dup.xml
    less OCLC-11447242.c.xml

---

multiple topicalSubject, geographicSubject

    -rw-r--r-- 1 twl8n snac  5373 Nov 19 16:39 qa_122456647_651_multi_a.xml
    less OCLC-122456647.c.xml

---

Are we supposed to parse 245$f dates? We only process for families, and since this isn't a family, its 245$f
date is not processed.

    -rw-r--r-- 1 twl8n snac  2874 Oct 24 14:56 qa_122519914_corp_body_245_f_date.xml
    less OCLC-122519914.c.xml

    -rw-r--r-- 1 twl8n snac  5618 Nov 19 18:12 qa_122537190_sundown_escape_characters.xml
    less OCLC-122537190.c.xml

---

<date localType="questionable">1735-1???.</date>

    -rw-r--r-- 1 twl8n snac 20333 Nov 26 14:55 qa_122542862_date_nqqq.xml
    less OCLC-122542862.r76.xml
    less OCLC-122542862.c.xml

    -rw-r--r-- 1 twl8n snac  7534 Nov 14 13:13 qa_122583172_marc_c_two_oclc_orgs.xml
    less OCLC-122583172.c.xml

Is the record really like this, or did I change it to create a test? Regardless, these two 657 elements are
identical.

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
         
     -rw-r--r-- 1 twl8n snac 21212 Oct 26 13:31 qa_123408061_dupe_function_657.xml
     less OCLC-123408061.c.xml

---

245$f dates are parsed for families.

<subfield code="f">1917-1960.</subfield>

<fromDate standardDate="1917" localType="active">active 1917</fromDate>
<toDate standardDate="1960" localType="active">1960</toDate>

    -rw-r--r-- 1 twl8n snac  5041 Oct 18 09:54 qa_123410709_family_245f_date.xml
    less OCLC-123410709.c.xml

    -rw-r--r-- 1 twl8n snac  3239 Oct  3 11:29 qa_123415450_or_question.xml
    less OCLC-123415450.c.xml

---

d. 767 or 8.
<fromDate/>
<toDate standardDate="0767" localType="died" notBefore="0767" notAfter="0768">-0767 or 0768</toDate>
               
    -rw-r--r-- 1 twl8n snac  4013 Oct  3 11:40 qa_123415456_died_or.xml
    less OCLC-123415456.c.xml

---

1213?-1296?

    <fromDate standardDate="1213" localType="born" notBefore="1212" notAfter="1214">1213</fromDate>
    <toDate standardDate="1296" localType="died" notBefore="1295" notAfter="1297">1296</toDate>
               
    -rw-r--r-- 1 twl8n snac  4073 Oct  3 11:52 qa_123415574_qmark.xml
    less OCLC-123415574.c.xml

    -rw-r--r-- 1 twl8n snac  5153 Sep 25 15:30 qa_123439095_mods_leader.xml
    less OCLC-123439095.c.xml

---

Tests 1xx with multi 7xx which generate .rxx, and generate mods name entries.
Horwitz is duplicated in the input, but we only output it once.

    -rw-r--r-- 1 twl8n snac 3636 Jan 14 15:10 qa/qa_123452814_dup_700_name.xml
    less OCLC-123452814.r01.xml
    less OCLC-123452814.c.xml

---

not1xx as well as a fake az (perhaps 651 Maine Freeport.)
Does have a 600, therefore generates .r00

    <datafield tag="600" ind1="1" ind2="0">
        <subfield code="a">Cushing, E., Captain.</subfield>
    </datafield>

    <part>Cushing, E., Captain.</part>

    -rw-r--r-- 1 twl8n snac  2785 Nov 15 15:50 qa_128216482_fake_az.xml
    less OCLC-128216482.r00.xml

---

As of dec 7 2012 the code clearly only processes $e (and $4) for 100, not for 110.  Apparently, that means
that this record does not have an occupation.

    -rw-r--r-- 1 twl8n snac  3409 Nov  5 16:43 qa_155416763_110_e_occupation.xml
    less OCLC-155416763.c.xml

---

date 1865(approx.)-1944.

    -rw-r--r-- 1 twl8n snac  1561 Oct  3 12:13 qa_155438491_approx.xml
    less OCLC-155438491.c.xml

---

date -1688

    -rw-r--r-- 1 twl8n snac  1904 Oct  4 11:56 qa_155448889_date_leading_hyphen.xml
    less OCLC-155448889.c.xml

---

dpt isn't in any of our authority lists, but col is.

    <subfield code="4">col</subfield>
    <subfield code="4">dpt</subfield>
    <occupation>
        <term>Collectors.</term>
    </occupation>

     -rw-r--r-- 1 twl8n snac  4410 Nov  2 08:30 qa_17851136_no_e_two_4_occupation.xml
     less OCLC-17851136.c.xml

----    

<languageDeclaration><language languageCode="swe">Swedish</language>

    -rw-r--r-- 1 twl8n snac  1375 Nov 13 10:51 qa_209838303_lang_040b_swe.xml
    less OCLC-209838303.c.xml

----

This verifies that questionable dates display as questionable.

    <date localType="questionable">????-????</date>
    
    -rw-r--r-- 1 twl8n snac  2814 Nov 26 10:31 qa_210324503_date_all_question_marks.xml
    less OCLC-210324503.c.xml

    -rw-r--r-- 1 twl8n snac  3542 Nov 26 14:48 qa_220227335_date_nnnn_hyphen-zero.xml
    less OCLC-220227335.c.xml

---


Has a good date and a bad date <date localType="questionable">1?54-</date>
The name is a duplicate, except that the dates are not the same which causes the names to be treated at
unique.

    -rw-r--r-- 1 twl8n snac  4352 Nov 26 11:21 qa_220426543_date_1_q_54_hypen.xml
    less OCLC-220426543.r01.xml

---

Manually created based on 222612265 so we would have a died ca combination date.

    qa_x222612265_fake_died_ca_date.xml
    less OCLC-x222612265.c.xml

    -rw-r--r-- 1 twl8n snac  3076 Oct  3 14:34 qa_222612265_b_ca_date.xml
    less OCLC-222612265.c.xml

    -rw-r--r-- 1 twl8n snac  3518 Oct 26 13:22 qa_225810091_600_family_date_dupe_occupation.xml
    less OCLC-225810091.c.xml

---

The 651$v "Correspondence" doesn't match an occupation, but 656$a "Gold miners" is an occupation, albeit not
one that is looked up in an authority record.

    -rw-r--r-- 1 twl8n snac  3709 Sep 20 12:56 qa_225815320_651_v.xml
    less OCLC-225815320.c.xml

----

When taking into account topical subject concatenation, I'm not seeing a frank duplication. I'm not seeing
it for a geographical subject either. In any case, this example has many topical subjects and a geographical
subject.

    -rw-r--r-- 1 twl8n snac  5545 Oct 26 11:43 qa_225851373_dupe_places_with_dot_dupe_topical.xml
    less OCLC-225851373.c.xml

---

<subfield code="d">fl. 2nd cent.</subfield>
<date localType="active " notBefore="0101" notAfter="0200">active 2nd century</date>

    -rw-r--r-- 1 twl8n snac  2536 Oct 11 09:29 qa_233844794_fl_2nd_cent_date.xml
    less OCLC-233844794.c.xml

---

Multi 1xx has no output at this time.

    -rw-r--r-- 1 twl8n snac  3706 Sep 10 11:01 qa_270613908_multi_1xx.xml
    less OCLC-270613908.c.xml

---

<subfield code="d">d. 1601/2.</subfield>
<toDate standardDate="1601" localType="died" notBefore="1601" notAfter="1602">-1601 or 1602</toDate>

    -rw-r--r-- 1 twl8n snac  1508 Oct  4 15:49 qa_270617660_date_slash.xml
    less OCLC-270617660.c.xml

---

<subfield code="d">fl. 1724/25.</subfield>
<date standardDate="1724" localType="active" notBefore="1724" notAfter="1725">active 1724 or 1725</date>

    -rw-r--r-- 1 twl8n snac  1738 Oct  8 10:07 qa_270657317_fl_date_slash_n.xml
    less OCLC-270657317.c.xml

---

The questionable date is output in the .r01 file.

<subfield code="d">1834-1876 or later.</subfield>
<date localType="questionable">1834-1876 or later.</date>

    -rw-r--r-- 1 twl8n snac  2573 Nov 26 10:40 qa_270873349_date_or_later.xml
    less OCLC-270873349.r01.xml

---

<subfield code="d">19th/20th cent.</subfield>
<date notBefore="1801" notAfter="2000">19th/20th century</date>

    -rw-r--r-- 1 twl8n snac  2428 Oct  3 08:58 qa_281846814_19th_slash_20th.xml
    less OCLC-281846814.c.xml

---

<subfield code="d">1837-[1889?]</subfield>
<fromDate standardDate="1837" localType="born">1837</fromDate>
<toDate standardDate="1889" localType="died" notBefore="1888" notAfter="1890">1889</toDate>

    -rw-r--r-- 1 twl8n snac  4505 Oct  3 14:41 qa_313817562_sq_bracket_date.xml
    less OCLC-313817562.c.xml

---

<subfield code="d">194l-</subfield>
<date localType="questionable">194l-</date>

    -rw-r--r-- 1 twl8n snac  1829 Oct  3 14:51 qa_3427618_date_194ell.xml
    less OCLC-3427618.c.xml

---

I think this test exists to make sure subfields are concatenated in order, even if that order is a, c, a, d,
as opposed to a, a, c, d as errant XSLT did at one point.

<subfield code="a">Jones,</subfield>
<subfield code="c">Mrs.</subfield>
<subfield code="a">J.C.,</subfield>
<subfield code="d">1854-</subfield>

results in:

           <part>Jones, Mrs. J.C., 1854-</part>

    -rw-r--r-- 1 twl8n snac 2112 Jan 14 15:14 qa/qa_367559635_100_acad_concat.xml
    less OCLC-367559635.c.xml

---

Tests proper de-duping that ignores trailing punctuation.

<subfield code="a">Hachimonji, Kumezô.</subfield>
<subfield code="a">Hachimonji, Kumezô</subfield>

    -rw-r--r-- 1 twl8n snac  6104 Oct 26 14:09 qa_39793761_punctation_name.xml
    less OCLC-39793761.c.xml

---

One of two examples of a 100 family with no 100$d date, so it used the 245$f date as an "active" date.

                  <datafield tag="245" ind1="1" ind2="0">
                     <subfield code="a">Waterman family papers,</subfield>
                     <subfield code="f">1839-1906.</subfield>
                  </datafield>

               <fromDate standardDate="1839" localType="active">active 1839</fromDate>
               <toDate standardDate="1906" localType="active">1906</toDate>

    -rw-r--r-- 1 twl8n snac 3826 Dec 19 11:14 qa/qa_42714894_waterman_245f_date.xml
    less OCLC-42714894.c.xml

---

Has a lone comma in 700$a which broke the code at one point. I can't remember why I called it
"multi_sequence".

<datafield tag="700" ind1="1" ind2=" ">
  <subfield code="a">,</subfield>
  <subfield code="e">interviewer.</subfield>
</datafield>

    -rw-r--r-- 1 twl8n snac  3589 Nov 19 21:03 qa_44529109_multi_sequence.xml
    less OCLC-44529109.c.xml

---

Only in the .r01 file.
<date localType="questionable">date -</date>

    -rw-r--r-- 1 twl8n snac  2912 Nov 26 14:46 qa_495568547_date_hyphen_only.xml
    less OCLC-495568547.c.xml
    less OCLC-495568547.r01.xml

---

<date localType="questionable">b. 1870s.</date>

    -rw-r--r-- 1 twl8n snac  2615 Oct  9 10:24 qa_505818582_date_1870s.xml
    less OCLC-505818582.c.xml

---

                  <datafield tag="100" ind1="1" ind2=" ">
                     <subfield code="a">Whipple, John Adams,</subfield>
                     <subfield code="d">1822-1891,</subfield>
                     <subfield code="e">photographer.</subfield>
                     <subfield code="4">att</subfield>
                  </datafield>

         <occupation>
            <term>Photographers.</term>
         </occupation>

    -rw-r--r-- 1 twl8n snac  2662 Nov  2 08:25 qa_51451353_e4_occupation.xml
    less OCLC-51451353.c.xml

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
<term>CHILE--MINISTERIO DE TIERRAS Y COLONIZACION--DEPARTAMENTO JURIDICO Y DE INPECCION DE SERVICIOS</term>

    -rw-r--r-- 1 twl8n snac  2348 Nov 19 11:17 qa_55316797_650_multi_b.xml
    less OCLC-55316797.c.xml

---

This .r56 should be a questionable date. It broke the code by trying to turn a null string into a
number. Either it made 0000 which is questionable (wrong), or saxon died with an error.

<date localType="questionable">1714 or -15-1757.</date>

    -rw-r--r-- 1 twl8n snac 14958 Nov 26 10:35 qa_611138843_date_or_hyphen_15_hyphen_1757.xml
    less OCLC-611138843.c.xml
    less OCLC-611138843.r56.xml

---

<fromDate standardDate="1834" localType="born" notBefore="1834" notAfter="1835">1834- or 1835</fromDate>

    -rw-r--r-- 1 twl8n snac  3278 Oct  8 10:27 qa_671812214_b_dot_or.xml
    less OCLC-671812214.c.xml

---

is (and should be) questionable, make sure it doesn't crash the script

<date localType="questionable">16uu-17uu.</date>

    -rw-r--r-- 1 twl8n snac  3801 Oct  9 11:57 qa_678631801_date_16uu.xml
    less OCLC-678631801.c.xml

---

<date notBefore="0001" notAfter="0100">1st century</date>

    -rw-r--r-- 1 twl8n snac  3347 Nov 20 10:44 qa_702176575_date_1st_cent.xml
    less OCLC-702176575.c.xml

---

The 100$e doesn't hit any occupation, but I think at one point trying to resolve a string with a leading
comma caused it to process as a sequence and not as a string and that made saxon die with an error.

    -rw-r--r-- 1 twl8n snac  6825 Nov 20 14:05 qa_733102265_comma_interviewee.xml
    less OCLC-733102265.c.xml

---

"Donors" is not an occupation in our authority files. "Authors" is.

                  <datafield tag="100" ind1="1" ind2=" ">
                     <subfield code="a">Jacobs, Jo,</subfield>
                     <subfield code="d">1933-</subfield>
                     <subfield code="e">donor</subfield>
                     <subfield code="e">author.</subfield>
                  </datafield>

         <occupation>
            <term>Authors.</term>
         </occupation>

    -rw-r--r-- 1 twl8n snac  2282 Nov  2 08:52 qa_768242927_multi_e_occupation.xml
    less OCLC-768242927.c.xml

---

verify that .r08 future date is questionable, even if it is probably a typo.

<date localType="questionable">8030-1857.</date>

    -rw-r--r-- 1 twl8n snac  7190 Nov 26 10:45 qa_777390959_date_greater_than_2012.xml
    less OCLC-777390959.c.xml
    less OCLC-777390959.r08.xml


---

look for only one .r record for "Kane, Thomas Leiper,". He shows up in the MODS record as a (co)creator.

    -rw-r--r-- 1 twl8n snac  3197 Sep 18 09:15 qa_8560008_dup_600_700.xml
    less OCLC-8560008.c.xml

---

MODS abstract is all 520$a concatented with space.

    -rw-r--r-- 1 twl8n snac  4168 Nov 28 12:57 qa_8560380_multi_520a.xml
    less OCLC-8560380.c.xml

---

verify geo "Ohio--Ashtabula County" from concat 650 with multi $z

<datafield tag="650" ind1=" " ind2="0">
  <subfield code="a">Real property</subfield>
  <subfield code="z">Ohio</subfield>
  <subfield code="z">Ashtabula County.</subfield>
</datafield>

<placeEntry>Ohio--Ashtabula County</placeEntry>

    -rw-r--r-- 1 twl8n snac  5389 Sep 27 10:26 qa_8562615_multi_650_multi_z.xml
    less OCLC-8562615.c.xml

---

100 is the .c and dup in 600 should not make a .r file. Value is "Longfellow, Henry Wadsworth, 1807-1882."

    -rw-r--r-- 1 twl8n snac  2252 Sep 18 09:14 qa_8563535_dup_100_600.xml
    less OCLC-8563535.c.xml

---

noRegistryResults

<maintenanceAgency>
  <agencyName>BANC</agencyName>
    <descriptiveNote>
      <p>
        <span localType="noRegistryResults"/>
        <span localType="original">BANC</span>
      </p>
  </descriptiveNote>
</maintenanceAgency>

    -rw-r--r-- 1 twl8n snac  4192 Nov 15 12:44 qa_86132608_marc_040a_BANC_no_result.xml
    less OCLC-86132608.c.xml

