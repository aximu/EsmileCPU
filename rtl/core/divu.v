`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/01/03 16:37:29
// Design Name: 
// Module Name: divu
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
// 除法模块;  试商法实现32位整数除法
// 每次除法运算至少需要33个时钟周期才能完成
module divu(
    input wire clk,
    input wire rstn,

    // from exu
    input wire[`RegWidthBus] dividend_i,             // 被除数
    input wire[`RegWidthBus] divisor_i,              // 除数
    input wire               start_i,                // 开始信号，运算期间这个信号需要一直保持有效
    input wire[2:0]          op_i,                   // 具体是哪一条指令
    input wire[`RegNumbBus]  reg_w_addr_i,            // 运算结束后需要写的寄存器
 
    // to exu 
    output reg[`RegWidthBus] result_o,        // 除法结果，高32位是余数，低32位是商; 是32位？
    output reg               ready_o,         // 运算结束信号
    output reg               busy_o,          // 正在运算信号
    output reg[`RegNumbBus]  reg_w_addr_o      // 运算结束后需要写的寄存器
    );

    // 状态定义
    localparam STATE_IDLE  = 4'b0001;
    localparam STATE_START = 4'b0010;
    localparam STATE_CALC  = 4'b0100;
    localparam STATE_END   = 4'b1000;

    reg [3:0] state;
    reg [`RegWidthBus] div_result;
    reg [`RegWidthBus] div_remain;
    reg [2:0] op_r;
    reg [`RegWidthBus] dividend_r;
    reg [`RegWidthBus] divisor_r;
    reg [`RegWidthBus] minuend;          //
    reg invert_result;
    reg [31:0] count;

    wire op_div = (op_r == `INST_DIV);
    wire op_divu = (op_r == `INST_DIVU);
    wire op_rem = (op_r == `INST_REM);
    wire op_remu = (op_r == `INST_REMU);

    wire[31:0] dividend_invert = (-dividend_r);     //取反
    wire[31:0] divisor_invert = (-divisor_r);
    wire minuend_ge_divisor = minuend >= divisor_r;
    wire[31:0] minuend_sub_res = minuend - divisor_r;
    wire[31:0] div_result_tmp = minuend_ge_divisor? ({div_result[30:0], 1'b1}): ({div_result[30:0], 1'b0});
    wire[31:0] minuend_tmp = minuend_ge_divisor? minuend_sub_res[30:0]: minuend[30:0];

    //用状态机实现
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            state <= STATE_IDLE;
            ready_o <= 0;
            result_o <= 0;
            div_result <= 0;
            div_remain <= 0;
            op_r <= 0;
            reg_w_addr_o <= 0;
            dividend_r <= 0;
            divisor_r <= 0;
            minuend <= 0;
            invert_result <= 0;
            busy_o <= 0;
            count <= 0;
        end
        else begin
            case(state)
                STATE_IDLE : begin
                    if(start_i) begin
                        op_r <= op_i;
                        dividend_r <= dividend_i;
                        divisor_r <= divisor_i;
                        reg_w_addr_o <= reg_w_addr_i;
                        state <= STATE_START;
                        busy_o <= 1;
                    end
                    else begin
                        op_r <= 0;
                        dividend_r <= 0;
                        divisor_r <= 0;
                        reg_w_addr_o <= 0;       
                        busy_o <= 0;
                        ready_o <= 0;
                        result_o <= 0;
                 //    state <= STATE_IDLE;
                    end
                end
                STATE_START: begin
                    if(start_i) begin
                        if(divisor_r == 0) begin            // 除数为0
                            if(op_div | op_divu) begin
                                result_o <= 32'hffffffff;
                            end
                            else begin              //若是取余数的指令
                                result_o <= dividend_r;
                            end
                            ready_o <= 1'b1;
                            state <= STATE_IDLE;
                            busy_o <= 1'b0;
                        end
                        else begin                           // 除数不为0
                            busy_o <= 1;
                            count <= 32'h4000_0000;          //  ??
                            state <= STATE_CALC;
                            div_result <= 0;
                            div_remain <= 0;

                            // DIV和REM这两条指令是有符号数运算指令
                            if (op_div | op_rem) begin
                                // 被除数求补码
                                if (dividend_r[31] == 1'b1) begin
                                    dividend_r <= dividend_invert;
                                    minuend <= dividend_invert[31];
                                end else begin
                                    minuend <= dividend_r[31];
                                end
                                // 除数求补码
                                if (divisor_r[31] == 1'b1) begin
                                    divisor_r <= divisor_invert;
                                end
                            end else begin
                                minuend <= dividend_r[31];
                            end

                            // 运算结束后是否要对结果取补码
                            if ((op_div && (dividend_r[31] ^ divisor_r[31] == 1'b1))
                                || (op_rem && (dividend_r[31] == 1'b1))) begin
                                invert_result <= 1'b1;
                            end else begin
                                invert_result <= 1'b0;
                            end
                        end
                    end
                    else begin
                        state <= STATE_IDLE;
                        result_o <= 0;
                        ready_o <= 0;
                        busy_o <= 0;
                    end
                end
                STATE_CALC : begin
                    if (start_i == 1) begin
                        dividend_r <= {dividend_r[30:0], 1'b0};
                        div_result <= div_result_tmp;
                        count <= {1'b0, count[31:1]};         //试商法循环31次
                        if (|count) begin
                            minuend <= {minuend_tmp[30:0], dividend_r[30]};
                        end else begin
                            state <= STATE_END;
                            if (minuend_ge_divisor) begin
                                div_remain <= minuend_sub_res;
                            end else begin
                                div_remain <= minuend;
                            end
                        end
                    end else begin
                        state <= STATE_IDLE;
                        result_o <= 0;
                        ready_o <= 0;
                        busy_o <= 0;
                    end
                end
                STATE_END  : begin
                    if (start_i == 1) begin
                        ready_o <= 1;
                        state <= STATE_IDLE;
                        busy_o <= 0;
                        if (op_div | op_divu) begin
                            if (invert_result) begin
                                result_o <= (-div_result);
                            end else begin
                                result_o <= div_result;
                            end
                        end else begin
                            if (invert_result) begin
                                result_o <= (-div_remain);
                            end else begin
                                result_o <= div_remain;
                            end
                        end
                    end else begin
                        state <= STATE_IDLE;
                        result_o <= 0;
                        ready_o <= 0;
                        busy_o <= 0;
                    end
                end
            endcase
        end
    end

endmodule
