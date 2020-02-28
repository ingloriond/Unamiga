MemTest - Utility to test the Unamiga

Port por Jose Manuel @delgrom proviniente de Multicore 2 de Victor Trucco.

Memtest screen:


Auto mode indicator (animated),
Test time passed in minutes,
Current memory module frequency in MHz,
(not used on Multicore 2
Number of of passed test cycles (each cycle is 32 MB),
Number of failed tests.


Controls (keyboard)

Up - increase frequency
Down - decrease frequency
Enter - reset the test
A - auto mode, detecting the maximum frequency for module being tested. Test starts from maximum frequency.
With every error frequency will be decreased.

Test is passed if amount of errors is 0. For quick test let it run for 10 minutes in auto mode. If you want to be sure, let it run for 1-2 hours.
Board should pass at least 120 MHz clock test. Any higher clock will assure the higher quality of the board.
