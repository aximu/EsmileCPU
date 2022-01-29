`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/01/01 10:37:07
// Design Name: 
// Module Name: esmilecpu
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

module esmilecpu(
    input wire clk,
    input wire rstn,

    //from pripheral
    input wire [`MemBus] rib_ex_data_i,

    //to pripheral
    output wire [`MemAddrBus] rib_ex_addr_o,    
    output wire [`MemBus]     rib_ex_data_o,
    output wire  rib_ex_req_o,
    output wire  rib_ex_we_o,

    //from rom
    input [`MemBus] rib_pc_data_i,
    //to rom
    output [`MemAddrBus] rib_pc_addr_o,

    //from JTAG
    input wire [`RegNumbBus]  jtag_reg_addr_i,
    input wire [`RegWidthBus] jtag_reg_data_i,
    input wire                jtag_reg_we_i,
    //to Jtag
    output wire [`RegWidthBus] jtag_reg_data_o,
    
    input wire rib_hold_flag_i,                // 总线暂停标志
    input wire jtag_halt_flag_i,               // jtag暂停标志
    input wire jtag_reset_flag_i,              // jtag复位PC标志

    input wire[`INT_BUS] int_i                 // 中断信号

    );

    // pc_reg模块输出信号
	wire[`InstAddrBus] pc_pc_o;

    // if2id模块输出信号
	wire[`InstBus] if_inst_o;
    wire[`InstAddrBus] if_inst_addr_o;
    wire[`INT_BUS] if_int_flag_o;

    // id模块输出信号
    wire[`RegNumbBus] id_reg1_r_addr_o;
    wire[`RegNumbBus] id_reg2_r_addr_o;
    wire[`InstBus] id_inst_o;
    wire[`InstAddrBus] id_inst_addr_o;
    wire[`RegWidthBus] id_reg1_r_data_o;
    wire[`RegWidthBus] id_reg2_r_data_o;
    wire id_reg_we_o;
    wire[`RegNumbBus] id_reg_w_addr_o;
    wire[`MemAddrBus] id_csr_r_addr_o;
    wire id_csr_we_o;
    wire[`RegWidthBus] id_csr_r_data_o;
    wire[`MemAddrBus] id_csr_w_addr_o;
    wire[`MemAddrBus] id_op1_o;
    wire[`MemAddrBus] id_op2_o;
    wire[`MemAddrBus] id_op1_jump_o;
    wire[`MemAddrBus] id_op2_jump_o;

    // id2ex模块输出信号
    wire[`InstBus] ie_inst_o;
    wire[`InstAddrBus] ie_inst_addr_o;
    wire ie_reg_we_o;
    wire[`RegNumbBus] ie_reg_w_addr_o;
    wire[`RegWidthBus] ie_reg1_r_data_o;
    wire[`RegWidthBus] ie_reg2_r_data_o;
    wire ie_csr_we_o;
    wire[`MemAddrBus] ie_csr_w_addr_o;
    wire[`RegWidthBus] ie_csr_r_data_o;
    wire[`MemAddrBus] ie_op1_o;
    wire[`MemAddrBus] ie_op2_o;
    wire[`MemAddrBus] ie_op1_jump_o;
    wire[`MemAddrBus] ie_op2_jump_o;

    // ex模块输出信号
    wire[`MemBus] ex_mem_w_data_o;
    wire[`MemAddrBus] ex_mem_r_addr_o;
    wire[`MemAddrBus] ex_mem_w_addr_o;
    wire ex_mem_we_o;
    wire ex_mem_req_o;
    wire[`RegWidthBus] ex_reg_w_data_o;
    wire ex_reg_we_o;
    wire[`RegNumbBus] ex_reg_w_addr_o;
    wire ex_hold_flag_o;
    wire ex_jump_flag_o;
    wire[`InstAddrBus] ex_jump_addr_o;
    wire ex_div_start_o;
    wire[`RegWidthBus] ex_div_dividend_o;
    wire[`RegWidthBus] ex_div_divisor_o;
    wire[2:0] ex_div_op_o;
    wire[`RegNumbBus] ex_div_reg_w_addr_o;
    wire[`RegWidthBus] ex_csr_w_data_o;
    wire ex_csr_we_o;
    wire[`MemAddrBus] ex_csr_w_addr_o;

    // regfile模块输出信号
    wire[`RegWidthBus] regs_r_data1_o;
    wire[`RegWidthBus] regs_r_data2_o;

    // csr_reg模块输出信号
    wire[`RegWidthBus] csr_data_o;
    wire[`RegWidthBus] csr_clint_data_o;
    wire csr_global_int_en_o;
    wire[`RegWidthBus] csr_clint_csr_mtvec;
    wire[`RegWidthBus] csr_clint_csr_mepc;
    wire[`RegWidthBus] csr_clint_csr_mstatus;

    // ctrl模块输出信号
    wire[`Hold_Flag_Bus] ctrl_hold_flag_o;
    wire ctrl_jump_flag_o;
    wire[`InstAddrBus] ctrl_jump_addr_o;

    // div模块输出信号
    wire[`RegWidthBus] div_result_o;
	wire div_ready_o;
    wire div_busy_o;
    wire[`RegNumbBus] div_reg_w_addr_o;

    // clint模块输出信号
    wire clint_we_o;
    wire[`MemAddrBus] clint_w_addr_o;
    wire[`MemAddrBus] clint_r_addr_o;
    wire[`RegWidthBus] clint_data_o;
    wire[`InstAddrBus] clint_int_addr_o;
    wire clint_int_assert_o;
    wire clint_hold_flag_o;

    assign rib_ex_addr_o = ex_mem_we_o ? ex_mem_w_addr_o : ex_mem_r_addr_o;   
    assign rib_ex_data_o = ex_mem_w_data_o; 
    assign rib_ex_req_o = ex_mem_req_o;
    assign rib_ex_we_o = ex_mem_we_o;

    assign rib_pc_addr_o = pc_pc_o;

/************************************************************/
    pc_reg u_pc_reg(
        .clk(clk),
        .rstn(rstn),
        .jump_flag_i(ctrl_jump_flag_o),
        .jump_addr_i(ctrl_jump_addr_o),
        .hold_flag_i(ctrl_hold_flag_o),
        .jtag_reset_flag_i(jtag_reset_flag_i),
        .pc_o(pc_pc_o)                  //PC addr
    );

    regfile u_regfile(
        .clk(clk),
        .rstn(rstn),
        .we_i(ex_reg_we_o),
        .w_regnum_i(ex_reg_w_addr_o),
        .w_data_i(ex_reg_w_data_o),
        .r_addr1_i(id_reg1_r_addr_o),
        .r_addr2_i(id_reg2_r_addr_o),
        .r_data1_o(regs_r_data1_o),
        .r_data2_o(regs_r_data2_o),
        .jtag_wen_i(jtag_reg_we_i),
        .jtag_regnum_i(jtag_reg_addr_i),        
        .jtag_w_data_i(jtag_reg_data_i),   
        .jtag_data_o(jtag_reg_data_o)     
    );

    csr_reg u_csr_reg(
        .clk (clk),
        .rstn(rstn),
        .we_i    (ex_csr_we_o),
        .r_addr_i(id_csr_r_addr_o),
        .w_addr_i(ex_csr_w_addr_o),
        .data_i  (ex_csr_w_data_o),
        .data_o  (csr_data_o),
        .clint_we_i    (clint_we_o),
        .clint_r_addr_i(clint_r_addr_o),
        .clint_w_addr_i(clint_w_addr_o),
        .clint_data_i  (clint_data_o),
        .clint_data_o     (csr_clint_data_o),
        .clint_csr_mtvec  (csr_clint_csr_mtvec),
        .clint_csr_mepc   (csr_clint_csr_mepc),
        .clint_csr_mstatus(csr_clint_csr_mstatus),
        .global_inter_en_o(csr_global_int_en_o)
    );

    if2id u_if2id(
        .clk (clk),
        .rstn(rstn),
        .inst_i     (rib_pc_data_i),
        .inst_addr_i(pc_pc_o),
        .int_flag_i(int_i),
        .int_flag_o(if_int_flag_o),
        .hold_flag_i(ctrl_hold_flag_o),
        .inst_o     (if_inst_o),
        .inst_addr_o(if_inst_addr_o)
    );

    idu u_idu(
        .rstn(rstn),
        .inst_i     (if_inst_o),
        .inst_addr_i(if_inst_addr_o),
        .reg1_r_data_i(regs_r_data1_o),
        .reg2_r_data_i(regs_r_data2_o),
        .csr_r_data_i(csr_data_o),
        .ex_jump_flag_i(ex_jump_flag_o),
        .reg1_r_addr_o(id_reg1_r_addr_o),
        .reg2_r_addr_o(id_reg2_r_addr_o),
        .csr_r_addr_o(id_csr_r_addr_o),   
        .op1_o(id_op1_o),
        .op2_o(id_op2_o),
        .op1_jump_o(id_op1_jump_o),
        .op2_jump_o(id_op2_jump_o),
        .inst_o(id_inst_o),
        .inst_addr_o(id_inst_addr_o),
        .reg1_r_data_o(id_reg1_r_data_o),
        .reg2_r_data_o(id_reg2_r_data_o),
        .reg_we_o(id_reg_we_o),
        .reg_w_addr_o(id_reg_w_addr_o),
        .csr_we_o(id_csr_we_o),                     
        .csr_r_data_o(id_csr_r_data_o),
        .csr_w_addr_o(id_csr_w_addr_o)
    );

    id_ex u_id_ex(
        .clk(clk),
        .rstn(rstn),
        .inst_i(id_inst_o),
        .inst_addr_i(id_inst_addr_o),
        .reg_we_i(id_reg_we_o),
        .reg_waddr_i(id_reg_w_addr_o),
        .reg1_rdata_i(id_reg1_r_data_o),
        .reg2_rdata_i(id_reg2_r_data_o),
        .hold_flag_i(ctrl_hold_flag_o),
        .inst_o(ie_inst_o),
        .inst_addr_o(ie_inst_addr_o),
        .reg_we_o(ie_reg_we_o),
        .reg_waddr_o(ie_reg_w_addr_o),
        .reg1_rdata_o(ie_reg1_r_data_o),
        .reg2_rdata_o(ie_reg2_r_data_o),
        .op1_i(id_op1_o),
        .op2_i(id_op2_o),
        .op1_jump_i(id_op1_jump_o),
        .op2_jump_i(id_op2_jump_o),
        .op1_o(ie_op1_o),
        .op2_o(ie_op2_o),
        .op1_jump_o(ie_op1_jump_o),
        .op2_jump_o(ie_op2_jump_o),
        .csr_we_i(id_csr_we_o),
        .csr_waddr_i(id_csr_w_addr_o),
        .csr_rdata_i(id_csr_r_data_o),
        .csr_we_o(ie_csr_we_o),
        .csr_waddr_o(ie_csr_w_addr_o),
        .csr_rdata_o(ie_csr_r_data_o)
    );

    exu u_exu(
        .rstn(rstn),
        .inst_i(ie_inst_o),
        .inst_addr_i(ie_inst_addr_o),
        .reg_we_i(ie_reg_we_o),
        .reg_w_addr_i(ie_reg_w_addr_o),
        .reg1_r_data_i(ie_reg1_r_data_o),
        .reg2_r_data_i(ie_reg2_r_data_o),
        .csr_we_i(ie_csr_we_o),
        .csr_w_addr_i(ie_csr_w_addr_o),
        .csr_r_data_i(ie_csr_r_data_o),
        .int_assert_i(clint_int_assert_o),
        .int_addr_i(clint_int_addr_o),
        .op1_i(ie_op1_o),
        .op2_i(ie_op2_o),
        .op1_jump_i(ie_op1_jump_o),
        .op2_jump_i(ie_op2_jump_o),
        .mem_r_data_i(rib_ex_data_i),
        .div_ready_i(div_ready_o),
        .div_result_i(div_result_o),
        .div_busy_i(div_busy_o),
        .div_reg_w_addr_i(div_reg_w_addr_o),     
        .mem_w_data_o(ex_mem_w_data_o),
        .mem_r_addr_o(ex_mem_r_addr_o),
        .mem_w_addr_o(ex_mem_w_addr_o),
        .mem_we_o(ex_mem_we_o),
        .mem_req_o(ex_mem_req_o),
        .reg_w_data_o(ex_reg_w_data_o),
        .reg_we_o(ex_reg_we_o),
        .reg_w_addr_o(ex_reg_w_addr_o),
        .csr_w_data_o(ex_csr_w_data_o),
        .csr_we_o(ex_csr_we_o),
        .csr_w_addr_o(ex_csr_w_addr_o),
        .div_start_o(ex_div_start_o),
        .div_dividend_o(ex_div_dividend_o),
        .div_divisor_o(ex_div_divisor_o),
        .div_op_o(ex_div_op_o),
        .div_reg_w_addr_o(ex_div_reg_w_addr_o),
        .hold_flag_o(ex_hold_flag_o),
        .jump_flag_o(ex_jump_flag_o),
        .jump_addr_o(ex_jump_addr_o)      
    );

    ctrl u_ctrl(
        .rstn(rstn),
        .jump_flag_i(ex_jump_flag_o),
        .jump_addr_i(ex_jump_addr_o),
        .hold_flag_ex_i(ex_hold_flag_o),
        .hold_flag_rib_i(rib_hold_flag_i),
        .jtag_halt_flag_i(jtag_halt_flag_i),
        .hold_flag_clint_i(clint_hold_flag_o),
        .hold_flag_o(ctrl_hold_flag_o),
        .jump_flag_o(ctrl_jump_flag_o),
        .jump_addr_o(ctrl_jump_addr_o)
    );

    clint u_clint(
        .clk(clk),
        .rstn(rstn),
        .int_flag_i(if_int_flag_o),
        .inst_i(id_inst_o),
        .inst_addr_i(id_inst_addr_o),
        .jump_flag_i(ex_jump_flag_o),
        .jump_addr_i(ex_jump_addr_o),
        .hold_flag_i(ctrl_hold_flag_o),
        .div_started_i(ex_div_start_o),
        .data_i(csr_clint_data_o),
        .csr_mtvec(csr_clint_csr_mtvec),
        .csr_mepc(csr_clint_csr_mepc),
        .csr_mstatus(csr_clint_csr_mstatus),
        .we_o(clint_we_o),
        .w_addr_o(clint_w_addr_o),
        .r_addr_o(clint_r_addr_o),
        .data_o(clint_data_o),
        .hold_flag_o(clint_hold_flag_o),
        .global_int_en_i(csr_global_int_en_o),
        .int_addr_o(clint_int_addr_o),
        .int_assert_o(clint_int_assert_o)
    );

    divu u_divu(
        .clk(clk),
        .rstn(rstn),
        .dividend_i(ex_div_dividend_o),
        .divisor_i(ex_div_divisor_o),
        .start_i(ex_div_start_o),
        .op_i(ex_div_op_o),
        .reg_w_addr_i(ex_div_reg_w_addr_o),
        .result_o(div_result_o),
        .ready_o(div_ready_o),
        .busy_o(div_busy_o),
        .reg_w_addr_o(div_reg_w_addr_o)
    );

endmodule
