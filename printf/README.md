# Minimal printf in x86-64 Assembly

This project implements a simplified `printf`-like function in x86‑64 assembly that prints to the terminal using the Linux `write` syscall only.  
It supports a small subset of format specifiers and manual argument handling via registers and the stack.

## Features

- Custom `my_printf` routine with support for:
  - `%s` – null‑terminated string.
  - `%d` – signed decimal integer.
  - `%u` – unsigned decimal integer.
  - `%%` – literal percent sign.
  - Unknown specifiers (like `%r`) are printed as two characters: `%` followed by the unknown letter.
- No C standard library: all output goes through a small `write_syscall` wrapper around `syscall`.

## Main components

- `write_syscall`  
  Thin wrapper around `write(1, buf, len)` that sends bytes directly to the terminal.

- `print_string`  
  Takes a pointer to a null‑terminated string, computes its length, and prints it via `write_syscall`.

- `my_printf`  
  - Takes a format string and up to several arguments (in registers and then on the stack).  
  - Parses the format string byte by byte.  
  - For plain characters, calls `print_one_char`.  
  - For `%d`, `%u`, `%s`, `%%`, fetches the next argument with `handle_argument` and prints it in the correct format.

- `unsigned_int_to_str` and `signed_int_to_str`  
  - Convert integers to decimal ASCII in a caller‑provided buffer.  
  - Build digits from right to left, then return a pointer to the first character of the resulting string.

## Example usage

The `main` function demonstrates calling `my_printf`:
My name is %s. I think I'll get a %u for my exam. What does %r do? And %%?

with:

- `%s` bound to the string `"Teo"`.  
- `%u` bound to the value `42`.  
- `%r` treated as an unknown specifier, printed as the literal sequence `%r`.  
- `%%` printed as a single `%`.

This illustrates how the custom printf handles strings, integers, unknown specifiers, and literal percent signs using only assembly and system calls.



