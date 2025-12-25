# Tiny Shell in x86-64 Assembly (`asmsh`)

This project implements a minimal interactive command shell in **x86‑64 Assembly**.
The shell runs in a loop without the standard C library (`libc`), communicating directly with the Linux kernel via system calls. It displays a prompt, reads a line from stdin, parses the command, and executes a small set of built‑in operations.

## Features

- **Prompt:** `shell> ` displayed before each command.
- **Commands:**
  - `help` – Print a short help message listing available commands.
  - `quit` – Exit the shell.
  - `add <n1> <n2>` – Adds two signed integers and prints the result.
  - `mul <n1> <n2>` – Multiplies two signed integers and handles overflow.
  - `div <n1> <n2>` – Divides two signed integers (integer division) and handles division by zero.
- **Input/Output:**
  - Uses Linux `read` and `write` syscalls directly (no C library dependencies).
  - Custom utility routines for printing strings and converting integers to/from text.

## Design Overview

- A fixed‑size input buffer in `.bss` holds the line read from stdin.
- The main loop (`_start`):
  1. Prints the prompt.
  2. Uses `sys_read` to read a command line into the buffer.
  3. Replaces the newline character with a null terminator.
  4. Parses the input:
     - Skips leading spaces.
     - Extracts the first word as the command token.
     - Dispatches execution to `do_help`, `do_quit`, `do_add`, `do_mul`, or `do_div`.
- **Helper Routines:**
  - `print_string` – Output helper using the `write` syscall.
  - `atoi_signed` – Converts decimal string tokens into signed 64-bit integers.
  - `signed_int_to_str` – Converts 64-bit integers back to decimal strings for output.
  - `read_word` / `skip_spaces` – Custom tokenizers for parsing command arguments.

## Build & Run

You can build the shell using `gcc` (acting as a driver for the assembler and linker). The flags ensure no standard library startup files are linked.
Compile and link (with debug symbols)
gcc -nostartfiles -no-pie -g shell.s -o shell
Run the shell
./shell
## Example Session

shell> help
available: help, quit, add, mul, div

shell> add 10 20
30

shell> mul 100 -5
-500

shell> div 100 3
33
