SOURCES
=======

http://www.lancs.ac.uk/fass/projects/corpus/LCMC/
  -> http://ota.ox.ac.uk/scripts/download.php?otaid=2474

The full XML data of the LCMC can be downloaded from the Oxford Text Archive
upon agreeing to their license by submitting your email address.



INSTALLATION
============

1) After downloading the file 2474.zip from the Oxford Text Archive, unzip the
file.

Linux:
  unzip 2474.zip 

Windows:
  Right-click->Extract All


2) Perl

Perl is generally included in most Linux distributions. In Windows, The
ActivePerl Community Edition [http://www.activestate.com/activeperl/downloads]
from ActiveState works fine on all versions of Windows.

In addition to Perl, the following library packages are also needed:

      Encode
      XML::SAX
      XML::SAX::Expat (note: the default SAX parser in XML::SAX is slow and
                       buggy; this Expat driver is not)
      HTML::TokeParser
      DBI
      DBD::SQLite


For a quick test of their existence (Linux or Windows console), issue this
command:

perl -MEncode -MXML::SAX -MXML::SAX::Expat -MHTML::TokeParser -MDBI -MDBD::SQLite -e 1


If you get no response, everything is there. If you get an error:
"Can't locate ... in @INC ...", then a package is missing.
To install missing packages:

Linux (Ubuntu, et. al)
  sudo apt-get install libxml-sax-perl 
  sudo apt-get install libhtml-parser-perl
  sudo apt-get install libdbi-perl
  sudo apt-get install libdbd-sqlite3-perl

Windows console (as Adminstrator)
  ppm install XML-SAX
  ppm install XML-SAX-Expat
  ppm install HTML-Parser
  ppm install DBI
  ppm install DBD-SQLite


Verify that the file C:\Perl\site\lib\XML\SAX\ParserDetails.ini exists. If
not, create this file as:

	[XML::SAX::PurePerl]
	http://xml.org/sax/features/namespaces = 1

	[XML::SAX::Expat]
	http://xml.org/sax/features/namespaces = 1
	http://xml.org/sax/features/external-general-entities = 1
	http://xml.org/sax/features/external-parameter-entities = 1

  (Cf. http://johnbokma.com/perl/installing-xml-sax.html)


RUNNING THE SCRIPTS
===================

1) perl parse_corpus_sax2sqlite.pl 

If you have the LCMC distribution in a subdirectory of the script location,
2474/Lcmc, the Perl script should work with no changes required. If you have
the LCMC files in a different location, just change the variable definitions
in the file parse_corpus_sax2sqlite.pl.

Normal output will look similar to this:

$ perl parse_corpus_sax2sqlite.pl 

Thu Oct 18 14:17:52 2012	Parsing references from G:/Home/Chinese/corpora/LCMC/distro/2474/2474/Lcmc/manual/KAT_?.HTM ...
Thu Oct 18 14:17:52 2012	    References parsed (500 file ids)
Thu Oct 18 14:17:52 2012	Parsing parts of speech from ./pos-extracted.txt.U8 ...
Thu Oct 18 14:17:52 2012	    Parts of speech parsed (50 records)
Thu Oct 18 14:17:52 2012	CREATE TABLE 'texts'		OK!
Thu Oct 18 14:17:52 2012	CREATE TABLE 'files'		OK!
Thu Oct 18 14:17:52 2012	CREATE TABLE 'words'		OK!
Thu Oct 18 14:17:52 2012	CREATE TABLE 'full_sentences'		OK!
Thu Oct 18 14:17:52 2012	CREATE TABLE 'characters'		OK!
Thu Oct 18 14:17:52 2012	CREATE TABLE 'pos'		OK!
Thu Oct 18 14:17:52 2012	CREATE TABLE 'pinyin_words'		OK!
Thu Oct 18 14:17:52 2012	CREATE TABLE 'pinyin_full_sentences'		OK!
Thu Oct 18 14:17:52 2012	CREATE TABLE 'pinyin_characters'		OK!
Thu Oct 18 14:17:52 2012	Database created
Thu Oct 18 14:17:52 2012	Parts of speech table loaded
Thu Oct 18 14:17:52 2012	Parsing file G:/Home/Chinese/corpora/LCMC/distro/2474/2474/Lcmc/data/character/LCMC_A.XML ...
Thu Oct 18 14:18:05 2012	    Finished G:/Home/Chinese/corpora/LCMC/distro/2474/2474/Lcmc/data/character/LCMC_A.XML
Thu Oct 18 14:18:05 2012	Parsing file G:/Home/Chinese/corpora/LCMC/distro/2474/2474/Lcmc/data/character/LCMC_B.XML ...
Thu Oct 18 14:18:13 2012	    Finished G:/Home/Chinese/corpora/LCMC/distro/2474/2474/Lcmc/data/character/LCMC_B.XML
...
Thu Oct 18 14:22:57 2012	Parsing pinyin file G:/Home/Chinese/corpora/LCMC/distro/2474/2474/Lcmc/data/pinyin/LCMC_P.xml ...
Thu Oct 18 14:23:06 2012	    Finished G:/Home/Chinese/corpora/LCMC/distro/2474/2474/Lcmc/data/pinyin/LCMC_P.xml
Thu Oct 18 14:23:06 2012	Parsing pinyin file G:/Home/Chinese/corpora/LCMC/distro/2474/2474/Lcmc/data/pinyin/LCMC_R.xml ...
Thu Oct 18 14:23:09 2012	    Finished G:/Home/Chinese/corpora/LCMC/distro/2474/2474/Lcmc/data/pinyin/LCMC_R.xml


2) Accessing the database

Linux
-----

In Linux, there is a console query interface to SQLite3 databases. The command is
just 
  sqlite3 lcmc.db3

If SQLite3 is not installed,

    sudo apt-get install sqlite3


For graphical applications, there are a few solutions, but none which include
a regular expression feature. SQLite Database Browser looks promising in
screenshots, but it doesn't work well with a database this large, as it tries
to load it all into memory. The other options are SQLite Manager (a Firefox
plugin) and Sqliteman.


Windows
-------

I highly recommend SQLiteSpy [http://www.yunqa.de/delphi/doku.php] as a
graphical interface to SQLite3 databases. It is surprisingly fast, even with
very large databases such as this. It also includes built-in regular
expression support, which allows for more powerful queries of the corpus data
(see next section for examples).


3) (optional) Adding frequency data to the database

The SQL script file add_frequency_fields.sql is a set of statements to add some
information on word frequencies to the database. It isn't included in the main
script because it relies on regular expressions to determine what is a Chinese
word, and would fail under some operating systems or software configurations.

Executing the statements in add_frequency_fields.sql will add the following to
the database:

  - A new table "frequencies", with word ranks, frequencies, and frequencies
    per million

  - A new column texts.ch_word_ct, containing the number of Chinese words in
    each of the 15 text categories



HAVE FUN!
=========

A) Raw frequency counts of all Chinese words in the corpus (requires regexp)

SELECT characters, COUNT('x')
  FROM words
 WHERE token_type = 'w'
   AND characters REGEXP '^[\x{3400}-\x{4DBF}\x{4E00}-\x{9FFF}\x{F900}-\x{FAFF}\x{00b7}]+$'
   /* or regexp '^[\p{InCJK_Unified_Ideographs_Extension_A}\p{InCJK_Unified_Ideographs}\p{InCJK_Compatibility_Ideographs}\x{b7}]+$' */
   /* or regexp '^\p{Han}+$' but this will include fullwidth numbers and letters */
 GROUP BY characters ORDER BY count('x') DESC, characters ASC;


B) List all words tagged as prepositions

SELECT W.characters, P.id, P.description, COUNT(*) from words W
  JOIN pos P on W.part_of_speech = P.id
 WHERE P.description = 'preposition'
 GROUP BY W.characters, P.id, P.description
 ORDER BY COUNT(*) DESC;


C) List the average sentence length per text category

SELECT T.id, T.type, ROUND(AVG(LENGTH(F.characters)), 1) as avg_sentence_length
  FROM full_sentences F
  JOIN texts T on F.text_id = T.id 
 GROUP BY T.id, T.type





Regexp Support in Linux
------------------------

Regular expression support is not essential to do many SQL queries, but it is
highly useful, especially when working with corpus data. One crucial use is in
filtering out non-Chinese words from word counts, for example.

Ubuntu and other distributions have a package (sqlite3-pcre) that can be
loaded into the SQLite3 command line client to allow the REGEXP operator to
work. Unfortunately, in some distributions it may not work with Unicode
strings.

After installing the sqlite3-pcre package, The command line client loads it by:

    sqlite> .load /usr/lib/sqlite3/pcre.so

After this, you can use the regexp operator,

    sqlite> select * from words where characters regexp '\x{0061}';

D|D14|0002|6|Taoism|nx|w|2|317095
D|D14|0003|7|Taoism|nx|w|2|317110
...

Regular expression support for SQLite in Linux software is lacking. For example,
the sqlite3-pcre package in Ubuntu uses the Perl Compiled Regular Expression
library (libpcre). However, the libpcre package may not be compiled with Unicode
support, making it useless for what it would be most effective for.

    sqlite> select * from words where characters regexp '\x{4e00}';

    Error: \x{4e00}: character value in \x{...} sequence is too large (offset 7)

which demonstrates that Unicode is not supported by the standard distribution.
