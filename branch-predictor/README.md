# 2‑bit Branch Predictor in x86-64 Assembly

This project implements a 2‑bit saturating counter branch predictor in x86‑64 assembly.  
It exposes three functions (`init`, `predict_branch`, `actual_branch`) that together simulate a small hardware-like branch predictor.

## Predictor model

Each branch has a 2‑bit state stored as a byte in a global table:

- 0 – strongly not taken  
- 1 – weakly / not taken  
- 2 – weakly / taken  
- 3 – strongly taken  

Rules:

- Prediction: states 0–1 → not taken, states 2–3 → taken.  
- Update: move one step toward the real outcome, clamped between 0 and 3.

## Data layout

The predictor table lives in `.bss`:

table: .space 2048


This reserves 2048 bytes, so up to 2048 distinct branches per run (one counter per branch).

## Functions

### init

Initializes the whole table to state **1** (biased toward “not taken”):

- Input: none  
- Effect: sets all 2048 counters in `table` to 1.

### predict_branch

Computes a prediction for a branch address:

- Input: `%rdi` = branch address (program counter).  
- Output: `%eax` = 0 (not taken) or 1 (taken).

Steps:

1. Compute index:
2. 
2. Read `state = table[idx]`.  
3. Return 1 if `state >= 2`, otherwise 0.

### actual_branch

Updates the predictor with the real outcome:

- Input: `%rdi` = branch address (PC), `%rsi` = actual outcome (0 or 1).  
- Output: none (table is updated in place).

Steps:

1. Recompute `idx` with the same hash as `predict_branch`.  
2. Load `state = table[idx]`.  
3. If outcome is 1 (taken): `state = min(state + 1, 3)`.  
4. If outcome is 0 (not taken): `state = max(state - 1, 0)`.  
5. Store the updated state back to `table[idx]`.

## Usage

- Uses the System V AMD64 calling convention (Linux / Unix-like).  
- Typical driver flow:
- Call `init()` once.  
- For each branch in a trace:
 - Call `predict_branch(pc)` and compare with the real outcome.
 - Count mispredictions.
 - Call `actual_branch(pc, outcome)` to train the predictor.



