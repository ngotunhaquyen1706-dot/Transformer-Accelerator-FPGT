# Transformer-Accelerator-FPGT
Systolic Processing Element Array for Matrix Multiplication
This repository implements a parameterizable systolic array architecture for matrix multiplication acceleration. The design is composed of four hierarchical modules:
Module Description
1. PE (Processing Element)
The fundamental computation unit.
Function: Each PE performs a Multiply-Accumulate (MAC) operation:
psum_out = psum_in + x × w
<img width="2560" height="1756" alt="image" src="https://github.com/user-attachments/assets/446f3def-4ae7-4569-9375-e6bfe4ba891f" />

