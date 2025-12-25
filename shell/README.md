# Tiny Shell in x86-64 Assembly

This project implements a minimal interactive command shell in x86‑64 assembly.  
The shell runs in a loop, shows a prompt, reads a line from stdin, parses a command, and executes a small set of built‑in commands.

## Planned features

- Prompt: `asmsh> ` displayed before each command.
- Commands:
  - `help` – Print a short help message listing available commands.
  - `quit` – Exit the shell.
  - `echo <text>` – Print `<text>` back to the terminal.
  - `add <a> <b>` – Parse two integers and print their sum.
- Input/output:
  - Uses Linux `read` and `write` syscalls directly (no C library).
  - Reuses utility routines for printing strings and converting integers to/from text.

## Design overview

- A fixed‑size input buffer in `.bss` holds the line read from stdin.
- The main loop:
  1. Prints the prompt.
  2. Calls `read_line` to read a command line and strip the newline.
  3. Calls `handle_command` to:
     - Skip leading spaces.
     - Extract the first word as the command.
     - Dispatch to `cmd_help`, `cmd_quit`, `cmd_echo`, or `cmd_add`.
- Helper routines:
  - `read_line` – Read from stdin into the buffer and null‑terminate.
  - `print_string` / `print_char` – Output helpers using `write`.
  - `parse_int` – Convert a decimal string token into a signed integer.

## Build & run

Example for Linux with `gcc` and NASM syntax (to be updated to your final file name):


