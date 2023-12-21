# Oric 48K en MiST y SiDi FPGA
fuente: https://github.com/rampa069/Oric_Mist_48K
## Reimplementación de Oric-1 y Oric Atmos en una FPGA moderna.

Actualmente Oric 1, Oric Atmos y Microdisc son completamente funcionales.

ULA HCS10017.

VÍA 6522.

procesador 6502.

64 KB completos de RAM.

Teclado gestionado por GI-8912.

Sonido (AY-3-8910).

ROM conmutable (entre la versión 1.1a ATMOS y la versión 1.0 ORIC 1).

Carga de cinta funcionando (a través del cable de audio en el pin RX).

Implementación de Oric Microdisc vía CUMULUS

Las operaciones de lectura/escritura de disco son totalmente compatibles con el formato EDSK (igual que amstrad cpc).

Sistema operativo Disc Sedoric/OricDOS Cargando completamente funcionando

### Pendiente

Depurando, comprobando posibles errores en el vídeo y mejorando el núcleo.
ERRORES CONOCIDOS
Ninguna por el momento..., pero si encuentras alguna, háznoslo saber, por favor.
CÓMO UTILIZAR UN ORIC 1 Y ATMOS CON placas MiST, MiSTica y SiDi FPGA.
Cree un directorio llamado ORIC en la raíz de su SD y coloque dentro las imágenes del disco para trabajar

Una vez lanzado el núcleo:

### Atajos de teclado:

F10 - Botón NMI, actúa como ORIC NMI original

F11 - Restablecer. Utilice F11 para reiniciar una vez que se seleccione un DSK en OSD

F12 - Menú principal OSD.

![oric](https://github.com/ingloriond/Unamiga/assets/31018768/d87b3c3a-f650-4b43-9c3b-d5345bd48756)

Activar el controlador FDC en el MENÚ OSD

Seleccione una imagen del directorio /ORIC, salga de OSD y presione F11. El sistema arrancará inmediatamente

## El EQUIPO de preservación de Oric Fpga

Ron Rodritty: Coordinación del equipo y pruebas de control de calidad.

Fernando Mosquera: gurú de las FPGA.

Subcritrical: Verilog y VHDL.

ManuFerHi: Consultoría de hardware.

Chema Enguita: gurú de Oric Software

SiliceBit: gurú del hardware Oric

ZXMarce: Soporte de hardware 24 horas al día, 7 días a la semana...

Ramón Martínez: Hardware Oric, Algo de software y codificación fpga.

Slingshot: Trabajo y asesoramiento sobre SDRAM.

Felicitaciones a: Sorgelig, Gehstock, DesUBIKado, RetroWiki y amigos.

Acerca de las imágenes de disco.

A pesar de la extensión .dsk, las imágenes de disco son el edsk estándar de facto para la conservación del disco (también conocido como "FORMATO EXTENDIDO AMSTRAD CPC"). Para convertir imágenes del "dsk" oric al "dsk" necesario, necesita el [software HxCFloppyEmulator] (https://hxc2001.com/download/floppy_drive_emulator/HxCFloppyEmulator_soft.zip).

Cargue el disco oric y expórtelo como archivo CPC DSK; la imagen resultante debería cargarse sin problemas en el Oric. Estas imágenes también son compatibles con firmware fastfloppy en gothek, cuamana reborn, etc trabajando con orics reales.
