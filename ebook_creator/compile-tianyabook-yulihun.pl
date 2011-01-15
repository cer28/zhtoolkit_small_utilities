#!/usr/bin/perl

# created 1/13/2011 by Chad Redman
# This program is free for any use.

# Description:
# Extract the content from a series of web pages, and format it for an e-book.
# For this script to work, all the content pages from the source mentioned below
# should be downloaded into the current working directory.


# This script is specific to Zhenya Xu's "Yu Li Hun", as found
# on 1/13/2011 at tianyabook - http://www.tianyabook.com/zw/yulihun/index.html
# Files: 1.html - 30.html


my $OUTPUT_FILE = 'output/Yu Li Hun - Xu Zhenya.txt';
mkdir './output';


use Encode;
use utf8;  # this gives length of characters instead of bytes for length()
use HTML::TokeParser;

open(OUT, "> $OUTPUT_FILE");
binmode OUT, ":utf8";   # This is necessary to avoid "Wide character in print" errors

my $file_ct = 1;   ## Files are numbered starting at 1.html

## Loop through all files named <index>.html in numeric order. Parse
## the content out of each one and append to the output file
while (-e sprintf("%d.html", $file_ct)) {

    my $file = sprintf("%d.html", $file_ct);
    ++$file_ct;

    if (!open(IN, "<$file")) {
        print "Couldn't open file $file: $!\n";
        next;
    }

    print "Converting file $file\n";

    my $buf = join('', <IN>);
    #$buf = Encode::decode('gb2312', $buf);  # gb2312 is the default encoding of the html pages.
                                             # These html pages balk here at decoding the entire file.
                                             # Instead, leave it as binary and decode the extracted texts

    my $tp = HTML::TokeParser->new(\$buf) or die $!;

    # jump to the content
    &scan_to_tag($tp, 'p', ('style'=>'line-height: 150%'));

    # This is the book name. Ignore it
    &scan_to_tag($tp, 'p');
    $tp->get_text;    # book name

    # This is the chapter title. Print it with an underline below
    &scan_to_tag($tp, 'p');
    my $title = Encode::decode('gb2312', $tp->get_text);    # chapter name

    print OUT $title, "\n", '-' x 20, "\n";  # Add underline under chapter title.

    while (1) {
        my $token = $tp->get_token;
        last unless $token;

        if ($token->[0] eq 'S' and $token->[1] eq 'p') {
            print OUT "\n";
            my $text = Encode::decode('gb2312', $tp->get_text);    # chapter name
            last if ($text =~ /^\x{3000}*----$/);  # U+3000 is an ideographic space. This marks the end of the content in tianyabook
            print OUT "$text\n";
        } elsif ($token->[0] eq 'E' and $token->[1] eq 'p') {
            last;
        } else {
            use Data::Dumper; print OUT Dumper $token;
        }
    }
    
    print OUT "\n\n";  #leave some space before the next chapter
}

print "Output file '$OUTPUT_FILE' created.\n";

exit 0;




sub scan_to_tag {
    my ($tp, $tag, %args) = @_;
    my $found;
    while (!$found) {
        last unless my $tmp = $tp->get_tag($tag);
        my $match = 1;
        while (my ($key, $value) = each %args) {
            $match = 0 unless defined $tmp->[1]{$key} and $tmp->[1]{$key} =~ /^$value$/;
        }
        $found = $tmp if $match == 1;

    }

    return $found;
}


sub token2tag {
    my $token = shift;
    my @extra;
    foreach my $key ( @{$token->[3]} ) {
        push @extra, $key, $token->[2]{$key};
    }
    return
        '<'
      . ($token->[0] eq 'E' ? '/' : '')
      . $token->[1]
      . (@extra ? join(' ', @extra) : '')
      . '>';

}
