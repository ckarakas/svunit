import svunit_pkg::*;

`define CLK_PERIOD 5

`define APB_EXPECT(ADDR,WRITE,SEL,ENABLE,DATA) \
  `FAIL_IF(my_apb_if.paddr   !== ADDR); \
  `FAIL_IF(my_apb_if.pwrite  !== WRITE); \
  `FAIL_IF(my_apb_if.psel    !== SEL); \
  `FAIL_IF(my_apb_if.penable !== ENABLE); \
  `FAIL_IF(my_apb_if.pwdata  !== DATA)

`define APB_SET(ADDR,WRITE,SEL,ENABLE,DATA) \
  my_apb_if.paddr   = ADDR; \
  my_apb_if.pwrite  = WRITE; \
  my_apb_if.psel    = SEL; \
  my_apb_if.penable = ENABLE; \
  my_apb_if.pwdata  = DATA

`include "svunit_defines.svh"
`include "apb_if.sv"
typedef class c_apb_if_unit_test;

module apb_if_unit_test;
  c_apb_if_unit_test unittest;
  string name = "apb_if_ut";

  logic clk;
  initial begin
    clk = 1;
    forever #`CLK_PERIOD clk = ~clk;
  end

  apb_if my_apb_if(.clk(clk));

  function void setup();
    unittest = new(name, my_apb_if);
  endfunction
endmodule

class c_apb_if_unit_test extends svunit_testcase;

  virtual apb_if.mstr my_apb_if;

  //===================================
  // Constructor
  //===================================
  function new(string name,
               virtual apb_if.mstr my_apb_if);
    super.new(name);

    this.my_apb_if = my_apb_if;
  endfunction


  //===================================
  // Setup for running the Unit Tests
  //===================================
  task setup();
    /* Place Setup Code Here */
  endtask


  //===================================
  // This is where we run all the Unit
  // Tests
  //===================================
  task run_test();
    super.run_test();

  endtask


  //===================================
  // Here we deconstruct anything we 
  // need after running the Unit Tests
  //===================================
  task teardown();
    super.teardown();
    /* Place Teardown Code Here */
  endtask

  logic [31:0] rdata;

  `SVUNIT_TESTS_BEGIN

  //--------------------------------------------------
  // Test: async_reset_if
  //
  // verify the pins on the interface can be
  // asynchronously reset
  //--------------------------------------------------
  `SVTEST(async_reset_if_test)
    #1 my_apb_if.async_reset();
    `APB_EXPECT(0, 0, 0, 0, 0);
  `SVTEST_END(async_reset_if_test)

  //--------------------------------------------------
  // Test: sync_reset_if
  //
  // verify the pins on the interface can be
  // synchronously reset (to the negedge of clk)
  //--------------------------------------------------
  `SVTEST(sync_reset_if_test)
    `APB_SET(1, 1, 1, 1, 1);

    @(posedge my_apb_if.clk);
    fork
      my_apb_if.sync_reset();
    join_none

    #(`CLK_PERIOD - 1);
    `APB_EXPECT(1, 1, 1, 1, 1);

    @(negedge my_apb_if.clk) #1;
    `APB_EXPECT(0, 0, 0, 0, 0);
  `SVTEST_END(sync_reset_if_test)

  //--------------------------------------------------
  // Test: write_1_psel
  //
  // verify the psel is asserted for 2 cycles then
  // de-asserted
  //--------------------------------------------------
  `SVTEST(write_1_psel)
    fork
      my_apb_if.write();
    join_none

    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.psel !== 1);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.psel !== 1);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.psel !== 0);
  `SVTEST_END(write_1_psel)

  //--------------------------------------------------
  // Test: write_2_psel
  //
  // verify the psel is asserted for 4 cycles then
  // de-asserted (back-to-back writes)
  //--------------------------------------------------
  `SVTEST(write_2_psel)
    fork
      repeat (2) my_apb_if.write();
    join_none

    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.psel !== 1);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.psel !== 1);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.psel !== 1);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.psel !== 1);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.psel !== 0);
  `SVTEST_END(write_2_psel)

  //--------------------------------------------------
  // Test: write_1_penable
  //
  // verify the penable is asserted for 1 cycle then
  // de-asserted
  //--------------------------------------------------
  `SVTEST(write_1_penable)
    fork
      my_apb_if.write();
    join_none

    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.penable !== 0);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.penable !== 1);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.penable !== 0);
  `SVTEST_END(write_1_penable)

  //--------------------------------------------------
  // Test: write_2_penable
  //
  // verify the penable is asserted twice in 4 cycles
  //--------------------------------------------------
  `SVTEST(write_2_penable)
    fork
      repeat (2) my_apb_if.write();
    join_none

    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.penable !== 0);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.penable !== 1);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.penable !== 0);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.penable !== 1);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.penable !== 0);
  `SVTEST_END(write_2_penable)

  //--------------------------------------------------
  // Test: write_1_paddr
  //
  // verify the paddr changes on the first clk edge
  //--------------------------------------------------
  `SVTEST(write_1_paddr)
    fork
      my_apb_if.write(1);
    join_none

    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.paddr !== 1);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.paddr !== 1);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.paddr !== 8'hx);
  `SVTEST_END(write_1_paddr)

  //--------------------------------------------------
  // Test: write_2_paddr
  //
  // verify the paddr transitions directly from 2 to
  // 3 for consecutive writes
  //--------------------------------------------------
  `SVTEST(write_2_paddr)
    fork
      begin
        my_apb_if.write(2);
        my_apb_if.write(3);
      end
    join_none

    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.paddr !== 2);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.paddr !== 2);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.paddr !== 3);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.paddr !== 3);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.paddr !== 8'hx);
  `SVTEST_END(write_2_paddr)

  //--------------------------------------------------
  // Test: write_1_pwdata
  //
  // verify the pwdata changes on the first clk edge
  //--------------------------------------------------
  `SVTEST(write_1_pwdata)
    fork
      my_apb_if.write(0, 12);
    join_none

    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.pwdata !== 12);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.pwdata !== 12);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.pwdata !== 32'hx);
  `SVTEST_END(write_1_pwdata)

  //--------------------------------------------------
  // Test: write_2_pwdata
  //
  // verify the pwdata transitions directly from 13 to
  // 14 for consecutive writes
  //--------------------------------------------------
  `SVTEST(write_2_pwdata)
    fork
      begin
        my_apb_if.write(0, 13);
        my_apb_if.write(0, 14);
      end
    join_none

    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.pwdata !== 13);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.pwdata !== 13);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.pwdata !== 14);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.pwdata !== 14);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.pwdata !== 32'hx);
  `SVTEST_END(write_2_pwdata)

  //--------------------------------------------------
  // Test: write_1_pwrite
  //
  // verify the pwrite changes on the first clk edge
  //--------------------------------------------------
  `SVTEST(write_1_pwrite)
    fork
      my_apb_if.write();
    join_none

    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.pwrite !== 1);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.pwrite !== 1);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.pwrite !== 1'hx);
  `SVTEST_END(write_1_pwrite)

  //--------------------------------------------------
  // Test: write_2_pwrite
  //
  // verify the pwrite stays asserted for consecutive
  // writes
  //--------------------------------------------------
  `SVTEST(write_2_pwrite)
    fork
      repeat (2) my_apb_if.write();
    join_none

    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.pwrite !== 1);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.pwrite !== 1);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.pwrite !== 1);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.pwrite !== 1);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.pwrite !== 1'hx);
  `SVTEST_END(write_2_pwrite)

  //--------------------------------------------------
  // Test: read_1_psel
  //
  // verify the psel is asserted for 2 cycles then
  // de-asserted
  //--------------------------------------------------
  `SVTEST(read_1_psel)
    fork
      my_apb_if.read(0, rdata);
    join_none

    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.psel !== 1);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.psel !== 1);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.psel !== 0);
  `SVTEST_END(read_1_psel)

  //--------------------------------------------------
  // Test: read_2_psel
  //
  // verify the psel is asserted for 4 cycles then
  // de-asserted (back-to-back reads)
  //--------------------------------------------------
  `SVTEST(read_2_psel)
    fork
      repeat (2) my_apb_if.read(0, rdata);
    join_none

    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.psel !== 1);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.psel !== 1);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.psel !== 1);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.psel !== 1);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.psel !== 0);
  `SVTEST_END(read_2_psel)

  //--------------------------------------------------
  // Test: read_1_penable
  //
  // verify the penable is asserted for 1 cycle then
  // de-asserted
  //--------------------------------------------------
  `SVTEST(read_1_penable)
    fork
      my_apb_if.read(0, rdata);
    join_none

    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.penable !== 0);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.penable !== 1);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.penable !== 0);
  `SVTEST_END(read_1_penable)

  //--------------------------------------------------
  // Test: read_2_penable
  //
  // verify the penable is asserted twice in 4 cycles
  //--------------------------------------------------
  `SVTEST(read_2_penable)
    fork
      repeat (2) my_apb_if.read(0, rdata);
    join_none
 
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.penable !== 0);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.penable !== 1);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.penable !== 0);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.penable !== 1);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.penable !== 0);
  `SVTEST_END(read_2_penable)
 
  //--------------------------------------------------
  // Test: read_1_paddr
  //
  // verify the paddr changes on the first clk edge
  //--------------------------------------------------
  `SVTEST(read_1_paddr)
    fork
      my_apb_if.read('hf, rdata);
    join_none
 
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.paddr !== 'hf);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.paddr !== 'hf);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.paddr !== 8'hx);
  `SVTEST_END(read_1_paddr)
 
  //--------------------------------------------------
  // Test: read_2_paddr
  //
  // verify the paddr transitions directly from fe to
  // ff for consecutive reads
  //--------------------------------------------------
  `SVTEST(read_2_paddr)
    fork
      begin
        my_apb_if.read('hfe, rdata);
        my_apb_if.read('hff, rdata);
      end
    join_none
 
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.paddr !== 'hfe);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.paddr !== 'hfe);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.paddr !== 'hff);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.paddr !== 'hff);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.paddr !== 8'hx);
  `SVTEST_END(read_2_paddr)
 
  //--------------------------------------------------
  // Test: read_1_prdata
  //
  // verify the prdata is captured in the enable state
  //--------------------------------------------------
  `SVTEST(read_1_prdata)
    fork
      begin
        my_apb_if.read(0, rdata);
        `FAIL_IF(rdata !== 'hffff);
      end
    join_none
 
    @(negedge my_apb_if.clk) #1 my_apb_if.prdata = 'hx;
    @(negedge my_apb_if.clk) #1 my_apb_if.prdata = 'hffff;
    @(negedge my_apb_if.clk) #1 my_apb_if.prdata = 'hx;
  `SVTEST_END(read_1_prdata)
 
  //--------------------------------------------------
  // Test: read_2_prdata
  //
  // verify the prdata is captured correctly for back
  // to back reads
  //--------------------------------------------------
  `SVTEST(read_2_prdata)
    fork
      begin
        my_apb_if.read(0, rdata);
        `FAIL_IF(rdata !== 'heeee);

        my_apb_if.read(0, rdata);
        `FAIL_IF(rdata !== 'hcccc);
      end
    join_none

    @(negedge my_apb_if.clk) #1 my_apb_if.prdata = 'hx;
    @(negedge my_apb_if.clk) #1 my_apb_if.prdata = 'heeee;
    @(negedge my_apb_if.clk) #1 my_apb_if.prdata = 'hx;
    @(negedge my_apb_if.clk) #1 my_apb_if.prdata = 'hcccc;
    @(negedge my_apb_if.clk) #1 my_apb_if.prdata = 'hx;
  `SVTEST_END(read_2_prdata)
 
  //--------------------------------------------------
  // Test: read_1_pwrite
  //
  // verify the pwrite changes on the first clk edge
  //--------------------------------------------------
  `SVTEST(read_1_pwrite)
    fork
      my_apb_if.read(0, rdata);
    join_none
 
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.pwrite !== 0);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.pwrite !== 0);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.pwrite !== 1'hx);
  `SVTEST_END(read_1_pwrite)
 
  //--------------------------------------------------
  // Test: read_2_pwrite
  //
  // verify the pwrite stays deasserted for consecutive
  // reads
  //--------------------------------------------------
  `SVTEST(read_2_pwrite)
    fork
      repeat (2) my_apb_if.read(0, rdata);
    join_none
 
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.pwrite !== 0);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.pwrite !== 0);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.pwrite !== 0);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.pwrite !== 0);
    @(negedge my_apb_if.clk) #1 `FAIL_IF(my_apb_if.pwrite !== 1'hx);
  `SVTEST_END(read_2_pwrite)

  `SVUNIT_TESTS_END
endclass


