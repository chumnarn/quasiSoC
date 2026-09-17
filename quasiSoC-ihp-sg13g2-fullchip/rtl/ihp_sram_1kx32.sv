`default_nettype none
module ihp_sram_1kx32(input logic clk_i,en_i,we_i,input logic [3:0] be_i,
 input logic [9:0] addr_i,input logic [31:0] wdata_i,output logic [31:0] rdata_o);
  RM_IHPSG13_1P_1024x32_c2_bm_bist u_sram(
    .A_CLK(clk_i),.A_MEN(en_i),.A_WEN(we_i),.A_REN(en_i & ~we_i),.A_ADDR(addr_i),
    .A_DIN(wdata_i),.A_DLY(1'b1),.A_DOUT(rdata_o),
    .A_BM({{8{be_i[3]}},{8{be_i[2]}},{8{be_i[1]}},{8{be_i[0]}}}),
    .A_BIST_CLK(1'b0),.A_BIST_EN(1'b0),.A_BIST_MEN(1'b0),.A_BIST_WEN(1'b0),
    .A_BIST_REN(1'b0),.A_BIST_ADDR('0),.A_BIST_DIN('0),.A_BIST_BM('0));
endmodule
`default_nettype wire
