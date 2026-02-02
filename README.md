# Asynchronous FIFO (SystemVerilog)

This repository contains a parameterizable **asynchronous FIFO** implemented in
SystemVerilog, designed for safe clock domain crossing (CDC) between independent
write and read clock domains.

The design uses **Gray-coded pointers** and **two-flip-flop synchronizers** to
ensure robust full and empty detection in asynchronous environments.

## Features
- Independent write and read clock domains
- CDC-safe design using Gray code pointers
- Parameterizable data width and FIFO depth
- Full and empty flag generation per clock domain
- Suitable for FPGA implementation (tested on Digilent Basys 3)

## Status
- RTL implementation completed
- Simulation and verification in progress

## Tools
- Xilinx Vivado 2022.2
- SystemVerilog (IEEE 1800)

## Target platform
- Digilent Basys 3 (Xilinx Artix-7)

## Notes
This project is intended as an academic and professional portfolio project
focused on digital design and CDC best practices.
