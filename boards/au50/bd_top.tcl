# Proc to create BD bd_top
proc cr_bd_bd_top { parentCell } {

  # CHANGE DESIGN NAME HERE
  set design_name bd_top

  common::send_gid_msg -ssname BD::TCL -id 2010 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

  create_bd_design $design_name

  set bCheckIPsPassed 1
  ##################################################################
  # CHECK IPs
  ##################################################################
  set bCheckIPs 1
  if { $bCheckIPs == 1 } {
     set list_check_ips "\ 
  xilinx.com:ip:axis_register_slice:1.1\
  xilinx.com:ip:xlconstant:1.1\
  xilinx.com:ip:axis_data_fifo:2.0\
  xilinx.com:ip:xpm_cdc_gen:1.0\
  xilinx.com:ip:cmac_usplus:3.1\
  xilinx.com:ip:util_vector_logic:2.0\
  xilinx.com:ip:clk_wiz:6.0\
  "

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

  }

  if { $bCheckIPsPassed != 1 } {
    common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
    return 3
  }

  
# Hierarchical cell: cmac_subsys
proc create_hier_cell_cmac_subsys { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_cmac_subsys() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 qsfp_4x

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 qsfp_161mhz

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 cmc_clk


  # Create pins
  create_bd_pin -dir O user_rstn
  create_bd_pin -dir O -type clk user_clk
  create_bd_pin -dir I -from 0 -to 0 -type rst pcie_rstn
  create_bd_pin -dir O -from 0 -to 0 hbm_cattrip

  # Create instance: const_12b0, and set properties
  set const_12b0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 const_12b0 ]
  set_property -dict [list \
    CONFIG.CONST_VAL {0} \
    CONFIG.CONST_WIDTH {12} \
  ] $const_12b0


  # Create instance: const_56b0, and set properties
  set const_56b0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 const_56b0 ]
  set_property -dict [list \
    CONFIG.CONST_VAL {0} \
    CONFIG.CONST_WIDTH {56} \
  ] $const_56b0


  # Create instance: axis_buf_tx, and set properties
  set axis_buf_tx [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_buf_tx ]
  set_property -dict [list \
    CONFIG.FIFO_DEPTH {1024} \
    CONFIG.FIFO_MEMORY_TYPE {block} \
    CONFIG.FIFO_MODE {2} \
    CONFIG.IS_ACLK_ASYNC {1} \
  ] $axis_buf_tx


  # Create instance: xpm_cdc_gen_0, and set properties
  set xpm_cdc_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xpm_cdc_gen:1.0 xpm_cdc_gen_0 ]
  set_property CONFIG.CDC_TYPE {xpm_cdc_sync_rst} $xpm_cdc_gen_0


  # Create instance: cmac_usplus_0, and set properties
  set cmac_usplus_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:cmac_usplus:3.1 cmac_usplus_0 ]
  set_property -dict [list \
    CONFIG.DIFFCLK_BOARD_INTERFACE {qsfp_161mhz} \
    CONFIG.ETHERNET_BOARD_INTERFACE {qsfp_4x} \
    CONFIG.RX_FLOW_CONTROL {0} \
    CONFIG.TX_FLOW_CONTROL {0} \
    CONFIG.USER_INTERFACE {AXIS} \
    CONFIG.USE_BOARD_FLOW {true} \
  ] $cmac_usplus_0


  # Create instance: rst_inv, and set properties
  set rst_inv [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 rst_inv ]
  set_property -dict [list \
    CONFIG.C_OPERATION {not} \
    CONFIG.C_SIZE {1} \
  ] $rst_inv


  # Create instance: axis_buf_rx, and set properties
  set axis_buf_rx [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_buf_rx ]
  set_property -dict [list \
    CONFIG.FIFO_DEPTH {1024} \
    CONFIG.FIFO_MEMORY_TYPE {block} \
    CONFIG.FIFO_MODE {2} \
    CONFIG.IS_ACLK_ASYNC {1} \
  ] $axis_buf_rx


  # Create instance: const_1b0, and set properties
  set const_1b0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 const_1b0 ]

  # Create instance: clk_wiz_0, and set properties
  set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0 ]
  set_property -dict [list \
    CONFIG.CLKOUT2_JITTER {102.086} \
    CONFIG.CLKOUT2_PHASE_ERROR {87.180} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {200.000} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.CLK_IN1_BOARD_INTERFACE {cmc_clk} \
    CONFIG.MMCM_CLKOUT1_DIVIDE {6} \
    CONFIG.NUM_OUT_CLKS {2} \
    CONFIG.USE_BOARD_FLOW {true} \
    CONFIG.USE_LOCKED {false} \
    CONFIG.USE_RESET {false} \
  ] $clk_wiz_0


  # Create instance: gt_rst_inv, and set properties
  set gt_rst_inv [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 gt_rst_inv ]
  set_property -dict [list \
    CONFIG.C_OPERATION {not} \
    CONFIG.C_SIZE {1} \
  ] $gt_rst_inv


  # Create interface connections
  connect_bd_intf_net -intf_net axis_buf_rx_M_AXIS [get_bd_intf_pins M_AXIS] [get_bd_intf_pins axis_buf_rx/M_AXIS]
  connect_bd_intf_net -intf_net axis_buf_tx_M_AXIS [get_bd_intf_pins axis_buf_tx/M_AXIS] [get_bd_intf_pins cmac_usplus_0/axis_tx]
  connect_bd_intf_net -intf_net cmac_usplus_0_axis_rx [get_bd_intf_pins axis_buf_rx/S_AXIS] [get_bd_intf_pins cmac_usplus_0/axis_rx]
  connect_bd_intf_net -intf_net cmac_usplus_0_gt_serial_port [get_bd_intf_pins qsfp_4x] [get_bd_intf_pins cmac_usplus_0/gt_serial_port]
  connect_bd_intf_net -intf_net cmc_clk_1 [get_bd_intf_pins cmc_clk] [get_bd_intf_pins clk_wiz_0/CLK_IN1_D]
  connect_bd_intf_net -intf_net qsfp_161mhz_1 [get_bd_intf_pins qsfp_161mhz] [get_bd_intf_pins cmac_usplus_0/gt_ref_clk]
  connect_bd_intf_net -intf_net regsl_ethtx_M_AXIS [get_bd_intf_pins S_AXIS] [get_bd_intf_pins axis_buf_tx/S_AXIS]

  # Create port connections
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins cmac_usplus_0/init_clk]
  connect_bd_net -net clk_wiz_0_clk_out2 [get_bd_pins clk_wiz_0/clk_out2] [get_bd_pins user_clk] [get_bd_pins xpm_cdc_gen_0/dest_clk] [get_bd_pins axis_buf_rx/m_axis_aclk] [get_bd_pins axis_buf_tx/s_axis_aclk]
  connect_bd_net -net cmac_gt_txusrclk2 [get_bd_pins cmac_usplus_0/gt_txusrclk2] [get_bd_pins cmac_usplus_0/rx_clk] [get_bd_pins axis_buf_tx/m_axis_aclk] [get_bd_pins axis_buf_rx/s_axis_aclk]
  connect_bd_net -net cmac_usplus_0_usr_tx_reset [get_bd_pins gt_rst_inv/Res] [get_bd_pins xpm_cdc_gen_0/src_rst] [get_bd_pins axis_buf_rx/s_axis_aresetn]
  connect_bd_net -net cmac_usplus_0_usr_tx_reset1 [get_bd_pins cmac_usplus_0/usr_tx_reset] [get_bd_pins gt_rst_inv/Op1]
  connect_bd_net -net const_1b0_dout [get_bd_pins const_1b0/dout] [get_bd_pins cmac_usplus_0/core_drp_reset] [get_bd_pins cmac_usplus_0/core_tx_reset] [get_bd_pins cmac_usplus_0/core_rx_reset] [get_bd_pins cmac_usplus_0/drp_clk] [get_bd_pins cmac_usplus_0/gtwiz_reset_tx_datapath] [get_bd_pins cmac_usplus_0/gtwiz_reset_rx_datapath] [get_bd_pins hbm_cattrip]
  connect_bd_net -net pcie_rstn_1 [get_bd_pins pcie_rstn] [get_bd_pins rst_inv/Op1]
  connect_bd_net -net rst_inv_Res [get_bd_pins rst_inv/Res] [get_bd_pins cmac_usplus_0/sys_reset]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins const_12b0/dout] [get_bd_pins cmac_usplus_0/gt_loopback_in]
  connect_bd_net -net xlconstant_1_dout [get_bd_pins const_56b0/dout] [get_bd_pins cmac_usplus_0/tx_preamblein]
  connect_bd_net -net xpm_cdc_gen_0_dest_rst_out [get_bd_pins xpm_cdc_gen_0/dest_rst_out] [get_bd_pins user_rstn] [get_bd_pins axis_buf_tx/s_axis_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}
  variable script_folder

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set qsfp_161mhz [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 qsfp_161mhz ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {161132812} \
   ] $qsfp_161mhz

  set qsfp_4x [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 qsfp_4x ]

  set cmc_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 cmc_clk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   ] $cmc_clk


  # Create ports
  set pcie_rstn [ create_bd_port -dir I -type rst pcie_rstn ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] $pcie_rstn
  set hbm_cattrip [ create_bd_port -dir O -from 0 -to 0 -type data hbm_cattrip ]

  # Create instance: regsl_ethrx, and set properties
  set regsl_ethrx [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 regsl_ethrx ]

  # Create instance: regsl_ethtx, and set properties
  set regsl_ethtx [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 regsl_ethtx ]

  # Create instance: cmac_subsys
  create_hier_cell_cmac_subsys [current_bd_instance .] cmac_subsys

  # Create interface connections
  connect_bd_intf_net -intf_net axis_buf_rx_M_AXIS [get_bd_intf_pins regsl_ethrx/S_AXIS] [get_bd_intf_pins cmac_subsys/M_AXIS]
  connect_bd_intf_net -intf_net cmac_usplus_0_gt_serial_port [get_bd_intf_ports qsfp_4x] [get_bd_intf_pins cmac_subsys/qsfp_4x]
  connect_bd_intf_net -intf_net cmc_clk_1 [get_bd_intf_ports cmc_clk] [get_bd_intf_pins cmac_subsys/cmc_clk]
  connect_bd_intf_net -intf_net qsfp_161mhz_1 [get_bd_intf_ports qsfp_161mhz] [get_bd_intf_pins cmac_subsys/qsfp_161mhz]
  connect_bd_intf_net -intf_net regsl_ethrx_M_AXIS [get_bd_intf_pins regsl_ethrx/M_AXIS] [get_bd_intf_pins regsl_ethtx/S_AXIS]
  connect_bd_intf_net -intf_net regsl_ethtx_M_AXIS [get_bd_intf_pins regsl_ethtx/M_AXIS] [get_bd_intf_pins cmac_subsys/S_AXIS]

  # Create port connections
  connect_bd_net -net cmac_subsys_hbm_cattrip [get_bd_pins cmac_subsys/hbm_cattrip] [get_bd_ports hbm_cattrip]
  connect_bd_net -net pcie_rstn_1 [get_bd_ports pcie_rstn] [get_bd_pins cmac_subsys/pcie_rstn]
  connect_bd_net -net user_clk [get_bd_pins cmac_subsys/user_clk] [get_bd_pins regsl_ethrx/aclk] [get_bd_pins regsl_ethtx/aclk]
  connect_bd_net -net user_rstn [get_bd_pins cmac_subsys/user_rstn] [get_bd_pins regsl_ethrx/aresetn] [get_bd_pins regsl_ethtx/aresetn]

  # Create address segments

  # Perform GUI Layout
  regenerate_bd_layout

  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
  close_bd_design $design_name 
}
# End of cr_bd_bd_top()
