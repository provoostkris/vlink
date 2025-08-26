# ccsds_crc16_frame.py

def ccsds_crc16(data: bytes) -> int:
    """
    Computes the CCSDS CRC-16 checksum for the given data.
    Polynomial: 0x1021
    Initial value: 0xFFFF
    """
    crc = 0xFFFF
    for byte in data:
        crc ^= byte << 8
        for _ in range(8):
            if crc & 0x8000:
                crc = (crc << 1) ^ 0x1021
            else:
                crc <<= 1
            crc &= 0xFFFF  # Keep CRC 16-bit
    return crc

def hex_to_bytes(hex_str: str) -> bytes:
    """
    Converts a hexadecimal string to bytes.
    Removes any spaces and validates input.
    """
    hex_str = hex_str.replace(" ", "")
    if len(hex_str) % 2 != 0:
        raise ValueError("Hex string must have an even number of characters.")
    return bytes.fromhex(hex_str)

if __name__ == "__main__":
    # Example input
    hex_input = input("Enter hexadecimal string (e.g. 'ABCD1234'): ").strip()
    try:
        data_bytes = hex_to_bytes(hex_input)
        crc = ccsds_crc16(data_bytes)
        print(f"CRC-16 (CCSDS) of {hex_input}: {crc:04X}")
    except ValueError as e:
        print(f"Error: {e}")
