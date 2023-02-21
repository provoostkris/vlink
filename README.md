### Vlink
Design files for a virtual link

### Files
[Top level design file](/vhdl/vlink/rtl/vlink.vhd)
Top level creating the transmitter - channel - reciever chain

### Components

[VLINK](/vhdl/vlink)
Virtual link


[FIR](/vhdl/fir)
Finite Impulse Response : perfroms a filtering of digital quantized numbers


[LFSR](/vhdl/lfsr)
Logic feedback shift register : generates a random stream used for scrambling / descrambling purpose


[PRBS](/vhdl/prbs)
Pseudo Random Bit Stream : generates and recieves a random bits stream and supports sequence error detection


[PSK](/vhdl/psk)
Phase shift keying : perfrom (currently) the BPSK modulation and demodulation 


[SEI](/vhdl/sei)
Systematic Error Insertion : systematically inserts a bit error in the incoming stream
