`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/01/01 10:01:33
// Design Name: 
// Module Name: define
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

`define CpuResetAddr 32'h0

`define InstAddrBus 31:0

//流水线暂停;三级流水线 三种暂停
`define Hold_Flag_Bus 2:0
`define Hold_None     3'b000
`define Hold_Pc       3'b001         
`define Hold_If       3'b010 
`define Hold_Id       3'b011        //3个流水线都暂停

//common regfile
`define RegNumbBus  4:0
`define RegNumb  32
`define RegWidth    32
`define RegWidthBus 31:0
`define DoubleRegBus 63:0

//Memory
`define MemAddrBus 31:0    //
`define MemBus  31:0
`define MemNum 4096

//Rom
`define RomNum 4096

// CSR reg addr
`define CSR_CYCLE   12'hc00        //User CSR; Standard read-only
`define CSR_CYCLEH  12'hc80        //User CSR; Standard read-only
`define CSR_MTVEC   12'h305
`define CSR_MCAUSE  12'h342
`define CSR_MEPC    12'h341
`define CSR_MIE     12'h304
`define CSR_MSTATUS 12'h300
`define CSR_MSCRATCH 12'h340

// CSR inst
`define INST_CSR    7'b1110011
`define INST_CSRRW  3'b001
`define INST_CSRRS  3'b010
`define INST_CSRRC  3'b011
`define INST_CSRRWI 3'b101
`define INST_CSRRSI 3'b110
`define INST_CSRRCI 3'b111

//instruction 
`define InstBus 31:0
`define InstAddrBus 31:0

// I type inst
`define INST_TYPE_I 7'b0010011
`define INST_ADDI   3'b000
`define INST_SLTI   3'b010          //当小于时置位的指令
`define INST_SLTIU  3'b011          //
`define INST_XORI   3'b100
`define INST_ORI    3'b110
`define INST_ANDI   3'b111
`define INST_SLLI   3'b001          //左移
`define INST_SRI    3'b101          //右移位指令

// Load type inst
`define INST_TYPE_L 7'b0000011
`define INST_LB     3'b000
`define INST_LH     3'b001
`define INST_LW     3'b010
`define INST_LBU    3'b100
`define INST_LHU    3'b101

// S type inst
`define INST_TYPE_S 7'b0100011
`define INST_SB     3'b000
`define INST_SH     3'b001
`define INST_SW     3'b010

// R and M type inst
`define INST_TYPE_R_M 7'b0110011
// R type inst
`define INST_ADD_SUB 3'b000
`define INST_SLL    3'b001
`define INST_SLT    3'b010
`define INST_SLTU   3'b011
`define INST_XOR    3'b100
`define INST_SR     3'b101
`define INST_OR     3'b110
`define INST_AND    3'b111
// M type inst
`define INST_MUL    3'b000
`define INST_MULH   3'b001
`define INST_MULHSU 3'b010
`define INST_MULHU  3'b011
`define INST_DIV    3'b100
`define INST_DIVU   3'b101
`define INST_REM    3'b110
`define INST_REMU   3'b111

// J type inst
`define INST_JAL    7'b1101111
`define INST_JALR   7'b1100111
//U type
`define INST_LUI    7'b0110111
`define INST_AUIPC  7'b0010111

`define INST_NOP    32'h00000001            //
`define INST_NOP_OP 7'b0000001

`define INST_MRET   32'h30200073
`define INST_RET    32'h00008067

`define INST_FENCE  7'b0001111                  //fence指令对外部可见的访存请求，如设备I / O和内存访问等进行串行化

`define INST_ECALL  32'h73                     //ecall指令用于向运行时环境发出请求                
`define INST_EBREAK 32'h00100073               //

// B type inst
`define INST_TYPE_B 7'b1100011
`define INST_BEQ    3'b000
`define INST_BNE    3'b001
`define INST_BLT    3'b100
`define INST_BGE    3'b101
`define INST_BLTU   3'b110
`define INST_BGEU   3'b11