set clk_port [get_ports clk_PAD]
create_clock -name core_clk -period 20.0 $clk_port
set_clock_uncertainty 0.25 [get_clocks core_clk]
set_clock_transition 0.15 [get_clocks core_clk]
set in_ports [remove_from_collection [all_inputs] $clk_port]
set_input_delay -min 0.0 -clock core_clk $in_ports
set_input_delay -max 2.0 -clock core_clk $in_ports
set_output_delay -min 0.0 -clock core_clk [all_outputs]
set_output_delay -max 4.0 -clock core_clk [all_outputs]
set_load 0.033442 [all_outputs]
set_false_path -from [get_ports rst_n_PAD]

