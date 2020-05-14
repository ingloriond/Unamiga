# Recuperación de emergencia

En el supuesto que hayamos flaheado y/o borrado el STM32 y no dispongamos de un usb TTL para reprogramarlo. Podemos usar el STM32UPDATER en formato jic. 

Instrucciones:

1 Desmontaremos el multicore (MC en adelante)

2 Con nuestro USBBLASTER flashearemos la fpga con el fichero STM32RECOVERY.JIC ( https://github.com/ingloriond/Unamiga/blob/master/ActualizacionMulticore/Como%20grabar%20cores%20en%20el%20UnAmiga%20-%20ForoFPGA.pdf )

3 Montaremos el MC y seguiremos los pasos pare reprogramar el STM32 ( https://github.com/ingloriond/Unamiga/blob/master/ActualizacionMulticore/Multicore%20Amiga_%20STM32%20Updater%20V105.pdf)

4 Desmontaremos de nuevo el MC y programaremos el firmware que necesitemos ( Por ejemplo : https://github.com/ingloriond/Unamiga/tree/master/ActualizacionMulticore/MC2FIRMWARE/1.05)

5 Montaremos el MC de nuevo y ya estará todo funcionando de nuevo.
