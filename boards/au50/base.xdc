set_operating_conditions -design_power_budget 63

set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property BITSTREAM.CONFIG.CONFIGFALLBACK Enable [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 63.8 [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN disable [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN Pullup [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR Yes [current_design]

#set_property PACKAGE_PIN AF8 [get_ports pcie_refclk_n]
#set_property PACKAGE_PIN AF9 [get_ports pcie_refclk_p]
set_property PACKAGE_PIN AW27 [get_ports pcie_rstn]
set_property IOSTANDARD LVCMOS18 [get_ports pcie_rstn]

#set_property PACKAGE_PIN N37 [get_ports qsfp_refclk_n]
#set_property PACKAGE_PIN N36 [get_ports qsfp_refclk_p]

# CMC => sysclk2
set_property PACKAGE_PIN G16 [get_ports cmc_clk_clk_n]
set_property PACKAGE_PIN G17 [get_ports cmc_clk_clk_p]
set_property IOSTANDARD DIFF_SSTL12 [get_ports cmc_clk_clk_n]
set_property IOSTANDARD DIFF_SSTL12 [get_ports cmc_clk_clk_p]

set_property PACKAGE_PIN J18 [get_ports hbm_cattrip]
set_property IOSTANDARD LVCMOS18 [get_ports hbm_cattrip]

set_false_path -through [get_nets pcie_rstn]
set_false_path -through [get_nets bd_top_i/user_rstn]

set user_clk    [get_clocks -of_object  [get_nets bd_top_i/user_clk ]]
set user_clk_t  [get_property PERIOD $user_clk ]
set ether_clk   [get_clocks -of_object  [get_nets bd_top_i/cmac_subsys/cmac_gt_txusrclk2 ]]
set ether_clk_t [get_property PERIOD $ether_clk ]
set_max_delay -datapath_only    -from $ether_clk   -to $user_clk    $ether_clk_t
set_max_delay -datapath_only    -from $user_clk    -to $ether_clk   $user_clk_t

create_pblock pblock_cmac
add_cells_to_pblock [get_pblocks pblock_cmac] [get_cells -quiet { bd_top_i/cmac_subsys }]
resize_pblock [get_pblocks pblock_cmac] -add {CLOCKREGION_X0Y6:CLOCKREGION_X1Y7}
