import sys
import filecmp
import subprocess
import sys
import os


# 主函数
def main():
    rtl_dir = sys.argv[1]

    tb_file = r'/tb/esmilecpu_soc_tb.v'
    # if rtl_dir != r'..':
    #     tb_file = r'/tb/compliance_test/tinyriscv_soc_tb.v'
    # else:
    #     tb_file = r'/tb/esmilecpu_soc_tb.v'

    # iverilog程序
    iverilog_cmd = ['iverilog']
    # 顶层模块
    #iverilog_cmd += ['-s', r'tinyriscv_soc_tb']
    # 编译生成文件
    iverilog_cmd += ['-o', r'out.vvp']
    # 头文件(defines.v)路径
    iverilog_cmd += ['-I', rtl_dir + r'/rtl/core']
    # 宏定义，仿真输出文件
    iverilog_cmd += ['-D', r'OUTPUT="signature.output"']
    # testbench文件
    iverilog_cmd.append(rtl_dir + tb_file)
    # ../rtl/core
    iverilog_cmd.append(rtl_dir + r'/rtl/core/clint.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/core/csr_reg.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/core/ctrl.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/core/define.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/core/divu.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/core/exu.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/core/idu.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/core/id2ex.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/core/if2id.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/core/pc_reg.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/core/regfile.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/core/rib.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/core/esmilecpu.v')
    # ../rtl/perips
    iverilog_cmd.append(rtl_dir + r'/rtl/peripheral/ram.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/peripheral/rom.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/peripheral/timer.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/peripheral/uart.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/peripheral/gpio.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/peripheral/spi.v')
    # ../rtl/debug
    iverilog_cmd.append(rtl_dir + r'/rtl/debug/jtag_dm.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/debug/jtag_driver.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/debug/jtag_top.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/debug/uart_debug.v')
    # ../rtl/soc
    iverilog_cmd.append(rtl_dir + r'/rtl/soc/esmilecpu_soc_top.v')
    # ../rtl/utils
    iverilog_cmd.append(rtl_dir + r'/rtl/utils/full_handshake_rx.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/utils/full_handshake_tx.v')
    #iverilog_cmd.append(rtl_dir + r'/rtl/utils/gen_buf.v')
    iverilog_cmd.append(rtl_dir + r'/rtl/utils/gen_dff.v')

   # print('Compile done!!!')
    # 编译
    process = subprocess.Popen(iverilog_cmd)
    process.wait(timeout=5)
   
    

if __name__ == '__main__':
    sys.exit(main())
