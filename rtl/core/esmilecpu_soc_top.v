`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/01/01 10:33:38
// Design Name: 
// Module Name: esmilecpu_soc_top
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

module esmilecpu_soc_top(
    input wire clk,
    input wire rstn






    );

    esmilecpu u_esmilecpu(
        .clk(clk),
        .rstn(rstn),

        .clk(),
        .clk(),
        .clk(),
        .clk(),
        .clk()
    );

    rom u_rom(
        .clk (clk),       
        .rstn(rstn),
        .we_i  (),
        .addr_i(),
        .data_i(),
        .data_o()
    );

    ram u_ram(
        .clk (clk),       
        .rstn(rstn),
        .we_i  (),
        .addr_i(),
        .data_i(),
        .data_o()
    );
    

endmodule
