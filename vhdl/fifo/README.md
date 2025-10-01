# [AXI4-Stream Dual-Clock FIFO](rtl/axis_dual_port_fifo.vhd)

This module implements a reusable, CDC-safe AXI4-Stream FIFO with independent read/write clocks. Designed for FPGA-based systems where AXIS data needs buffering across domains.

## Features

- ✅ AXIS slave input / AXIS master output
- ✅ CDC-safe via Gray-coded pointers
- ✅ tlast support for packet framing
- ✅ Parameterized depth and width
- ✅ Vendor-agnostic VHDL-2008



## Literature
https://www.ti.com/lit/an/scaa042a/scaa042a.pdf
https://developer.arm.com/documentation/ihi0051/latest/