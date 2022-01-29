import sys
import os
import subprocess

def main():

    #1.将bin文件转成能写入到ROM里的mem文件
    cmd = r'python ../tools/Bin2Mem_CLI.py' + ' ' + sys.argv[1] + ' ' + sys.argv[2]
    f = os.popen(cmd)
    f.close()
    
    # 2.编译rtl文件
    cmd = r'python compile_rtl.py' + r' ..'
    f = os.popen(cmd)
    f.close()



    #运行  
    vvp_cmd = [r'vvp']         
    vvp_cmd.append(r'out.vvp')
    process = subprocess.Popen(vvp_cmd)
    try:
        process.wait(timeout = 20)
    except subprocess.TimeoutExpired:
        print('!!!Fail, vvp exec time out!!! ')
    

if __name__ == '__main__':
    sys.exit(main())
