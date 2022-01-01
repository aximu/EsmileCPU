`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/01/01 09:34:37
// Design Name: 
// Module Name: pc_reg
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

module pc_reg(  
    input wire                      clk,
    input wire                      rstn,
    input wire                      jump_flag_i,
    input wire [`InstAddrBus]       jump_addr_i,        // 跳转地址; 32位
    input wire [`Hold_Flag_Bus]     hold_flag_i,        //流水线暂停标志；3位
    input wire                      jtag_reset_flag_i,

    output reg [`InstAddrBus]       pc_o

    );

    always @(posedge clk or negedge rstn) begin
        if(!rstn || jtag_reset_flag_i == 1'b1) begin
            pc_o <= `CpuResetAddr;            
        end
        else if(jump_flag_i == 1) begin
            pc_o <= jump_addr_i;
        end
        else if(hold_flag_i >= `Hold_Pc) begin
            pc_o <= pc_o;
        end
        else begin
            pc_o <= pc_o + 4'h4;
        end
    end

endmodule
