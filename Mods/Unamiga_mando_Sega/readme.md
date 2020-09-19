<span style='color:blue'>Tutorial por Lui sal @luixyto </span> [a link](https://github.com/ingloriond/Unamiga/blob/master/Mods/Unamiga_mando_Sega/Modificar%20Unamiga%20para%20tener%206%20botones%2B%20Start%20%2B%20Men%C3%BA%20(norma%20megadrive%206%20buttons).md)

<span style='color:red'>ACTUALIZACION 13/8/2020 Jose Manuel @delgrom</span>

### Modificar Unamiga para tener 6 botones+ Start + Menú (norma megadrive 6 buttons) [a link](https://github.com/ingloriond/Unamiga/blob/master/Mods/Unamiga_mando_Sega/Modificar%20Unamiga%20para%20tener%206%20botones%2B%20Start%20%2B%20Men%C3%BA%20(norma%20megadrive%206%20buttons).md) por @luyixyto



El pin **T13**, que inicialmente estaba para la señal **joyX_p7_o** ha tenido que ser desplazado al pin **R12**.

La razón es debida a que el addon que contiene al stm32 y la memoria sram ha sido modificado para tener dos líneas más en las direcciones de la memoria (A19 y A20) para poder direccionar 2 Megabytes y usar el core de Next, y en esa zona no había más pines disponibles de entrada/salida.

Como se ve en la foto que se adjunta a este post, el pin R12 pertenece a la hilera de pines interior de paso 2.0 mm.

Gracias a A. Villena por la modificación del addon y a F. Mosquera por el port del core de Spectrum Next al Unamiga.

  ![joyx_p7_0_en_R12.jpg](http://www.forofpga.es/download/file.php?id=673)joyx_p7_0_en_R12.jpg 
