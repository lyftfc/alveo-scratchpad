# Parameters
# --board     Alveo board target to use
# --prjname   Project name to create, defaults to [board]-scratchpad
# --runjobs   Number of jobs (CPU threads) for synth/impl. Set 0 to skip run.

# Default board: Alveo U50
set board       au50

for {set i 0} {$i < $::argc} {incr i} {
  set option [string trim [lindex $::argv $i]]
  if { $option eq "--board" } {
    incr i
    set board [lindex $::argv $i]
  }
}

set board_dir boards/$board
set params_file $board_dir/params.tcl

if {![file exists $params_file]} {
  puts "ERROR: Board '$board' is not supported. File '$params_file' not found."
  exit 1
}

# Provides: prjpart prjboard
source $params_file

# Project name and directory under build dir
set prjname     ${board}_scratchpad
# Synth/Implementation Jobs, set 0 to disable
set run_njobs   0

for {set i 0} {$i < $::argc} {incr i} {
  set option [string trim [lindex $::argv $i]]
  switch -regexp -- $option {
    "--board"       { incr i }
    "--prjname"     { incr i; set prjname [lindex $::argv $i] }
    "--runjobs"     { incr i; set run_njobs [lindex $::argv $i] }
    default         { if { [regexp {^-} $option] }
        { puts "ERROR: Unknown option '$option' specified.\n"; exit 1 }
      }
  }
}

set prjpath     ./build/$prjname
set bdname      bd_top

# Create Project
create_project $prjname $prjpath -part $prjpart -force
set_property board_part $prjboard [current_project]

# Add Constraints
import_files -fileset constrs_1 -norecurse $board_dir/base.xdc
import_files -fileset constrs_1 -norecurse $board_dir/dut_floor.xdc
set_property used_in_synthesis false    [get_files $board_dir/dut_floor.xdc]

# Creating BD: provides cr_bd_bd_top
source $board_dir/${bdname}.tcl
cr_bd_bd_top ""

set_property REGISTERED_WITH_MANAGER "1" [get_files ${bdname}.bd ]
set_property SYNTH_CHECKPOINT_MODE "Hierarchical" [get_files ${bdname}.bd ]
set bd_wrap_file [ make_wrapper -files [get_files ${bdname}.bd] -top ]
add_files -norecurse $bd_wrap_file
update_compile_order -fileset sources_1

# Launch runs

if { $run_njobs != 0 } {
  # Synth
  launch_runs synth_1 -jobs $run_njobs
  wait_on_run synth_1
  # Implementation
  launch_runs impl_1 -jobs $run_njobs
  wait_on_run impl_1
  # Report timing
  set run_wns [ get_property STATS.WNS [get_runs impl_1] ]
  set run_tns [ get_property STATS.TNS [get_runs impl_1] ]
  puts "Implementation WNS/TNS (ns): $run_wns $run_tns"
}
