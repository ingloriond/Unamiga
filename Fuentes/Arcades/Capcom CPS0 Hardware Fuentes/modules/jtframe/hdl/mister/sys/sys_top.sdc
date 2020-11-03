# Specify root clocks
create_clock -period "50.0 MHz" [get_ports FPGA_CLK1_50]
create_clock -period "50.0 MHz" [get_ports FPGA_CLK2_50]
create_clock -period "50.0 MHz" [get_ports FPGA_CLK3_50]
create_clock -period "100.0 MHz" [get_pins -compatibility_mode *|h2f_user0_clk] 
create_clock -period 10.0 [get_pins -compatibility_mode spi|sclk_out] -name spi_sck

derive_pll_clocks

# Specify PLL-generated clock(s)
#create_generated_clock -name SDRAM_CLK -source [get_pins {emu|pll|pll_inst|altera_pll_i|outclk_wire[1]~CLKENA0|outclk}] [get_ports {SDRAM_CLK}]

create_generated_clock -source [get_pins -compatibility_mode {pll_hdmi|pll_hdmi_inst|altera_pll_i|cyclonev_pll|counter[0].output_counter|divclk}] \
                       -name HDMI_CLK [get_ports HDMI_TX_CLK]


derive_clock_uncertainty

#############################################################
### SDRAM  AS4C16M16SA
### Pins:
### SDRAM_A, SDRAM_DQ, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, 
### SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS, SDRAM_BA, SDRAM_CLK, SDRAM_CKE,

#set SDRAM_CLK emu|pll|pll_inst|altera_pll_i|outclk_wire[1]~CLKENA0|outclk
#set SDRAM_CLK {emu|pll|pll_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}
# if there is no phase shift, then output 1 gets deleted and
# SDRAM is output 0
set SDRAM_CLK {emu|pll|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}


# This is tHS in the data sheet (setup time)
set_output_delay -clock $SDRAM_CLK \
    -max 1.5 [get_ports SDRAM_*] -reference_pin SDRAM_CLK
# This is tiH in the data sheet (hold time), 0.8ns in data sheet. Using 1.5ns for extra margin
set_output_delay -clock $SDRAM_CLK \
    -min 1.5 [get_ports SDRAM_*] -reference_pin SDRAM_CLK
# the above statement generates an output delay constraint for SDRAM_CLK pin itself
# that is not needed:
remove_output_delay SDRAM_CLK

# This is tAC in the data sheet
set_input_delay -clock $SDRAM_CLK -max 6 [get_ports SDRAM_DQ[*]] -reference_pin SDRAM_CLK
# this is tOH in the data sheet
set_input_delay -clock $SDRAM_CLK -min 2.5 [get_ports SDRAM_DQ[*]] -reference_pin SDRAM_CLK

##################################################################

# Decouple different clock groups (to simplify routing)
set_clock_groups -asynchronous \
   -group [get_clocks { *|pll|pll_inst|altera_pll_i|general[*].gpll~PLL_OUTPUT_COUNTER|divclk}] \
   -group [get_clocks { pll_hdmi|pll_hdmi_inst|altera_pll_i|cyclonev_pll|counter[0].output_counter|divclk}] \
   -group [get_clocks { *|h2f_user0_clk}] \
   -group [get_clocks { FPGA_CLK1_50 FPGA_CLK2_50 FPGA_CLK3_50}]

set_output_delay -max -clock HDMI_CLK 2.0ns [get_ports {HDMI_TX_D[*] HDMI_TX_DE HDMI_TX_HS HDMI_TX_VS}]
set_output_delay -min -clock HDMI_CLK -1.5ns [get_ports {HDMI_TX_D[*] HDMI_TX_DE HDMI_TX_HS HDMI_TX_VS}]

set_false_path -from {*} -to [get_registers {wcalc[*] hcalc[*]}]

# Put constraints on input ports
set_false_path -from [get_ports {KEY*}] -to *
set_false_path -from [get_ports {BTN_*}] -to *

# Put constraints on output ports
set_false_path -from * -to [get_ports {LED_*}]
set_false_path -from * -to [get_ports {VGA_*}]
set_false_path -from * -to [get_ports {AUDIO_SPDIF}]
set_false_path -from * -to [get_ports {AUDIO_L}]
set_false_path -from * -to [get_ports {AUDIO_R}]
