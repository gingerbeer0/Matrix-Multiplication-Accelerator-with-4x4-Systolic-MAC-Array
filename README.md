# Matrix Multiplication Accelerator (4x4 Systolic MAC Array)

This project implements a matrix multiplication accelerator using a 4x4 dynamic-weight systolic MAC array. It supports matrix sizes from 1×1 to 8×8 using block matrix multiplication, and clock gating is used to improve efficiency on smaller computations. The design has been functionally verified through simulation and synthesized using Quartus.

## 💡 Features

- Supports arbitrary matrix sizes (1x1 ~ 8x8)
- Uses only a 4x4 MAC array as per spec
- Dynamic-weight systolic array (more flexible than stationary-weight)
- Block matrix multiplication for larger matrices
- Clock gating for smaller matrices (power-efficient)
- Result aggregation handled by result buffer in grouped operations

## 🧩 System Overview

- **Control Module**: Manages flow of operations based on MNT input.
- **Input/Weight Buffer**: Fetches matrix blocks from memory.
- **4x4 MAC Array**: Systolic array for core matrix multiplication.
- **Result Buffer**: Accumulates intermediate results and writes to output memory.

## 📁 File Structure


## ▶️ Simulation

Simulated using predefined `.hex` files for multiple MNT cases (e.g., 888, 333, 357). All cases passed successfully.

## 🛠️ Synthesis

Synthesis was performed with Intel Quartus. Additional registers were inserted to meet timing (hold time fix), but area remains within design constraints.

