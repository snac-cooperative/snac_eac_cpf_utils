#!/usr/bin/perl

use strict;

# sep 28 2014 Add nice to the indexing commands 

# Usage: 
# xtf_index.pl 2 &

# /home/snac/eac-graph-load/xtf-x2/index/lazy/default/britlib

# Probably better to change the symlink in xtfTest* rather than changing the dir at the other end of the
# symlink.

# > find xtfTest* -maxdepth 1 -ls
# 16651927    0 lrwxrwxrwx   1 twl8n    snac           26 Jun 25  2013 xtfTest2/britlib -> /uva-working/twl8n/britlib
# 15892948    0 lrwxrwxrwx   1 twl8n    snac           29 Jun 11  2013 xtfTest3/sia_fb_cpf -> /uva-working/twl8n/sia_fb_cpf
# 16124987    0 lrwxrwxrwx   1 twl8n    snac           27 Jul  9  2013 xtfTest4/nysa_cpf -> /uva-working/twl8n/nysa_cpf
# 14991420    0 lrwxrwxrwx   1 twl8n    snac           31 Jul  9  2013 xtfTest5/sia_agencies -> /uva-working/twl8n/sia_agencies
# 14969578    0 lrwxrwxrwx   1 twl8n    snac           19 Nov 21 11:55 xtfTest6/cpf -> /lv3/data/twl8n/cpf
# 21952733    0 lrwxrwxrwx   1 twl8n    snac           28 Sep 16 11:36 xtfTest7/henry_cpf -> /uva-working/twl8n/henry_cpf
# 21954524    0 lrwxrwxrwx   1 twl8n    snac           22 Dec 12 16:56 xtfTest8/ead -> /uva-working/twl8n/ead

my %href = ( 1 => "xtfTest http://shannon.village.virginia.edu:8083/xtf/search",
             2 => "xtfTest2 http://shannon.village.virginia.edu:8084/xtf/search",
             3 => "xtfTest3 http://socialarchive.iath.virginia.edu:8086/xtf/search",
             4 => "xtfTest4 http://socialarchive.iath.virginia.edu:8087/xtf/search",
             5 => "xtfTest5 http://socialarchive.iath.virginia.edu:8088/xtf/search",
             6 => "xtfTest6 http://socialarchive.iath.virginia.edu:8089/xtf/search",
             7 => "xtfTest7 http://socialarchive.iath.virginia.edu:8090/xtf/search",
             8 => "xtfTest8 http://socialarchive.iath.virginia.edu:8091/xtf/search");

my %port = ( 1 => "8083",
             2 => "8084",
             3 => "8086",
             4 => "8087",
             5 => "8088",
             6 => "8089",
             7 => "8090",
             8 => "8091");

# xtf index arg 
my $xa = "";

if ($ARGV[0] =~ m/^(1|2|3|4|5|6|7|8)$/)
{
   $xa = $ARGV[0];
   if ($xa == 1)
   {
       $xa = ""; # Oddly, the first instance has no suffix digit.
   }
   `echo "Your href is: $href{$xa}" > xtf$xa.log`;
}
else
{
    print STDERR "Usage $0 1|2|3|4|5|6|7|8\n";
    foreach my $key (1..8)
    {
        print STDERR "$href{$key}\n";
    }
    exit();
}

# This (what is "this"? Is it the whole script, or just the chmod below?) does not work if the person running the
# script isn't the file owner. Better to check these, die with a warning and after the user fixes the problem,
# they can re-run the script.

# `chmod -R g+w /uva-working/xtfTest$xa/*`;

if ($xa < 5)
{
    # append to the log file that is created by the echo at line 52. 
    `nice /home/snac/eac-graph-load/servers/tomcat_x$xa/webapps/xtf/bin/textIndexer -clean -trace info -index default >> xtf$xa.log 2>&1`;

    # Wait a few seconds for some other process to run
    sleep 30;
    `chmod -R g+w /home/snac/eac-graph-load/servers/tomcat_x$xa/webapps/xtf/index/lazy/default/`;
}
else
{
    my $port = $port{$xa};
    # append to the log file that is created by the echo at line 52. 
    `nice /home/snac/twincat/xtf$port/webapps/xtf/bin/textIndexer  -clean -trace info -index default >> xtf$xa.log 2>&1`;

    # Wait a few seconds for some other process to run
    sleep 30;
    `chmod -R g+w /home/snac/twincat/xtf$port/webapps/xtf/index/lazy/default/`;
}

