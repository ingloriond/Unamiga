#### 																	ACTUALIZACION 13/8/2020 @delgrom

### Modificar Unamiga para tener 6 botones+ Start + Menú (norma megadrive 6 buttons)



El pin **T13**, que inicialmente estaba para la señal **joyX_p7_o** ha tenido que ser desplazado al pin **R12**.

La razón es debida a que el addon que contiene al stm32 y la memoria sram ha sido modificado para tener dos líneas más en las direcciones de la memoria (A19 y A20) para poder direccionar 2 Megabytes y usar el core de Next, y en esa zona no había más pines disponibles de entrada/salida.

Como se ve en la foto que se adjunta a este post, el pin R12 pertenece a la hilera de pines interior de paso 2.0 mm.

Gracias a A. Villena por la modificación del addon y a F. Mosquera por el port del core de Spectrum Next al Unamiga.

- Adjuntos

  ![joyx_p7_0_en_R12.jpg](http://www.forofpga.es/download/file.php?id=673)joyx_p7_0_en_R12.jpg 