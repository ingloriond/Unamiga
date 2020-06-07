# Amiga 1200 con Dac I2S

#### Implementación por Fernando Mosquera @benitoss https://github.com/benitoss

http://www.forofpga.es/viewtopic.php?f=141&t=355

Gracias a Fernando Mosquera ( @benitoss ) por implementar el dac al core de Unamiga y a Jose Manuel ( @delgrom ) por buscar los pines libres para ello, podemos disfrutar de una calidad de audio brutal muy superior al Delta Sigma ;). Los pines elegidos para ello se encuentran debajo del addon ps2/vga de Antonio villena, son los siguientes:

I2S MCLK pin R6 Unamiga (solo CS4344 y PCM5102, no usado en la ES2093)

I2S BCLK pin T5 Unamiga

I2S LRCLK pin T6 Unamiga

I2S DATA pin T7 Unamiga

![Esquema ES2093](https://user-images.githubusercontent.com/31018768/83967558-08537e00-a8c3-11ea-829a-a84d1da4b66b.jpg)

![ES9023](https://user-images.githubusercontent.com/31018768/83967489-3dab9c00-a8c2-11ea-864e-163e48195298.jpg)

![Esquema CS4344 y PCM5102](https://user-images.githubusercontent.com/31018768/83967494-55832000-a8c2-11ea-8d66-49dc219cf3b8.jpg)
