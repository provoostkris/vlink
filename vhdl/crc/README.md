# 🚀 CRC-16 CCSDS Implementation

This project provides an implementation of the **CRC-16 algorithm** as specified by the *Consultative Committee for Space Data Systems (CCSDS)*. 
It is used for error detection in space communication protocols, particularly in Telecommand Transfer Frames.

---

## 📘 Overview

- **Standard**: CCSDS 101.0-B-6
- **Type**: Cyclic Redundancy Check (CRC)
- **Width**: 16 bits
- **Purpose**: Detect transmission errors in space communication frames

---

## ⚙️ CRC Parameters

| Parameter           | Value                          |
|---------------------|--------------------------------|
| Polynomial          | `0x1021` (x¹⁶ + x¹² + x⁵ + 1)  |
| Initial value       | `0xFFFF`                       |
| Final XOR value     | `0x0000`                       |
| Input reflection    | No                             |
| Output reflection   | No                             |
| CRC length          | 16 bits                        |

---

## 🧮 Algorithm Description

1. **Initialize** the CRC register to `0xFFFF`.
2. **Process each byte** of the input:
   - XOR the byte with the high byte of the CRC register.
   - Shift the CRC register left by 8 bits.
   - For each bit:
     - If the MSB is 1, XOR the CRC with the polynomial `0x1021`.
3. **Final CRC** is the 16-bit result after processing all bytes.

---

## 🧪 Test Vectors

| Input (Hex) | Expected CRC (Hex) |
|-------------|--------------------|
| `06000cf0 00040055 8873c900 000521`  | `0x75FB`|

---

## 💻 Implementations

Available in:

- ✅ VHDL (`ccsds_crc16_frame.vhd`)
- ❌ Python (`ccsds_crc16_frame.py`)

