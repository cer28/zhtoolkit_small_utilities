#!/usr/bin/perl

# created 1/13/2011 by Chad Redman
# This program is free for any use.

# Description:
# Extract the content from a series of web pages, and format it for an e-book.
# For this script to work, all the content pages from the source mentioned below
# should be downloaded into the current working directory.


# This script is specific to online novel "Chaoji Shuaige" by "da si wuxie",
# as found on 12/23/2010 at readnovel.com - http://www.readnovel.com/partlist/105240/
#
# Files: 1.html - 50.html


my $OUTPUT_FILE = 'output/Chaoji Shuaige - da si wuxie.txt';
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
    &scan_to_tag($tp, 'div', ('id'=>'article'));

    # This is the chapter title. Print it with an underline below
    &scan_to_tag($tp, 'h2');
    my $title = Encode::decode('gb2312', $tp->get_text);    # chapter name

    print OUT $title, "\n", '-' x 20, "\n";  # Add underline under chapter title.

    while (1) {
        my $token = $tp->get_token;
        last unless $token;

        if ($token->[0] eq 'E' and $token->[1] eq 'div') {
            #Found a </div> tag
            #This signals the end of the text
            last;
        } elsif ($token->[0] eq 'S' and $token->[1] eq 'br') {
            #Found a <br> tag
            #there are already line breaks in the paragraphs. This just adds extra lines
            #print OUT "\n";
        } elsif ($token->[0] eq 'T') {
            #Found plain text
            my $text = $token->[1];

            print OUT Encode::decode('gb2312', $text);
        } elsif ($token->[0] eq 'S' and $token->[1] eq 'p') {
            # <p>
            print OUT "\n";
        } elsif ($token->[0] =~ /^[SE]$/) {
            # output other tokens, but ignore font directives
            next if $token->[1] eq 'font';  # ignore <font> and </font>
            next if $token->[0] eq 'E' and $token->[1] =~ /^(p|h2)$/;  # ignore </p> and </h2>
            print OUT &token2tag($token);
        } else {
            print "Found an unhandled token: $token->[0], $token->[1]\n";
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
