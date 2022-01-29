`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/01/03 13:13:13
// Design Name: 
// Module Name: exu
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
//执行模块；组合逻辑实现
module exu(
    input wire rstn,

    //from idu
    input wire[`InstBus]        inst_i,            // 指令内容
    input wire[`InstAddrBus]    inst_addr_i,      // 指令地址
    input wire                  reg_we_i,         // 是否写通用寄存器
    input wire[`RegNumbBus]     reg_w_addr_i,       // 写通用寄存器地址
    input wire[`RegWidthBus]    reg1_r_data_i,       // 通用寄存器1输入数据
    input wire[`RegWidthBus]    reg2_r_data_i,       // 通用寄存器2输入数据
    input wire                  csr_we_i,         // 是否写CSR寄存器
    input wire[`MemAddrBus]     csr_w_addr_i,    // 写CSR寄存器地址
    input wire[`RegWidthBus]    csr_r_data_i,        // CSR寄存器输入数据
    input wire                  int_assert_i,       // 中断发生标志
    input wire[`InstAddrBus]    int_addr_i,       // 中断跳转地址
    input wire[`MemAddrBus]     op1_i,
    input wire[`MemAddrBus]     op2_i,
    input wire[`MemAddrBus]     op1_jump_i,
    input wire[`MemAddrBus]     op2_jump_i,   

    //from RAM mem
    input wire[`MemBus] mem_r_data_i,        //内存输入数据

    //from divu
    input wire               div_ready_i,                 // 除法运算完成标志
    input wire[`RegWidthBus] div_result_i,                // 除法运算结果
    input wire               div_busy_i,                  // 除法运算忙标志
    input wire[`RegNumbBus]  div_reg_w_addr_i,            // 除法运算结束后要写的寄存器地址

    //to mem 
    output reg[`MemBus]     mem_w_data_o,        // 写内存数据
    output reg[`MemAddrBus] mem_r_addr_o,       // 读内存地址
    output reg[`MemAddrBus] mem_w_addr_o,       // 写内存地址
    output wire             mem_we_o,          // 是否要写内存
    output wire             mem_req_o,         // 请求访问内存标志

    //to regfile
    output wire[`RegWidthBus] reg_w_data_o,       // 写寄存器数据
    output wire               reg_we_o,          // 是否要写通用寄存器
    output wire[`RegNumbBus]  reg_w_addr_o,       // 写通用寄存器地址

    //to csr reg
    output reg[`RegWidthBus]  csr_w_data_o,        // 写CSR寄存器数据
    output wire               csr_we_o,            // 是否要写CSR寄存器
    output wire[`MemAddrBus]  csr_w_addr_o,         // 写CSR寄存器地址

    //to divu
    output wire              div_start_o,                // 开始除法运算标志
    output reg[`RegWidthBus] div_dividend_o,             // 被除数
    output reg[`RegWidthBus] div_divisor_o,              // 除数
    output reg[2:0]          div_op_o,                   // 具体是哪一条除法指令
    output reg[`RegNumbBus]  div_reg_w_addr_o,            // 除法运算结束后要写的寄存器地址

    //to ctrl
    output wire               hold_flag_o,                // 是否暂停标志
    output wire               jump_flag_o,                // 是否跳转标志
    output wire[`InstAddrBus] jump_addr_o                 // 跳转目的地址
    );

    reg [`RegWidthBus] mul_op1;
    reg [`RegWidthBus] mul_op2;
    wire [`DoubleRegBus] mul_temp;
    wire [`DoubleRegBus] mul_temp_invert;
    wire [31:0] reg1_data_invert;
    wire [31:0] reg2_data_invert;

    assign reg1_data_invert = ~reg1_r_data_i + 1;
    assign reg2_data_invert = ~reg2_r_data_i + 1;

    assign mul_temp = mul_op1 * mul_op2;         //两个乘法操作数直接相乘
    assign mul_temp_invert = ~mul_temp + 1;

    //译码
    wire [6:0] opcode = inst_i[6:0];            //直接在定义时赋值跟 先定义再用assign赋值有什么区别？？
    wire [2:0] funct3 = inst_i[14:12];
    wire [6:0] funct7 = inst_i[31:25];
    wire [4:0] rd =     inst_i[11:7];
    // wire [4:0] rs1 =    inst_i[19:15];
    // wire [4:0] rs2 =    inst_i[24:20];
    wire [4:0] zimm   = inst_i[19:15];

    //div
    reg div_we;
    reg [`RegWidthBus] div_w_data;          //除法结果
    reg [`RegNumbBus] div_w_addr;
    reg div_start;
    reg div_jump_flag;                      //   
    reg div_hold_flag;
    reg [`InstAddrBus] div_jump_addr;       //除法跳转地址

    wire [31:0] op1_add_op2;
    wire [31:0] op1_jump_add_op2_jump;

    //操作数相加
    assign op1_add_op2 = op1_i + op2_i;             //操作数直接相加
    assign op1_jump_add_op2_jump = op1_jump_i + op2_jump_i;     

    // 有符号数比较
    wire op1_ge_op2_signed;
    assign op1_ge_op2_signed = $signed(op1_i) >= $signed(op2_i);
    // 无符号数比较
    wire op1_ge_op2_unsigned;
    wire op1_eq_op2;
    assign op1_ge_op2_unsigned = op1_i >= op2_i;
    assign op1_eq_op2 = (op1_i == op2_i);

    reg reg_we;
    reg [`RegNumbBus] reg_w_addr;
    reg mem_req;
    reg jump_flag;              //发生跳转标志
    reg hold_flag;
    reg [`InstAddrBus] jump_addr;       //跳转地址
    reg mem_we;
    reg [`RegWidthBus] reg_w_data;
    wire [1:0] mem_r_addr_index;
    wire [1:0] mem_w_addr_index;

    assign mem_r_addr_index = (op1_i + op2_i) & 2'b11;      //获取地址最小两位;判断读取第几个字节
    assign mem_w_addr_index = (op1_i + op2_i) & 2'b11;

    //shift right (immediate);
    wire [31:0] sr_shift = reg1_r_data_i >> reg2_r_data_i[4:0];     //不带立即数，这时从寄存器2中的地址取移位量
    wire [31:0] sri_shift = reg1_r_data_i >> inst_i[24:20];          //带立即数的移位
    wire [31:0] sr_shift_mask = 32'hffffffff >> reg2_r_data_i[4:0];  //??
    wire [31:0] sri_shift_mask = 32'hffffffff >> inst_i[24:20];

    assign reg_w_data_o = reg_w_data | div_w_data;
//    assign jump_addr_o = int_assert_i ? int_addr_i: (jump_addr | div_jump_addr);
    assign div_start_o = int_assert_i ? 0 : div_start;
     // 响应中断时不写通用寄存器
    assign reg_we_o = int_assert_i ? 0: (reg_we || div_we);
    assign reg_w_addr_o = reg_w_addr | div_w_addr;
     // 响应中断时不写内存
    assign mem_we_o = int_assert_i ? 0 : mem_we;
    // 响应中断时不向总线请求访问内存
    assign mem_req_o = int_assert_i ? 0: mem_req;

    assign hold_flag_o = hold_flag || div_hold_flag;
    assign jump_flag_o = jump_flag || div_jump_flag || ((int_assert_i) ? 1: 0);
    assign jump_addr_o = (int_assert_i) ? int_addr_i: (jump_addr | div_jump_addr);

    // 响应中断时不写CSR寄存器
    assign csr_we_o = (int_assert_i) ? 0: csr_we_i;
    assign csr_w_addr_o = csr_w_addr_i;

/**********************************************************************/
    //处理乘法指令
    always @(*) begin
        if((opcode == `INST_TYPE_R_M) && (funct7 == 7'b0000001)) begin
            case (funct3)
                `INST_MUL, `INST_MULHU: begin
                    mul_op1 = reg1_r_data_i;
                    mul_op2 = reg2_r_data_i;
                end
                `INST_MULHSU: begin
                    mul_op1 = (reg1_r_data_i[31] == 1'b1)? (reg1_data_invert): reg1_r_data_i;
                    mul_op2 = reg2_r_data_i;
                end
                `INST_MULH: begin
                    mul_op1 = (reg1_r_data_i[31] == 1'b1)? (reg1_data_invert): reg1_r_data_i;
                    mul_op2 = (reg2_r_data_i[31] == 1'b1)? (reg2_data_invert): reg2_r_data_i;
                end
                default: begin
                    mul_op1 = reg1_r_data_i;
                    mul_op2 = reg2_r_data_i;
                end
            endcase
        end
        else begin
            mul_op1 = reg1_r_data_i;
            mul_op2 = reg2_r_data_i;
        end
    end

    //处理除法指令
    always @(*) begin
        div_dividend_o = reg1_r_data_i;
        div_divisor_o = reg2_r_data_i;
        div_op_o = funct3;
        div_reg_w_addr_o = reg_w_addr_i;
        if ((opcode == `INST_TYPE_R_M) && (funct7 == 7'b0000001)) begin
            div_we = 0;
            div_w_data = 0;
            div_w_addr = 0;
            case (funct3)
                `INST_DIV, `INST_DIVU, `INST_REM, `INST_REMU: begin
                    div_start = 1;
                    div_jump_flag = 1;
                    div_hold_flag = 1;
                    div_jump_addr = op1_jump_add_op2_jump;
                end
                default: begin
                    div_start = 0;
                    div_jump_flag = 0;
                    div_hold_flag = 0;
                    div_jump_addr = 0;
                end
            endcase
        end else begin
            div_jump_flag = 0;
            div_jump_addr = 0;
            if (div_busy_i) begin
                div_start = 1;
                div_we = 0;
                div_w_data = 0;
                div_w_addr = 0;
                div_hold_flag = 1;
            end else begin
                div_start = 0;
                div_hold_flag = 0;
                if (div_ready_i) begin
                    div_w_data = div_result_i;
                    div_w_addr = div_reg_w_addr_i;
                    div_we = 1;
                end else begin
                    div_we = 0;
                    div_w_data = 0;
                    div_w_addr = 0;
                end
            end
        end
    end

    // 执行其它类型指令
    always @ (*) begin
        reg_we = reg_we_i;
        reg_w_addr = reg_w_addr_i;
        mem_req = 0;
        csr_w_data_o = 0;

        case (opcode)
            `INST_TYPE_I: begin
                case (funct3)
                    `INST_ADDI: begin
                        jump_flag = 0;
                        hold_flag = 0;
                        jump_addr = 0;
                        mem_w_data_o = 0;
                        mem_r_addr_o = 0;
                        mem_w_addr_o = 0;
                        mem_we = 0;
                        reg_w_data = op1_add_op2;
                    end
                    `INST_SLTI: begin       //set less than inmmediate
                        jump_flag = 0;
                        hold_flag = 0;
                        jump_addr = 0;
                        mem_w_data_o = 0;
                        mem_r_addr_o = 0;
                        mem_w_addr_o = 0;
                        mem_we = 0;
                        reg_w_data = {32{(~op1_ge_op2_signed)}} & 32'h1;
                    end
                    `INST_SLTIU: begin
                        jump_flag = 0;
                        hold_flag = 0;
                        jump_addr = 0;
                        mem_w_data_o = 0;
                        mem_r_addr_o = 0;
                        mem_w_addr_o = 0;
                        mem_we = 0;
                        reg_w_data = {32{(~op1_ge_op2_unsigned)}} & 32'h1;
                    end
                    `INST_XORI: begin
                        jump_flag = 0;
                        hold_flag = 0;
                        jump_addr = 0;
                        mem_w_data_o = 0;
                        mem_r_addr_o = 0;
                        mem_w_addr_o = 0;
                        mem_we = 0;
                        reg_w_data = op1_i ^ op2_i;
                    end
                    `INST_ORI: begin
                        jump_flag = 0;
                        hold_flag = 0;
                        jump_addr = 0;
                        mem_w_data_o = 0;
                        mem_r_addr_o = 0;
                        mem_w_addr_o = 0;
                        mem_we = 0;
                        reg_w_data = op1_i | op2_i;
                    end
                    `INST_ANDI: begin
                        jump_flag = 0;
                        hold_flag = 0;
                        jump_addr = 0;
                        mem_w_data_o = 0;
                        mem_r_addr_o = 0;
                        mem_w_addr_o = 0;
                        mem_we = 0;
                        reg_w_data = op1_i & op2_i;
                    end
                    `INST_SLLI: begin               //shift left logical immediate
                        jump_flag = 0;
                        hold_flag = 0;
                        jump_addr = 0;
                        mem_w_data_o = 0;
                        mem_r_addr_o = 0;
                        mem_w_addr_o = 0;
                        mem_we = 0;
                        reg_w_data = reg1_r_data_i << inst_i[24:20];
                        //reg_w_data = op1_i << op2_i[4:0];
                    end
                    `INST_SRI: begin
                        jump_flag = 0;
                        hold_flag = 0;
                        jump_addr = 0;
                        mem_w_data_o = 0;
                        mem_r_addr_o = 0;
                        mem_w_addr_o = 0;
                        mem_we = 0;
                        if (inst_i[30] == 1'b1) begin       //算术右移
                            reg_w_data = (sri_shift & sri_shift_mask) | ({32{reg1_r_data_i[31]}} & (~sri_shift_mask));
                        end else begin                      //逻辑右移
                            reg_w_data = reg1_r_data_i >> inst_i[24:20];
                        end
                    end
                    default: begin
                        jump_flag = 0;
                        hold_flag = 0;
                        jump_addr = 0;
                        mem_w_data_o = 0;
                        mem_r_addr_o = 0;
                        mem_w_addr_o = 0;
                        mem_we = 0;
                        reg_w_data = 0;
                    end
                endcase
            end
            `INST_TYPE_R_M: begin
                if ((funct7 == 7'b0000000) || (funct7 == 7'b0100000)) begin
                    case (funct3)
                        `INST_ADD_SUB: begin
                            jump_flag = 0;
                            hold_flag = 0;
                            jump_addr = 0;
                            mem_w_data_o = 0;
                            mem_r_addr_o = 0;
                            mem_w_addr_o = 0;
                            mem_we = 0;
                            if (inst_i[30] == 1'b0) begin
                                reg_w_data = op1_add_op2;
                            end else begin
                                reg_w_data = op1_i - op2_i;
                            end
                        end
                        `INST_SLL: begin            //shift left logical
                            jump_flag = 0;
                            hold_flag = 0;
                            jump_addr = 0;
                            mem_w_data_o = 0;
                            mem_r_addr_o = 0;
                            mem_w_addr_o = 0;
                            mem_we = 0;
                            reg_w_data = op1_i << op2_i[4:0];
                        end
                        `INST_SLT: begin            //set less than
                            jump_flag = 0;
                            hold_flag = 0;
                            jump_addr = 0;
                            mem_w_data_o = 0;
                            mem_r_addr_o = 0;
                            mem_w_addr_o = 0;
                            mem_we = 0;
                            reg_w_data = {32{(~op1_ge_op2_signed)}} & 32'h1;
                        end
                        `INST_SLTU: begin
                            jump_flag = 0;
                            hold_flag = 0;
                            jump_addr = 0;
                            mem_w_data_o = 0;
                            mem_r_addr_o = 0;
                            mem_w_addr_o = 0;
                            mem_we = 0;
                            reg_w_data = {32{(~op1_ge_op2_unsigned)}} & 32'h1;
                        end
                        `INST_XOR: begin
                            jump_flag = 0;
                            hold_flag = 0;
                            jump_addr = 0;
                            mem_w_data_o = 0;
                            mem_r_addr_o = 0;
                            mem_w_addr_o = 0;
                            mem_we = 0;
                            reg_w_data = op1_i ^ op2_i;
                        end
                        `INST_SR: begin                     //shift right
                            jump_flag = 0;
                            hold_flag = 0;
                            jump_addr = 0;
                            mem_w_data_o = 0;
                            mem_r_addr_o = 0;
                            mem_w_addr_o = 0;
                            mem_we = 0;
                            if (inst_i[30] == 1'b1) begin
                                reg_w_data = (sr_shift & sr_shift_mask) | ({32{reg1_r_data_i[31]}} & (~sr_shift_mask));
                            end else begin
                                reg_w_data = op1_i >> op2_i[4:0];
                            end
                        end
                        `INST_OR: begin
                            jump_flag = 0;
                            hold_flag = 0;
                            jump_addr = 0;
                            mem_w_data_o = 0;
                            mem_r_addr_o = 0;
                            mem_w_addr_o = 0;
                            mem_we = 0;
                            reg_w_data = op1_i | op2_i;
                        end
                        `INST_AND: begin
                            jump_flag = 0;
                            hold_flag = 0;
                            jump_addr = 0;
                            mem_w_data_o = 0;
                            mem_r_addr_o = 0;
                            mem_w_addr_o = 0;
                            mem_we = 0;
                            reg_w_data = op1_i & op2_i;
                        end
                        default: begin
                            jump_flag = 0;
                            hold_flag = 0;
                            jump_addr = 0;
                            mem_w_data_o = 0;
                            mem_r_addr_o = 0;
                            mem_w_addr_o = 0;
                            mem_we = 0;
                            reg_w_data = 0;
                        end
                    endcase
                end else if (funct7 == 7'b0000001) begin
                    case (funct3)
                        `INST_MUL: begin
                            jump_flag = 0;
                            hold_flag = 0;
                            jump_addr = 0;
                            mem_w_data_o = 0;
                            mem_r_addr_o = 0;
                            mem_w_addr_o = 0;
                            mem_we = 0;
                            reg_w_data = mul_temp[31:0];
                        end
                        `INST_MULHU: begin       //无符号数相乘，取高32位
                            jump_flag = 0;
                            hold_flag = 0;
                            jump_addr = 0;
                            mem_w_data_o = 0;
                            mem_r_addr_o = 0;
                            mem_w_addr_o = 0;
                            mem_we = 0;
                            reg_w_data = mul_temp[63:32];
                        end
                        `INST_MULH: begin              //有符号
                            jump_flag = 0;
                            hold_flag = 0;
                            jump_addr = 0;
                            mem_w_data_o = 0;
                            mem_r_addr_o = 0;
                            mem_w_addr_o = 0;
                            mem_we = 0;
                            case ({reg1_r_data_i[31], reg2_r_data_i[31]})
                                2'b00: begin
                                    reg_w_data = mul_temp[63:32];
                                end
                                2'b11: begin
                                    reg_w_data = mul_temp[63:32];
                                end
                                2'b10: begin
                                    reg_w_data = mul_temp_invert[63:32];
                                end
                                default: begin
                                    reg_w_data = mul_temp_invert[63:32];
                                end
                            endcase
                        end
                        `INST_MULHSU: begin
                            jump_flag = 0;
                            hold_flag = 0;
                            jump_addr = 0;
                            mem_w_data_o = 0;
                            mem_r_addr_o = 0;
                            mem_w_addr_o = 0;
                            mem_we = 0;
                            if (reg1_r_data_i[31] == 1'b1) begin
                                reg_w_data = mul_temp_invert[63:32];
                            end else begin
                                reg_w_data = mul_temp[63:32];
                            end
                        end
                        default: begin
                            jump_flag = 0;
                            hold_flag = 0;
                            jump_addr = 0;
                            mem_w_data_o = 0;
                            mem_r_addr_o = 0;
                            mem_w_addr_o = 0;
                            mem_we = 0;
                            reg_w_data = 0;
                        end
                    endcase
                end else begin
                    jump_flag = 0;
                    hold_flag = 0;
                    jump_addr = 0;
                    mem_w_data_o = 0;
                    mem_r_addr_o = 0;
                    mem_w_addr_o = 0;
                    mem_we = 0;
                    reg_w_data = 0;
                end
            end
            `INST_TYPE_L: begin
                case (funct3)
                    `INST_LB: begin     //memory load byte
                        jump_flag = 0;
                        hold_flag = 0;
                        jump_addr = 0;
                        mem_w_data_o = 0;
                        mem_w_addr_o = 0;
                        mem_we = 0;
                        mem_req = 1;
                        mem_r_addr_o = op1_add_op2;         //基址加立即数得到内存地址
                        case (mem_r_addr_index)
                            2'b00: begin
                                reg_w_data = {{24{mem_r_data_i[7]}}, mem_r_data_i[7:0]};
                            end
                            2'b01: begin
                                reg_w_data = {{24{mem_r_data_i[15]}}, mem_r_data_i[15:8]};
                            end
                            2'b10: begin
                                reg_w_data = {{24{mem_r_data_i[23]}}, mem_r_data_i[23:16]};
                            end
                            default: begin
                                reg_w_data = {{24{mem_r_data_i[31]}}, mem_r_data_i[31:24]};
                            end
                        endcase
                    end
                    `INST_LH: begin             //load halfword
                        jump_flag = 0;
                        hold_flag = 0;
                        jump_addr = 0;
                        mem_w_data_o = 0;
                        mem_w_addr_o = 0;
                        mem_we = 0;
                        mem_req = 1;
                        mem_r_addr_o = op1_add_op2;
                        if (mem_r_addr_index == 2'b0) begin
                            reg_w_data = {{16{mem_r_data_i[15]}}, mem_r_data_i[15:0]};
                        end else begin
                            reg_w_data = {{16{mem_r_data_i[31]}}, mem_r_data_i[31:16]};
                        end
                    end
                    `INST_LW: begin
                        jump_flag = 0;
                        hold_flag = 0;
                        jump_addr = 0;
                        mem_w_data_o = 0;
                        mem_w_addr_o = 0;
                        mem_we = 0;
                        mem_req = 1;
                        mem_r_addr_o = op1_add_op2;
                        reg_w_data = mem_r_data_i;
                    end
                    `INST_LBU: begin
                        jump_flag = 0;
                        hold_flag = 0;
                        jump_addr = 0;
                        mem_w_data_o = 0;
                        mem_w_addr_o = 0;
                        mem_we = 0;
                        mem_req = 1;
                        mem_r_addr_o = op1_add_op2;
                        case (mem_r_addr_index)
                            2'b00: begin
                                reg_w_data = {24'h0, mem_r_data_i[7:0]};
                            end
                            2'b01: begin
                                reg_w_data = {24'h0, mem_r_data_i[15:8]};
                            end
                            2'b10: begin
                                reg_w_data = {24'h0, mem_r_data_i[23:16]};
                            end
                            default: begin
                                reg_w_data = {24'h0, mem_r_data_i[31:24]};
                            end
                        endcase
                    end
                    `INST_LHU: begin
                        jump_flag = 0;
                        hold_flag = 0;
                        jump_addr = 0;
                        mem_w_data_o = 0;
                        mem_w_addr_o = 0;
                        mem_we = 0;
                        mem_req = 1;
                        mem_r_addr_o = op1_add_op2;
                        if (mem_r_addr_index == 2'b0) begin
                            reg_w_data = {16'h0, mem_r_data_i[15:0]};
                        end else begin
                            reg_w_data = {16'h0, mem_r_data_i[31:16]};
                        end
                    end
                    default: begin
                        jump_flag = 0;
                        hold_flag = 0;
                        jump_addr = 0;
                        mem_w_data_o = 0;
                        mem_r_addr_o = 0;
                        mem_w_addr_o = 0;
                        mem_we = 0;
                        reg_w_data = 0;
                    end
                endcase
            end
            `INST_TYPE_S: begin
                case (funct3)
                    `INST_SB: begin         //store byte
                        jump_flag = 0;
                        hold_flag = 0;
                        jump_addr = 0;
                        reg_w_data = 0;
                        mem_we = 1;
                        mem_req = 1;
                        mem_w_addr_o = op1_add_op2;
                        mem_r_addr_o = op1_add_op2;
                        case (mem_w_addr_index)
                            2'b00: begin
                                mem_w_data_o = {mem_r_data_i[31:8], reg2_r_data_i[7:0]};
                            end
                            2'b01: begin
                                mem_w_data_o = {mem_r_data_i[31:16], reg2_r_data_i[7:0], mem_r_data_i[7:0]};
                            end
                            2'b10: begin
                                mem_w_data_o = {mem_r_data_i[31:24], reg2_r_data_i[7:0], mem_r_data_i[15:0]};
                            end
                            default: begin
                                mem_w_data_o = {reg2_r_data_i[7:0], mem_r_data_i[23:0]};
                            end
                        endcase
                    end
                    `INST_SH: begin
                        jump_flag = 0;
                        hold_flag = 0;
                        jump_addr = 0;
                        reg_w_data = 0;
                        mem_we = 1;
                        mem_req = 1;
                        mem_w_addr_o = op1_add_op2;
                        mem_r_addr_o = op1_add_op2;
                        if (mem_w_addr_index == 2'b00) begin
                            mem_w_data_o = {mem_r_data_i[31:16], reg2_r_data_i[15:0]};
                        end else begin
                            mem_w_data_o = {reg2_r_data_i[15:0], mem_r_data_i[15:0]};
                        end
                    end
                    `INST_SW: begin
                        jump_flag = 0;
                        hold_flag = 0;
                        jump_addr = 0;
                        reg_w_data = 0;
                        mem_we = 1;
                        mem_req = 1;
                        mem_w_addr_o = op1_add_op2;
                        mem_r_addr_o = op1_add_op2;
                        mem_w_data_o = reg2_r_data_i;
                    end
                    default: begin
                        jump_flag = 0;
                        hold_flag = 0;
                        jump_addr = 0;
                        mem_w_data_o = 0;
                        mem_r_addr_o = 0;
                        mem_w_addr_o = 0;
                        mem_we = 0;
                        reg_w_data = 0;
                    end
                endcase
            end
            `INST_TYPE_B: begin     //branch
                case (funct3)
                    `INST_BEQ: begin
                        hold_flag = 0;
                        mem_w_data_o = 0;
                        mem_r_addr_o = 0;
                        mem_w_addr_o = 0;
                        mem_we = 0;
                        reg_w_data = 0;
                        jump_flag = op1_eq_op2 & 1'b1;
                        jump_addr = {32{op1_eq_op2}} & op1_jump_add_op2_jump;    //PC+imm
                    end
                    `INST_BNE: begin
                        hold_flag = 0;
                        mem_w_data_o = 0;
                        mem_r_addr_o = 0;
                        mem_w_addr_o = 0;
                        mem_we = 0;
                        reg_w_data = 0;
                        jump_flag = (~op1_eq_op2) & 1;
                        jump_addr = {32{(~op1_eq_op2)}} & op1_jump_add_op2_jump;  
                    end
                    `INST_BLT: begin
                        hold_flag = 0;
                        mem_w_data_o = 0;
                        mem_r_addr_o = 0;
                        mem_w_addr_o = 0;
                        mem_we = 0;
                        reg_w_data = 0;
                        jump_flag = (~op1_ge_op2_signed) & 1;
                        jump_addr = {32{(~op1_ge_op2_signed)}} & op1_jump_add_op2_jump;  
                    end
                    `INST_BGE: begin
                        hold_flag = 0;
                        mem_w_data_o = 0;
                        mem_r_addr_o = 0;
                        mem_w_addr_o = 0;
                        mem_we = 0;
                        reg_w_data = 0;
                        jump_flag = (op1_ge_op2_signed) & 1;
                        jump_addr = {32{(op1_ge_op2_signed)}} & op1_jump_add_op2_jump;
                    end
                    `INST_BLTU: begin
                        hold_flag = 0;
                        mem_w_data_o = 0;
                        mem_r_addr_o = 0;
                        mem_w_addr_o = 0;
                        mem_we = 0;
                        reg_w_data = 0;
                        jump_flag = (~op1_ge_op2_unsigned) & 1;
                        jump_addr = {32{(~op1_ge_op2_unsigned)}} & op1_jump_add_op2_jump;
                    end
                    `INST_BGEU: begin
                        hold_flag = 0;
                        mem_w_data_o = 0;
                        mem_r_addr_o = 0;
                        mem_w_addr_o = 0;
                        mem_we = 0;
                        reg_w_data = 0;
                        jump_flag = (op1_ge_op2_unsigned) & 1;
                        jump_addr = {32{(op1_ge_op2_unsigned)}} & op1_jump_add_op2_jump;
                    end
                    default: begin
                        jump_flag = 0;
                        hold_flag = 0;
                        jump_addr = 0;
                        mem_w_data_o = 0;
                        mem_r_addr_o = 0;
                        mem_w_addr_o = 0;
                        mem_we = 0;
                        reg_w_data = 0;
                    end
                endcase
            end
            `INST_JAL, `INST_JALR: begin            // jump and link register
                hold_flag = 0;
                mem_w_data_o = 0;
                mem_r_addr_o = 0;
                mem_w_addr_o = 0;
                mem_we = 0;
                jump_flag = 1;
                jump_addr = op1_jump_add_op2_jump;     //JAL: PC+imm; JARL:rs1+imm;    
                reg_w_data = op1_add_op2;              //PC+4
            end
            `INST_LUI, `INST_AUIPC: begin       //load upper imm; add upper imm to pc
                hold_flag = 0;
                mem_w_data_o = 0;
                mem_r_addr_o = 0;
                mem_w_addr_o = 0;
                mem_we = 0;
                jump_addr = 0;
                jump_flag = 0;
                reg_w_data = op1_add_op2;
            end
            `INST_NOP_OP: begin
                jump_flag = 0;
                hold_flag = 0;
                jump_addr = 0;
                mem_w_data_o = 0;
                mem_r_addr_o = 0;
                mem_w_addr_o = 0;
                mem_we = 0;
                reg_w_data = 0;
            end
            `INST_FENCE: begin
                hold_flag = 0;
                mem_w_data_o = 0;
                mem_r_addr_o = 0;
                mem_w_addr_o = 0;
                mem_we = 0;
                reg_w_data = 0;
                jump_flag = 1;
                jump_addr = op1_jump_add_op2_jump;      //pc+4
            end
            `INST_CSR: begin
                jump_flag = 0;
                hold_flag = 0;
                jump_addr = 0;
                mem_w_data_o = 0;
                mem_r_addr_o = 0;
                mem_w_addr_o = 0;
                mem_we = 0;
                case (funct3)
                    `INST_CSRRW: begin          //Atomic Read/Write CSR
                        csr_w_data_o = reg1_r_data_i;
                        reg_w_data = csr_r_data_i;
                    end
                    `INST_CSRRS: begin          //Atomic Read and Set Bits in CSR
                        csr_w_data_o = reg1_r_data_i | csr_r_data_i;    //用寄存器的值作为掩码重置CSR的值
                        reg_w_data = csr_r_data_i;
                    end
                    `INST_CSRRC: begin         //Atomic Read and Clear Bits in CSR
                        csr_w_data_o = csr_r_data_i & (~reg1_r_data_i);
                        reg_w_data = csr_r_data_i;
                    end
                    `INST_CSRRWI: begin        //下面三个是上面三个的变体，只是换成用立即数
                        csr_w_data_o = {27'h0, zimm};
                        reg_w_data = csr_r_data_i;
                    end
                    `INST_CSRRSI: begin
                        csr_w_data_o = {27'h0, zimm} | csr_r_data_i;
                        reg_w_data = csr_r_data_i;
                    end
                    `INST_CSRRCI: begin
                        csr_w_data_o = (~{27'h0, zimm}) & csr_r_data_i;
                        reg_w_data = csr_r_data_i;
                    end
                    default: begin
                        jump_flag = 0;
                        hold_flag = 0;
                        jump_addr = 0;
                        mem_w_data_o = 0;
                        mem_r_addr_o = 0;
                        mem_w_addr_o = 0;
                        mem_we = 0;
                        reg_w_data = 0;
                    end
                endcase
            end
            default: begin
                jump_flag = 0;
                hold_flag = 0;
                jump_addr = 0;
                mem_w_data_o = 0;
                mem_r_addr_o = 0;
                mem_w_addr_o = 0;
                mem_we = 0;
                reg_w_data = 0;
            end
        endcase
    end
endmodule
