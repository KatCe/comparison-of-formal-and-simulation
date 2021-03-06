// Copyright 2020 Tudor Timisescu (verificationgentleman.com)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.


module shape_processor_tb_top;

  import shape_processor_tests::*;
  import uvm_pkg::*;


  bit rst_n;
  bit clk;

  bit write;
  bit [31:0] write_data;

  bit read;
  bit [31:0] read_data;

  bit error;


  shape_processor dut(.*);


  always
    #1 clk = ~clk;

  initial begin
    @(posedge clk);
    rst_n <= 1;
  end


  bus_interface bus_intf(.*);

  initial
    uvm_config_db #(virtual bus_interface)::set(null, "*", "bus_intf", bus_intf);


  initial
    run_test();

endmodule
