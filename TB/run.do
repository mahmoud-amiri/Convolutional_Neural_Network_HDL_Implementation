# Check if the 'work' library exists and delete it if present
if {[file exists "work"]} {
    vdel -all
}
vlib work

# Function to compile files listed in a text file
proc compile_files {filename command} {
    set file_list [open $filename r]
    while {[gets $file_list file] >= 0} {
        if {[string trim $file] ne ""} {
            eval "$command $file"
        }
    }
    close $file_list
}

# Compile the design files from the text files
#compile_files "vhdl_files.txt" "vcom -2008 -work work"
compile_files "sv_files.txt" "vlog -sv -work work"
compile_files "verilog_files.txt" "vlog -work work"

# Optimize the testbench design
vopt work.PingPongController_tb -o tb_optimized +acc

# Load and simulate the testbench
vsim -lib work tb_optimized


# Setup for simulation
set NoQuitOnFinish 1
onbreak {resume}
log /* -r
add wave -r /*

# Run the simulation
run -all

# Save waveforms if waves.do file exists
if {[file exists "waves.do"]} {
    do waves.do
    wave save waves.wlf
}
quit
