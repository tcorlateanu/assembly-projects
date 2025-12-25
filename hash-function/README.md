# SHA‑1 Chunk Processing in x86-64 Assembly

This project implements the core **SHA‑1 compression function** (“chunk” processing) in x86‑64 assembly.  
The `sha1_chunk` routine takes one 512‑bit message block and updates the five SHA‑1 state words `h0..h4`.

## Interface

- Input:
  - `%rdi` – pointer to the 5 state words `h0, h1, h2, h3, h4` (32‑bit each).
  - `%rsi` – pointer to an array of 80 32‑bit words `w[0..79]`.
    - `w[0..15]` must already be filled with the expanded message block.
- Output:
  - The state at `%rdi` is updated in place (`h0..h4` modified according to SHA‑1).

## Algorithm

The function follows the SHA‑1 specification:

1. **Message schedule extension**  
   - Starts from `w[16]` and computes up to `w[79]` with:

     ```
     w[i] = leftrotate(w[i-3] ^ w[i-8] ^ w[i-14] ^ w[i-16], 1);
     ```

   - Uses 32‑bit registers (`r12d`, `r13d`, `r14d`, `r15d`, `eax`) and `roll $1`.

2. **Main hash loop (80 rounds)**  
   - Initializes working variables:

     ```
     a = h0, b = h1, c = h2, d = h3, e = h4
     ```

   - For each round `i = 0..79`:

     ```
     temp = leftrotate(a, 5) + f(b, c, d, i) + e + k(i) + w[i];
     e = d;
     d = c;
     c = leftrotate(b, 30);
     b = a;
     a = temp;
     ```

   - Uses the SHA‑1 round functions and constants:

     - `0–19`:  `f = (b & c) | (~b & d)`, `k = 0x5A827999`
     - `20–39`: `f = b ^ c ^ d`,        `k = 0x6ED9EBA1`
     - `40–59`: `f = (b & c) | (b & d) | (c & d)`, `k = 0x8F1BBCDC`
     - `60–79`: `f = b ^ c ^ d`,        `k = 0xCA62C1D6`

3. **State update**

   After 80 rounds, the routine adds the working variables back into the original state:


