onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/clk_sys
add wave -noupdate /tb/reset
add wave -noupdate -radix hexadecimal /tb/sd_lba
add wave -noupdate /tb/sd_rd_s
add wave -noupdate /tb/sd_wr
add wave -noupdate /tb/sd_ack
add wave -noupdate /tb/imc_ctrl/state_s
add wave -noupdate -radix hexadecimal /tb/dsk_addr_s
add wave -noupdate -divider {New Divider}
add wave -noupdate -radix hexadecimal /tb/sd_buff_addr
add wave -noupdate -radix hexadecimal /tb/sd_buff_din
add wave -noupdate -radix hexadecimal /tb/sd_buff_dout
add wave -noupdate /tb/sd_buff_wr
add wave -noupdate -divider {New Divider}
add wave -noupdate /tb/u765/ce
add wave -noupdate /tb/u765/ds0
add wave -noupdate /tb/u765/sd_buff_type
add wave -noupdate /tb/u765/hds
add wave -noupdate -divider {dual port ram}
add wave -noupdate -expand -group {New Group} /tb/u765/sbuf/clock
add wave -noupdate -expand -group {New Group} -radix hexadecimal /tb/u765/sbuf/address_a
add wave -noupdate -expand -group {New Group} -radix hexadecimal /tb/u765/sbuf/q_a
add wave -noupdate -expand -group {New Group} -radix hexadecimal /tb/u765/sbuf/data_a
add wave -noupdate -expand -group {New Group} /tb/u765/sbuf/wren_a
add wave -noupdate -expand -group {New Group} -radix hexadecimal /tb/u765/sbuf/address_b
add wave -noupdate -expand -group {New Group} -radix hexadecimal /tb/u765/sbuf/q_b
add wave -noupdate -expand -group {New Group} -radix hexadecimal /tb/u765/sbuf/data_b
add wave -noupdate -expand -group {New Group} /tb/u765/sbuf/wren_b
add wave -noupdate -divider {New Divider}
add wave -noupdate /tb/u765/#ublk#0#211/image_scan_state
add wave -noupdate /tb/u765/#ublk#0#211/i_scan_lock
add wave -noupdate /tb/u765/#ublk#0#211/image_ready
add wave -noupdate /tb/u765/#ublk#0#211/image_edsk
add wave -noupdate /tb/u765/#ublk#0#211/sd_busy
add wave -noupdate /tb/u765/buff_wait
add wave -noupdate -divider {track offsets}
add wave -noupdate -radix hexadecimal /tb/u765/image_track_offsets
add wave -noupdate -radix hexadecimal /tb/u765/image_track_offsets_addr
add wave -noupdate -radix hexadecimal /tb/u765/image_track_offsets_in
add wave -noupdate -radix hexadecimal /tb/u765/image_track_offsets_out
add wave -noupdate /tb/u765/image_track_offsets_wr
add wave -noupdate -divider {New Divider}
add wave -noupdate /tb/u765/#ublk#0#211/state
add wave -noupdate -radix hexadecimal /tb/u765/#ublk#0#211/i_seek_pos
add wave -noupdate /tb/u765/#ublk#0#211/i_current_sector_pos
add wave -noupdate -radix unsigned /tb/u765/#ublk#0#211/i_rpm_timer
add wave -noupdate /tb/u765/#ublk#0#211/i_r
add wave -noupdate /tb/a0
add wave -noupdate /tb/din
add wave -noupdate /tb/nWR
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {157648 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 296
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {143279 ns} {145039 ns}
