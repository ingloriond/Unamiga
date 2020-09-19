# Amstrad CPC 464
## Port por Jose Manuel @delgrom Código original de Sorgelig modificando el core de Renaud Helias. La versión Unamiga proviene del port a multicore 2 realizado por Victor Trucco. :+1:

![Amstrad_CPC464_keyboard](https://user-images.githubusercontent.com/31018768/70374573-49f37400-18f4-11ea-9aac-15d1f3aee8b6.jpg)
#### Fuente imagen: https://commons.wikimedia.org/wiki/File:Amstrad_CPC464_keyboard.jpg

### Requerimientos: 

#### SRAM: NO

#### MULTICORE: SI

#### SOPORTE PAD 6 BOTONES: NO

#### SALIDA DE VIDEO : VGA,RGB

#### SOPORTE I2S: NO

### Instrucciones:

#### Descomprima y copie en archivo .rbf y el fichero "Amstrad.dat" en la raíz de la tarjeta SD del addon STM32.

####Teclas del core
--------------------------------------

#### Bloq Despl: VGA/RGB

#### * (teclado numérico): Soft Reset

#### - (teclado numérico): Hard Reset

#### F12: OSD


#### Las imágenes de cinta deben tener la extensión "CDT".Las imágenes de disco deben tener la extensión "DSK".Las imágenes pueden estar en carpetas dentro de la tarjeta SD. Las imágenes de cinta pueden cargarse normalmente por el reproductor interno simplemente dando el comando de carga CPC correspondiente. El reproductor comienza a reproducir audio automáticamente 15 a 30 segundos después del comando de carga. Solo cabe esperar este tiempo.

#### Commandos Básicos:

cat -- ver contenido del disco
run" -- mas nombre garga del juego 
