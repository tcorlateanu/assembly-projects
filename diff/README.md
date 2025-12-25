# Mini diff in x86-64 Assembly

This project implements a simplified version of the Unix `diff` tool in **x86-64 assembly**.  
It compares two multi-line text buffers and prints the differing lines together with their line numbers.

## Features

- Compares two in-memory text buffers line by line.
- Supports:
  - `-i` flag for case-insensitive comparison.
  - `-B` flag to ignore lines that are only spaces or tabs.
- Prints a small “hunk” for each difference in the format:


