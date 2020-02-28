# MemTest - Utility to test the Unamiga

### Port por Jose Manuel @delgrom proviniente de Multicore 2 de Victor Trucco ( https://gitlab.com/victor.trucco/Multicore_Bitstreams/-/tree/master/Multicore%202%2FSDRAM%20Test#memtest-screen )

Memtest:

![memtest](https://user-images.githubusercontent.com/31018768/75568746-230c9000-5a54-11ea-82d9-d43881caeeb2.png)

1 Indicador de Modo Automático (animado),
2 Tiempo que lleva el test expresado en minutos
3 Frecuencia actual a la que trabaja el módulo in Mhz
4 Sin uso en el Unamiga
5 Número de pasadas efectuadas por el test (cada ciclo son 32 MB)
6 Número de test fallados


Controles (Teclado)

Arriba - Incrementa la Frecuencia
Abajo - Decrece la Frecuencia
Enter - resetea el test
A - Modo Automatico, detecta la frecuencia máxima de módulo para testearlo. El test comienza a máxima frecuencia.
Con cada error la frecuencia baja.

El test de da por superado cuando el número de errores sea 0. Para un test rápido dejarlo 10 minutos en automático. Si quieres estar seguro, dejalo funcionando entre 1-2 horas.

