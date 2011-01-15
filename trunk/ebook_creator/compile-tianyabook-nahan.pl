#!/usr/bin/perl

# created 1/13/2011 by Chad Redman
# This program is free for any use.

# Description:
# Extract the content from a series of web pages, and format it for an e-book.
# For this script to work, all the content pages from the source mentioned below
# should be downloaded into the current working directory.


# This script is specific to Lu Xun's "Nahan" story collection, as found
# on 1/13/2011 at tianyabook - http://www.tianyabook.com/luxun/lh/
# Files: 000.htm - 014.htm


my $OUTPUT_FILE = 'output/Nahan - Lu Xun.txt';
mkdir './output';


use Encode;
use utf8;  # this gives length of characters instead of bytes for length()
use HTML::TokeParser;

open(OUT, "> $OUTPUT_FILE");
binmode OUT, ":utf8";   # This is necessary to avoid "Wide character in print" errors

my $file_ct = 0;   ## Files are numbered starting at 000.htm

## Loop through all files named <index>.html in numeric order. Parse
## the content out of each one and append to the output file
while (-e sprintf("%03d.htm", $file_ct)) {

    my $file = sprintf("%03d.htm", $file_ct);
    ++$file_ct;

	if (!open(IN, "<$file")) {
		print "Couldn't open file $file: $!\n";
		next;
	}

	print "Converting file $file\n";

	my $buf = join('', <IN>);
    $buf = Encode::decode('gb2312', $buf);  # gb2312 is the default encoding of the html pages.

    my $tp = HTML::TokeParser->new(\$buf) or die $!;

    # jump to the content
    # This is the chapter heading
    $found = &scan_to_tag($tp, 'b');
    my $title = $tp->get_text;    # chapter title
    $title =~ s/[\x{2474}-\x{2482}]/'(' . (ord($&) - 9331) . ')'/ge;   # These are "Parenthesized Digit". They are unprintable squares on Kindle. Convert to (x)
    $title =~ s/[\x{2460}-\x{2469}]/'(' . (ord($&) - 9311) . ')'/ge;   # These are "Circled Digit" numbers. They are unprintable squares on Kindle. Convert to (x)

    print OUT $title, "\n", '-' x 20, "\n";  # Add underline under chapter title.

    # skip to the start of the text
    $found = &scan_to_tag($tp, 'hr', ('color' => '#EE9B73'));

    while (1) {
        my $token = $tp->get_token;
        last unless $token;

        if ($token->[0] eq 'S' and $token->[1] eq 'br') {
            #Found a <br> tag
            #there are already line breaks in the paragraphs. This just adds extra lines
            #print OUT "\n";
        } elsif ($token->[0] eq 'T') {
            #Found plain text
            my $text = $token->[1];

            $text =~ s/\x{25a1}//; # Before the "zhushi" annotations, sometimes there is a white square in the original text. Just clean it out
            $text =~ s/[\x{2474}-\x{2482}]/'(' . (ord($&) - 9331) . ')'/ge;   # These are "Parenthesized Digit". They are unprintable squares on Kindle. Convert to (x)
            $text =~ s/[\x{2460}-\x{2469}]/'(' . (ord($&) - 9311) . ')'/ge;   # These are "Circled Digit" numbers. They are unprintable squares on Kindle. Convert to (x)

            # There are also \x{3000} "Ideographic space" (i.e. fullwidth space) chars to do the indenting and come centering.
            # You can strip these out if you would prefer

            print OUT $text;
        } elsif ($token->[0] eq 'S' and $token->[1] eq 'div') {
            #Found a <div> tag
            #This signals the end of the text
            last;
        } elsif ($token->[0] =~ /^[SE]$/) {
            # output other tokens, but ignore font directives
            next if $token->[1] eq 'font';
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
