`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/01/02 08:59:28
// Design Name: 
// Module Name: idu
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
//instrction decode unit
module idu(
 //   input wire clk,
    input wire rstn,

    //from if2id 
    input wire [`InstBus]       inst_i,
    input wire [`InstAddrBus]   inst_addr_i,    //指令地址

    //from regfile
    input wire [`RegWidthBus] reg1_r_data_i,   //通用寄存器(源操作数)1输入数据
    input wire [`RegWidthBus] reg2_r_data_i,   //

    //from CSR reg
    input wire [`RegWidthBus] csr_r_data_i,

    //from exu
    input wire ex_jump_flag_i,              //跳转标志

    //to regfile
    output reg [`RegNumbBus] reg1_r_addr_o,
    output reg [`RegNumbBus] reg2_r_addr_o,

    //to CSR reg
    output reg [`MemAddrBus] csr_r_addr_o,

    //to exu
    output reg[`MemAddrBus]  op1_o,             //从寄存器得到的源操作数      
    output reg[`MemAddrBus]  op2_o,
    output reg[`MemAddrBus]  op1_jump_o,        //??
    output reg[`MemAddrBus]  op2_jump_o,
    output reg[`InstBus]     inst_o,             // 指令内容
    output reg[`InstAddrBus] inst_addr_o,        // 指令地址
    output reg[`RegWidthBus] reg1_r_data_o,       // 通用寄存器1数据
    output reg[`RegWidthBus] reg2_r_data_o,       // 通用寄存器2数据
    output reg               reg_we_o,           // 写通用寄存器标志
    output reg[`RegNumbBus]  reg_w_addr_o,       // 写通用寄存器地址
    output reg               csr_we_o,          // 写CSR寄存器标志
    output reg[`RegWidthBus] csr_r_data_o,      // CSR寄存器数据
    output reg[`MemAddrBus]  csr_w_addr_o       // 写CSR寄存器地址

    );

    wire [6:0] opcode = inst_i[6:0];
    wire [2:0] funct3 = inst_i[14:12];
    wire [6:0] funct7 = inst_i[31:25];
    wire [4:0] rd =     inst_i[11:7];
    wire [4:0] rs1 =    inst_i[19:15];
    wire [4:0] rs2 =    inst_i[24:20];    

    always @(*) begin
        inst_o = inst_i;                    //这里需要修改？？？
        inst_addr_o = inst_addr_i;
        reg1_r_data_o = reg1_r_data_i;
        reg2_r_data_o = reg2_r_data_i;
        csr_r_data_o = csr_r_data_i;
        csr_r_addr_o = 0;
        csr_w_addr_o = 0;
        csr_we_o = 0;
        op1_o = 0;
        op2_o = 0;
        op1_jump_o = 0;
        op2_jump_o = 0;

        case(opcode)
            `INST_TYPE_I: begin
                case(funct3)
                    `INST_ADDI, `INST_SLTI, `INST_SLTIU, `INST_XORI, `INST_ORI, `INST_ANDI, `INST_SLLI, `INST_SRI: begin
                        reg_we_o = 1;
                        reg_w_addr_o = rd;
                        reg1_r_addr_o = rs1;
                        reg2_r_addr_o = 0;
                        op1_o = reg1_r_data_i;
                        op2_o = {{20{inst_i[31]}},inst_i[31:20]};    //寄存器和立即数为操作数
                    end
                    default: begin
                        reg_we_o = 0;
                        reg_w_addr_o = 0;
                        reg1_r_addr_o = 0;
                        reg2_r_addr_o = 0;
                    end
                endcase
            end
            `INST_TYPE_L: begin
                case (funct3)
                    `INST_LB, `INST_LH, `INST_LW, `INST_LBU, `INST_LHU: begin
                        reg1_r_addr_o = rs1;        
                        reg2_r_addr_o = 0;
                        reg_we_o = 1;
                        reg_w_addr_o = rd;          //取出数据写入目标寄存器
                        op1_o = reg1_r_data_i;      //基址
                        op2_o = {{20{inst_i[31]}}, inst_i[31:20]};
                    end
                    default: begin
                        reg_we_o = 0;
                        reg_w_addr_o = 0;
                        reg1_r_addr_o = 0;
                        reg2_r_addr_o = 0;
                    end
                endcase
            end
            `INST_TYPE_S: begin
                case (funct3)
                    `INST_SB, `INST_SW, `INST_SH: begin
                        reg1_r_addr_o = rs1;
                        reg2_r_addr_o = rs2;
                        reg_we_o = 0;
                        reg_w_addr_o = 0;
                        op1_o = reg1_r_data_i;
                        op2_o = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
                    end
                    default: begin
                        reg_we_o = 0;
                        reg_w_addr_o = 0;
                        reg1_r_addr_o = 0;
                        reg2_r_addr_o = 0;
                    end
                endcase
            end
            `INST_TYPE_R_M: begin
                if((funct7 == 7'b0000000) || (funct7 == 7'b0100000)) begin
                    case(funct3) 
                        `INST_ADD_SUB, `INST_SLL, `INST_SLT, `INST_SLTU, `INST_XOR, `INST_SR, `INST_OR, `INST_AND: begin
                            reg_we_o = 1;
                            reg_w_addr_o = rd;
                            reg1_r_addr_o = rs1;
                            reg2_r_addr_o = rs2;
                            op1_o = reg1_r_data_i;
                            op2_o = reg2_r_data_i;
                        end
                        default: begin
                            reg_we_o = 0;
                            reg_w_addr_o = 0;
                            reg1_r_addr_o = 0;
                            reg2_r_addr_o = 0;
                        end
                    endcase
                end
                else if(funct7 == 7'b0000001) begin
                    case(funct3)
                        `INST_MUL, `INST_MULHU, `INST_MULH, `INST_MULHSU: begin
                            reg_we_o = 1;
                            reg_w_addr_o = rd;
                            reg1_r_addr_o = rs1;
                            reg2_r_addr_o = rs2;
                            op1_o = reg1_r_data_i;
                            op2_o = reg2_r_data_i;
                        end
                        `INST_DIV, `INST_DIVU, `INST_REM, `INST_REMU: begin    //这里和乘法部分有区别
                            reg_we_o = 0;
                            reg_w_addr_o = rd;
                            reg1_r_addr_o = rs1;
                            reg2_r_addr_o = rs2;
                            op1_o = reg1_r_data_i;
                            op2_o = reg2_r_data_i;
                            op1_jump_o = inst_addr_i;       //为什么除法单独弄跳转地址？
                            op2_jump_o = 32'h4;
                        end
                        default: begin
                            reg_we_o = 0;
                            reg_w_addr_o = 0;
                            reg1_r_addr_o = 0;
                            reg2_r_addr_o = 0;
                        end
                    endcase
                end
                else begin
                    reg_we_o = 0;
                    reg_w_addr_o = 0;
                    reg1_r_addr_o = 0;
                    reg2_r_addr_o = 0;
                end
            end
            `INST_JAL: begin                        //jamp and link
                reg_we_o = 1;
                reg_w_addr_o = rd;
                reg1_r_addr_o = 0;
                reg2_r_addr_o = 0;
                op1_o = inst_addr_i;            //PC
                op2_o = 32'h4;
                op1_jump_o = inst_addr_i;
                op2_jump_o = {{12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};        //立即数
            end
            `INST_JALR: begin
                reg_we_o = 1;
                reg_w_addr_o = rd;
                reg1_r_addr_o = rs1;
                reg2_r_addr_o = 0;
                op1_o = inst_addr_i;
                op2_o = 32'h4;
                op1_jump_o = reg1_r_data_i;
                op2_jump_o = {{20{inst_i[31]}}, inst_i[31:20]};
            end
            `INST_LUI: begin
                reg_we_o = 1;
                reg_w_addr_o = rd;
                reg1_r_addr_o = 0;
                reg2_r_addr_o = 0;
                op1_o = {inst_i[31:12], 12'b0};
                op2_o = 0;
            end
            `INST_AUIPC: begin
                reg_we_o = 1;
                reg_w_addr_o = rd;
                reg1_r_addr_o = 0;
                reg2_r_addr_o = 0;
                op1_o = inst_addr_i;
                op2_o = {inst_i[31:12], 12'b0};
            end
            `INST_NOP_OP: begin
                reg_we_o = 0;
                reg_w_addr_o = 0;
                reg1_r_addr_o = 0;
                reg2_r_addr_o = 0;
            end
            `INST_FENCE: begin              //
                reg_we_o = 0;
                reg_w_addr_o = 0;
                reg1_r_addr_o = 0;
                reg2_r_addr_o = 0;
                op1_jump_o = inst_addr_i;
                op2_jump_o = 32'h4;
            end
            `INST_TYPE_B: begin
                case (funct3)
                    `INST_BEQ, `INST_BNE, `INST_BLT, `INST_BGE, `INST_BLTU, `INST_BGEU: begin
                        reg1_r_addr_o = rs1;
                        reg2_r_addr_o = rs2;
                        reg_we_o = 0;
                        reg_w_addr_o = 0;
                        op1_o = reg1_r_data_i;
                        op2_o = reg2_r_data_i;
                        op1_jump_o = inst_addr_i;           //PC
                        op2_jump_o = {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};          //imm
                    end
                    default: begin
                        reg1_r_addr_o = 0;
                        reg2_r_addr_o = 0;
                        reg_we_o = 0;
                        reg_w_addr_o = 0;
                    end
                endcase
            end
            `INST_CSR: begin
                reg_we_o = 0;
                reg_w_addr_o = 0;
                reg1_r_addr_o = 0;
                reg2_r_addr_o = 0;
                csr_r_addr_o = {20'h0, inst_i[31:20]};      //寄存器地址
                csr_w_addr_o = {20'h0, inst_i[31:20]};
                case (funct3)
                    `INST_CSRRW, `INST_CSRRS, `INST_CSRRC: begin
                        reg1_r_addr_o = rs1;
                        reg2_r_addr_o = 0;
                        reg_we_o = 1;
                        reg_w_addr_o = rd;
                        csr_we_o = 1;
                    end
                    `INST_CSRRWI, `INST_CSRRSI, `INST_CSRRCI: begin
                        reg1_r_addr_o = 0;
                        reg2_r_addr_o = 0;
                        reg_we_o = 1;
                        reg_w_addr_o = rd;
                        csr_we_o = 1;
                    end
                    default: begin
                        reg_we_o = 0;
                        reg_w_addr_o = 0;
                        reg1_r_addr_o = 0;
                        reg2_r_addr_o = 0;
                        csr_we_o = 0;
                    end
                endcase
            end
            default: begin
                reg_we_o = 0;
                reg_w_addr_o = 0;
                reg1_r_addr_o = 0;
                reg2_r_addr_o = 0;
            end            
        endcase
    end
endmodule
