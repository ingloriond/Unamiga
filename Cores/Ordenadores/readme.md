# Msx1Fpga

### Core portado por Jose Manuel @delgrom

MSX1 cloned in FPGA

Este projecto es un MSx1 clonado a FPGA, con algunas partes del projecto OCM

##### Características:

Multiple placas

MSX1 50Hz o 60Hz

Tamaño RAM Mapper configurable

128K Nextor (MSX-DOS2 evolución) ROM con driver SD

Megaram SCC/SCC+ del projecto OCM (tamañó configurable)

Mapa de teclado configurables

15/31KHz selecccionable

Scanlines seleccionable

Hay un loader (IPL) para arrancar y cargar las ROMs y configuraciones desde la SD.


##### Instrucciones de Uso:

Formatear una SD en formato FAT16 (máximo 4gb), descomprime el filechero 'msx1_sd_files.zip' en la raiz de la SD.

Teclas de función:

Print Screen: VGA//15KHZ

Scroll Lock: Scanlines modes

Pause/Break: 50/60 Hz Frecuencia Vertical

F11: Modo Turbo

CTRL+ALT+DEL: Soft Reset

CTRL+ALT+F12: Hard Reset

CTRL+ALT+BACKSPACE: Sólo para ZX-Uno : Recarga FPGA;

Left ALT: MSX GRAPH Tecla;

Right ALT: MSX CODE Tecla;

Page Up: MSX SELECT Tecla;

END: MSX STOP Tecla.

El puerto de joystick esta mapeado como JooyMega, y configurado para usar un SEGA Genesis/Megadrive joypad.

Para ir al BASIC desde MSX-DOS tienes que ejecutar el commando BASIC

Para ir al MSX-DOS desde BASIC, se ha de ejecutar CALL SYSTEM.

##### NOTAS:

En BASIC usa las teclas "CTRL + STOP" para parar la ejecución de un programa. La tecla MSX STOP está mapeada a la tecla END del PC.
Para cambiar del modo de video de 50HZ a 60HZ, y jugar a la velocidad correcta juegos PAL, como " La Invasion de  los Mounstraos 
Zombies", por VGA tienes que usar el programa "DISPLAY.COM", lo podeis bajar de este hilo (https://www.msx.org/forum/msx-talk/software/dos-tool-to-switch-from-50-to-60hz).

SOFTWARE LOADING:
A.- .ROM files
They are dumps of programs in cartridges.

Uses the SROM.COM utility to load the ROMs file. Ex: SROM NEMESIS1.ROM

B.- .DSK files
They are dumps of programs in disketes.

Uses the SRI.COM utility to emulate a disk. Ex: SRI GAME.DSK

C.- .CAS files
They are images with the content of the audio tapes. The way to use them is very well explained in the article Load CAS files with MegaFlashROM and an MSX-2 (hhttps://programbytes48k.wordpress.com/2015/11/19/cargar-archivos-cas-con-megaflashrom-y-un-msx-2/).

The LOADCAX and LOADCAXX files are located in the BIN folder on the diskette http://www.msxcartridgeshop.com/bin/ROMDISK.DSK of the MegaFlashROM SCC+ SD.

D.- .BAS files
They are programs in BASIC that we can record in the SD, and also load them to execute them. From inside the BASIC we can type:

SAVE "A:HOLA.BAS"
to save the program, and with

LOAD "A:HOLA.BAS"
we recover it.

To know the differences between CSAVE, BSAVE and SAVE, or other commands to store and retrieve the information, you can consult this section (https://www.msx.org/wiki/Category:Disk_BASIC) with the Disk BASIC commands of the wiki from msx.org (https://www.msx.org/wiki/).

To load a .BAS file from Nextor-DOS, simply write its name with or without extension and press ENTER.

E.- AUDIO IN
The core allows the loading of programs by audio. The way to do it is from BASIC with the commands:

RUN”CAS:”
or well:

BLOAD”CAS:”,R
or well:

LOAD”CAS:”,R
Do not forget to disable TURBO to load a real K7 audio.

It is perfectly explained in the article How to load programs in MSX (https://programbytes48k.wordpress.com/2012/01/04/como-cargar-programas-en-msx/).

In the (http://www.vintagenarios.com/hilo-oficial-wavs-msx-t1997.html) forum of Vintagenarios you can find many MSX programs in WAV format that can be loaded by audio.
