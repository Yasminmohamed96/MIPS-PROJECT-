module RF(rr1,rr2,wr,wd,rd1,rd2,enable,clk);
  input [4 :0] rr1,rr2,wr;//rr:read register,wr:write register
  input signed[31:0] wd;//wd:write data
  input enable,clk ;//enable:write_enable
 output reg signed [31:0] rd1,rd2;//rd:read data
 reg signed [31:0] mem[0:31];//2D array
initial
  begin
    mem[0]=5   ; mem[1]=100; mem[2]=2147483648 ; mem[3] =2147483647;
    mem[4]=500 ;             mem[5]=-2147483647; mem[6] =2147483646;
    mem[7]=-400; mem[8]=-2 ; mem[9]=-4;		 mem[10]=-5;
    mem[11]=-6 ; mem[12]=6; 
  end
always@(posedge clk)
begin
  rd1<=mem[rr1];
  rd2<=mem[rr2];
  if(enable)
    mem[wr]<=wd;
end 
endmodule
module alu(result ,overflow ,A,B,mode,op,shift_amp);

input signed [31:0] A,B,shift_amp;
input wire mode;
input wire [3:0] op;

output[31:0] result;
output wire overflow;

wire [31:0] B_negative;
assign B_negative =-B;
 
assign result = (op==4'b0000)?(A+B):(op==4'b0001)?(A-B):(op==4'b0010)?(A&B):(op==4'b0011)?(A|B):
 // add operation ..................sub operation......and operation.........or operation

(op==4'b0100)?( A <<shift_amp):(op==4'b0101)?( A>>shift_amp):(op==4'b0110)?(-(-A>>>shift_amp)):
// shift left  ................shift right logical...........shift right arthmatic

(mode ==1 && op==4'b1000 )?(A<B):(mode==1 && op==4'b0111)?(A>B):32'hx;
///less than................................................//greater than

assign overflow=(op==4'b0000 && A[31] == B[31]&& result[31]==~A[31] )?1 : 
// overflow of the sum when the most sign. bit are the same at both inputs and the result is different

  (mode==1&& op==4'b0001 && A[31] == B_negative[31]&& result[31]==~A[31]) ? 1:0;
// overflow of the Sub.operation when the most sign. bit are the same at both inputs and the result is different

endmodule 

module Mux2to1 (in1,in2,out,sel);
input [31:0] in1,in2;
input [ 1:0] sel;
output reg [31:0] out;
always @ (*)
 begin
  case(sel)
   0:out<=in1;
   1:out<=in2;
  endcase
 end
endmodule

module TOPMODULE (input clk,input [1:0] sel,input [4:0] rr1,input[4:0] rr2,input[4:0] wr,input [31:0] data_written, input enable,input mode,input [3:0] op,input [31:0]  shift_amp,output[31:0] out1,output overflow);
wire [31:0] in11 ;
wire [31:0] in22 ;
wire [31:0] wd1 ;
alu u(out1 ,overflow ,in11,in22,mode,op,shift_amp);
RF rr (rr1,rr2,wr,wd1,in11,in22,enable,clk);
Mux2to1 mux (data_written,out1,wd1,sel);
endmodule

module TestBench ();
reg[4 :0] rr1,rr2,wr;
reg[31:0] data_written;
reg enable,clk,mode;
reg [1:0] sel; 
reg [31:0] shift_amp;
reg [3:0] op;
wire [31:0] out1;
wire overflow;

TOPMODULE mytopmodule (clk,sel,rr1,rr2,wr,data_written,enable,mode,op,shift_amp,out1,overflow);
initial begin
clk <= 0 ;
forever #2 clk <= ~clk ;
end

initial 
 begin
  rr1<=0;rr2<=1;op=4'b0000;wr<=1;sel=1;mode=1;enable <= 1;
#2 $display ($time,"                           Testing case 1 (addition no overflow)                                           ");
#2 $display ($time," mem[%0d]=5          , mem[%0d]=100        , opcode=%0d, so the result from the ALU is   %0d   and the overflow %0d \n",rr1,rr2,op,$signed (out1), overflow);
  rr1<=2;rr2<=2;op=4'b0000;wr<=1;sel=1;mode=1;enable <= 1;
#2 $display ($time,"                           Testing case 2 (addition with overflow)                                          ");
#2 $display ($time," mem[%0d]=2147483648 , mem[%0d]=2147483648 , opcode=%0d, so the result from the ALU is   %0d   and the overflow %0d \n",rr1,rr2,op,$signed (out1), overflow);
  rr1<=5;rr2<=6;op=4'b0000;wr<=1;sel=1;mode=1;enable <= 1;
#2 $display ($time,"                           Testing case 3 (addition negative & positive numbers)                            ");
#2 $display ($time," mem[%0d]=-2147483647, mem[%0d]=2147483646 , opcode=%0d, so the result from the ALU is   %0d   and the overflow %0d \n",rr1,rr2,op,$signed (out1), overflow); 
  rr1<=8;rr2<=9;op=4'b0000;wr<=1;sel=1;mode=1;enable <= 1;
#2 $display ($time,"                           Testing case 4 (addition negative numbers no overflow)                           ");
#2 $display ($time," mem[%0d]=-2         , mem[%0d]=-4         , opcode=%0d, so the result from the ALU is   %0d   and the overflow %0d \n",rr1,rr2,op,$signed (out1), overflow);
  rr1<=4;rr2<=1;op=4'b0001;wr<=1;sel=1;mode=1;enable <= 1;
#2 $display ($time,"                           Testing case 5 (subtraction no overflow)                                         ");
#2 $display ($time," mem[%0d]=500        , mem[%0d]=100        , opcode=%0d, so the result from the ALU is   %0d   and the overflow %0d \n",rr1,rr2,op,$signed (out1), overflow);
  rr1<=5;rr2<=6;op=4'b0001;wr<=1;sel=1;mode=1;enable <= 1;
#2 $display ($time,"                           Testing case 6 (subtraction with overflow)                                       ");
#2 $display ($time," mem[%0d]=-2147483647, mem[%0d]=2147483646 , opcode=%0d, so the result from the ALU is   %0d   and the overflow %0d \n",rr1,rr2,op,$signed (out1), overflow);
  rr1<=0;rr2<=12;op=4'b0010;wr<=1;sel=1;mode=1;enable <= 1;
#2 $display ($time,"                           Testing case 7 (and)                                                             ");
#2 $display ($time," mem[%0d]=5          , mem[%0d]=6          , opcode=%0d, so the result from the ALU is   %0b                        \n",rr1,rr2,op,out1, overflow);
  rr1<=0;rr2<=12;op=4'b0011;wr<=1;sel=1;mode=1;enable <= 1;
#2 $display ($time,"                           Testing case 8 (or)                                                              ");
#2 $display ($time," mem[%0d]=5          , mem[%0d]=6          , opcode=%0d, so the result from the ALU is   %0b                        \n",rr1,rr2,op,out1, overflow);  
  rr1<=0;op=4'b0100;wr<=1;sel=1;mode=1;enable <= 1;shift_amp=2;
#2 $display ($time,"                           Testing case 9 (ShiftLeft)                                                       ");
#2 $display ($time," mem[%0d]=5          , shift_amount = %0d  , opcode=%0d, so the result from the ALU is   %0d                        \n",rr1,shift_amp,op,$signed (out1));
  rr1<=12;op=4'b0101;wr<=1;sel=1;mode=1;enable <= 1;shift_amp=1;
#2 $display ($time,"                           Testing case 10 (Shift Right Logical)                                            ");
#2 $display ($time," mem[%0d]=6          , shift_amount = %0d  , opcode=%0d, so the result from the ALU is   %0d                        \n",rr1,shift_amp,op,$signed (out1));
 rr1<=11;op=4'b0110;wr<=1;sel=1;mode=1;enable <= 1;shift_amp=1;
#2 $display ($time,"                           Testing case 11 (Shift Right Arithmatic)                                         ");
#2 $display ($time," mem[%0d]=-6          , shift_amount = %0d  , opcode=%0d, so the result from the ALU is  %0d                        \n",rr1,shift_amp,op,$signed (out1));
 rr1<=0;rr2<=12;op=4'b0111;wr<=1;sel=1;mode=1;enable <= 1;
#2 $display ($time,"                           Testing case 12 (GreaterThan with positve numbers)                                   ");
#2 $display ($time," mem[%0d]=5          , mem[%0d]=6          , opcode=%0d, so the result from the ALU is   %0d                        \n",rr1,rr2,op,$signed (out1));
  rr1<=10;rr2<=11;op=4'b0111;wr<=1;sel=1;mode=1;enable <= 1;
#2 $display ($time,"                           Testing case 13 (GreaterThan with negative numbers)                                 ");
#2 $display ($time," mem[%0d]=-5         , mem[%0d]=-6         , opcode=%0d, so the result from the ALU is   %0d                        \n",rr1,rr2,op,$signed (out1));
 rr1<=10;rr2<=12;op=4'b0111;wr<=1;sel=1;mode=1;enable <= 1;
#2 $display ($time,"                           Testing case 14 (GreaterThan with positve and negative numbers)                                   ");
#2 $display ($time," mem[%0d]=-5          , mem[%0d]=6          , opcode=%0d, so the result from the ALU is   %0d                        \n",rr1,rr2,op,$signed (out1));
  rr1<=10;rr2<=11;op=4'b1000;wr<=1;sel=1;mode=1;enable <= 1;
#2 $display ($time,"                           Testing case 15 (LessThan with negative numbers)                                 ");
#2 $display ($time," mem[%0d]=-5         , mem[%0d]=-6         , opcode=%0d, so the result from the ALU is   %0d                        \n",rr1,rr2,op,$signed (out1));
 rr1<=0;rr2<=12;op=4'b1000;wr<=1;sel=1;mode=1;enable <= 1;
#2 $display ($time,"                           Testing case 16 (LessThan with positve numbers)                                   ");
#2 $display ($time," mem[%0d]=5          , mem[%0d]=6          , opcode=%0d, so the result from the ALU is   %0d                        \n",rr1,rr2,op,$signed (out1));
 rr1<=10;rr2<=12;op=4'b1000;wr<=1;sel=1;mode=1;enable <= 1;
#2 $display ($time,"                           Testing case 17 (LessThan with positve and negative numbers)                                   ");
#2 $display ($time," mem[%0d]=-5          , mem[%0d]=6          , opcode=%0d, so the result from the ALU is   %0d                        \n",rr1,rr2,op,$signed (out1));
/*    
    mem[0]=5   ; mem[1]=100; mem[2]=2147483648 ; mem[3] =2147483647;
    mem[4]=500 ;             mem[5]=-2147483647; mem[6] =2147483646;
    mem[7]=-400; mem[8]=-2 ; mem[9]=-4;		 mem[10]=-5;
    mem[11]=-6 ; mem[12]=6;*/
end
endmodule
//display displays one time
//monitor displays when the variable changes 