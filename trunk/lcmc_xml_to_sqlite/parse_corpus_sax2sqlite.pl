#!/usr/bin/perl -w

# Written 2012 Chad Redman
# Free for any use


## Notes:

# http://perl-xml.sourceforge.net/faq/#parserdetails.ini
# "could not find ParserDetails.ini"

# Error in LCMC_L.XML:
#     utf8 "\x83" does not map to Unicode at C:/Perl/site/lib/XML/SAX/PurePerl/Reader/Stream.pm line 37.
# The problem is in XML::SAX::PurePerl. Install the XML::SAX::Expat package, and also make sure
# that ParserDetails.ini exists (see README for details)


my $corpattern = './2474/2474/Lcmc/data/character/LCMC_?.XML';
my $corpattern_pinyin = './2474/2474/Lcmc/data/pinyin/LCMC_?.XML';
my $refpattern = './2474/2474/Lcmc/manual/KAT_?.HTM';
my $dbname = 'lcmc.db3';
my $infile_pos = './pos-extracted.txt.U8';
my $sql_create = 'create_db.sql';


package MySAXHandler;

# Doesn't seem to be needed so far
# use Encode;
    
use base qw(XML::SAX::Base);

sub new {
    my ($type, $references) = @_;
    return bless {
           'content' => {
                   'texts' => [],
                   'files' => [],
                   'words' => [],
                   'full_sentences' => [],  # virtual data, not directly in the xml file
                   'characters' => [],     # virtual data, not directly in the xml file
           },
           'references' => $references,
    }, $type;
}

use vars qw/$current_element $current_textid $current_fileid $ct_para $sentence_full $current_sentence_id
    $ct_word $buf_word $current_speech $running_word_idx/;

$current_element = '';
$current_textid = '';
$current_fileid = '';
$ct_para = 0;
$sentence_full = undef;
$current_sentence_id = '';
$ct_word = 0;
$buf_word = undef;
$current_speech = undef;
$running_word_idx = 1;


sub start_element {
    my ($self, $el) = @_;
    $current_element = $el->{Name};
    if ($el->{Name} eq 'text') {
        $current_textid = $el->{Attributes}->{'{}ID'}{Value};
        push @{$self->{content}{texts}}, [ $el->{Attributes}->{'{}ID'}{Value}, $el->{Attributes}->{'{}TYPE'}{Value}];
    }
    elsif ($el->{Name} eq 'file') {
        $current_fileid = $el->{Attributes}->{'{}ID'}{Value};
        push @{$self->{content}{files}}, [$current_fileid, $current_textid, ($self->{references}{$current_fileid} || '* description not found*')];     # id, text_id, reference
    }
    elsif ($el->{Name} eq 'p') {
        ++$ct_para;
    }
    elsif ($el->{Name} eq 's') {
        $ct_word = 0;
        $sentence_full = '';
        $current_sentence_id = $el->{Attributes}->{'{}n'}{Value};
    }
    elsif ($el->{Name} eq 'w') {
        $buf_word = '';
        $current_speech = $el->{Attributes}->{'{}POS'}{Value};
        ++$ct_word;
    }
    elsif ($el->{Name} eq 'c') {
        $buf_word = '';
        $current_speech = $el->{Attributes}->{'{}POS'}{Value};
        ++$ct_word;
    }
}

sub end_element {
    my ($self, $el) = @_;

    if ($el->{Name} eq 'text') {
        $current_textid = undef;
    }
    if ($el->{Name} eq 'file') {
        $current_fileid = undef;
        $ct_para = 0;
    }
    elsif ($el->{Name} eq 'p') {
    }
    elsif ($el->{Name} eq 's') {
        push @{$self->{content}{full_sentences}}, [$current_textid, $current_fileid, $current_sentence_id, $ct_para, $sentence_full];
        $sentence_full = undef;
        $current_sentence_id = '';
        $ct_word = 0;
    }
    elsif ($el->{Name} eq 'w' or $el->{Name} eq 'c') {
        push @{$self->{content}{words}}, [$current_textid, $current_fileid, $current_sentence_id, $ct_word, $buf_word, $current_speech, $el->{Name}, $ct_para, $running_word_idx];
        my @chars = split(//, $buf_word);
        for (my $i = 0; $i < @chars; ++$i) {
            push @{$self->{content}{characters}}, [$current_textid, $current_fileid, $current_sentence_id, $ct_word, $i+1, $chars[$i], $el->{Name}];
        }
        $sentence_full .= $buf_word;
        $running_word_idx += length($buf_word);
        $buf_word = undef;
        $current_speech = undef;
    }
}

sub characters {
    my ($self, $chars) = @_;

    if ($current_element =~ /^(c|w)$/) {
        $buf_word .= $chars->{Data};
    }
}




package MyPinyinSAXHandler;

use base qw(XML::SAX::Base);

sub new {
    my ($type) = @_;
    return bless {
           'content' => {
                   'texts' => [],
                   'files' => [],
                   'words' => [],
                   'pinyin_words' => [],
                   'pinyin_full_sentences' => [],
                   'pinyin_characters' => [],

           },
    }, $type;
}

use vars qw/$current_element $current_textid $current_fileid $ct_para $sentence_full $current_sentence_id
    $ct_word $buf_word $current_speech $running_word_idx/;


$current_element = '';
$current_textid = '';
$current_fileid = '';
$ct_para = 0;
$sentence_full = undef;
$current_sentence_id = '';
$ct_word = 0;
$buf_word = undef;
$current_speech = undef;
$running_word_idx = 1;

sub start_element {
    my ($self, $el) = @_;
    $current_element = $el->{Name};
    if ($el->{Name} eq 'text') {
        $current_textid = $el->{Attributes}->{'{}ID'}{Value};
        push @{$self->{content}{texts}}, [ $el->{Attributes}->{'{}ID'}{Value}, $el->{Attributes}->{'{}TYPE'}{Value}];
    }
    elsif ($el->{Name} eq 'file') {
        $current_fileid = $el->{Attributes}->{'{}ID'}{Value};
        push @{$self->{content}{files}}, [$current_fileid, $current_textid, ($self->{references}{$current_fileid} || '* description not found*')];     # id, text_id, reference
    }
    elsif ($el->{Name} eq 'p') {
        ++$ct_para;
    }
    elsif ($el->{Name} eq 's') {
        $ct_word = 0;
        $sentence_full = '';
        $current_sentence_id = $el->{Attributes}->{'{}n'}{Value};
    }
    elsif ($el->{Name} eq 'w') {
        $buf_word = '';
        $current_speech = $el->{Attributes}->{'{}POS'}{Value};
        ++$ct_word;
    }
    elsif ($el->{Name} eq 'c') {
        $buf_word = '';
        $current_speech = $el->{Attributes}->{'{}POS'}{Value};
        ++$ct_word;
    }
}

sub end_element {
    my ($self, $el) = @_;

    if ($el->{Name} eq 'text') {
        $current_textid = undef;
    }
    if ($el->{Name} eq 'file') {
        $current_fileid = undef;
        $ct_para = 0;
    }
    elsif ($el->{Name} eq 'p') {
    }
    elsif ($el->{Name} eq 's') {
        push @{$self->{content}{pinyin_full_sentences}}, [$current_textid, $current_fileid, $current_sentence_id, $ct_para, $sentence_full];
        $sentence_full = undef;
        $current_sentence_id = '';
        $ct_word = 0;
    }
    elsif ($el->{Name} eq 'w' or $el->{Name} eq 'c') {
        push @{$self->{content}{pinyin_words}}, [$current_textid, $current_fileid, $current_sentence_id, $ct_word, $buf_word, $current_speech, $el->{Name}, $ct_para, $running_word_idx];
        my @chars = $buf_word =~ /([a-z]+[1-5]|\x{b7})/g;
        for (my $i = 0; $i < @chars; ++$i) {
            push @{$self->{content}{pinyin_characters}}, [$current_textid, $current_fileid, $current_sentence_id, $ct_word, $i+1, $chars[$i], $el->{Name}];
        }
        
        #if ($el->{Name} eq 'w' and $buf_word =~ /^([a-z]+[1-5])+$/) {
        #    $sentence_full .= (length($sentence_full)) ? ' ' . $buf_word : $buf_word;
        #} else {
        #    $sentence_full .= $buf_word;
        #}
        $sentence_full .= (length($sentence_full)) ? ' ' . $buf_word : $buf_word;

        $running_word_idx += length($buf_word);
        $buf_word = undef;
        $current_speech = undef;
    }
}

sub characters {
    my ($self, $chars) = @_;

    if ($current_element =~ /^(c|w)$/) {
        $buf_word .= $chars->{Data};
    }
}


package MyReferenceParser;

sub extract_references {
    my ($pattern) = @_;
    my %res;
    
    use HTML::TokeParser;
    use Encode('decode');

    foreach my $file (glob($pattern)) {
        
        #Can't do this directly because it's not utf encoded
        #my $p = HTML::TokeParser->new($file);
        
        open(HTML, "< $file");
        my $content = join('', <HTML>);
        $content = decode('euc-cn', $content);
        my $p = HTML::TokeParser->new(\$content);
        #my $p = HTML::TokeParser->new($content);
        &parse_reference_file($p, \%res);
        
    }
    
    return (%res);

}


sub parse_reference_file {
    my ($p, $h_fileids) = @_;  #TokeParser

    my @lines;
    my $buffer = '';
    my $font_size = -1;
    my $bold_is_set = 0;
    my $fileid;

    my $state = 'START';
    
    while (my $tag = $p->get_tag('p', 'b', 'font', 'span', 'a', '/p', '/b', '/span', '/a')) {
        #print join("\t", $tag->[0], $state, $bold_is_set, $font_size, $fileid, $buffer), "\n";
        if ($state eq 'START') {
            if ($tag->[0] eq 'p') {
                $state = 'LOOP';
                next;
            } elsif ($tag->[0] eq 'font') {
                # oops, they didn't open their p tag
                $state = 'LOOP';
                next;
            } else {
                next;
            }
        }

        if ($state eq 'LOOP') {
            if ($tag->[0] eq 'p') {
                # oops, they didn't close their p tag
                ($bold_is_set, $font_size, $fileid, $h_fileids, $buffer, @lines) = _state_close_p($bold_is_set, $font_size, $fileid, $h_fileids, $buffer, @lines);
                $state = 'LOOP';
                next;
            }
            if ($tag->[0] eq 'b') {
                $bold_is_set = 1;
                $buffer .= $p->get_text();
                next;
            } elsif ($tag->[0] eq '/b') {
                #$bold_is_set = 0;
                next;
            } elsif ($tag->[0] eq 'span') {
                $buffer .= $p->get_text();
                next;
            } elsif ($tag->[0] eq '/span') {
                $buffer .= $p->get_text();
                next;
            } elsif ($tag->[0] eq 'a') {
                $buffer .= $p->get_text();
                next;
            } elsif ($tag->[0] eq '/a') {
                $buffer .= $p->get_text();
                next;
            } elsif ($tag->[0] eq 'font') {
                if ($tag->[1]{size}) {
                    $font_size = $tag->[1]{size};
                    $buffer .= $p->get_text();
                    next;
                }
            } elsif ($tag->[0] eq '/p') {
                ($bold_is_set, $font_size, $fileid, $h_fileids, $buffer, @lines) = _state_close_p($bold_is_set, $font_size, $fileid, $h_fileids, $buffer, @lines);
                $state = 'START';

            } else {
                next;
            }
        }

    }
    
    # The last one is left hanging
    my $text = join("\n", @lines);
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    $h_fileids->{$fileid} = $text;
}


sub _state_close_p {
    # This function could have been done inline as part of the </p> state. But it also needs to be called for a new <p> when
    #  the preceeding </p> is missing. This avoids code duplication
    my ($bold_is_set, $font_size, $fileid, $h_fileids, $buffer, @lines) = @_;

                #if ($bold_is_set and $font_size eq '2') {   # Most headings are <b><font size=2>. But a few are just <b><font>, so we can't be that specific
                if ($bold_is_set and $font_size ne '4') {
                    # Indicates a fileid heading
                    if ($fileid) {
                        # save data from the previous fileid
                        my $text = join("\n", @lines);
                        $text =~ s/^\s+//;
                        $text =~ s/\s+$//;
                        $h_fileids->{$fileid} = $text;
                        @lines = ();
                    }

                    $fileid = $buffer;

                } elsif (!$bold_is_set) {
                    #a regular paragraph
                    $buffer =~ s/\r?\n/ /g;
                    $buffer =~ s/\s{3,}/  /g;   # We can no longer tell which were original non-effectual whitespace vs. explicit nbsp. Let's just give a little extra space to make it look similar
                    push @lines, $buffer;
                }

                $buffer = '';
                $font_size = -1;
                $bold_is_set = 0;

    return ($bold_is_set, $font_size, $fileid, $h_fileids, $buffer, @lines)
}



# Parts of Speech
package MyPOSParser;

sub extract_pos {
    my ($infile) = @_;
    open(IN, "< $infile") or die $!;

    my @pos;
    
    while (<IN>) {
        chomp;
        next if (/^\s*$/);
        my ($id, $desc) = split(/\t/, $_, 2);
        
        push @pos, [$id, $desc];

    }

    return (@pos);

}

package main;

use DBI;
use XML::SAX::ParserFactory;

# Flush standard output
{
    my $old_handle = select (STDOUT);
    $| = 1;
    select ($old_handle);
}

binmode STDOUT, ":utf8";  # avoid "Wide character in print" warnings


&log("Parsing references from $refpattern ...");
my %refs = MyReferenceParser::extract_references($refpattern);
&log("    References parsed (", scalar(keys %refs), " file ids)");


&log("Parsing parts of speech from $infile_pos ...");
my @pos = MyPOSParser::extract_pos($infile_pos);
&log("    Parts of speech parsed (", scalar(@pos), " records)");


my $dbh = &create_database($sql_create, $dbname) || exit 2;
&log("Database created");

write_object($dbh, {'pos'=>[@pos]}, 'pos');
&log("Parts of speech table loaded");


foreach my $xmlfile (glob($corpattern)) {
    my $handler = MySAXHandler->new(\%refs);
    my $parser = XML::SAX::ParserFactory->parser(Handler => $handler );

    &log("Parsing file $xmlfile ...");

    $parser->parse_uri($xmlfile);

    my $content = $handler->{content};

    eval {
        write_object($dbh, $content, 'texts', 'files', 'words', 'full_sentences', 'characters');
        $dbh->commit;   # commit the changes if we get this far
    };
    if ($@) {
        &log("    Transaction aborted because $@");
        eval { $dbh->rollback };
    }
    
    &log("    Finished $xmlfile");
}

foreach my $xmlfile (glob($corpattern_pinyin)) {
    my $handler = MyPinyinSAXHandler->new();
    my $parser = XML::SAX::ParserFactory->parser(Handler => $handler );

    &log("Parsing pinyin file $xmlfile ...");

    $parser->parse_uri($xmlfile);

    my $content = $handler->{content};

    eval {
        write_object($dbh, $content, 'pinyin_words', 'pinyin_full_sentences', 'pinyin_characters');
        $dbh->commit;   # commit the changes if we get this far
    };
    if ($@) {
        &log("    Transaction aborted because $@");
        eval { $dbh->rollback };
    }
    
    &log("    Finished $xmlfile");

}


exit 0;






sub create_database {
    my ($sqlfile, $dbfile) = @_;

    if (-e $dbfile) {
        rename($dbfile, "$dbfile.99");
        if (-e $dbfile) {
            &log("Couldn't rename the database '$dbfile' to '$dbfile.99' -- exiting\n");
            exit 1;
        }
    }

    open(IN, "< $sqlfile") or die "Couldn't open sql file '$sqlfile': $!\n";
    my $sql;

    my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","") or die $!;
    #$dbh->{unicode} = 1;  #deprecated
    $dbh->{sqlite_unicode} = 1;
    
    $dbh->{AutoCommit} = 0;
    $dbh->{RaiseError} = 0;

    my $num_errors = 0;

    my $table_name = '';
    while (<IN>) {
        $sql .= $_;
        if (($table_name eq '') and $_ =~ /CREATE TABLE (\w+)/i) {
            $table_name = $1;
        }
        if (/;/) {
            eval { $dbh->do($sql) }; 

            if ($@ || $dbh->err()) {
                ++$num_errors;
                print "    *ERROR creating table '$table_name': ", $dbh->errstr, "\n\n";   # is $DBI::errstr the same thing?
                next;
            }

            &log("CREATE TABLE '$table_name'\t\tOK!");
            $sql = '';
            $table_name = '';
        }

        $dbh->commit;   # commit the changes if we get this far
    }

    if ($num_errors) {
        print "*** There were errors creating the database\n";
        return undef;
    } else {
        return $dbh;
    }

}

    

sub write_object {
    my ($dbh, $content, @targets) = @_;

    my %sql = (
        texts => '?, ?',
        files => '?, ?, ?',
        words => '?, ?, ?, ?, ?, ?, ?, ?, ?',
        full_sentences => '?, ?, ?, ?, ?',
        characters => '?, ?, ?, ?, ?, ?, ?',
        pos => '?, ?',
        pinyin_words => '?, ?, ?, ?, ?, ?, ?, ?, ?',
        pinyin_full_sentences => '?, ?, ?, ?, ?',
        pinyin_characters => '?, ?, ?, ?, ?, ?, ?',
        
    );
        
    foreach my $target (@targets) {
        my $sth = $dbh->prepare("INSERT INTO $target VALUES ($sql{$target})");
        foreach my $obj (@{$content->{$target}}) {
            my $rows_affected = $sth->execute(@$obj);
            if ($rows_affected != 1) {
                print "*Error: $target: $rows_affected, ", $dbh->errstr, "\n";
            }
        }
    }
    
    $dbh->commit;   # commit the changes if we get this far

}


sub dump_object {
    my ($content, $target) = @_;
    open(OUT, "$target.txt") or die $!;
    #open(OUT, ">:utf8", "$target.txt") or die $!;

    foreach my $obj (@{$content->{$target}}) {
        #use Data::Dumper; print Dumper $obj; exit 0;
        print OUT join("\t", @$obj), "\n";
    }
    
    close OUT;
}

sub log {
    my (@msg) = @_;
    print scalar(localtime), "\t", join('', @msg), "\n";
}


__END__


/***********/

SELECT TOP 100 A.*, B.characters, C.characters, B.part_of_speech, C.part_of_speech
FROM words A
join words B on A.file_id = B.file_id and A.sentence_id = B.sentence_id and A.word_num + 1 = B.word_num
join words C on A.file_id = C.file_id and A.sentence_id = C.sentence_id and A.word_num + 2 = C.word_num
WHERE A.part_of_speech = 'p'

/* sample - how to get random words (SQL Server) */
select TOP 100 W.file_id, T.type, W.characters, S.characters from words W , full_sentences S, texts T
where W.file_id = S.file_id and W.sentence_id = S.sentence_id
AND W.text_id = T.id
and W.part_of_speech = 'p' and len(S.characters) between 10 and 24
and W.characters NOT IN (N'?')
order by NEWID()


/* find sentences containing a specific token */
select W.file_id, T.type, W.characters, W.part_of_speech, S.characters
from words W
join full_sentences S on W.file_id = S.file_id and W.sentence_id = S.sentence_id
join texts T on S.text_id = T.id
where W.characters like N'??' and len(S.characters) < 25
