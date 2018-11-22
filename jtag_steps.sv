
wait(100)  //test comment

jtag_test_req()  

wait(100) 

jtag_read_expect(ABS_REG_CFG_MAIN_CLKS, 32'hffff_ffff)

wait(100)
jtag_write_single(ABS_REG_DAC_WORK , 32'h0000040D)

wait(100)
