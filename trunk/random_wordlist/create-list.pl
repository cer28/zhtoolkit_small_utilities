#!/usr/bin/perl -w

# created 2/7/2011 by Chad Redman
# This program is free for any use.

# Description:
# The program constructs a random word list using word frequency data gleaned
# from the Lancaster Corpus of Mandarin Chinese, and pinyin and definitions
# from CC-CEDICT. It creates groups of words within specific word rank
# bands, e.g., 1-1000, 1001-2000, 2001-3500, .... Each group starts with the
# header "Range: start - end". Certain flashcard programs (e.g., Stackz) can
# use these headings as indicators for each batch and name them appropriately.


### Configurable variables ###

## SQLite3 file containing segmented words from the LCMC
my $LCMC_FILE = 'G:/Home/Chinese/devel/corpus/lcmc.db3';

## CC-CEDICT formatted dictionary, e.g., from http://www.mdbg.net/chindict/chindict.php?page=cc-cedict
my $CEDICT_FILE = 'G:/Home/Chinese/Dictionaries/cedict_ts.u8';

## Number of samples in each frequency band
my $NUM_IN_SET = 50;

## The highest rank of each frequency band
my @ranks = (1000, 2000, 3500, 6000, 10000, 18000);

## Add an extra band up to the highest ranked words; e.g., 18001=>34508
my $APPEND_LAST_RANK = 1;


#--- End of configuration variables ---#
########################################

use DBI;

binmode STDOUT, ":utf8";

use List::Util 'shuffle';    # `sort { rand() <=> rand() }` isn't very random. Use `shuffle ($start..$end)` instead


my $dbh_lcmc = DBI->connect("dbi:SQLite:dbname=$LCMC_FILE", '', '') or die $!;
$dbh_lcmc->{unicode} = 1;

my ($wordsum, $wordranks) = &fillRandomWords($dbh_lcmc);

my $cedict = &loadcedict($CEDICT_FILE) or die $!;

if ($APPEND_LAST_RANK) {
    push @ranks, scalar(@$wordranks);
}


#print "num words: ", scalar(@$wordranks), "\n";
#print "total freq: $wordsum\n";


print join("\t", 'simplified', 'pinyin', 'English definition', 'freq. per million / rank'), "\n";

my ($low, $high) = (0, 0);
while (@ranks) {
    $low = $high + 1;
    $high = shift @ranks;

    print "Range: $low - $high\n";
    #print "Range: $low - $high\n", '='x40, "\n";   # same, but with a pretty underline

    my $ct = 1;

    foreach my $rnd_rank ( shuffle($low-1 .. $high-1) ) {
        my $word = $wordranks->[$rnd_rank];
        print join("\t", , $word->[0], ($cedict->{$word->[0]}[0] or ''), ($cedict->{$word->[0]}[1] or ''), sprintf("%d / %d", int($word->[2]*1.0e6/$wordsum), $word->[1])), "\n";
        last if ++$ct > $NUM_IN_SET;
    }

}

exit 0;


sub loadcedict {
    my $file = shift;
    my $cedict = {};

    my $cjkUnifiedIdeographs = "\x{4E00}-\x{9FFF}";
    my $cjkUnifiedIdeographsExtA = "\x{3400}-\x{4DBF}";
        #cjkUnifiedIdeographsExtB = "\x{2000}0-2A6DF";
        #cjkEnclosedLettersAndMonths = "\x{3200}-\x{32FF}";
    my $cjkCompatibilityIdeographs = "\x{F900}-\x{FAFF}";

    #Non-CJK characters used in simplified/traditional field 
        #Some of these are covered in Halfwidth and Fullwidth Forms. But this makes a stricter filter
    my $cjkMiddleDot = "\x{30FB}";
    my $cjkFullwidthComma = "\x{FF0C}";
    my $cjkLingZero = "\x{3007}";
    my $cjkFullwidthLatin = "\x{FF21}-\x{FF3A}\x{FF41}-\x{FF5A}";

    my $cjkRange = join('', $cjkMiddleDot, $cjkFullwidthComma, $cjkLingZero, $cjkUnifiedIdeographsExtA, $cjkUnifiedIdeographs, $cjkCompatibilityIdeographs, $cjkFullwidthLatin);
    my $pat = "^([$cjkRange]+) ([$cjkRange]+) \\[([a-zA-Z0-9,\xb7: ]+)\\] \\/(.*)\\/\\s*\$";


    open(DICT, "<:utf8", $file) or return undef;
    
    while (<DICT>) {
        next unless /\w/;
        next if (/^\s*#/);
        chomp;
        #unless (m|^(\S+)\s(\S+)\s\[([a-zA-Z0-9: ]+)\]\s/(.*)/\s*$| ) {
        unless (/$pat/ ) {
            #warn "Line $.: Invalid entry '$_'\n";
            next;
        }
        my ($trad, $simp, $pinyin, $english) = ($1, $2, $3, $4);
        if (!exists $cedict->{$simp}) {
            $cedict->{$simp} = [ $pinyin, $english ];
        } else {
            #merge multiple entries under a single definition
            if ($pinyin ne $cedict->{$simp}[0]) {
                $cedict->{$simp}[0] .= '; ' . $pinyin;
            }
            if ($english ne $cedict->{$simp}[1]) {
                $cedict->{$simp}[1] .= '; ' . $english;
            }
        }
    }
    
    close DICT;
    return $cedict;
    
}


sub fillRandomWords {
    my $dbh = shift;

    my $wordsum = 0;
    my $wordranks = [];

    #skip these types
    #id  type
    #A   Press reportage
    #B   Press editorial
    #C   Press review
    #D   Religion
    #H   Miscellaneous (reports, official documents)

    #keep these
    #id  type
    #E   Skills, trades and hobbies
    #F   Popular lore
    #G   Biographies and essays
    #J   Science (academic prose)
    #K   General fiction
    #L   Mystery and detective fiction
    #M   Science fiction
    #N   Martial art fiction
    #P   Romantic fiction
    #R   Humour


    my $sql = "
SELECT characters, COUNT(*)
FROM words
WHERE text_id NOT IN ('A', 'B', 'C', 'D', 'H')
AND token_type = 'w'
AND part_of_speech NOT IN ('nr', 'nx') GROUP BY characters ORDER BY count(*) DESC, characters ASC";

    my $sth = $dbh->prepare($sql);
    my $rv = $sth->execute();
    my $currow = 0;

    while (my ($chars, $ct) = $sth->fetchrow_array) {
        # Filter words too obvious to test on: ordinal and cardinal numbers (and di + number, or number + yue, nian, etc)
        next if (
            ($chars ge "-" and $chars le "\x{3229}")  #special chars
         ||
            ($chars ge "\x{FF10}" and $chars le "\x{FF19}\x{FF19}\x{FF19}")  # double width numbers
         ||
            ($chars =~ /^[\x{25cb}\x{4e00}\x{4e8c}\x{4e09}\x{56db}\x{4e94}\x{516d}\x{4e03}\x{516b}\x{4e5d}\x{5341}\x{767e}\x{5343}\x{4e07}\x{4ebf}\x{00b7}]{2,}$/)  # 1-10 in characters, except for single digits
              #               0        1      2       3       4        5      6       7       8       9       10      bai    qian    wan     yi      dot
         ||
            ($chars =~ /^\x{7b2c}[0-9\.\x{FF10}-\x{FF19}\x{25cb}\x{4e00}\x{4e8c}\x{4e09}\x{56db}\x{4e94}\x{516d}\x{4e03}\x{516b}\x{4e5d}\x{5341}\x{4e24}\x{767e}\x{5343}\x{4e07}\x{4ebf}\x{00b7}]+/)
              #               di   [      dw0     dw9      0        1     2          3     4      5          6     7        8       9        10    liang   bai    qian    wan      yi      dot  ]
         ||
            ($chars =~ /^\x{7b2c}?[0-9\.\x{FF10}-\x{FF19}\x{25cb}\x{4e00}\x{4e8c}\x{4e09}\x{56db}\x{4e94}\x{516d}\x{4e03}\x{516b}\x{4e5d}\x{5341}\x{4e24}\x{767e}\x{5343}\x{4e07}\x{4ebf}\x{00b7}]+[\x{4e2a}\x{65e5}\x{6708}\x{5e74}\x{5206}]$/)
              #               di ?  [       dw0     dw9      0        1     2          3     4      5          6     7        8       9     10     liang     bai    qian    wan      yi     dot  ] [  ge      ri      yue     nian    fen ]     
         );
        $wordsum+= $ct;
        push @$wordranks, [ $chars, ++$currow, $ct ];
    }

    return ($wordsum, $wordranks);
}


__END__

## This is a cleaner version of the query, but it looks like regexp isn't supported in Perl's SQLite driver

    my $sql_wdct = "
SELECT COUNT(*)
FROM words
WHERE token_type = 'w'
AND (
    part_of_speech IN ('t', 'm')
    AND (
        characters BETWEEN '-' AND '\x{3229}'
        OR characters BETWEEN '\x{FF10}' AND '\x{FF19}\x{FF19}\x{FF19}'
        OR characters REGEXP '^[\x{25cb}\x{4e00}\x{4e8c}\x{4e09}\x{56db}\x{4e94}\x{516d}\x{4e03}\x{516b}\x{4e5d}\x{5341}\x{4e24}\x{767e}\x{5343}\x{4e07}\x{00b7}\x{4e2a}\x{7b2c}\x{6708}\x{5e74}]'
    )
)
AND part_of_speech NOT IN ('nr', 'nx')";

    my $sql_words = "
SELECT characters, COUNT(*)
FROM words
WHERE token_type = 'w'
AND (
    part_of_speech IN ('t', 'm')
    AND (
        /* characters BETWEEN '-' AND '\x{3229}'
        OR characters BETWEEN '\x{FF10}' AND '\x{FF19}\x{FF19}\x{FF19}'
        OR characters REGEXP '^[\x{25cb}\x{4e00}\x{4e8c}\x{4e09}\x{56db}\x{4e94}\x{516d}\x{4e03}\x{516b}\x{4e5d}\x{5341}\x{4e24}\x{767e}\x{5343}\x{4e07}\x{00b7}\x{4e2a}\x{7b2c}\x{6708}\x{5e74}][\x{4e2a}]'
        OR */ characters REGEXP '^([\x{25cb}\x{4e00}\x{4e8c}\x{4e09}\x{56db}\x{4e94}\x{516d}\x{4e03}\x{516b}\x{4e5d}\x{5341}\x{4e24}\x{767e}\x{5343}\x{4e07}\x{00b7}\x{4e2a}\x{7b2c}\x{6708}\x{5e74}][\x{4e2a}])'
    )
)
AND part_of_speech NOT IN ('nr', 'nx') GROUP BY characters ORDER BY count(*) DESC, characters ASC";
