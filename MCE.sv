module MCE #(parameter width = 8)
  (input [width-1:0] A,
  input [width-1:0] B,
  output [width-1:0] MAX,
  output [width-1:0] MIN);

  assign MAX = (A>=B) ? A:B ;
  assign MIN = (A<B) ? A:B ;

endmodule
