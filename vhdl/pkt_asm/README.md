# Flexible VHDL Packet Assembler

This repository contains a fully parameterized VHDL-2008 module for assembling packets using AXI-Stream-style interfaces. It supports dynamic packet headers, optional length insertion, and trailer fields, making it ideal for custom communication protocols, embedded systems, or FPGA-based data framing.

## 🚀 Features

- **Scalable Type Field**: Configurable width (`G_TYPE_WIDTH`) and dynamic value per frame.
- **Optional Length Field**: Insert a 2-byte payload length if `insert_length = '1'`.
- **Buffered Payload**: Accepts streaming input and buffers until `tlast`.
- **Fixed Trailer Field**: Configurable width (`G_TRAILER_WIDTH`) and value per frame.
- **AXI-Stream Compatible**: 8-bit input/output with `tvalid`, `tready`, and `tlast`.

## 📦 Packet Format

Depending on the `insert_length` signal, the packet structure is:

### With Length (`insert_length = '1'`)
[type (N bytes)] [length (2 bytes)] [payload (N bytes)] [trailer (M bytes)]

### Without Length (`insert_length = '0'`)
[type (N bytes)] [payload (N bytes)] [trailer (M bytes)]


## 🛠️ Parameters

| Name             | Type    | Description                                 |
|------------------|---------|---------------------------------------------|
| `G_TYPE_WIDTH`    | `natural` | Width of the type field in bits (e.g. 8, 16, 32) |
| `G_TRAILER_WIDTH` | `natural` | Width of the trailer field in bits         |
| `G_MAX_BYTES`     | `natural` | Maximum payload size in bytes              |

## 🔌 Ports

### Input Stream (AXI-style)
- `s_axis_tdata` : `std_logic_vector(7 downto 0)` — Payload byte
- `s_axis_tvalid`: `std_logic` — Valid signal
- `s_axis_tready`: `std_logic` — Ready signal
- `s_axis_tlast` : `std_logic` — End-of-frame indicator

### Header/Trailer Inputs
- `packet_type`   : `std_logic_vector(G_TYPE_WIDTH-1 downto 0)` — Type field value
- `packet_trailer`: `std_logic_vector(G_TRAILER_WIDTH-1 downto 0)` — Trailer field value
- `insert_length` : `std_logic` — Controls whether length is inserted (`'1'` or `'0'`)

### Output Stream (AXI-style)
- `m_axis_tdata` : `std_logic_vector(7 downto 0)` — Assembled packet byte
- `m_axis_tvalid`: `std_logic` — Valid signal
- `m_axis_tready`: `std_logic` — Ready signal
- `m_axis_tlast` : `std_logic` — End-of-packet indicator

## Example Use Cases

- Custom protocol framing for serial or parallel links
- Packetization for DMA or memory-mapped transfers
- Embedding metadata (type, length, trailer) in hardware streams



