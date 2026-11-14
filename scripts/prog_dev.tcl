set ip_addr 192.168.0.xxx
set port 3121

open_hw_manager

connect_hw_server -url localhost:3121
current_hw_target
open_hw_target

set_property PROGRAM.FILE {build/main.bit} [current_hw_device]
program_hw_devices [current_hw_device]

close_hw_manager
