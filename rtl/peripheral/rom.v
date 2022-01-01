`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/01/01 19:04:12
// Design Name: 
// Module Name: rom
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

module rom(
    input wire clk,
    input wire rstn,

    input wire                  we_i, 
    input wire [`MemAddrBus]    addr_i, 
    input wire [`MemBus]        data_i,

    output reg [`MemBus]        data_o
    );

    reg [`MemBus] _rom [0:`RomNum-1];       //用寄存器来实现ROM

    //write ROM
    always @(posedge clk) begin
        if(we_i) begin
            _rom[addr_i[31:2]] <= data_i;       //为什么只取高30位 ???
        end
    end

    //read ROM
    always @(*) begin
        if(!rstn) begin
            data_o <= 0;
        end
        else begin
            data_o <= _rom[addr_i[31:2]];
        end
    end

endmodule
