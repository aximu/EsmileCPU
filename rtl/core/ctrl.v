`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/01/04 19:48:44
// Design Name: 
// Module Name: ctrl
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
// 控制模块;  发出跳转、暂停流水线信号
module ctrl(
    input rstn,

    // from exu
    input wire jump_flag_i,
    input wire[`InstAddrBus] jump_addr_i,
    input wire hold_flag_ex_i,          //来自执行模块的暂停标志

    // from rib
    input wire hold_flag_rib_i,         //来自总线模块的暂停标志

    // from jtag
    input wire jtag_halt_flag_i,        //来自jtag模块的暂停标志

    // from clint
    input wire hold_flag_clint_i,       //

    output reg[`Hold_Flag_Bus] hold_flag_o,   //暂停标志

    // to pc_reg
    output reg jump_flag_o,
    output reg[`InstAddrBus] jump_addr_o

    );

    always @ (*) begin
        jump_addr_o = jump_addr_i;
        jump_flag_o = jump_flag_i;
        // 默认不暂停
        hold_flag_o = 3'b0;
        // 按优先级处理不同模块的请求
        if (jump_flag_i || hold_flag_ex_i || hold_flag_clint_i) begin
            // 暂停整条流水线
            hold_flag_o = `Hold_Id;
        end 
        else if (hold_flag_rib_i) begin
            // 暂停PC，即取指地址不变
            hold_flag_o = `Hold_Pc;
        end 
        else if (jtag_halt_flag_i) begin
            // 暂停整条流水线
            hold_flag_o = `Hold_Id;
        end else begin
            hold_flag_o = `Hold_None;
        end
    end

endmodule
