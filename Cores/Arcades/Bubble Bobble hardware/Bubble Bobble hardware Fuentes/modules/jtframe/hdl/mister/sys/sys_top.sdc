# Specify root clocks
create_clock -period "50.0 MHz" [get_ports FPGA_CLK1_50]
create_clock -period "50.0 MHz" [get_ports FPGA_CLK2_50]
create_clock -period "50.0 MHz" [get_ports FPGA_CLK3_50]
create_clock -period "100.0 MHz" [get_pins -compatibility_mode *|h2f_user0_clk]
create_clock -period "100.0 MHz" [get_pins -compatibility_mode spi|sclk_out] -name spi_sck

derive_pll_clocks
derive_clock_uncertainty

# Decouple different clock groups (to simplify routing)
set_clock_groups -exclusive \
   -group [get_clocks { *|pll|pll_inst|altera_pll_i|*[*].*|divclk}] \
   -group [get_clocks { pll_hdmi|pll_hdmi_inst|altera_pll_i|*[0].*|divclk}] \
   -group [get_clocks { *|h2f_user0_clk}] \
   -group [get_clocks { FPGA_CLK1_50 }] \
   -group [get_clocks { FPGA_CLK2_50 }] \
   -group [get_clocks { FPGA_CLK3_50 }]

set_false_path -from [get_ports {KEY*}]
set_false_path -from [get_ports {BTN_*}]
set_false_path -to [get_ports {LED_*}]
set_false_path -to [get_ports {VGA_*}]
set_false_path -to [get_ports {AUDIO_SPDIF}]
set_false_path -to [get_ports {AUDIO_L}]
set_false_path -to [get_ports {AUDIO_R}]
set_false_path -to {cfg[*]}
set_false_path -from {cfg[*]}
set_false_path -from {VSET[*]}
set_false_path -to {wcalc[*] hcalc[*]}

set_multicycle_path -to {*_osd|osd_vcnt*} -setup 2
set_multicycle_path -to {*_osd|osd_vcnt*} -hold 2
set_false_path -to {*_osd|v_cnt*}
set_false_path -to {*_osd|v_osd_start*}
set_false_path -to {*_osd|h_osd_start*}
set_false_path -from {*_osd|v_osd_start*}
set_false_path -from {*_osd|h_osd_start*}
set_false_path -from {*_osd|rot*}
set_false_path -from {*_osd|dsp_width*}
set_false_path -to {*_osd|half}

set_false_path -to   {WIDTH[*] HFP[*] HS[*] HBP[*] HEIGHT[*] VFP[*] VS[*] VBP[*]}
set_false_path -from {WIDTH[*] HFP[*] HS[*] HBP[*] HEIGHT[*] VFP[*] VS[*] VBP[*]}
set_false_path -to   {FB_BASE[*] FB_BASE[*] FB_WIDTH[*] FB_HEIGHT[*] FB_HMIN[*] FB_HMAX[*] FB_VMIN[*] FB_VMAX[*]}
set_false_path -from {FB_BASE[*] FB_BASE[*] FB_WIDTH[*] FB_HEIGHT[*] FB_HMIN[*] FB_HMAX[*] FB_VMIN[*] FB_VMAX[*]}
set_false_path -to   {vol_att[*] scaler_flt[*] led_overtake[*] led_state[*]}
set_false_path -from {vol_att[*] scaler_flt[*] led_overtake[*] led_state[*]}

set_false_path -from [get_keepers {emu:emu|jtframe_mister:u_frame|hps_io:u_hps_io|ioctl_index[*]}] -to [get_keepers {emu:emu|jtframe_mister:u_frame|jtframe_board:u_board|game_rst}]

set_false_path -from [get_keepers {emu:emu|jtframe_mister:u_frame|hps_io:u_hps_io|ioctl_download}] -to [get_keepers {emu:emu|jtframe_mister:u_frame|jtframe_board:u_board|game_rst}]

# These are static signals that don't need to be concerned with
set_false_path -from [get_registers {emu:emu|jtframe_mister:u_frame|jtframe_board:u_board|jtframe_dip:u_dip|enable_psg}]
set_false_path -from [get_registers {emu:emu|jtframe_mister:u_frame|jtframe_board:u_board|jtframe_dip:u_dip|enable_fm}]

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