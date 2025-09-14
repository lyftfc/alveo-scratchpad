create_pblock pblock_dut
add_cells_to_pblock [get_pblocks pblock_dut] [get_cells -quiet { bd_top_i/dut }]
resize_pblock [get_pblocks pblock_dut] -add {CLOCKREGION_X2Y4:CLOCKREGION_X7Y7}
