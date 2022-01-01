`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/01/01 10:56:49
// Design Name: 
// Module Name: regfile
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

module regfile(
    input wire clk,
    input wire rstn,

    //from exu
    input wire                  we_i,
    input wire [`RegNumbBus]    w_regnum_i,
    input wire [`RegWidthBus]   w_data_i,

    //from idu (instruction decode unit)
    input wire [`RegNumbBus] r_addr1_i,
    input wire [`RegNumbBus] r_addr2_i,

    //to idu
    output reg [`RegWidthBus] r_data1_o,
    output reg [`RegWidthBus] r_data2_o,

    //from Jtag
    input wire                  jtag_wen_i,
    input wire [`RegNumbBus]     jtag_regnum_i,
    input wire [`RegWidthBus]    jtag_w_data_i,

    //to jtag
    output reg [`RegWidthBus]    jtag_data_o
    );

    reg [`RegWidthBus]  regs [0:`RegNumb-1];  //32 common regfile

    //write regtfile
    always @(posedge clk) begin
        if(rstn) begin         //会有优先级别
            if(we_i && (w_regnum_i != 0)) begin
                regs[w_regnum_i] <= w_data_i;
            end
            else if(jtag_wen_i && (jtag_regnum_i != 0)) begin
                regs[jtag_regnum_i] <= jtag_w_data_i;
            end
        end
    end

    //read source operand 1
    always @(*) begin
        if(r_addr1_i == 0) begin
            r_data1_o = 0;
        end
        else if((r_addr1_i == w_regnum_i) && we_i) begin  //若读写的寄存器是同一个，则直接输出要写的值
            r_data1_o = w_data_i;
        end        
        else begin
            r_data1_o = regs[r_addr1_i];
        end 
    end

    //read source operand 2
    always @(*) begin
        if(r_addr2_i == 0) begin
            r_data2_o = 0;
        end
        else if((r_addr2_i == w_regnum_i) && we_i) begin  //若读写的寄存器是同一个，则直接输出要写的值
            r_data2_o = w_data_i;
        end        
        else begin
            r_data2_o = regs[r_addr2_i];
        end 
    end

    //jtag read
        //read source operand 1
    always @(*) begin
        if(jtag_regnum_i == 0) begin
            jtag_data_o = 0;
        end
        // else if((r_addr1_i == w_regnum_i) && we_i) begin  //若读写的寄存器是同一个，则直接输出要写的值
        //     r_data1_o = w_data_i;
        // end        
        else begin
            jtag_data_o = regs[jtag_regnum_i];
        end 
    end

endmodule
