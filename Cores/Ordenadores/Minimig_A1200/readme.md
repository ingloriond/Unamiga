# Amiga A1200

## Core por Jepalza, @NeuroRulez (https://github.com/neurorulez) y Edu Arana @eduarana(https://arananet.net/) preparando el entorno de compilacion para el osd y la traducción. Mención especial las ultimas correcciones AGA por @NeuroRulez

![a1200foto](https://user-images.githubusercontent.com/31018768/71215821-17188b00-22b9-11ea-8033-4ef7fa745241.jpg)




#### Características

CPU: Motorola MC68EC020 a 14.32 MHz (NTSC) o 14.18 MHz (PAL)
Chipset: AGA (Advanced Graphics Architecture)
Audio (Paula):
4 voces / 2 canales (Stereo)
8-bits de resolución / 6-bits de volumen
Frecuencia de muestreo de 28 kHz (normal), 56 kHz (Modo Productivity)
70 dB S/N Ratio
Video (Lisa):
Paleta de 24-bits (16.7 Millones de colores)
256 colores simultáneos (262'144 en HAM-8)
Rango de resoluciones de 320x200 a 1280x512i (entrelazado)
Memoria:
512 KiB de ROM para el Kickstart code
2 MiB de CHIP RAM
Hasta 8 MiB de Fast RAM en el slot de expansión
Hasta 256 MiB de Fast RAM con tarjetas aceleradoras
Almacenamiento Removible:
Unidad de disquete de 3.5" Doble Densidad, con capacidad de 880 KiB
Almacenamiento interno:
Emplazamiento para disco duro 2.5" (Controladora IDE PIO-0)
Conectores de Entrada/Salida:
Salida vídeo compuesto TV (PAL en las versiones vendidas en Europa, Australia y parte de Asia, NTSC el resto)
Conector de video RGB analógico a 15 kHz (DB-23)
Conectores RCA audio estéreo
2 conectores Joystick/mouse (DE-9)
Puerto serie RS-232 (DB-25)
Puerto de impresora paralelo Centronics (DB-25)
Puerto de unidad de disquete externa (DB-23)
Puerto PCMCIA Type II de 16-bits
Puerto de expansión local de 150 pines (compuerta inferior)
Puerto de 22 pines para reloj interno
Otras características
Fuente de alimentación externa 23W, 220-240V/50Hz(PAL), 110V/60Hz(NTSC)
Peso: 8 libras (3.6Kg)
Tamaño: 9.5" profundo x 18.5" ancho x 3" alto (250 x 490 x 70 mm)
Teclado estándar Amiga QWERTY/QWERTZ/AZERTY integrado con 96 teclas (incluyendo 19 teclas de función y el keypad numérico)
Software (incluido):
Sistema operativo AmigaOS 3.0-3.1. (Kickstart 3.0-3.1/Workbench 3.0-3.1)

##### Fuente: Wikipedia https://es.wikipedia.org/wiki/Commodore_Amiga_1200

## Intrucciones:

El fichero de1_boot.bin (es el encargado de mostrar el menú OSD de selección de ficheros) debe estar en la tarjeta SD junto a una Rom valida, por defecto nombrada KICK.rom (KickStart 1.3 para el A500 ECS o kickstart 3.1 para el A1200 AGA) no suminstrada por temas de copyright. con la tecla F12 podemos acceder al menú OSD en cualquier momento. Con la tecla SCROLL-LOCK elegimos entre modo 15khz y modo VGA. Por defecto entra en modo VGA.

En esta versión del código AGA, se han hecho varias mejoras, como poder emplear hasta 16+4 megas de RAM formato "FAST" (dos ampliaciones tipo ZORRO-II y III de 4mb mas 16mb). Ademas, se ha traducido el menú a Español.

