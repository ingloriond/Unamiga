set_global_assignment -name VERILOG_MACRO "CORENAME=\"JT1943\""
set_global_assignment -name VERILOG_MACRO "VERTICAL_SCREEN=1"
set_global_assignment -name VERILOG_MACRO "HAS_TESTMODE=1"
set_global_assignment -name VERILOG_MACRO "GAMETOP=jt1943_game"
set_global_assignment -name VERILOG_MACRO "MISTTOP=jt1943_mist"
set_global_assignment -name VERILOG_MACRO "JT12=1"

set_global_assignment -name VERILOG_FILE ../../modules/jt12/jt49/hdl/filter/jt49_dcrm2.v
set_global_assignment -name VERILOG_FILE ../../modules/jt12/hdl/mixer/jt12_mixer.v
set_global_assignment -name VERILOG_MACRO "OSD_NOBCK=<None>"
