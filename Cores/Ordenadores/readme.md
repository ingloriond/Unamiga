# Msx1Fpga

### Core portado por Jose Manuel @delgrom | https://github.com/fbelavenuto/msx1fpga

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

CARGA DE SOFTWARE:
A.- ficheros .ROM
Son volcados de programas en cartuchos.

Usa la utilidad SROM.COM para cargar las ROMs. Ex: SROM NEMESIS1.ROM

B.- ficheros .DSK
Son volcados de  programas en disketes.

Usa la utilidad SRI.COM para emular un disco. Ex: SRI GAME.DSK

C.- .CAS files
Son imágenes con el contenido de cintas de audio. La manera de usarlas esta muy bien explicado en  el artículo "Load CAS files with MegaFlashROM and an MSX-2" (https://programbytes48k.wordpress.com/2015/11/19/cargar-archivos-cas-con-megaflashrom-y-un-msx-2/).

Los ficheros LOADCAX y LOADCAXX se encuentran en la carpeta BIN del diskette http://www.msxcartridgeshop.com/bin/ROMDISK.DSK del MegaFlashROM SCC+ SD.

D.- ficheros .BAS
Son programas en BASICque pueden ser grabados en la SD, y también cargarlos y ejecutarlos. Desde BASIC podemos teclear:

SAVE "A:HOLA.BAS"
para grabar un programa, y con

LOAD "A:HOLA.BAS"
recuperarlo.

Para saber las diferencias entre los comandos CSAVE, BSAVE and SAVE, y otros comandos para almacenar y recuperar informacion, puedes consultar esta secciñon (https://www.msx.org/wiki/Category:Disk_BASIC) with the Disk BASIC commands of the wiki from msx.org (https://www.msx.org/wiki/).

Para cargar un fichero .BAS desde Nextor-DOS, simplemente esribe su nombre con o sin  extensión y presiona ENTER.

E.- Entrada de AUDIO
El core permite la carga de programas de audio. La manera de hacerlo es mediante los siguientes comandos de BASIC:

RUN”CAS:”
o mejor:

BLOAD”CAS:”,R
o mejor:

LOAD”CAS:”,R
No olvidar deshabilitar el TURBO para cargar audio K7 real.

Esto esta perfectamente explicado en el artículo "How to load programs in MSX" (https://programbytes48k.wordpress.com/2012/01/04/como-cargar-programas-en-msx/).

En el foro de (http://www.vintagenarios.com/hilo-oficial-wavs-msx-t1997.html)Vintagenarios puedes encontrart muchos programas de MSX en formato WAV y cargarlos via audio.
