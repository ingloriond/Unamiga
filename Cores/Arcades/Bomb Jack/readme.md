# Bomb Jack

Port por Jose Manuel @delgrom | vhdl por d18c7db | proviene de adaptación de Victor Trucco a su multicore2

![bombjack](https://user-images.githubusercontent.com/31018768/71326969-8cc36780-2502-11ea-98b4-a97e80e44dee.jpeg)

### Requerimientos:

SRAM: SI

MULTICORE: SI

SOPORTE PAD 6 BOTONES: NO

SALIDA DE VIDEO : VGA , 15KHZ

Instrucciones:

F3: COIN

F1: 1P

F2: 2P

F4: SCANLINES (sólo VGA)

F5: BLEND (sólo VGA)

Se adjunta en formato RBF para el multicore y SOF.: BombJack_VGA inicia primero en modo VGA y BombJack_15khz inicia en RGB
Requiere el archivo BombJack.dat en la tarjeta SD del addon STM32.
