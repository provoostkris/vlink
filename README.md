# 🔗 VLink: Virtual Link Design in VHDL

**VLink** is a modular VHDL framework for simulating digital communication links. It models a full transmitter–channel–receiver chain, including modulation, scrambling, coding, error insertion, signal processing and more. Ideal for educational use, prototyping, or introduction to communication principles.


## 📁 Project Structure

### 🧠 TOP level
| Component   | Description |
|------------|-------------|
| **VLINK**   | Top-level wrapper connecting transmitter, channel, and receiver |

### 🧠 Core Modules

| Component   | Description |
|------------|-------------|
| **CONV**    | Convolutional coding : encoding|
| **CORDIC**  | Algorithmic processor for sine/cosing calculation |
| **CRC**     | Cyclic redundancy check algorithm : CRC-16 |
| **FIR**     | Finite Impulse Response filter for shaping and processing signals |
| **LFSR**    | Linear Feedback Shift Register used for scrambling and descrambling |
| **NCO**     | Algorithmic processor for oscillations computation |
| **PKT_ASM** | General purpose packet assembly for streaming data |
| **PRBS**    | Pseudo-Random Bit Sequence generator and checker with error detection |
| **PSK**     | Phase Shift Keying modulator/demodulator (currently BPSK) |
| **RS_CODE** | Reed Solomon codec |

### 🧠 Helper Modules / Models

| Component   | Description |
|------------|-------------|
| **DAC**   | Digital to Analog Convertor |
| **SEI**   | Systematic Error Insertion to simulate data corruption |

## 🧪 Test Benches

Each module includes a dedicated test bench to verify functionality and simulate realistic behavior. These are great for learning, debugging, or validating your own modifications.

## 📌 Goals
- Simulate realistic digital communication links
- Test modulation, filtering, and error handling
- Provide reusable components for education and research
- Encourage modular design and experimentation

## 📚 Requirements
- VHDL-2008 compatible simulator
- Basic understanding of digital systems and signal processing

## 🧠 Inspiration

VLink was created to offer a modular and extensible way to explore digital communication systems in VHDL. Whether you're a student, researcher, or engineer, it gives you the basic building blocks to experiment and learn.

## 💖 Support This Project

If you find VLink useful and would like to support its development, consider making a donation:

- [☕ Buy Me a Coffee](https://www.buymeacoffee.com/provoostkris)
- [❤️ GitHub Sponsors](https://github.com/sponsors/provoostkris)

Your support helps keep the project alive and evolving. Thank you!
