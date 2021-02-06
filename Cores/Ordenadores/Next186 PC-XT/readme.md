# Next186 PC-XT
## Portado por Jepalza de https://opencores.org/project/next186_soc_pc
### Fuente: http://www.forofpga.es/viewtopic.php?f=11&t=10

"Versión para UnAmiga del core de Opencores (https://opencores.org/project/next186_soc_pc). es una versión un tanto especial, ya que lleva una pequeña trampa, muy simple, que consisten en engañar a un registro "pop" que solicita la CPU cuando se le pide identifcar el tipo de CPU. Si le devuelvo el valor que espera que devuelva un 80286, el msdos se lo cree y lo muestra como tal, a pesar de ser un "simple" 80186.
Esta trampa es ideal para poder instalar por ejemplo, un coprocesador matemático por "soft", como el EM8087 , y de ese modo, podemos cargar viejas aplicaciones al estilo del POV-RAY o el Autocad ;-)
Pero claro, es solo una trampa, por que, si se le piden instrucciones específicas del 80286, no va a funcionar, dado que no existen. Con esto, espondería a la hipotética pregunta "¿y si lo dijeras que es un 386?". Como la diferencia entre un 80266 y 80186 es mínima, apenas se da cuenta el sistema operativo. Y las instrucciones específicas del 80286 son pocas, y raras de usar.
Otra cosa, es que no funciona el modo protegido del 80286 y superiores, que permite emplear la memoria para crear CPU virtuales y conseguir la multitarea. Aquí solo tenemos el modo real, que es poco, pero permite ejecutar un Windows 3.0, con una pequeña trampa, incluída en los ficheros de la SD.

De momento, estamos obligados a tener la BIOS grabada en los últimos 8k de la tarjeta sd de 4gb, mediante el programa HxD, por ejemplo.

Imagen

Aquí vemos como se ejecuta un emulador de coprocesador, gracias a la trampa 80286:
Imagen

Y las mas chula de todas: Windows 3.0 con la trampa del Kernel que publicó Quest en el foro hermano zxuno (www.zxuno.es)
( por cierto, con la "sombrilla" preparada por AntonioVillena y el menda lerenda)
Imagen


El contenido de la SD ,el core y los fuentes, se pueden coger en este enlace:
https://drive.google.com/open?id=1s5Obs ... 84nQHbgEIm" Jepalza

