`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/01/01 14:46:49
// Design Name: 
// Module Name: csr_reg
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
// CSR寄存器模块
module csr_reg(
    input wire clk,
    input wire rstn,

    //from exu
    input wire  we_i,
    input wire [`MemAddrBus]  r_addr_i,         //ex模块读寄存器地址
    input wire [`MemAddrBus]  w_addr_i,
    input wire [`RegWidthBus] data_i,   

    //to exu
    output reg [`RegWidthBus] data_o,

    //from clint (clint::核心本地中断模块，对输入的中断请求信号进行总裁，产生最终的中断信号)
    input wire                clint_we_i,
    input wire [`MemAddrBus]  clint_r_addr_i,
    input wire [`MemAddrBus]  clint_w_addr_i,
    input wire [`RegWidthBus] clint_data_i,

    //to client
    output reg [`RegWidthBus] clint_data_o,
    output wire [`RegWidthBus] clint_csr_mtvec,
    output wire [`RegWidthBus] clint_csr_mepc,
    output wire [`RegWidthBus] clint_csr_mstatus,

    //global interrupt
    output wire [`RegWidthBus] global_inter_en_o

    );

    reg [`DoubleRegBus] cycle;
    reg [`RegWidthBus] mtvec;         //机器模式异常入口基地址寄存器（ Machine Trap-Vector Base-Address Register)
    reg [`RegWidthBus] mcause;        //机器模式异常原因寄存器
    reg [`RegWidthBus] mepc;          //机器模式异常PC寄存器
    reg [`RegWidthBus] mie;           //机器模式中断使能寄存器
    reg [`RegWidthBus] mstatus;       //机器模式状态寄存器
    reg [`RegWidthBus] mscratch;      //机器模式擦写寄存器

    assign global_inter_en_o = (mstatus[3] == 1'b1) ? 1 : 0;

    assign clint_csr_mtvec = mtvec;
    assign clint_csr_mepc  = mepc;
    assign clint_csr_mstatus = mstatus;

    //cycle counter; (复位撤销后就一直计数)    用处？？
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            cycle <= 0;
        end
        else begin
            cycle <= cycle + 1;
        end
    end

    //write reg
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            mtvec    <= 0;  
            mcause   <= 0; 
            mepc     <= 0;   
            mie      <= 0;    
            mstatus  <= 0;
            mscratch <= 0;
        end
        else begin  //会有写优先级
            if(we_i) begin     //针对CSR寄存器，RISC-V留有12位的地址空间
                case(w_addr_i[11:0])
                    `CSR_MTVEC   :begin
                        mtvec <= data_i;
                    end
                    `CSR_MCAUSE  :begin
                        mcause <= data_i;
                    end
                    `CSR_MEPC    :begin
                        mepc <= data_i;
                    end
                    `CSR_MIE     :begin
                        mie <= data_i;
                    end
                    `CSR_MSTATUS :begin
                        mstatus <= data_i;
                    end
                    `CSR_MSCRATCH:begin
                        mscratch <= data_i;
                    end
                    default: begin
                        
                    end

                endcase
            end
            else if(clint_we_i) begin
                case (clint_w_addr_i[11:0])
                    `CSR_MTVEC: begin
                        mtvec <= clint_data_i;
                    end
                    `CSR_MCAUSE: begin
                        mcause <= clint_data_i;
                    end
                    `CSR_MEPC: begin
                        mepc <= clint_data_i;
                    end
                    `CSR_MIE: begin
                        mie <= clint_data_i;
                    end
                    `CSR_MSTATUS: begin
                        mstatus <= clint_data_i;
                    end
                    `CSR_MSCRATCH: begin
                        mscratch <= clint_data_i;
                    end
                    default: begin

                    end
                endcase
            end
        end
    end

    //read reg; exu read CSR
    always @(*) begin
        if(w_addr_i[11:0] == r_addr_i[11:0] && we_i) begin
            data_o = data_i;
        end
        else begin
            case (r_addr_i[11:0])
                `CSR_CYCLE: begin
                    data_o = cycle[31:0];
                end
                `CSR_CYCLEH: begin
                    data_o = cycle[63:32];
                end
                `CSR_MTVEC: begin
                    data_o = mtvec;
                end
                `CSR_MCAUSE: begin
                    data_o = mcause;
                end
                `CSR_MEPC: begin
                    data_o = mepc;
                end
                `CSR_MIE: begin
                    data_o = mie;
                end
                `CSR_MSTATUS: begin
                    data_o = mstatus;
                end
                `CSR_MSCRATCH: begin
                    data_o = mscratch;
                end
                default: begin
                    data_o = 0;
                end
            endcase
        end
    end

    //clint read reg
    always @(*) begin
        if ((clint_w_addr_i[11:0] == clint_r_addr_i[11:0]) && clint_we_i) begin
            clint_data_o = clint_data_i;
        end else begin
            case (clint_r_addr_i[11:0])
                `CSR_CYCLE: begin
                    clint_data_o = cycle[31:0];
                end
                `CSR_CYCLEH: begin
                    clint_data_o = cycle[63:32];
                end
                `CSR_MTVEC: begin
                    clint_data_o = mtvec;
                end
                `CSR_MCAUSE: begin
                    clint_data_o = mcause;
                end
                `CSR_MEPC: begin
                    clint_data_o = mepc;
                end
                `CSR_MIE: begin
                    clint_data_o = mie;
                end
                `CSR_MSTATUS: begin
                    clint_data_o = mstatus;
                end
                `CSR_MSCRATCH: begin
                    clint_data_o = mscratch;
                end
                default: begin
                    clint_data_o = 0;
                end
            endcase
        end
    end

endmodule
