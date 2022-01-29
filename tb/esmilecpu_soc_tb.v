`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/01/05 19:50:30
// Design Name: 
// Module Name: esmilecpu_soc_tb
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

`include "../rtl/core/define.v"

module esmilecpu_soc_tb();

    reg clk;
    reg rstn;

    always #10 clk = ~clk;

    wire[`RegWidthBus] x3 = esmilecpu_soc_top_0.u_esmilecpu.u_regfile.regs[3];
    wire[`RegWidthBus] x26 = esmilecpu_soc_top_0.u_esmilecpu.u_regfile.regs[26];
    wire[`RegWidthBus] x27 = esmilecpu_soc_top_0.u_esmilecpu.u_regfile.regs[27];

    integer r;

    initial begin
        clk = 0;
        rstn = 0;
        $display("test running...");
        #40 
        rstn = 1;
        #200
        
        wait(x26 == 32'b1)   //wait sim end, when x26 == 1
        #100
        if(x27 == 32'b1) begin
            $display("~~~~~~~~~~~~~~~~~~~ TEST_PASS ~~~~~~~~~~~~~~~~~~~");
            $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
            $display("~~~~~~~~~ #####     ##     ####    #### ~~~~~~~~~");
            $display("~~~~~~~~~ #    #   #  #   #       #     ~~~~~~~~~");
            $display("~~~~~~~~~ #    #  #    #   ####    #### ~~~~~~~~~");
            $display("~~~~~~~~~ #####   ######       #       #~~~~~~~~~");
            $display("~~~~~~~~~ #       #    #  #    #  #    #~~~~~~~~~");
            $display("~~~~~~~~~ #       #    #   ####    #### ~~~~~~~~~");
            $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        end
        else begin
            $display("~~~~~~~~~~~~~~~~~~~ TEST_FAIL ~~~~~~~~~~~~~~~~~~~~");
            $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
            $display("~~~~~~~~~~######    ##       #    #     ~~~~~~~~~~");
            $display("~~~~~~~~~~#        #  #      #    #     ~~~~~~~~~~");
            $display("~~~~~~~~~~#####   #    #     #    #     ~~~~~~~~~~");
            $display("~~~~~~~~~~#       ######     #    #     ~~~~~~~~~~");
            $display("~~~~~~~~~~#       #    #     #    #     ~~~~~~~~~~");
            $display("~~~~~~~~~~#       #    #     #    ######~~~~~~~~~~");
            $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
            $display("fail testnum = %2d", x3);
            for (r = 0; r < 32; r = r + 1) begin
                $display("x%2d = 0x%x", r, esmilecpu_soc_top_0.u_esmilecpu.u_regfile.regs[r]);
            end
        end

        $finish;
    end

        // sim timeout
    initial begin
        #500000
        $display("Time Out.");
        $finish;
    end

    // read mem data
    initial begin
        $readmemh ("inst.data", esmilecpu_soc_top_0.u_rom._rom);
    end

        // generate wave file, used by gtkwave
    initial begin
        $dumpfile("esmilecpu_soc_tb.vcd");
        $dumpvars(0, esmilecpu_soc_tb);
    end

    esmilecpu_soc_top esmilecpu_soc_top_0(
        .clk(clk),
        .rstn(rstn),
        // .over   (),
        // .success(),
        // .halted_ind(),
         .uart_debug_pin(1'b0)
        // .uart_tx_pin(),
        // .uart_rx_pin(),
        // .gpio(),
        // .jtag_TCK(),
        // .jtag_TMS(),
        // .jtag_TDI(),
        // .jtag_TDO(),
        // .spi_miso(),
        // .spi_mosi(),
        // .spi_ss  (),
        // .spi_clk ()
    );

endmodule
