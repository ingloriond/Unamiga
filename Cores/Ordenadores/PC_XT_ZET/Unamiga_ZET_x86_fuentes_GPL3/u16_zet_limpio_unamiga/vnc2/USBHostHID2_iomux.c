/*
** Filename: USBHostHIDKbd_iomux.c
**
** Automatically created by Application Wizard 1.4.2
**
** Part of solution USBHostHIDKbd in project USBHostHIDKbd
**
** Comments:
**
** Important: Sections between markers "FTDI:S*" and "FTDI:E*" will be overwritten by
** the Application Wizard
*/
#include "vos.h"

void iomux_setup(void)
{
	/* FTDI:SIO IOMux Functions */
	unsigned char packageType;
	
	packageType = vos_get_package_type();
	if (packageType == VINCULUM_II_32_PIN)
	{
		// Debugger to pin 11 as Bi-Directional.
		vos_iomux_define_bidi(11, IOMUX_IN_DEBUGGER, IOMUX_OUT_DEBUGGER);
		
		// GPIO_Port_A_2 to pin 14 as Output.
		vos_iomux_define_output(14, IOMUX_OUT_GPIO_PORT_A_2); //LED
		vos_iocell_set_config  (14, 3, 0, 1, 0);

		
		// GPIO_Port_A_1 to pin 12 as Input.
		vos_iomux_define_input(12, IOMUX_IN_GPIO_PORT_A_1);
		//vos_iomux_define_output(12, IOMUX_OUT_GPIO_PORT_A_1);
		//vos_iocell_set_config(12, 3, 0, 0, 0);
		//vos_iomux_define_bidi(12, IOMUX_IN_GPIO_PORT_A_1, IOMUX_OUT_GPIO_PORT_A_1);
		//vos_iocell_set_config(12, 3, 0, 0, 2); // Pull UP 75k
		
		// GPIO_Port_A_3 to pin 15 as Input.
		vos_iomux_define_input(15, IOMUX_IN_GPIO_PORT_A_3);
		//vos_iomux_define_output(15, IOMUX_OUT_GPIO_PORT_A_3);
		//vos_iocell_set_config(15, 3, 0, 0, 0);
		//vos_iomux_define_bidi(15, IOMUX_IN_GPIO_PORT_A_3, IOMUX_OUT_GPIO_PORT_A_3);
		//vos_iocell_set_config(15, 3, 0, 0, 2); // Pull UP 75k


		// UART_TXD to pin 23 as Output.
		vos_iomux_define_output(23, IOMUX_OUT_UART_TXD);
		// UART_RXD to pin 24 as Input.
		vos_iomux_define_input(24, IOMUX_IN_UART_RXD);
		// UART_RTS_N to pin 25 as Output.
		vos_iomux_define_output(25, IOMUX_OUT_UART_RTS_N); // Not connected to Cyclone
		// UART_CTS_N to pin 26 as Input.
		vos_iomux_define_input(26, IOMUX_IN_UART_CTS_N);   // Not connected to Cyclone
		vos_iocell_set_config(26, 0, 0, 0, 1);


		//=======================SPI==============================================
		// SPI_Slave_0_CLK to pin 29 as Input.
		//vos_iomux_define_input(29, IOMUX_IN_SPI_SLAVE_0_CLK);
		vos_iomux_define_bidi(29, IOMUX_IN_GPIO_PORT_A_4, IOMUX_OUT_GPIO_PORT_A_4);
		vos_iocell_set_config(29, 3, 0, 0, 2); // Pull UP 75k



		// SPI_Slave_0_MOSI to pin 30 as Input.
		//vos_iomux_define_input(30, IOMUX_IN_SPI_SLAVE_0_MOSI);
		vos_iomux_define_bidi(30, IOMUX_IN_GPIO_PORT_A_5, IOMUX_OUT_GPIO_PORT_A_5);
		vos_iocell_set_config(30, 3, 0, 0, 2); // Pull UP 75k



		// SPI_Slave_0_MISO to pin 31 as Output.
		//vos_iomux_define_output(31, IOMUX_OUT_SPI_SLAVE_0_MISO);
		vos_iomux_define_bidi(31, IOMUX_IN_GPIO_PORT_A_6, IOMUX_OUT_GPIO_PORT_A_6);
		vos_iocell_set_config(31, 3, 0, 0, 2); // Pull UP 75k
		
		// SPI_Slave_0_CS to pin 32 as Input.
		//vos_iomux_define_input(32, IOMUX_IN_SPI_SLAVE_0_CS);
		vos_iomux_define_bidi(32, IOMUX_IN_GPIO_PORT_A_7, IOMUX_OUT_GPIO_PORT_A_7);
		vos_iocell_set_config(32, 3, 0, 0, 2); // Pull UP 75k
	
	}
	
	/* FTDI:EIO */

}
