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


module shape_processor_props(
    input bit rst_n,
    input bit clk,

    input bit write,
    input bit [31:0] write_data,

    input bit read,
    input bit [31:0] read_data,

    input bit error
    );

  import shape_processor_modeling::*;


  default disable iff !rst_n;

  default clocking @(posedge clk);
  endclocking


  let shape_in_sfr = shape_processor.ctrl_sfr.shape;
  let operation_in_sfr = shape_processor.ctrl_sfr.operation;


  //------------------------------------------------------------------------------------------------
  // Check that we never see any reserved values in the SFR. This ensures that the DUT will have
  // some kind of handling in place to reject such values.

  no_reserved_shapes_in_sfr: assert property (
      !is_reserved_shape(shape_in_sfr));

  no_reserved_operations_in_sfr: assert property (
      !is_reserved_operation(operation_in_sfr));

  //------------------------------------------------------------------------------------------------


  no_keep_shape_in_sfr: assert property (
      shape_in_sfr != KEEP_SHAPE);

  no_keep_operation_in_sfr: assert property (
      operation_in_sfr != KEEP_OPERATION);

  only_legal_combinations_in_sfr: assert property (
      is_legal_combination(shape_in_sfr, operation_in_sfr));


  //------------------------------------------------------------------------------------------------
  // Cover that we can see each shape. This way we know that the DUT can, in principle, update the
  // 'SHAPE' field. Using this property we can flag errors if the design ignores this field
  // completely when writing.

  circle_in_sfr: cover property (
      shape_in_sfr == CIRCLE);

  rectangle_in_sfr: cover property (
      shape_in_sfr == RECTANGLE);

  triangle_in_sfr: cover property (
      shape_in_sfr == TRIANGLE);

  //------------------------------------------------------------------------------------------------


  //------------------------------------------------------------------------------------------------
  // Cover that we can see each operation. The same comments as for 'SHAPE' apply.

  for (genvar operation = 0; operation < 2**$bits(operation_e); operation++) begin
    if (operation inside { PERIMETER, AREA, IS_SQUARE, IS_EQUILATERAL, IS_ISOSCELES }) begin
      operation_in_sfr_seen: cover property (
          operation_in_sfr == operation);
    end
  end

  //------------------------------------------------------------------------------------------------


  ctrl_sfr_reg write_data_as_ctrl_sfr;
  assign write_data_as_ctrl_sfr = write_data;

  let shape_on_write_bus = write_data_as_ctrl_sfr.SHAPE;
  let operation_on_write_bus = write_data_as_ctrl_sfr.OPERATION;


  legal_write_data_written_to_shape: assert property (
      write && shape_on_write_bus != KEEP_SHAPE && is_legal_ctrl_write_data() |=>
          shape_in_sfr == $past(shape_on_write_bus));


  function bit is_legal_ctrl_write_data();
    return !is_reserved_shape(shape_on_write_bus)
        && !is_reserved_operation(operation_on_write_bus)
        && is_legal_ctrl_write_data_combination();
  endfunction

  function bit is_legal_ctrl_write_data_combination();
    if (shape_on_write_bus == KEEP_SHAPE)
      return is_legal_combination(shape_in_sfr, operation_on_write_bus);
    if (operation_on_write_bus == KEEP_OPERATION)
      return is_legal_combination(shape_on_write_bus, operation_in_sfr);
    return is_legal_combination(shape_on_write_bus, operation_on_write_bus);
  endfunction


  legal_write_data_written_to_operation: assert property (
      write && operation_on_write_bus != KEEP_OPERATION && is_legal_ctrl_write_data() |=>
          operation_in_sfr == $past(operation_on_write_bus));


  sfr_constant_if_no_write: assert property (
      !write |=> $stable(shape_processor.ctrl_sfr));


  sfr_constant_if_reserved_shape_write: assert property (
      write && is_reserved_shape(shape_on_write_bus) |=>
          $stable(shape_processor.ctrl_sfr));

  sfr_constant_if_reserved_operation_write: assert property (
      write && is_reserved_operation(operation_on_write_bus) |=>
          $stable(shape_processor.ctrl_sfr));

  sfr_constant_if_illegal_combination_write: assert property (
      write && !is_legal_ctrl_write_data_combination() |=>
          $stable(shape_processor.ctrl_sfr));


  shape_constant_if_keep_shape_write: assert property (
      write && shape_on_write_bus == KEEP_SHAPE |=>
          $stable(shape_in_sfr));

  operation_updated_when_keep_shape: cover property (
      write && shape_on_write_bus == KEEP_SHAPE ##1 $changed(operation_in_sfr));

  operation_constant_if_keep_operation_write: assert property (
      write && operation_on_write_bus == KEEP_OPERATION  |=>
          $stable(operation_in_sfr));

  shape_updated_when_keep_operation: cover property (
      write && operation_on_write_bus == KEEP_OPERATION ##1 $changed(shape_in_sfr));

endmodule


bind shape_processor shape_processor_props props(.*);
