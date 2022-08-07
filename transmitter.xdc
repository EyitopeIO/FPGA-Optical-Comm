#seven-segment LED display
set_property PACKAGE_PIN W7 [get_ports {LED_out[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_out[6]}]
set_property PACKAGE_PIN W6 [get_ports {LED_out[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_out[5]}]
set_property PACKAGE_PIN U8 [get_ports {LED_out[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_out[4]}]
set_property PACKAGE_PIN V8 [get_ports {LED_out[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_out[3]}]
set_property PACKAGE_PIN U5 [get_ports {LED_out[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_out[2]}]
set_property PACKAGE_PIN V5 [get_ports {LED_out[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_out[1]}]
set_property PACKAGE_PIN U7 [get_ports {LED_out[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_out[0]}]
set_property PACKAGE_PIN U2 [get_ports {Anode_Activate[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Anode_Activate[0]}]
set_property PACKAGE_PIN U4 [get_ports {Anode_Activate[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Anode_Activate[1]}]
set_property PACKAGE_PIN V4 [get_ports {Anode_Activate[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Anode_Activate[2]}]
set_property PACKAGE_PIN W4 [get_ports {Anode_Activate[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Anode_Activate[3]}]

set_property PACKAGE_PIN W5 [get_ports clock]
set_property PACKAGE_PIN U18 [get_ports reset]
set_property PACKAGE_PIN B18 [get_ports uart_rx]
set_property PACKAGE_PIN L1 [get_ports uart_activity]
set_property IOSTANDARD LVCMOS33 [get_ports uart_activity]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx]
set_property IOSTANDARD LVCMOS33 [get_ports reset]
set_property PACKAGE_PIN A18 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports clock]
set_property IOSTANDARD LVCMOS33 [get_ports manchester2]
set_property PACKAGE_PIN A15 [get_ports manchester2]
set_property PACKAGE_PIN P1 [get_ports overrun]
set_property PACKAGE_PIN A14 [get_ports manchester1]
set_property IOSTANDARD LVCMOS33 [get_ports manchester1]
set_property IOSTANDARD LVCMOS33 [get_ports overrun]
set_property PACKAGE_PIN N3 [get_ports led_idle]
set_property IOSTANDARD LVCMOS33 [get_ports led_idle]

set_property IOSTANDARD LVCMOS33 [get_ports standby]
set_property PACKAGE_PIN L1 [get_ports standby]

set_property PACKAGE_PIN P1 [get_ports manc_error]
set_property IOSTANDARD LVCMOS33 [get_ports manc_error]
set_property PACKAGE_PIN N3 [get_ports uart_error]
set_property IOSTANDARD LVCMOS33 [get_ports uart_error]

set_property PACKAGE_PIN U3 [get_ports manleddle]
set_property IOSTANDARD LVCMOS33 [get_ports manleddle]
