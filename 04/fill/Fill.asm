// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/04/Fill.asm

// Runs an infinite loop that listens to the keyboard input.
// When a key is pressed (any key), the program blackens the screen
// by writing 'black' in every pixel;
// the screen should remain fully black as long as the key is pressed. 
// When no key is pressed, the program clears the screen by writing
// 'white' in every pixel;
// the screen should remain fully clear as long as no key is pressed.

// Reference:https://blog.morifuji-is.ninja/post/2019-01-14

// Calculate @maxscreen
@8192
D=A
@SCREEN
D=D+A
@maxscreen
M=D

(KEY)
// Initialize @address
@SCREEN
D=A
@address
M=D

@KBD
D=M

@WHITE
D;JEQ // if @KBD == 0 then @WHITE jump
@BLACK
D;JNE // if @KBD ≠= 0 then @BLACK jump

(WHITE)
@color
M=0
@DRAW
0;JMP

(BLACK)
@color
M=-1
@DRAW
0;JMP

(DRAW)
@color
D=M

@address
A=M // Set the value of @address in the A register
M=D // Change the value of @address to the value of @color

D=A+1 // Next address 
@address
M=D // Store next address in @address

@maxscreen
D=M-D

@DRAW
D;JNE // if (@maxscreen - @address) ≠= 0 then @DRAW jump

@KEY
0;JMP
