README for small_utilities/ebook_creator
========================================

This directory contains example scripts for turning a series of HTML files
into a combined text document. This document can be used directly in a
conversion program like Calibre (http://calibre-ebook.com/) to produce an
e-book with a table of contents.

The table of contents is available because the scripts add an extra row of
underlines beneath each chapter title. When the option in Calibre is
enabled to process text using Markdown, these are detected as level 2
headings which automatically become the entries in the table of contents.

There are three example scripts contained here, each of which is customized
to handle HTML formatted in a particular way.

EXAMPLE
-------

All the files from Lu Xun's "Nahan" story collection from
http://www.tianyabook.com/luxun/lh/ have the following format:

    ...
    <B>chapter title</B>
    ...
    <hr color="#EE9B73" size="1" width="94%">
    <BR>
      paragraph 1
    <BR>
      paragraph 2
    ... etc.
    <div align="center">


The script compile-tianyabook-nahan.pl loops through each of the files
named 000.htm through 014.htm, extracts the title and content, and appends
the result into a cumulative output text file. While the input files are
all in GB text encoding, the output will be in UTF-8.


REQUIREMENTS
------------

These scripts all require Perl to run. In addition, it uses the Perl module
HTML::TokeParser (http://search.cpan.org/~gaas/HTML-Parser-3.68/lib/HTML/TokeParser.pm)
to assist with file parsing. This distribution does not contain the
original HTML files that the scripts act on. You can obtain them from:


Script: compile-tianyabook-nahan.pl
Book:   Nahan, by Lu Xun
URL:    http://www.tianyabook.com/luxun/lh/
Files:  000.htm - 014.htm

Script: compile-tianyabook-yulihun.pl
Book:   Yu Li Hun, by Zhenya Xu
URL:    http://www.tianyabook.com/zw/yulihun/index.html
Files:  1.html - 30.html

Script: compile-readnovel-chaoji-shuaige.pl
Book:   Chaoji Shuaige (book 1), by "da si wuxie"
URL:    http://www.readnovel.com/partlist/105240/
Files:  1.html - 50.html


These HTML files need to be in the same directory as the corresponding script.


AUTHOR
------
These utilities were written January, 2011 by Chad Redman. The Perl scripts themselves may be used for any purpose. Book content files are included for illustrative purposes only.
