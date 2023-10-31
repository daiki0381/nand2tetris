// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/04/Mult.asm

// Multiplies R0 and R1 and stores the result in R2.
// Assumes that R0 >= 0, R1 >= 0, and R0 * R1 < 32768.
// (R0, R1, R2 refer to RAM[0], RAM[1], and RAM[2], respectively.)

// Reference:https://blog.morifuji-is.ninja/post/2019-01-14

// Initialize @R2
@R2
M=0

// Initialize @count with @R1
@R1
D=M
@count
M=D

(LOOP)
@count
D=M
@END
D;JEQ // if @count == 0 then @END jump

// @R0+@R2
@R0
D=M
@R2
M=M+D

// @count-1
@count
M=M-1

@LOOP
0;JMP
  
// Infinite loop
(END)
@END
0;JMP
