# Transformer-Accelerator-FPGT
This repository implements a parameterizable systolic array architecture for matrix multiplication acceleration. The design is composed of three hierarchical modules: PE, PE_line and PE_array

Module Description
# 1. PE (Processing Element)

The fundamental computation unit.

Function: Each PE performs a Multiply-Accumulate (MAC) operation:

psum_out = psum_in + x × w
<img width="2560" height="1756" alt="image" src="https://github.com/user-attachments/assets/446f3def-4ae7-4569-9375-e6bfe4ba891f" />

# 2. PE_line

A horizontal chain of Processing Elements.

Function:
- Receives one activation input.
- Broadcasts weights to all PEs.
- Propagates activation horizontally.
- Computes one matrix row contribution.

Architecture:
<img width="2560" height="1462" alt="image" src="https://github.com/user-attachments/assets/f9f51015-dd5a-4fea-acf5-564024dab3a5" />

# 3. PE_array

Top-level systolic array.

Function: Performs matrix-vector multiplication.

Architecture:
<img width="2560" height="2157" alt="image" src="https://github.com/user-attachments/assets/13035c39-f5cb-4a0a-bbe0-43a8250fae67" />

# 4. right_shifter

Quantization module.

Function: Performs:
- Arithmetic right shift
- Rounding
- Saturation
