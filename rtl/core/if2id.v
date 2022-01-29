`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/01/01 20:25:04
// Design Name: 
// Module Name: if2id
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
//instruction fetch to instruction decode
module if2id(
    input wire clk,
    input wire rstn,

    //instrunction
    input wire [`InstBus]       inst_i,
    input wire [`InstAddrBus]   inst_addr_i,

    //pipeline interrupr flag
    input wire [`Hold_Flag_Bus] hold_flag_i,

    //peripherial interrupt flag
    input wire[`INT_BUS] int_flag_i,        // 外设中断输入信号；7位
    output wire[`INT_BUS] int_flag_o,

    //to idu
    output wire [`InstBus]      inst_o,
    output wire [`InstAddrBus]  inst_addr_o
    );

    wire hold_en = (hold_flag_i >= `Hold_If) ? 1 : 0;

    //inst to idu
    wire [`InstBus] inst;
    gen_pipe_dff #(32) inst_ff(clk, rstn, hold_en, `INST_NOP, inst_i, inst); //指令打一拍之后向后传输；这里复位或流水线暂停时，指令默认输出0x1;
    assign inst_o = inst;

    wire [`InstAddrBus] inst_addr;
    gen_pipe_dff #(32) inst_addr_dff(clk, rstn, hold_en, 0, inst_addr_i, inst_addr); //指令打一拍之后向后传输；这里复位或流水线暂停时，默认地址0;
    assign inst_addr_o = inst_addr;

    //peripherial interrupt
    wire[`INT_BUS] int_flag;
    gen_pipe_dff #(8) int_ff(clk, rstn, hold_en, `INT_NONE, int_flag_i, int_flag);
    assign int_flag_o = int_flag;
    
endmodule
