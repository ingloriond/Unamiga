##
## DEVICE  "EP3C25E144C8"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {clock_50_i} -period 20.000 -waveform { 0.000 10.000 } [get_ports {clock_50_i}]
create_clock -name {SPI_SCK}  -period 27.777  [get_ports {SPI_SCK}]
# create_clock -name {u_frame|u_board|u_scandoubler|vga_hsync} -period 31777.000 -waveform { 0.000 15888.500 }


#**************************************************************
# Create Generated Clock
#**************************************************************

derive_pll_clocks -create_base_clocks

create_generated_clock -name SDRAM_CLK -source \
    [get_pins {u_pll_game|altpll_component|auto_generated|pll1|clk[2]}] \
    -divide_by 1 \
    [get_ports SDRAM_CLK]



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************
derive_clock_uncertainty

#**************************************************************
# Set Input Delay
#**************************************************************

# This is tAC in the data sheet. It is the time it takes to the
# output pins of the SDRAM to change after a new clock edge.
# This is used to calculate set-up time conditions in the FF
# latching the signal inside the FPGA
set_input_delay -clock SDRAM_CLK -max 6 [get_ports SDRAM_DQ[*]]

# This is tOH in the data sheet. It is the time data is hold at the
# output pins of the SDRAM after a new clock edge.
# This is used to calculate hold time conditions in the FF
# latching the signal inside the FPGA (3.2)
set_input_delay -clock SDRAM_CLK -min 3 [get_ports SDRAM_DQ[*]]

#**************************************************************
# Set Output Delay
#**************************************************************

# This is tDS in the data sheet, setup time, spec is 1.5ns
set_output_delay -clock SDRAM_CLK -max 1.5 \
    [get_ports {SDRAM_A[*] SDRAM_BA[*] SDRAM_CKE SDRAM_DQMH SDRAM_DQML \
                SDRAM_DQ[*] SDRAM_nCAS SDRAM_nCS SDRAM_nRAS SDRAM_nWE}]
# This is tDH in the data sheet, hold time, spec is 0.8ns
set_output_delay -clock  SDRAM_CLK -min -0.8 \
    [get_ports {SDRAM_A[*] SDRAM_BA[*] SDRAM_CKE SDRAM_DQMH SDRAM_DQML \
                SDRAM_DQ[*] SDRAM_nCAS SDRAM_nCS SDRAM_nRAS SDRAM_nWE}]



#**************************************************************
# Set Clock Groups
#**************************************************************

set_clock_groups -asynchronous -group [get_clocks {SPI_SCK}] -group [get_clocks {*|altpll_component|auto_generated|pll1|clk[*]}]
set_clock_groups -asynchronous -group [get_clocks {u_pll_game|altpll_component|auto_generated|pll1|clk[1]}] -group [get_clocks {u_pll_vga|altpll_component|auto_generated|pll1|clk[0]}]

#**************************************************************
# Set False Path
#**************************************************************

set_false_path -to [get_ports {AUDIO_L}]
set_false_path -to [get_ports {AUDIO_R}]
set_false_path -to [get_ports {VGA_*}]

# These are static signals that don't need to be concerned with
set_false_path -from [get_registers {u_frame|u_board|u_dip|enable_psg}]
set_false_path -from [get_registers {:u_frame|u_board|u_dip|enable_fm}]

#**************************************************************
# Set Multicycle Path
#**************************************************************

#set_multicycle_path -from [get_clocks {u_pll_game|altpll_component|auto_generated|pll1|clk[1]}] -to [get_clocks {u_pll_game|altpll_component|auto_generated|pll1|clk[2]}] -end 2

#set_multicycle_path -from [get_clocks {u_pll_game|altpll_component|auto_generated|pll1|clk[1]}] -to [get_clocks {u_pll_game|altpll_component|auto_generated|pll1|clk[2]}] -start 2

#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************



#**************************************************************
# Set Input Delay
#**************************************************************

set_input_delay -clock SPI_SCK -max 6.4 [get_ports SPI_DI]
set_input_delay -clock SPI_SCK -min 3.2 [get_ports SPI_DI]
set_input_delay -clock SPI_SCK -max 6.4 [get_ports SPI_SS*]
set_input_delay -clock SPI_SCK -min 3.2 [get_ports SPI_SS*]
#
#

set_output_delay -add_delay -max -clock SPI_SCK  6.4 [get_ports SPI_DO]
set_output_delay -add_delay -min -clock SPI_SCK  3.2 [get_ports SPI_DO]
