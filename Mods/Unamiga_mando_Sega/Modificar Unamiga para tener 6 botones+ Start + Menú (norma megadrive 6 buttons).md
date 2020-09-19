### [Modificar Unamiga para tener 6 botones+ Start + Menú (norma megadrive 6 buttons)](http://www.forofpga.es/viewtopic.php?f=141&t=303#p1257)
#### Tutorial por : Lui sal @luixyto
#### Fuente : http://www.forofpga.es/viewtopic.php?f=141&t=303#)

Hola chicos:
Voy a explicaros que tenéis que hacer para modificar vuestro Unamiga para poder usar los futuros cores que se creen con opción de 6 botones + Start + Menú
Antes de nada decir que todo esto ha sido idea de @benitoss (Fernando Mosquera) y que todo el merito es únicamente suyo .
Él nos dijo que modificaciones teníamos que hacer y se curró un test para comprobar su funcionamiento basándose en el trabajo realizado en sus maquinas por Victor Trucco.

https://gitlab.com/victor.trucco
Con esta modificación tendremos posibilidad de pulsación en botones ABC XYZ Start y Menú.
La modificación es muy sencilla y solo hay que soldar unos cables a los puertos db9 de joystick de nuestro unamiga

1) llevar señal de 3.3 voltios a los pines 5 del puerto db9 de ambos mandos
![Imagen](https://i.ibb.co/rH5TPyd/modjoy1-copia.jpg)

![Imagen](https://i.ibb.co/8zR9VKg/unamiga-mod-copia.jpg)

Punto 3,3 V Alternativos gracias a Monstronio 
![ShortWay](https://user-images.githubusercontent.com/31018768/93665736-42631d00-fa79-11ea-8a8c-cb6da7b7906b.png)

2) Puentear los pines 7 de ambos puertos db9 de los joystick al pin T13 de nuestra FPGA

![Imagen](https://i.ibb.co/4dsr14Q/modjoy3.jpg)



![Imagen](https://i.ibb.co/j8G4MD2/modjoy4.jpg)


![:!:](http://www.forofpga.es/images/smilies/icon_exclaim.gif) **Por lo que pueda pasar (posible daño en la fpga ) no se les ocurra conectar un joystick especial de 3 botones o Ratón de 3 botones de Amiga en los puertos del joystick** ![:!:](http://www.forofpga.es/images/smilies/icon_exclaim.gif)

Decir que ya se han probado algunos cores que utilizan más de 2 botones y funcionan perfectamente (ejemplo arcade capcom gunsmoke, 3 botones) , y explicar también que esto no afecta a los antiguos cores y que los mandos norma atari/amiga funcionan perfectamente con los antiguos cores.

