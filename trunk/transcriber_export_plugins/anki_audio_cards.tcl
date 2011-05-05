################################################################
##
# Export plugin suitable for Anki file import
#
# This plugin creates a tab-delimited file (file ending *.tab) with fields
# useful for importing into Anki (http://ankisrs.net/) to create new cards.
# This format works in combination with the "Audacity Labels" export, as
# Audacity's function Export Multiple can split the original audio with
# filenames matching row data from this plugin.
#
# When sections are named with the current topic, this title is used as an
# output column. The topic field is intended for use on the card front
# along with the audio clip, to indicate the context of the clip.
#
# When the episode attribute "Program" is set, this is inserted as a comment
# at the top of the file. Multiple lines in this comment can be delimited
# with the string "<eol>". While this information doesn't get imported into
# Anki, it can be useful for reference purposes if the import file is kept.
#
# The output format is:
# (line 1)       tags:{episode name} audio
# (line 2)       #Basename <tab> Reading <tab>Topic <tab> Sequence
# (line 3...)    #{comments}
# (lines 4..end) {episode}-{start msec} <tab> {turn contents} <tab> {section title} <tab> {line number within section}
#
# The data "{episode}-{start msec}" is the same string used in the Audacity
# labels. When using Audacity's Export Multiple function, be sure to select
# "Name files using label/track name".
#
# Transcriber's timing is slightly inaccurate. Real times are 99.54% of those
# reported by Transcriber. This plugin compensates for that factor, so that
# Audacity creates the segment files in the correct places.
#
#
# @author Chad Redman
# @since 2011-05-04
# @version 1.0, 2011-05-04
# @link xxxxxxxxxxxx Source	
# @license http://www.gnu.org/licenses/gpl-2.0.html GNU General Public License, version 2 (see COPYING file)
##
################################################################

namespace eval anki_audio_cards {

    variable msg "Anki Audio Cards"
    variable ext ".tab"

    proc filename_replace val {
        regsub -all ":" $val {_} val
        regsub -all "\\." $val {_} val
        regsub -all " " $val {-} val
        return $val
    }

    proc export {filename} {
        global v

        # The times in Transcriber are a little off. This corrects it by the appropriate factor
        variable lengthfix 0.995472

        variable time ""
        variable msec 0
        variable text ""
        variable topic ""

        set basename [filename_replace [file root [file tail $v(sig,name)]]]

        set channel [open $filename w]
        if {![catch {encoding system}]} {
            fconfigure $channel -encoding [EncodingFromName $v(encoding)]
        }

        puts $channel "tags:$basename audio"
        puts $channel "#Basename\tReading\tTopic\tSequence"

        set episode [$v(trans,root) getChilds "element" "Episode"]

        set episodeName [$episode getAttr program]
        regsub -all "<eol>" $episodeName "\n#" episodeName
        puts $channel "#$episodeName"

        foreach sec [$episode getChilds "element" "Section"] {
            variable seqnum 0
            set topic [::section::short_name $sec]

            foreach tur [$sec getChilds "element" "Turn"] {
                foreach chn [$tur getChilds] {
                    if {[$chn class] == "data"} {
	                set text [$chn getData]

                        set timems [format "%07d" $msec]
                        incr seqnum
                        puts $channel "$basename-$timems\t$text\t$topic\t$seqnum"
	            } elseif {[$chn getType] == "Sync"} {
                        set ts [expr [$chn getAttr "time"] * $lengthfix]
                        set newtime [format "%.3f" $ts]
                        if {$time == "" || $newtime > $time} {
                            set time $newtime
                            set msec [expr int($ts * 1000)]
                            #set text [$chn getData]
                            #set text [StringOfEvent $chn]
                        }
                    }

                }
            }
        }
        close $channel
    }

}
