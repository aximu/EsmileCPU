`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/01/01 19:21:58
// Design Name: 
// Module Name: ram
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

`include "../core/define.v"

module ram(
    input wire clk,
    input wire rstn,

    input wire                  we_i, 
    input wire [`MemAddrBus]    addr_i, 
    input wire [`MemBus]        data_i,

    output reg [`MemBus]        data_o
    );

    reg [`MemBus] _ram [0:`MemNum-1];       //用寄存器来实现RaM

    //write RAM
    always @(posedge clk) begin
        if(we_i) begin
            _ram[addr_i[31:2]] <= data_i;       //为什么只取高30位 ???
        end
    end

    //read ROM
    always @(*) begin
        if(!rstn) begin
            data_o <= 0;
        end
        else begin
            data_o <= _ram[addr_i[31:2]];
        end
    end
endmodule
