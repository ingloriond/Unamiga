# Amiga 500

### Core por Jepalza, mejoras por @NeuroRulez(Twitter @Neuro_999, Github: https://github.com/neurorulez) y Edu Arana @eduarana ( https://arananet.net/ ) preparando el entorno de compilacion para el osd y la traducción.

![Amiga500_system](https://user-images.githubusercontent.com/31018768/71216316-77f49300-22ba-11ea-937a-9e4053472e94.jpg)

# Características:

CPU CISC Motorola 68000 a 7,16 MHz la versión NTSC, o 7,1 MHz la PAL. Aunque implementa un modelo de 32 bits y tiene registros de 32 bits, así como un bus interno de datos de 32 bits, su ALU es de 16 bits, su bus externo de datos es de 16 bits y su bus de direcciones es de 24 bits, por lo que sólo puede direccionar 16 MB de RAM.
ROM: de 512 KB conteniendo el Kickstart.
RAM: 512 KB de CHIP RAM por defecto (buffers de sonido, memoria gráfica y software coexisten en el mismo espacio), ampliables a 1 MB de CHIP RAM y hasta 8 MB de Fast RAM3​ (direccionable sólo por el microprocesador, sin compartirla con el resto del chipset). Ulteriormente la Fast RAM podía ser ampliada hasta 128 MB con tarjeta aceleradora.4​
Sistema operativo: AmigaOS 1.2 o 1.3 (teniendo micronúcleo multitarea preferente de 32-bit) dependiendo de la revisión.
Chipset OCS/ECS en los A500+ disfrazados de Amiga 500.
Versiones a 50 Hz PAL o 60 Hz NTSC dependiendo del país.
Filtro de graves de audio controlable por software (LED de funcionamiento brillante con el filtro activado, más oscuro con el filtro apagado).
Compartición de interrupciones IRQ (como el bus PCI).
Sistema de IRQ con 7 niveles de prioridades de interrupciones.
Sin límite en el número de interrupciones utilizadas.
Recursos gestionados por Autoconfig, muy similar a ACPI. Los recursos no eran numerados o etiquetados, simplemente dados como cantidades y direcciones de memoria.
No hay puertos de E/S específicos, usa E/S mapeada en memoria separadamente para cada dispositivo.
Soporte:
Unidad de disquete interna de 3,5" y doble densidad, 880 KB en formato estándar Amiga, capacidad de leer/escribir discos en formato MS-DOS usando un sistema de archivos adicional. Debido a su controladora, es capaz de leer/escribir casi cualquier formato de doble densidad.
Hasta 3 unidades de disco externas conectables en cadena, de 3,5" o de 5,25".
Disco duro externo IDE o SCSI por medio de expansión (puede incorporar más prestaciones, como ampliaciones de memoria).
Unidad externa de CD-ROM Amiga A570 opcional.
Teclado: estándar Amiga QWERTY/QWERTZ/AZERTY mecánico con interruptores Mitsumi, conformado por 96 teclas incluyendo 10 teclas de función, Ayuda, Suprimir, bloque de cuatro teclas del cursor y el teclado numérico.
Carcasa: rectangular con la parte del teclado en plano inclinado, muy similar a la del Commodore 64c. En el lateral izquierdo, protegido por una trampilla, está el conector Zorro II de ampliación. En el derecho, unidad de disquete integrada. En la trasera, conectores.
Conectores
Dos conectores para joysticks digitales y ratón (DE-9). El ratón debe soportar el protocolo privativo o bien conectarse con un adaptador.
Dos conectores de sonido estéreo (RCA).
Un puerto de unidades de disquete externas (DB-23F), para conectar hasta 3 unidades en cadena.5​
Un puerto serie RS-232 (DB-25).
Puerto de impresora paralelo Centronics (DB-25).
Conector de alimentación externa (+5V, +/-12V).6​
Conector RGB analógico con salida de video a 50 Hz PAL o 60 Hz NTSC (DB-23M). Puede usarse con monitores de vídeo como el Commodore 1084S o, mediante adaptadores, con monitores VGA multisíncronos o cualquier equipo con un euroconector completo. El uso de un monitor VGA común requiere un periférico adicional para doblar la velocidad de barrido, dada la diferencia entre la señal original del Amiga (~15 kHz) y la que soportan estos monitores (~31 kHz+).
Conector de vídeo monocromo (RCA).
Conector de expansión de bus de tipo Zorro II en el lateral izquierdo.
Conector de expansión interna, accesible mediante una trampilla inferior, para expansiones de RAM, reloj en tiempo real y otras.

Fuente Wikipedia: https://es.wikipedia.org/wiki/Commodore_Amiga_500

### Instrucciones:

El fichero de1_boot.bin (es el encargado de mostrar el menú OSD de selección de ficheros) debe estar en la tarjeta SD junto a una Rom valida, por defecto nombrada KICK.rom (KickStart 1.3 para el A500 ECS) no suminstrada por temas de copyright. con la tecla F12 podemos acceder al menú OSD en cualquier momento. Con la tecla SCROLL-LOCK elegimos entre modo 15khz y modo VGA. Por defecto entra en modo VGA.
