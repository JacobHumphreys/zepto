A simple black-box clone of the pico text editor written from scratch using zig.

![demo](https://github.com/JacobHumphreys/zepto/blob/main/assets/demo_hoto.png)
*zepto editing its source code*
## Motivation
As an exercise of writing slightly more complex software in Zig, I decided to attempt to create
a text editor without using any external libraries. This project makes use of libc and the zig 
standard library in order to replicate the functionality of the unix pico text editor.

## Compilation
This project utilizes no external libraries. Its only dependency is the zig programming language itself which additionally packages libc. In order to build the project, you can simply run the following command in the project root:

```bash
zig build
```

This will build the project and export a binary to $PROJECT_ROOT/.zig-out/bin/. Alternatively you can enter the following to build and run the project:

```bash
zig build run
```
**Note:** this project is designed for use with x-term compatable terminal emulators. This should include most Linux and Macos terminals. The Windows terminal does support many x-term features, but this project is designed for use with Unix systems and is only officially supports Linux.

## Status
Zepto is still in active development with the goal of achieving full feature parity with the [Alpine pico text editor](https://en.wikipedia.org/wiki/Pico_(text_editor)). This project is **not** attempting to replace pico's existing [derivatives](https://en.wikipedia.org/wiki/GNU_nano)
