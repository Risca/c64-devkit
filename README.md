# c64-devkit
All you need to start programming 6510 assembler for the Commodore 64 on Microsoft Windows or Linux.

![c64-devkit](https://github.com/cliffordcarnmo/c64-devkit/blob/master/screenshot.png)

## Quick usage
Run `build.bat` on Microsoft Windows or `make` on Linux to generate tables, compile the source code, crunch the binary and launch your program in the emulator. This produces `build\c64-devkit.prg` - a classic oldschool demoscene intro which is runnable on a real Commodore 64 or using an emulator.

## Notes
The source code is located in a file called `main.asm` that resides in the `source\` folder.

This devkit is based on the following components:

- [__ACME__](https://sourceforge.net/projects/acme-crossass) Compiler
- [__pucrunch__](https://github.com/mist64/pucrunch) Cruncher
- [__VICE__](http://vice-emu.sourceforge.net) Commodore 64 emulator
- [__genosine__](https://github.com/cliffordcarnmo/genosine) Sin/Cos LUT generator
- [__Pixcen__](https://github.com/Hammarberg/pixcen) Graphics and sprites editor
- [__GangEd__](http://www.thegang.nu/releases.php?type=4&year=all&headline=Utils&nomenu=1) Graphics, sprites, charset etc. multitool
- [__vchar64__](https://github.com/ricardoquesada/vchar64) Charset etc. editor

The Microsoft Windows binaries was compiled with Visual Studio 2017 under Microsoft Windows 10.

The Linux binaries was compiled with GCC 6.2.0-5 under Ubuntu 16.10 amd64.

Please consult `readme.txt` in `compiler\`, `cruncher\` or `genosine\` if you need to compile the tools yourself.

## Getting started
The Commodore 64 originally released in 1982 is an amazing piece of technical engineering with a huge software catalog and evolving enthusiast scene and demoscene. Some argue that the computer revolution of the early 90's would not have occurred without it. Programming it is very fun and differs fundamentally from modern software development.
The Commodore 64 operates on 0.985 MHz (PAL) and 64 KB RAM + 20 KB ROM. In there is an entire, yet limited, operating system with functions for [amazing video](https://www.youtube.com/watch?v=9LFD4SzW3e0), [dazzling colors](https://www.youtube.com/watch?v=Ee5jcpkDnJw) and [lovely sound](https://www.youtube.com/watch?v=2XUxT2pyDos).

## Why write 8-bit assembly code in 2017? Is this your way of dealing with asperger's?
Today we got Visual Studio, Node.js, Google V8, Python, Java, C#, JavaScript, C++, OpenGL, DirectX and other technologies that solves any problem very, very effective but you - the programmer - do not need to care about the underlying hardware and the technologies your software speaks to. You are often operating on several layers above your computer when using modern programming tools and usually do not care about allocating memory, the timing of CPU instructions and how your computer works.

For example, Your laptop -> Microsoft Windows -> API -> .NET Framework -> .NET Common Language Runtime -> __Your code__.

When programming assembly code on the Commodore 64 it looks like this: Your Commodore 64 -> __Your code__.

Another thing worth mentioning is the evolution of modern technology which also takes away size constraints, the need for optimization and having to save precious bytes of memory to be able to jam your source code into the machine. In short, having to learn how the hardware works to write software force you to think about what you are doing with every single call and operation, on a fundamental level. I am convinced that this will make you a better programmer regardless of what tools and languages you use in your modern day life.

Oh, and did I mention it is also __extremely__ fun and challenging.

## Wait what? 8-bit?
The stuff inside your computer is based on tiny numbers called bits. Basically, the more bits your computer can handle, the higher it can count. Back in the (glory) days of home computers 8 bits was all you could get your hands on without spending a fortune.

A bit is a single 1 or 0 switch that represents if a position in a byte is "on" or "off.

8 of these switches - or bits - represents a byte. You might have heard of kilobytes, megabytes and gigabytes. Those are loads and loads of bits. A bit is the smallest data entity a computer operates on. An 8-bit computer can store 8 switches in the "on" or "off" position like this: `10011001`.

A byte is made up of 8 binary positions with the corresponding numbers 128 64 32 16 8 4 2 1. Our example above would look this when we map the bits to their number:
~~~~
128 64 32 16 8 4 2 1
  1  0  0  1 1 0 0 0 = 152
~~~~
Here we have one 128, no 64, no 32, one 16, one 8, no 4, no 2 and no 1. Add these up and you get the decimal number __152__ (hexadecimal 98).
If we turn all the switches on and add them all up the result is __255__. This is the highest an 8-bit computer can count in a single operation and it looks like this: `11111111`.

Or if we look at it this way:
~~~~
128 64 32 16 8 4 2 1
  1  1  1  1 1 1 1 1 = 255
~~~~

For all of you reading this thinking “__WRONG!__, the Commodore 64 can count higher than 255!” – yes, it can. The 6510 CPU has a 16-bit address bus and can talk to 64 KB memory by using two bytes (high and low byte) to form a higher number. The individual bytes taking up memory space can however only have a value of 0 to 255.

Congratulations, you now know more about the fundamentals of computers and software development than most of the population of this planet. You're welcome.

## Hello World
Using this fabulous devkit we are going to focus on writing a very simple program that displays the text "HELLO WORLD" in the middle of the Commodore 64 screen. You do not need to care about all the tools and scripts needed to get assembly code compiled and crunched right now.

Programming the Commodore 64 is all about juggling the right numbers at the right locations in memory at the right time. When we power on (an unmodified) the Commodore 64 it is factory configured to give us a text mode with screen memory located at $0400 hexadecimal (1024 decimal). Some of you grew up staring at this.

The screen in text mode is made up of 25 rows with 40 columns. Screen memory is directly mapped to this screen. This means that we have 25 * 40 = 1000 bytes of screen memory that we can bang values straight into and they will magically appear on the screen.

## Writing the Hello World example
Start by deleting everything in the folder `source\` and create a new file in `source\` called `main.asm`. Open it in your favorite text editor and enter the following.
~~~~
	*=$0801
	
	jsr $e544

	lda #$03
	sta $d020
	sta $d021

	ldx #$00

loop:
	lda text,x
	sta $0400+40*12,x
	inx
	cpx #40
	bne loop

wait:
	jmp wait

text:
	!scr "              hello world               "
~~~~

Save the file and run `build.bat` on Microsoft Windows or `make` on Linux in the root of the c64-devkit folder. Your emulator should now start and you will see a colored screen with the message “HELLO WORLD” on it. Congratulations, you are now cooler than most of the population of this planet. You’re welcome.

## Analyzing the Hello World example

Although this is not a [assembler tutorial](https://skilldrick.github.io/easy6502/) here is a breakdown of what you just wrote.

`*=$0801`

Tells the compiler that our code should be located and executed from the hexadecimal memory location 0801 (2049 decimal).

`jsr $e544`

Introduces a concept called KERNAL functions. Somewhere inside the ROM of the Commodore 64 there are premade utility functions for all kinds of stuff. One of these is located at location $e544 and clears the screen. We could do this manually by looping and writing a space character, but for the scope of this tutorial, a KERNAL call is enough. Jsr means jump to subroutine.

`lda #$03`

Load the hexadecimal number 3 into the accumulator register.

`sta $d020`

Store the value (3) of the accumulator register in memory location d020. This memory location is responsible for the background color of the screen.

`sta $d021`

Store the value (3) of the accumulator register in memory location d021. This memory location is responsible for the border color of the screen.
	
`ldx #$00`

Load the number 0 into the X index register. There are two index registers, X and Y. These are mainly used for indexing, looping and indexed addressing.

`loop:`

This is a label, something human readable to represent a location in memory that we don’t need to know about. We could also have pointed directly to a memory address.
	
`lda text,x`

Load the first byte from the memory location pointed at by the label text and add the value of index register X. 
	
`sta $0400+40*12,x`

Store the value at memory location (screen memory) $0400 plus 40 columns times 12 rows, and add the value of index register X.
	
`inx`

Increase whatever value is in index register X with 1.
	
`cpx #$28`

Compare if the value in index register X is 40 decimal.
	
`bne loop`

Branch back to the label loop if it is not equal to 40.

`wait:`

Another label for a memory location.

`jmp wait`

Jump to subroutine wait. Basically, an infinite loop.

`text:`

Another label for a memory location.

`!scr "              hello world               "`

A special compiler keyword that converts the text hello world into a format that the Commodore 64 understands. Notice that it’s padded with spaces to appear in the center of the screen.

## What happens when I run `build.bat` or `make`?
The build script does a lot of magic behind the scenes to make your journey into the wonderful world of assembly code as smooth sailing as possible. The steps taken to transform your source code into a runnable program is basically:

1. Setup a bunch of variables.
2. Remove the current build and tables.
3. Create lookup tables with genosine. These are not needed for our Hello World example. Just ignore them.
4. Compile the source with ACME and generate an output .prg file in the `build\` directory.
5. Crunch the output binary with pucrunch and add startup code to it so it is easily runnable on the Commodore 64.
6. Start the emulator and load your program.

## Further reading
We have just begun to scratch the surface and your path to eternal glory starts here. To learn more about the Commodore 64 and how to program it, check out these websites. They helped me a lot.

- [http://sta.c64.org/cbm64krnfunc.html](http://sta.c64.org/cbm64krnfunc.html)
- [http://sta.c64.org/cbm64mem.html](http://sta.c64.org/cbm64mem.html)
- [http://codebase64.org/doku.php](http://codebase64.org/doku.php)

## Credits for the included intro
- Code and graphics by Clifford 'Randy' Carnmo
- Music by Joakim 'dLx' Falk

We are both members of [iNSANE](http://insane.demoscene.se) - an oldschool demoscene group.
