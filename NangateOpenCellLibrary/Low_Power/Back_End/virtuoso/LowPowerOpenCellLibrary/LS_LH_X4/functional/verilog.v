// Created by ihdl
module LS_LH_X4 (A, Z);
  input A;
  output Z;

  buf(Z, A);

  specify
    (A => Z) = (0.1, 0.1);
  endspecify

endmodule
