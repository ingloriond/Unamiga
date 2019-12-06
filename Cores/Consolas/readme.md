## Port Fernando Mosquera fuentes aqui https://github.com/benitoss/UnAmiga/tree/master/Cores

PortPuerto Colecovision FGPA de Multicore 2 de Victor Trucco (antiguo proyecto PACE).

La información original del proyecto está aquí: http://members.iinet.net.au/~msmcdoug/pace/Nanoboard/nanoboard.html

Usaa el control SNES para emular todos los botones de joystick originales. Manteniendo presionado el botón TL, los botones originales:
Y => 1
X => 2
B => 3
A => 4
SELECCIONAR => 5
START => 6
Manteniendo presionado el botón TR, los botones originales:

Y => 7
X => 8
B => 9
A => 0
SELECCIONAR => *
START => #
Si mantiene presionado START y SELECT juntos, se reinicia la máquina, regresando al menú.

El botón B y Y (disparo automático) es el fuego 1 del joystick original. El botón A y X (disparo automático) es el fuego 2.

Para las placas DE-1, DE-2 y ZX-Uno, el teclado PS / 2 emula el joystick original:

Las teclas de flecha simulan el direccional original. La tecla Z es 'disparar 1', la tecla X es 'disparar 2', 0-9 es '0-9', la tecla Q es '*' y la tecla W es '#'. La tecla ESC restablece la máquina.
La combinación de teclas CTRL + ALT + RETROCESO, en la versión ZX-Uno, recarga el núcleo principal de Xilinx, volviendo al menú principal.
En placas con salida VGA (ZX-Uno), usa la tecla INICIO para alternar la salida VGA.
La ROM de la BIOS se carga desde la tarjeta SD. El fichero 'SD_Card' contiene todos los archivos necesarios para la tarjeta SD. Formatar a FAT16 y copia los archivos.
