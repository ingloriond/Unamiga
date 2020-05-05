### Por por Jose Manuel @delgrom Código original de Sorgelig modificando el core de Renaud Helias.
La versión unamiga proviene del port a multicore 2 realizado por Victor Trucco.

![Amstrad_CPC464_keyboard](https://user-images.githubusercontent.com/31018768/70374573-49f37400-18f4-11ea-9aac-15d1f3aee8b6.jpg)

#### Fuente imagen: https://commons.wikimedia.org/wiki/File:Amstrad_CPC464_keyboard.jpg

### Intrucciones:

Descomprima y copie en archivo .rbf y el fichero "Amstrad.dat" en la raíz de la tarjeta SD del addon STM32.

Teclas del core

Bloq Despl: Alterna entre VGA/RGB 15 Khz

* (teclado numérico): reset suave

- (teclado numérico): reset completo

F12: abre el menú para seleccionar archivos de imagen.


Las imágenes de cinta deben tener la extensión "CDT".

Las imágenes de disco deben tener la extensión "DSK".

Las imágenes pueden estar en carpetas dentro de la tarjeta SD.


Las imágenes de cinta pueden cargarse normalmente por el reproductor interno simplemente dando el comando de carga CPC correspondiente.
El reproductor comienza a reproducir audio automáticamente 15 a 30 segundos después del comando de carga. Solo cabe esperar este tiempo.


Se adjunta en formato RBF,MC2 para el multicore y SOF.: Amstrad_VGA inicia primero en modo VGA yAmstrad_15khz inicia en RGB
Requiere el archivo Amstrad.dat en la tarjeta SD del addon STM32.

Commandos Básicos:

cat -- ver contenido del disco
run" -- mas nombre garga del juego 
