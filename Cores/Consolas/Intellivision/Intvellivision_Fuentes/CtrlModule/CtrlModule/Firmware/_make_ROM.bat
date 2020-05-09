
	sed 's/dualportram/CtrlROM_ROM/' >CtrlROM_ROM.vhd <..\..\ZPUFlex\RTL\rom_prologue.vhd
	"..\..\ZPUFlex\Firmware\zpuromgen.exe" CtrlROM.bin >>CtrlROM_ROM.vhd
	copy CtrlROM_ROM.vhd + ..\..\ZPUFlex\RTL\rom_epilogue.vhd CtrlROM_ROM.vhd