# x86-64 Assembly Systems Portfolio

## Overview
This repository contains a collection of low-level systems projects written in **x86-64 Assembly**, focusing on memory management, processor architecture, and direct Operating System interaction.

As a Computer Science student at **TU Delft**, I built these tools to gain a concrete understanding of how software interacts with hardware. While some projects explore concepts from the *CSE1400 Computer Organisation* course, the **Shell** implementation is an independent project built to understand process creation and management at the kernel level.

## Project Highlights

| Project | Type | Key Technical Concepts |
| :--- | :--- | :--- |
| **[TinyShell](./shell)** | **Independent Project** | Linux syscalls (`fork`, `execve`), process isolation, manual string tokenization. |
| **[Branch Predictor](./branch-predictor)** | Architecture Simulation | Simulating CPU pipeline behavior and implementing prediction logic to minimize stalls. |
| **[Printf Implementation](./printf-mini)** | Standard Library | Manually handling the **System V AMD64 ABI**, stack frame management, and variadic argument parsing. |
| **[Diff Tool](./diff-mini)** | Algorithms | File comparison algorithm optimized for minimal register usage and efficient memory access. |
| **[Hash Function](./hash-mini)** | Cryptography | Implementation of hashing logic at the instruction level, focusing on bitwise operations. |

## Why Assembly?
In an era of high-level frameworks, writing Assembly provides a competitive advantage by revealing the cost of abstractions.
*   **Memory Awareness:** Understanding stack frames and heap allocation helps me write optimized Java/C++ code.
*   **Debugging:** Experience with registers and instruction pointers makes debugging complex segmentation faults or JVM crashes significantly easier.
*   **Systems Design:** Implementing core tools from scratch (like a shell or printf) clarifies how Operating Systems actually function "under the hood."

---
*Author: Teodora Corlateanu - TU Delft Computer Science and Engineering Student*
