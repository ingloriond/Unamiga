# Clock constraints

create_clock -name "clock_50_i" -period 20.0 [get_ports {clock_50_i}]
create_clock -name {stm_b13_io}  -period 41.666 -waveform { 20.8 41.666 } [get_ports {stm_b13_io}]

# Automatically constrain PLL and other generated clocks
derive_pll_clocks -create_base_clocks

# Automatically calculate clock uncertainty to jitter and other effects.
derive_clock_uncertainty

# Clock groups
set_clock_groups -asynchronous -group [get_clocks {stm_b13_io}] -group [get_clocks {pll|altpll_component|auto_generated|pll1|clk[*]}]

# SDRAM delays
set_input_delay -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -max 6.4 [get_ports sdram_da[*]]
set_input_delay -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -min 3.2 [get_ports sdram_da[*]]

set_output_delay -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -max 1.5 [get_ports {sdram_d* sdram_a* sdram_ba_o SDRAM_n* sdram_cke_o}]
set_output_delay -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -min -0.8 [get_ports {sdram_d* sdram_a* sdram_ba_o SDRAM_n* sdram_cke_o}]

# Some relaxed constrain to the VGA pins. The signals should arrive together, the delay is not really important.
set_output_delay -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -max 0 [get_ports {vga_*}]
set_output_delay -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -min -5 [get_ports {vga_*}]
set_multicycle_path -to [get_ports {vga_*}] -setup 3
set_multicycle_path -to [get_ports {vga_*}] -hold 3

# T80 just cannot run in 64 MHz, but it's safe to allow 2 clock cycles for the paths in it
set_multicycle_path -from {Amstrad_motherboard:motherboard|T80pa:CPU|T80:u0|*} -setup 2
set_multicycle_path -from {Amstrad_motherboard:motherboard|T80pa:CPU|T80:u0|*} -hold 2

set_multicycle_path -from {video_mixer:video_mixer|scandoubler:sd|Hq2x:Hq2x|*} -setup 2
set_multicycle_path -from {video_mixer:video_mixer|scandoubler:sd|Hq2x:Hq2x|*} -hold 2

set_multicycle_path -to {u765:u765|i_rpm_time[*][*][*]} -setup 4
set_multicycle_path -to {u765:u765|i_rpm_time[*][*][*]} -hold 4

# False paths

# Don't bother optimizing sigma_delta_dac
set_false_path -to {sigma_delta_dac:*}

#set_false_path -to [get_ports {VGA_*}]
set_false_path -to [get_ports {dac_r_o}]
set_false_path -to [get_ports {dac_l_o}]
