################################################################
##
# Export plugin suitable for Audacity label import
#
# This plugin creates a tab-delimited file in a format that can be
# read by Audacity to create a label track. This format works in
# combination with the "Anki Audio Cards" export, as Audacity's function
# Export Multiple can split the original audio with filenames matching row
# data from this plugin.
#
# The output format is:
# {start sec} <tab> {episode}-{start msec}
#
# The data "{episode}-{start msec}" is the same string used in the Anki Audio
# Cards data. When using Audacity's Export Multiple function, be sure to select
# "Name files using label/track name". This will enable the Anki deck to refer
# to the correct mp3 file.
#
# Transcriber's timing is slightly inaccurate. Real times are 99.54% of those
# reported by Transcriber. This plugin compensates for that factor, so that
# Audacity creates the segment files in the correct places.
#
#
# @author Chad Redman
# @since 2011-05-04
# @link http://svn.zhtoolkit.com/small_utilities/trunk/transcriber_export_plugins/audacity_labels.tcl Source	
# @license http://www.gnu.org/licenses/gpl-2.0.html GNU General Public License, version 2 (see COPYING file)
##
################################################################

namespace eval audacity_labels {

    variable msg "Audacity Labels"
    variable ext "-labels.txt"

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

        set basename [filename_replace [file root [file tail $v(sig,name)]]]

        set channel [open $filename w]
        set episode [$v(trans,root) getChilds "element" "Episode"]
        foreach sec [$episode getChilds "element" "Section"] {
            foreach tur [$sec getChilds "element" "Turn"] {
                foreach chn [$tur getChilds] {
                    if {[$chn getType] == "Sync"} {
                        set ts [expr [$chn getAttr "time"] * $lengthfix]
                        set newtime [format "%.3f" $ts]
                        if {$time == "" || $newtime > $time} {
                            set time $newtime
                            set msec [expr int($ts * 1000)]
                        }
                        
                        set timems [format "%07d" $msec]
                        puts $channel "$time\t$basename-$timems"

                    }
                }
            }
        }
        close $channel
    }

}
