

Table of contents
-----------------
* [Overview of ead_cpf_utils](#overview-of-ead_cpf_utils)
* [What you might need to get started](#what-you-might-need-to-get-started)
* [Getting the code](#getting-the-code)
* [Getting languages and relators rdf xml](#getting-languages-and-relators-rdf-xml)
* [Review of files and applications](#review-of-files-and-applications)
* [Quickly run the code](#quickly-run-the-code)
* [Validate output with jing](#validate-output-with-jing)
* [MARC conversion .mrc to xml](#marc-conversion-mrc-to-xml)
* [WorldCat agency codes](#worldcat-agency-codes)
* [Building your own list of WorldCat agency codes](#building-your-own-list-of-worldcat-agency-codes)
* [Common error messages](#common-error-messages)
* [Overview for large input files](#overview-for-large-input-files)
* [Build WorldCat agency codes from a very large input file](#build-worldcat-agency-codes-from-a-very-large-input-file)
* [What are the other files?](#what-are-the-other-files)
* [More about large numbers of input records](#more-about-large-numbers-of-input-records)
* [Command line params of oclc_marc2cpf.xsl](#command-line-params-of-oclc_marc2cpfxsl)
* [How do I get a block of records from the MARC input?](#how-do-i-get-a-block-of-records-from-the-marc-input)
* [Example config file](#example-config-file)


Overview of ead_cpf_utils
-------------------------

This software is beta pre-release. It may contain bugs, and it likely to change before the first production version.

These are XSLT scripts that convert MARC21/slim XML into EAD-CPF (Corporations, Persons, and Families). Some sample data
is (or soon will be) included. There are also Perl scripts which are primarily used when the number of input
records to be processed will exceed the memory of the computer.

Throughout this document we use the generic user id "mst3k" as your user id. 

Copyright 2013 University of Virginia. Licensed under the Educational Community License, Version 2.0 (the
"License"); you may not use this file except in compliance with the License. You may obtain a copy of the
License at http://www.osedu.org/licenses/ECL-2.0 or see the file license.txt in this repository.

Unless required by applicable law or agreed to in writing, software distributed under the License is
distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
the License for the specific language governing permissions and limitations under the License.



What you might need to get started
----------------------------------

* All the files from the GitHub repository ead_cpf_utils. While you won't necessarily use every file from the
ead_cpf_utils repository, many of the files cross reference each other.

* Saxon 9he (XSLT 2.0 processor)

* Java (to run Saxon)

* The git command line utility. (Maybe)


You will have to run some commands in the terminal window. For Linux I like xterm, although any terminal or
console should be fine. Mac users should use Terminal: Applications -> Utilities -> Terminal.  If you are
using Microsoft Windows, it may be possible to use the command prompt or PowerShell, but I recommend that you
install and use cygwin.

http://www.cygwin.com/

You can retrieve the EAD-CPF code from github with a web browser, or via the command line utility "git". The command
line utility is faster and easier to use for updates.

Beginners may enjoy the introduction to Linux and MacOSX commands:

http://defindit.com/readme_files/intro_unix.html

The required input file format is MARC21/slim XML, so you may need MARC conversion tools. The open source
utility yaz will convert MARC .mrc to MARC21/slim XML.

http://people.oregonstate.edu/~reeset/marcedit/html/index.php

MARC Specialized Tools from The Library of Congress

http://www.loc.gov/marc/marctools.html


Getting the code
----------------

Stable code is on GitHub at:

https://github.com/twl8n/ead_cpf_utils

While we recommed that you use a git utility, you may also use the direct link to download a ZIP archive:

https://github.com/twl8n/ead_cpf_utils/archive/master.zip

You can download from a web browser as zip, or use the git command line. When using the web browser on the
repository page, look for a button with a cloud and arrow and "ZIP". The downloaded file is called
ead_cpf_utils-master.zip and when unzipped it creates a directory named "ead_cpf_utils-master". Note that the
directory name is different than if you used git from the command line.

    > unzip -l ~/Downloads/ead_cpf_utils-master.zip 
    Archive:  /Users/mst3k/Downloads/ead_cpf_utils-master.zip
    c07a9f3201b034e7e7b990879d69eaec9e0526e8
     Length     Date   Time    Name
    --------    ----   ----    ----
           0  01-17-13 13:04   ead_cpf_utils-master/
        1057  01-17-13 13:04   ead_cpf_utils-master/agency.cfg
          32  01-17-13 13:04   ead_cpf_utils-master/agency_test.txt
        1048  01-17-13 13:04   ead_cpf_utils-master/all_eac.cfg
        8647  01-17-13 13:04   ead_cpf_utils-master/eac_cpf.xsl
    ...

Using the git command:

    git clone https://github.com/twl8n/ead_cpf_utils.git

The git command automatically creates a directory "ead_cpf_utils" and downloads the most recent versions of
all files. Throughout this document I'll assume you used the git command, and that your files are in the
directory ead_cpf_utils.

To do an update later on:

    cd eac_cpf_utils
    git pull


Git for MacOS:

http://git-osx-installer.googlecode.com/files/git-1.8.1-intel-universal-snow-leopard.dmg

Saxon for Java:

http://downloads.sourceforge.net/project/saxon/Saxon-HE/9.4/SaxonHE9-4-0-6J.zip

Saxon's main page at Sourceforge:

http://sourceforge.net/projects/saxon/

The Saxon home page:

http://www.saxonica.com/

You will need Java. Most modern computers have it pre-installed. It is unclear if gcj or the openjdk will
work. The link below is probably the correct page to download Oracle (formerly Sun) Java:

http://www.java.com/en/download/index.jsp

You can try this command to see if you already have Java:

    > java -version
    java version "1.6.0_37"
    Java(TM) SE Runtime Environment (build 1.6.0_37-b06-434-10M3909)
    Java HotSpot(TM) 64-Bit Server VM (build 20.12-b01-434, mixed mode)


The included script saxon.sh expects Saxon to be in $HOME/bin/saxon9he.jar. For example on MacOS
/Users/mst3k/bin/saxon9he.jar or for Linux /home/mst3k/bin/saxon9he.jar. When you install saxons9he.jar,
please put it in ~/bin, otherwise you must edit saxon.sh to reflect the correct location.

After downloading Saxon, these will be typical commands:

    mkdir ~/bin
    cd ~/bin
    unzip ~/Downloads/SaxonHE9-4-0-6J.zip

After installing git, if the "git --version" command works, then you are ready.

    > git --version
    git version 1.8.1


If git --version did not work, then check that your $PATH environment variable has a path to git. Discovery
the path to git by using the shell commands 'which', or 'locate', or by examining the installer log. Look at
the values in $PATH to verify that the git path is a default (or not). The MacOS installer puts git in
/usr/local/git/bin. Linux users using a package or software manager (yum, apt, dpkg, KDE software center,
etc.) can skip this step since their git will be in a standard path. Here are some typical commands:

    which git
    locate git
    echo $PATH

    > which git
    /usr/bin/git

    > echo $PATH
    /usr/local/bin:/bin:/usr/bin:/home/mst3k/bin:/usr/local/sbin:/usr/sbin:/sbin:/usr/java/latest/bin:/home/mst3k/bin:.


The most common problem is simply that your default path doesn't include git's directory. You may wish to edit
your shell rc file (.bashrc) to add the path to git to PATH. Add this line to .bashrc (bash) or .zshrc
(zsh). This is bash/zsh format:

    export PATH=$PATH:/usr/local/git/bin

After editing your .bashrc (or .zshrc), close and re-open the terminal. You might have to logout and login
again. Or just try ". .bashrc" which is the same as "source .bashrc".

> cd ~/
> . .bashrc
> echo $PATH
.:/Users/mst3k/bin:.:/Users/mst3k/bin:.:/Users/mst3k/bin:.:/Users/mst3k/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/local/git/bin:/usr/X11/bin:/Users/mst3k/bin:.:/usr/local/git/bin:/usr/local/git/bin:/usr/local/ncbi:/usr/local/ncbi:/usr/local/git/bin:/usr/local/ncbi:/usr/local/git/bin:/usr/local/ncbi:/usr/local/git/bin


Getting languages and relators rdf xml
--------------------------------------


You will need two rdf xml files, which can be downloaded from loc.gov, and unzipped. Below I give the unzip
command, but feel free to unzip with your favorite utility, and copy the files into the ead_cpf_utils
directory.

http://id.loc.gov/static/data/vocabularylanguages.rdfxml.zip

http://id.loc.gov/static/data/vocabularyrelators.rdfxml.zip

    cd ~/ead_cpf_utils
    unzip ../Downloads/vocabularylanguages.rdfxml.zip
    unzip ../Downloads/vocabularyrelators.rdfxml.zip


Review of files and applications
--------------------------------

Assuming that you are in the ead_cpf_utils directory, you should be able to run 4 commands "git status", "ls
-l", "java -version", "saxon.sh -?" and get output similar to what follows:

    > git status
    # On branch master
    # Untracked files:
    #   (use "git add <file>..." to include in what will be committed)
    #
    #	vocabularylanguages.rdf
    #	vocabularyrelators.rdf
    nothing added to commit but untracked files present (use "git add" to track)

    > ls -l
    total 8128
    -rw-r--r--  1 mst3k  staff     1057 Jan 17 15:08 agency.cfg
    -rw-r--r--  1 mst3k  staff       32 Jan 17 15:08 agency_test.txt
    -rw-r--r--  1 mst3k  staff     1048 Jan 17 15:08 all_eac.cfg
    -rw-r--r--  1 mst3k  staff     8488 Feb  1 14:56 eac_cpf.xsl
    -rwxr-xr-x  1 mst3k  staff    10589 Feb  1 14:56 exec_record.pl
    -rw-r--r--  1 mst3k  staff     3130 Jan 18 16:44 extract_040a.xsl
    -rwxr-xr-x  1 mst3k  staff     5948 Feb  1 14:56 get_record.pl
    -rw-r--r--  1 mst3k  staff   115931 Feb  1 14:53 lib.xsl
    -rw-r--r--  1 mst3k  staff    10938 Jan 17 15:08 license.txt
    -rw-r--r--  1 mst3k  staff    99272 Jan 17 15:08 occupations.xml
    -rw-r--r--  1 mst3k  staff    37119 Feb  1 14:53 oclc_marc2cpf.xsl
    -rw-r--r--  1 mst3k  staff    36887 Feb  1 14:56 readme.md
    -rwxr-xr-x  1 mst3k  staff      101 Jan 18 10:51 saxon.sh
    -rw-r--r--  1 mst3k  staff    60660 Feb  1 14:56 session_lib.pm
    -rw-r--r--  1 mst3k  staff     1055 Feb  1 14:54 test_eac.cfg
    -rw-r--r--@ 1 mst3k  staff  2216850 Jan 17 15:15 vocabularylanguages.rdf
    -rw-r--r--@ 1 mst3k  staff   674261 Jan 17 15:15 vocabularyrelators.rdf
    -rwxr-xr-x  1 mst3k  staff    10983 Feb  1 14:53 worldcat_code.pl
    -rw-r--r--  1 mst3k  staff   819145 Feb  1 14:55 worldcat_code.xml

    > java -version
    java version "1.6.0_37"
    Java(TM) SE Runtime Environment (build 1.6.0_37-b06-434-10M3909)
    Java HotSpot(TM) 64-Bit Server VM (build 20.12-b01-434, mixed mode)

    > cp saxon.sh.dist saxon.sh
    > saxon.sh -?
    Saxon-HE 9.4.0.6J from Saxonica
    Usage: see http://www.saxonica.com/documentation/using-xsl/commandline.xml
    Format: net.sf.saxon.Transform options params
    Options available: -? -a -catalog -config -cr -dtd -expand -explain -ext -im -init -it -l -m -now -o -opt -or -outval -p -r -repeat -s -sa -strip -t -T -threads -TJ -TP -traceout -tree -u -val -versionmsg -warnings -x -xi -xmlversion -xsd -xsdversion -xsiloc -xsl -xsltversion -y
    Use -XYZ:? for details of option XYZ
    Params: 
    param=value           Set stylesheet string parameter
    +param=filename       Set stylesheet document parameter
    ?param=expression     Set stylesheet parameter using XPath
    !param=value          Set serialization parameter


Quickly run the code
--------------------

Many thanks to Mark Custer for publicly sharing a few sample records under the Educational Community
License. These records are in the file beinecke_sample.xml that we use in the working example below.

If you have not copied the .dist files to local copies, do so now:

   cp saxon.sh.dist saxon.sh
   cp worldcat_code.xml.small worldcat_code.xml

Just about the simplest method, relies on some internal defaults, but overrides the output directory name:

    saxon.sh beinecke_sample.xml oclc_marc2cpf.xsl output_dir=brbl

Here is a session transcript showing that 546 files were generated, listing the first few files in the ./brbl
directory, and showing the first few lines of brbl/CtY-BR-3118211.c.xml:

    > saxon.sh beinecke_sample.xml oclc_marc2cpf.xsl output_dir=brbl 
    <?xml version="1.0" encoding="UTF-8"?>

    > ls -l brbl/* | wc -l
    545

    > ls -l brbl/* | head
    -rw-r--r-- 1 twl8n snac  16452 Feb 27 16:09 brbl/CtY-BR-3118211.c.xml
    -rw-r--r-- 1 twl8n snac  13728 Feb 27 16:09 brbl/CtY-BR-3118211.r01.xml
    -rw-r--r-- 1 twl8n snac  13434 Feb 27 16:09 brbl/CtY-BR-3118211.r02.xml
    -rw-r--r-- 1 twl8n snac  13472 Feb 27 16:09 brbl/CtY-BR-3118211.r03.xml
    -rw-r--r-- 1 twl8n snac  13367 Feb 27 16:10 brbl/CtY-BR-3150242.c.xml
    -rw-r--r-- 1 twl8n snac  12166 Feb 27 16:10 brbl/CtY-BR-3150242.r01.xml
    -rw-r--r-- 1 twl8n snac  12170 Feb 27 16:10 brbl/CtY-BR-3150242.r02.xml
    -rw-r--r-- 1 twl8n snac  11943 Feb 27 16:09 brbl/CtY-BR-3248834.c.xml
    -rw-r--r-- 1 twl8n snac  31460 Feb 27 16:10 brbl/CtY-BR-3251340.c.xml
    -rw-r--r-- 1 twl8n snac  20373 Feb 27 16:10 brbl/CtY-BR-3251340.r01.xml

    > head brbl/CtY-BR-3118211.c.xml
    <?xml version="1.0" encoding="UTF-8"?>
    <?oxygen RNGSchema="http://socialarchive.iath.virginia.edu/shared/cpf.rng" type="xml"?>
    <eac-cpf xmlns:mads="http://www.loc.gov/mads/" xmlns="urn:isbn:1-931666-33-4"
             xmlns:xs="http://www.w3.org/2001/XMLSchema"
             xmlns:eac="urn:isbn:1-931666-33-4">
       <control>
          <recordId>CtY-BR-3118211.c</recordId>
          <maintenanceStatus>new</maintenanceStatus>
          <maintenanceAgency>
             <agencyCode>CtY-BR</agencyCode>

    > java -jar ~/bin/jing.jar ~/bin/cpf.rng brbl/*

    >


Note above that the jing command produced no output. That is good and means the CPF XML output validates. Jing
is discussed later.

Below is an prototype command line where you have more than 100 records (lets say 1000 records), and wish to
have the output in separate directories aka "chunking". Override the default output directory, and write
chunks of records to "test_N" where N is a counting number, and log results test.log:

    saxon.sh big_marc_file.xml oclc_marc2cpf.xsl chunk_prefix=test > test.log 2>&1

There is not a 1000 record sample file included in the Github repository. However, I ran 1000 records of data
so you can see more or less what to expect. After the command above, a couple of commands give an overview of
what the log file and directories look like:

    > head test.log
    not_167xx: 8560473

    not_167xx: 8561559

    not_167xx: 8564868

    not_167xx: 8571931

    not_167xx: 8582413

    > ls -ld test_*
    drwxr-xr-x  199 twl8n  staff   6766 Feb  4 09:54 test_1
    drwxr-xr-x  285 twl8n  staff   9690 Feb  4 09:55 test_10
    drwxr-xr-x    8 twl8n  staff    272 Feb  4 09:55 test_11
    drwxr-xr-x  203 twl8n  staff   6902 Feb  4 09:54 test_2
    drwxr-xr-x  206 twl8n  staff   7004 Feb  4 09:54 test_3
    drwxr-xr-x  174 twl8n  staff   5916 Feb  4 09:55 test_4
    drwxr-xr-x  165 twl8n  staff   5610 Feb  4 09:55 test_5
    drwxr-xr-x  336 twl8n  staff  11424 Feb  4 09:55 test_6
    drwxr-xr-x  418 twl8n  staff  14212 Feb  4 09:55 test_7
    drwxr-xr-x  280 twl8n  staff   9520 Feb  4 09:55 test_8
    drwxr-xr-x  320 twl8n  staff  10880 Feb  4 09:55 test_9
    -rw-r--r--    1 twl8n  staff   1055 Feb  1 14:54 test_eac.cfg



Validate output with jing
-------------------------

You need two things: jing.jar (aka jing) and cpf.rng. There are several applications in the world named
"jing". You want the application from Thai Open Source. Download jing and put it in your personal ~/bin
directory, or if you have admin (root) privileges, you can install it somewhere like /usr/share.

http://www.thaiopensource.com/relaxng/jing.html

http://code.google.com/p/jing-trang/downloads/list


You can find the EAD-CPF schema file cpf.rng (with modifications formally submitted to TS-EAC) on the web at:

http://socialarchive.iath.virginia.edu/shared/cpf.rng


Validate a single file:

    java -jar /usr/share/jing/bin/jing.jar /projects/socialarchive/published/shared/cpf.rng OCLC-8560380.c.xml 

If you had installed both jing.jar and cpf.rng in your ~/bin (for example /home/mst3k/bin) directory:

    java -jar ~/bin/jing.jar ~/bin/cpf.rng SNAC-8560380.c.xml 

When there is an error, jing will report the line number which is 10 in the example below. In fact, agencyCode
may not be empty.

    > java -jar ~/bin/jing.jar ~/bin/cpf.rng SNAC-8560380.c.xml
    /lv1/home/twl8n/eac_project/SNAC-8560380.c.xml:10:23: error: bad character content for element

    > less -N SNAC-8560380.c.xml 
    
          1 <?xml version="1.0" encoding="UTF-8"?>
          2 <?oxygen RNGSchema="http://socialarchive.iath.virginia.edu/shared/cpf.rng" type="xml"?>
          3 <eac-cpf xmlns:mads="http://www.loc.gov/mads/" xmlns="urn:isbn:1-931666-33-4"
          4          xmlns:xs="http://www.w3.org/2001/XMLSchema"
          5          xmlns:eac="urn:isbn:1-931666-33-4">
          6    <control>
          7       <recordId>SNAC-8560380.c</recordId>
          8       <maintenanceStatus>new</maintenanceStatus>
          9       <maintenanceAgency>
         10          <agencyCode/>
         11          <agencyName/>


Below is another form of a command used to run jing where a large number of files in a group of directories
are being checked. Note the + in "find" instead of the very slow and traditional "\;". The find with older
versions MacOS OSX may not support +.

    > ls -ld devx_* 
    drwxr-xr-x 2 twl8n snac 40960 Feb 15 14:54 devx_1
    drwxr-xr-x 2 twl8n snac 36864 Feb 15 14:55 devx_10
    drwxr-xr-x 2 twl8n snac 69632 Feb 15 14:54 devx_2
    drwxr-xr-x 2 twl8n snac 69632 Feb 15 14:54 devx_3
    drwxr-xr-x 2 twl8n snac 53248 Feb 15 14:54 devx_4
    drwxr-xr-x 2 twl8n snac 28672 Feb 15 14:55 devx_5
    drwxr-xr-x 2 twl8n snac 36864 Feb 15 14:55 devx_6
    drwxr-xr-x 2 twl8n snac 36864 Feb 15 14:55 devx_7
    drwxr-xr-x 2 twl8n snac 36864 Feb 15 14:55 devx_8
    drwxr-xr-x 2 twl8n snac 20480 Feb 15 14:55 devx_9

    find /home/mst3k/devx_* -name "*.xml" -exec java -jar /home/mst3k/bin/jing.jar /home/mst3k/bin/cpf.rng {} + > test_validation.txt


If there are no messages from jing, then your EAD-CPF XML is valid. Note the file size below is zero.

    > ls -l test_validation.txt
    -rw-r--r-- 1 mst3k snac 0 Feb 15 14:56 test_validation.txt

You can discover the version of Jing by a command similar to the following, assuming that your jing.jar file
is in /usr/share/jing/bin. (Modify the command as necessary for your jing.jar path):

    java -jar /usr/share/jing/bin/jing.jar


MARC conversion .mrc to xml
---------------------------

The yaz package contains a utility yaz-marcdump that easily converts from MARC .mrc to MARC21/slim XML. If you are running Fedora Linux or a similar Redhat distribution that uses yum, the command below should work to install yaz:

    sudo yum -y install yaz

The utility application yaz-marcdump several options. The minimum options seem to be -f and -o. Use "-f marc8"
to specifiy the from format. I had success with "marc8" and the documentation (man page) suggests that
"MARC-8" also works. The -o option is output format and we want "marcxml". The third argument is the input
file name. The usual Linux redirection takes care of the output file. In the first command below, output is
piped to "less" for viewing on the fly. In the second command, output is redirected to a file.

yaz-marcdump -f marc8 -o marcxml UF-CC0-2013-02.mrc| less

yaz-marcdump -f marc8 -o marcxml UF-CC0-2013-02.mrc > UF-CC0-2013-02.xml



WorldCat agency codes
---------------------

The MARC-to-CPF XSLT scripts look up agency codes and agency names in a local file, "worldcat_code.xml". A fairly large
example is provided.

Many of you will wish to create a modified or smaller worldcat_code.xml file containing your local agency
codes. There are two quick ways to do this:

1. Put your agency codes in a text file, one per line, and let the Perl script worldcat_code.pl do all the
work. See the [Quickstart](#quickstart-to-run-worldcat_codepl) below.

2. Manually create a worldcat_code.xml based on the supplied example. See the [Hand create](#hand-create-worldcat_codexml-in-an-xml-or-text-editor) below.

The third, less quick way: [Building your own list of WorldCat agency codes](#building-your-own-list-of-worldcat-agency-codes)

Quickstart to run worldcat_code.pl
----------------------------------

Even if you only have one or two agency codes, it might be easy to run the Perl script. To use
worldcat_code.pl, put OCLC or MARC agency codes into a text file, one code per line, then run worldcat_code.pl file=your_file_name

Feel free to add your agency codes to the included example agency_test.txt then run these commands:

    chmod +x worldcat_code.pl
    ./worldcat_code.pl file=agency_test.txt
    
You now have a new worldcat_code.xml file. Some status messages will print while the script is running.

    Using cache dir wc_data
    Ouput file is worldcat_code.xml
    Using cache for rid: 39003 safe_data: wc_data/3339303033.xml
    Using cache for rid: 5087 safe_data: wc_data/35303837.xml
    Sending requst for rid: 87830
    Sending requst for rid: 16387
    multi mc: A-Ar
    ...

Additionally, you can manually edit the resulting worldcat_code.xml. The script only searches for MARC and
OCLC codes from the WorldCat registry, and many organizations could be missing. If you know the relevant
information, simply edit the appropriate record in worldcat_code.xml.

For example, Cty-BR is not in WorldCat's registry, so the record is mostly empty:

      <container>
        <orig_query>CtY-BR</orig_query>
        <marc_code/>
        <name/>
        <isil/>
        <matching_element/>
      </container>

Manually updated to:

      <container>
        <orig_query>CtY-BR</orig_query>
        <marc_code>CtY-BR</marc_code>
        <name>Yale University, Beinecke Rare Book and Manuscript Library</name>
        <isil>CtY-BR</isil>
        <matching_element/>
      </container>

In the future, the ISIL may be updated to for better standards conformance. 


Hand create worldcat_code.xml in an XML or text editor
------------------------------------------------------

To create worldcat_code.xml by hand there are three steps: (1) manually search, (2) copy info, (3) paste into an XML text file.

1. For the manual, one-at-a-time code lookup, I suggest using the somewhat daunting, but more accurate web
service search page. Search for a specific field's value. For example local.marcOrgCode "Viu". (Leave the
defaults of "=" and "and". The search appears to be case-insensitive.) Is is possible to have multiple
results. The search for "Viu" correctly returns the University of Virginia. If you search "RHi" you'll get two
results, both of which have the marcOrgCode "RHi".

http://worldcat.org/webservices/registry/search/

2. Manually look up the codes from the WorldCat registry search web page. If there is only on result, click
the link "Download this Profile as XML". If there are multiple results, click the institution name, then click
"Download this Profile as XML". With a little luck, the XML opens in your web browser, and you can copy various values.

3. Copy and paste various pieces of data into worldcat_code.xml. There's no schema, but the data format should be fairly easy
to understand.


You can get a more general result by searching the field srw.serverChoice (near the bottom of the web page).

Below is a single record worldcat_code.xml example from searching for the MARC code "Viu". 

* The outer continer element is "all". It must have at least one "container" child, and may have many
  "container" elements.

* Each institution is in a "container" element. An institution may have multiple "container" entries differentiated by the
  orig_query. Only the first entry will be used.

* Element "orig_query" is the original search whether marc or otherwise.

* Elements marc_code, name, isil, and oclcSymbol all come out of the WorldCat record.

* Element matching_element is a copy of what element was matched in the WorldCat record.

<?xml version="1.0" encoding="UTF-8"?>
<all xmlns="http://socialarchive.iath.virginia.edu/worldcat">
  <container>
    <orig_query>ViU</orig_query>
    <marc_code>ViU</marc_code>
    <name>University of Virginia</name>
    <isil>OCLC-VA@</isil>
    <oclcSymbol>VA@</oclcSymbol>
    <matching_element><marcOrgCode>ViU</marcOrgCode></matching_element>
  </container>
</all>


WorldCat also has a more genearl search. It is quite broad and will match against any fields, thus a search
for "Viu" will return several institutions, some of which are "bad" in the sense that the "viu" string matched
in URLs or elements besides the marcOrgCode or oclcSymbol.

http://www.worldcat.org/registry/Institutions



Building your own list of WorldCat agency codes
-----------------------------------------------

This section applies to larger data sets. Please skip this section if it does not apply to you.

We use the WorldCat registry web API:

http://oclc.org/developer/services/worldcat-registry

(An API or Application Programmer Interface is a collection of functions or services available for use outside
an application or web site. It is programmer lingo for building blocks of software tools.)

The file worldcat_code.xml is used by the XLST to resolve agency codes without going out to the internet each
time. Essentially, this process of building your own list is a way to cache the agency code data.

Included in the repository is worldcat_code.xml which is a data file of the unique WorldCat agency codes found
in our largest corpus of MARC21/slim XML records. Your agency codes may vary. You can prepare your own
worldcat_code.xml. The process begins by getting all the 040$a from the MARC21/slim XML records. Next we look up those
values up via the WorldCat web API. Finally, the unique values are written into worldcat_code.xml.

If worldcat_code.pl is not executable, make it so with chmod. 

    chmod +x worldcat_code.pl


First, backup the original worldcat_code.xml.

    cp worldcat_code.xml worldcat_code.xml.back

If your MARC21/slim XML data is in marc_sample.xml, run the following command which will extract all the agency codes
into agency_code.log:

    saxon.sh marc_sample.xml extract_040a.xsl > agency_code.log 2>&1

Check that things worked more or less as expected with the "head" command:

    > head agency_code.log 

    040$a: YWM
    040$a: YWM
    040$a: WAT
    040$a: WAT
    040$a: RHI
    040$a: OHI
    040$a: PRE
    040$a: PRE
    040$a: PRE


Next you get the values from the log file and create a unique list. The exciting command below using a Perl one-liner
is fairly standard practice in the Linux world.

    cat agency_code.log | perl -ne 'if ($_ =~ m/040\$a: (.*)/) { print "$1\n";} ' | sort -fu > agency_unique.txt

The final step involves looking up the codes from WorldCat's servers. The script "worldcat_code.pl" must have
a command line argument file=agency_unique.txt where "agency_unique.txt" is a file with one agency code per
line. The script worldcat_code.pl reads the data file and writes a new file "worldcat_code.xml". It also
creates a directory of cached results "./wc_data". What worldcat_code.pl does is to make an http request to
the WorldCat servers via a web API. Results from http requests to the WorldCat web API are cached as files in
./wc_data and therefore if you repeat a run, it will be much, much faster the second time. The first run can
be quite slow, partly because the script pauses briefly after each request so it does not overload the
WorldCat servers.

    ./worldcat_code.pl file=agency_unique.txt > tmp.log

 After the run, you'll have tmp.log, a new directory wc_data, and the results in worldcat_code.xml.

    > ls -alt | head
    total 18816
    drwxr-xr-x+  92 mst3k  staff     3128 Feb  1 15:48 ..
    drwxr-xr-x  375 mst3k  staff    12750 Feb  1 15:48 wc_data
    -rw-r--r--    1 mst3k  staff    35526 Feb  1 15:48 worldcat_code.xml
    -rw-r--r--    1 mst3k  staff      213 Feb  1 15:48 tmp.log

The results are in worldcat_code.xml, and here is the top few lines (via the "head" command):

    > head worldcat_code.xml
    <?xml version="1.0" encoding="UTF-8"?>
    <all xmlns="http://www.loc.gov/MARC21/slim">
      <container>
        <marc_query>AHJ</marc_query>
        <marc_code>WyU-AH</marc_code>
        <name>University of Wyoming, American Heritage Center</name>
        <isil>OCLC-AHJ</isil>
        <matching_element><oclcSymbol>AHJ</oclcSymbol></matching_element>
      </container>
      <container>


The file tmp.log contains entries for codes that have multiple entries. 

    > head tmp.log
    Using cache dir wc_data
    Ouput file is worldcat_code.xml
    multi mc: COC
    multi mc: CSt-H
    multi mc: CtY
    multi mc: CU
    multi mc: DGW
    multi mc: DLC
    multi mc: GEU-S
    multi mc: OHI

You can get a count of the number of codes with multiple codes via "grep" and "wc":

    > grep "multi mc:" tmp.log | wc -l
          11

Now you should have a valid worldcat_code.xml, ready for use in generating EAD-CPF.


Common error messages
---------------------

Error:

    Can't locate DBI.pm in @INC (@INC contains: ...


Solition: 

You are missing a Perl module. Install the module via your package manager or see the
soon-to-be-created docs on this topic.


Error:

    > ./worldcat_code.pl file=agency_test.txt > tmp.log
    bash: ./worldcat_code.pl: Permission denied

Solution: 

The script worldcat_code.pl is not executable. Verify with "ls -l" and fix with "chmod +x". Notice
that there are no "x" permissions, only "rw" and "r". Verify the fix with a second "ls -l" where we see "x"
permissions.

    > ls -l worldcat_code.pl 
    -rw-r--r--  1 mst3k  staff  10997 Feb  1 15:45 worldcat_code.pl

    > chmod +x worldcat_code.pl 
    > ls -l worldcat_code.pl 
    -rwxr-xr-x  1 mst3k  staff  10997 Feb  1 15:45 worldcat_code.pl


Overview for large input files
------------------------------

This section applies to larger data sets. Please skip this section if it does not apply to you.

If you have a large number of input MARC21/slim XML records, probably more than 100,000, then your computer may run out
of memory during the xsl transformation when Saxon is running oclc_marc2cpf.xsl. In this case, you can use
exec_record.pl to "chunk" the data into smaller runs avoiding the memory problems. The use of chunking applies
to both generating CPF records, and to generating your list of agency codes.

See the section detailing oclc_marc2cpf.xsl which briefly describes and internal chunking ability of
oclc_marc2cpf.xsl. This internal chunking is useful if you wish to generate output in multiple directories
each with a smaller number of files, as oppose to all the output files in a single, large, unwieldy
directory. The script exec_record.pl also automatically handles chunking output into multiple directories.

The script get_record.pl is also useful for chunking, but operates only on one subset of input records.

Configuration of exec_record.pl is controlled via simple configuration files. Each config file serves a single
purpose. Saving a copy of a given config file with the output provides a historical record of how the output
was generated.

Here is a list of the scripts and config files:

    > ls -l exec_record.pl oclc_marc2cpf.xsl eac_cpf.xsl lib.xsl session_lib.pm extract_040a.xsl agency.cfg all_eac.cfg
    -rw-r--r-- 1 mst3k snac   1057 Jan 15 14:06 agency.cfg
    -rw-r--r-- 1 mst3k snac   1044 Jan  8 15:07 all_eac.cfg
    -rw-r--r-- 1 mst3k snac   7938 Jan 11 14:15 eac_cpf.xsl
    -rwxr-xr-x 1 mst3k snac   9386 Jan 10 15:37 exec_record.pl
    -rw-r--r-- 1 mst3k snac   2366 Jan 15 11:38 extract_040a.xsl
    -rw-r--r-- 1 mst3k snac 113162 Jan 11 16:55 lib.xsl
    -rw-r--r-- 1 mst3k snac  35629 Jan 11 14:09 oclc_marc2cpf.xsl
    -rw-r--r-- 1 mst3k snac  58583 Nov 28 12:32 session_lib.pm

These are necessary data files:

    > ls -l *.rdf occupations.xml worldcat_code.xml 
    -rw-r--r-- 1 mst3k snac   54936 Nov  5 09:17 occupations.xml
    -rw-r--r-- 1 mst3k snac 2217050 Nov  6 11:03 vocabularylanguages.rdf
    -rw-r--r-- 1 mst3k snac  674261 Nov  5 09:53 vocabularyrelators.rdf
    -rw-r--r-- 1 mst3k snac  819145 Jan 15 14:14 worldcat_code.xml
           
Thes are useful, but not required config files. File agency_test.txt has some select agency codes that
exercise parts of the code, or are known to have various issues such as not found, or multiple agencies for
the same code.

    > ls -l test_eac.cfg agency_test.txt
    -rw-r--r-- 1 mst3k snac   32 Nov  8 14:47 agency_test.txt
    -rw-r--r-- 1 mst3k snac 1055 Jan  8 15:13 test_eac.cfg


If your input data is in the same format as we used (MARC21/slim XML records without a container element), and the input
file name is snac.xml, then this example command line is will read 5000 records in 1000 recor chunks, writing
the output into directories with the prefix "devx_":

    ./exec_record.pl config=test_eac.cfg &

The Perl script exec_record.pl pulls records from the original WorldCat data and pipes those records to a
Saxon command. Before sending the MARC/21 SLIM XML records to Saxon, the record set is surrounded by a `<collection>` element
in order to create valid XML. The WorldCat data as it we have it is not valid XML (no surrounding element), but
the Perl code deals with that. The script exec_record.pl uses a combination of regular expressions and state
variables to find a `<record>` element regardless of intervening whitespace (or not).

The XSLT script, oclc_marc2cpf.xsl reads each record, extracting relevant information and putting it into
variables which are put into parameters for a final template that renders the EAD-CPF output. Each eac-cpf
output is sent to a separate file. Files are put into a single depth directory hierarchy via some chunking
code. The script oclc_marc2cpf.xsl includes a two additional XSLT files, eac_cpf.xsl and lib.xsl. The file
eac_cpf.xsl is which is mostly just an eac-cpf template. It is wrapped in a XSLT named template with
parameters, and has only the necessary XSL to fill in field values. All the programming logic is in
oclc_marc2cpf.xsl and lib.xsl.

The Perl module session_lib.pm has supporting functions, expecially config file reading.

All the xsl is currently 2.0 due to use of several XSLT 2.0 features.

See the extensive comments in the source code files.

The second, alternate system of chunking uses get_record.pl in place of exec_record.pl. This system is works
in batches and lacks the automated chunking of exec_record.pl. This older system does not use a config file,
so tracking history would require a record of the command line arguments. Necessary configuration is handled
via command line arguments.

This example reads MARC21/slim XML input snac.xml, starts with record 1, and reads 10 records. Note that the output file
name is based on the input record id, so my EAD-CPF XML files have names that begin with an OCLC identifer
like "OCLC-8559898". Your output files will have names relative to your record ids.

    > get_record.pl file=snac.xml offset=1 limit=10 | saxon.sh -s:- oclc_marc2cpf.xsl
    not_167xx: 8560473

    <?xml version="1.0" encoding="UTF-8"?>

    mst3k@d-128-167-227 Fri Jan 18 15:01:41 EST 2013
    /Users/mst3k/ead_cpf_utils
    > ls -l OCLC-85*
    -rw-r--r--  1 mst3k  staff   7403 Jan 18 15:01 OCLC-8559898.c.xml
    -rw-r--r--  1 mst3k  staff  10989 Jan 18 15:01 OCLC-8560008.c.xml
    -rw-r--r--  1 mst3k  staff   9653 Jan 18 15:01 OCLC-8560008.r01.xml
    -rw-r--r--  1 mst3k  staff   9403 Jan 18 15:01 OCLC-8560008.r02.xml

This example reads snac.xml, starts with record 1, reads 1000 records, sets the output chunk size to 100, will
write output to "test_N" where N is a counting number:

    > get_record.pl file=snac.xml offset=1 limit=1000 | saxon.sh -s:- oclc_marc2cpf.xsl chunk_size=100 offset=1 chunk_prefix=test output_dir=. > tmp.log 2>&1 &

    > ls -l get_record.pl oclc_marc2cpf.xsl eac_cpf.xsl lib.xsl 
    -rw-r--r-- 1 mst3k snac   7885 Jan  7 11:16 eac_cpf.xsl
    -rwxr-xr-x 1 mst3k snac   4970 Sep  4 09:25 get_record.pl
    -rw-r--r-- 1 mst3k snac 108638 Jan  7 16:12 lib.xsl
    -rw-r--r-- 1 mst3k snac  36795 Jan  8 15:05 oclc_marc2cpf.xsl

The Perl script get_record.pl pulls back one or more records from the original data and pipes those records to
stdout. We simply pipe stdout to a saxon.sh command. Before being piped to stdout, the set of records is
surrounded by a `<collection>...</collection>` in order to create valid XML.

All the xsl is currently 2.0 due to use of several XSLT 2.0 features.

See the extensive comments in the source code files.



Build WorldCat agency codes from a very large input file
--------------------------------------------------------

This section applies to larger data sets. Please skip this section if it does not apply to you.

Just as with generating CPF from a large number of input records
[Overview for large input files](#overview-for-large-input-files) you can use exec_record.pl to get agency
codes from a large number if input records. Please read the "Overview section first".  Please also see the
section on building your own agency codes:
[Building your own list of WorldCat agency codes](#building-your-own-list-of-worldcat-agency-codes).

Edit agency.cfg for your MARC21/slim XML input records, and run the command below. Your MARC21/slim XML input is the "file" config
value, with the default being "file = snac.xml". The output "log_file = agency_code.log" which has all of the
040$a values from your data. The XSLT script that is run is "xsl_script = extract_040a.xsl".

    ./exec_record.pl config=agency.cfg &

Assuming that everthing worked, the command below will get the values from the log file and create a unique
list. This exciting command using a Perl one-liner is fairly standard practice in the Linux world.

    cat agency_code.log | perl -ne 'if ($_ =~ m/040\$a: (.*)/) { print "$1\n";} ' | sort -fu > agency_unique.txt

The command "worldcat_code.pl file=agency_unique.txt" reads the file "agency_unique.txt" and writes a new file
"worldcat_code.xml". It also creates a directory of cached results "./wc_data". Results from http requests to
the WorldCat web API are cached as files in ./wc_data and therefore if you repeat a run, it will be much, much
faster the second time.

    ./worldcat_code.pl file=agency_unique.txt > tmp.log

The log file contains entries for codes that have multiple entries. Grep the log for 'multi mc:'.

The files agency_code.log and agency_unique.txt are often essentially temporary (as long as they were created
by scripts as above), in which case you may delete them after running worldcat_code.pl and verifying the results.

    > ls -l agency.cfg worldcat_code.* extract_040a.xsl
    -rw-r--r-- 1 mst3k snac   1057 Jan 15 14:06 agency.cfg
    -rw-r--r-- 1 mst3k snac   2366 Jan 15 11:38 extract_040a.xsl
    -rwxr-xr-x 1 mst3k snac  10427 Jan 15 11:42 worldcat_code.pl
    -rw-r--r-- 1 mst3k snac 819145 Jan 15 14:14 worldcat_code.xml


The file "occupations.xml" was created by Daniel Pitti from a spreadsheet supplied by the LoC. The XML was
subsequently modified by Tom Laudeman to add singular forms to simplify name matching.



What are the other files?
-------------------------

The repository will eventually include some files that are useful as learing examples, or that perform some
function related to either understanding the data, or developing algorithms. We will also eventually include
quality assurance (QA) files that we use during development to verify correct function of the code.



More about large numbers of input records
-----------------------------------------

This section applies to larger data sets. Please skip this section if it does not apply to you.

If you have a very large number of files, you may wish to use the Perl script exec_record.pl to chunk your
data. The chunking is necesary to prevent Saxon from running out of memory (RAM). There are two usages of
"chunk". The first is 'chunk' and refers to the number of records that will be sent to Saxon. The second is
'xsl_chunk_size' and this is how many records Saxon processes before it creates a new output directory.

The default behavior of oclc_marc2cpf.xsl is to ignore chunking and put all files in the current directory.

Copy the config file test_eac.cfg to a new config file (or not, as appropriate). Choose a small value for
config options "iterations", and "chunk". test_eac.cfg will process the first 5000 records, in other words
'1000 * 5'.

    chunk = 1000

    iterations = 5

    ./exec_record.pl config=test_eac.cfg &

Output EAD-CPF will be in the directory specified by config options "output_dir", and "chunk_prefix" with
numeric suffixes. For example ./devx_1, ./devx_2 and so on. Messages from the scripts will be in "log_file",
which is tmp_test_er.log for test_eac.cfg. You can monitor the progress of the run with "tail" and the log file.

    watch tail tmp_test_er.log




Command line params of oclc_marc2cpf.xsl
----------------------------------------


The command line params understood by oclc_marc2cpf.xsl are normally not necessary. If you wanted to use the
Perl script get_records.pl to run a test with a subset of your data, the params could be useful. The Perl
script exec_record.pl relies on these params, but they are automatically managed based on configuration values
from a supplied .cfg file.

chunk_size  default 100

The chunk_size is the number of records input before a new output directory is created, taking in account the
param 'offset'. The Perl script exec_record.pl supplies a corresponding 'offset' param so that
oclc_marc2cpf.xsl can adjust when to chunk.

chunk_prefix default zzz

The directory suffix is chunk_prefix plus a digit. For example zzz_1, zzz_2, and so on. It is a prefix in the
sense that it comes before the numeric chunk suffix. The full directory is a concatenated string of: output_dir, '/', chunk_prefix, '_', chunk_suffix.

offset default 1

The offset is automatically supplied by exec_record.pl. If you are running oclc_marc2cpf.xsl, you will almost
always use 1 or just leave the param off the command line so that it defaults to 1.

output_dir  default ./

Output CPF files will be created in subdirectories of the output_dir, based on the full directory string (see above).

use_chunks 0 (also may depend on chunk_prefix)

Normally chunks default to be off, but you can enable them with use_chunks=1 on the command line. If you
change the chunk_prefix from default, use_chunks will be enabled.

debug  default false()

The debug param enables some verbose output. This is developers and debugging.



How do I get a block of records from the MARC input?
----------------------------------------------------

This section applies to larger data sets. Please skip this section if it does not apply to you.

Get_record.pl simply gets some MARC21/slim XML records, and we redirect into a temporary xml file.

    ./get_record.pl file=snac.xml offset=1 limit=10 > tmp.xml

This is also handy to pulling out a single record into a separate file, often used for testing. Here we
retrieve the record 235.

    ./get_record.pl file=snac.xml offset=235 limit=1 > record_235.xml



Example config file
-------------------

This section applies to larger data sets. Please skip this section if it does not apply to you.

    # Use with exec_record.pl. Must have oclc_marc2cpf.xsl, (and included files
    # lib.xsl, and eac_cpf.xsl).

    ./exec_record.pl config=test_eac.cfg &

    # the file name of the xslt script to run
    xsl_script = oclc_marc2cpf.xsl
    
    # 1 or 0. When we're running oclc_marc2cpf.xsl, we need a bunch of args (params)
    # for the Saxon command line.
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

