`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/01/01 10:37:07
// Design Name: 
// Module Name: esmilecpu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "define.v"

module esmilecpu(
    input wire clk,
    input wire rstn



    );

    pc_reg u_pc_reg(
        .clk(clk),
        .rstn(rstn),
        .jump_flag_i(),
        .jump_addr_i(),
        .hold_flag_i(),
        .jtag_reset_flag_i(),
        .pc_o()
    );

    regfile u_regfile(
        .clk(clk),
        .rstn(rstn),
        .we_i(),
        .w_regnum_i(),
        .w_data_i(),
        .r_addr1_i(),
        .r_addr2_i(),
        .r_data1_o(),
        .r_data2_o(),
        .jtag_wen_i(),
        .jtag_regnum_i(),        
        .jtag_w_data_i(),   
        .jtag_data_o()     
    );

    csr_reg u_csr_reg(
        .clk (clk),
        .rstn(rstn),
        .we_i    (),
        .r_addr_i(),
        .w_addr_i(),
        .data_i  (),
        .data_o  (),
        .clint_we_i    (),
        .clint_r_addr_i(),
        .clint_w_addr_i(),
        .clint_data_i  (),
        .clint_data_o     (),
        .clint_csr_mtvec  (),
        .clint_csr_mepc   (),
        .clint_csr_mstatus(),
        .global_inter_en_o()
    );

    if2id u_if2id(
        .clk (clk),
        .rstn(rstn),
        .inst_i     (),
        .inst_addr_i(),
        .hold_flag_i(),
        .inst_o     (),
        .inst_addr_o()
    );


endmodule
