"""Drive tb_crc16_frame_pipe through Windows named pipes.

The VHDL testbench reads one ASCII record per line from the input pipe:
  - two hexadecimal characters for a byte, for example ``01``
  - ``--`` for end of frame

It writes one result line per frame to the output pipe.
"""

import argparse
import ctypes
from ctypes import wintypes
from pathlib import Path
import threading


kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)

PIPE_ACCESS_INBOUND = 0x00000001
PIPE_ACCESS_OUTBOUND = 0x00000002
PIPE_TYPE_BYTE = 0x00000000
PIPE_READMODE_BYTE = 0x00000000
PIPE_WAIT = 0x00000000
ERROR_BROKEN_PIPE = 109
ERROR_PIPE_CONNECTED = 535
INVALID_HANDLE_VALUE = wintypes.HANDLE(-1).value

kernel32.CreateNamedPipeW.argtypes = [
    wintypes.LPCWSTR,
    wintypes.DWORD,
    wintypes.DWORD,
    wintypes.DWORD,
    wintypes.DWORD,
    wintypes.DWORD,
    wintypes.DWORD,
    wintypes.LPVOID,
]
kernel32.CreateNamedPipeW.restype = wintypes.HANDLE

kernel32.ConnectNamedPipe.argtypes = [wintypes.HANDLE, wintypes.LPVOID]
kernel32.ConnectNamedPipe.restype = wintypes.BOOL

kernel32.WriteFile.argtypes = [
    wintypes.HANDLE,
    wintypes.LPCVOID,
    wintypes.DWORD,
    ctypes.POINTER(wintypes.DWORD),
    wintypes.LPVOID,
]
kernel32.WriteFile.restype = wintypes.BOOL

kernel32.ReadFile.argtypes = [
    wintypes.HANDLE,
    wintypes.LPVOID,
    wintypes.DWORD,
    ctypes.POINTER(wintypes.DWORD),
    wintypes.LPVOID,
]
kernel32.ReadFile.restype = wintypes.BOOL

kernel32.FlushFileBuffers.argtypes = [wintypes.HANDLE]
kernel32.FlushFileBuffers.restype = wintypes.BOOL

kernel32.DisconnectNamedPipe.argtypes = [wintypes.HANDLE]
kernel32.DisconnectNamedPipe.restype = wintypes.BOOL

kernel32.CloseHandle.argtypes = [wintypes.HANDLE]
kernel32.CloseHandle.restype = wintypes.BOOL


def windows_error(operation: str) -> OSError:
    return ctypes.WinError(ctypes.get_last_error(), operation)


def create_pipe(name: str, access: int) -> wintypes.HANDLE:
    handle = kernel32.CreateNamedPipeW(
        name,
        access,
        PIPE_TYPE_BYTE | PIPE_READMODE_BYTE | PIPE_WAIT,
        1,
        65536,
        65536,
        0,
        None,
    )
    if handle == INVALID_HANDLE_VALUE:
        raise windows_error(f"CreateNamedPipeW({name})")
    return handle


def connect_pipe(handle: wintypes.HANDLE, name: str) -> None:
    if kernel32.ConnectNamedPipe(handle, None):
        return
    if ctypes.get_last_error() != ERROR_PIPE_CONNECTED:
        raise windows_error(f"ConnectNamedPipe({name})")


def write_all(handle: wintypes.HANDLE, data: bytes) -> None:
    buffer = ctypes.create_string_buffer(data)
    written = wintypes.DWORD()
    if not kernel32.WriteFile(handle, buffer, len(data), ctypes.byref(written), None):
        raise windows_error("WriteFile")
    if written.value != len(data):
        raise OSError(f"Short named-pipe write: {written.value} of {len(data)} bytes")


def receive_results(handle: wintypes.HANDLE) -> None:
    buffer = ctypes.create_string_buffer(4096)
    received = wintypes.DWORD()
    pending = b""

    while True:
        success = kernel32.ReadFile(
            handle, buffer, ctypes.sizeof(buffer), ctypes.byref(received), None
        )
        if not success:
            error = ctypes.get_last_error()
            if error == ERROR_BROKEN_PIPE:
                break
            raise windows_error("ReadFile")
        if received.value == 0:
            continue

        pending += buffer.raw[: received.value]
        while b"\n" in pending:
            line, pending = pending.split(b"\n", 1)
            print(line.rstrip(b"\r").decode("ascii"), flush=True)

    if pending:
        print(pending.decode("ascii"), flush=True)


def send_input(handle: wintypes.HANDLE, input_path: Path) -> None:
    with input_path.open("rb") as input_file:
        for line_number, line in enumerate(input_file, start=1):
            line = line.rstrip(b"\r\n")
            if not line:
                continue
            write_all(handle, line + b"\n")
            if len(line) != 2 and line != b"--":
                raise ValueError(
                    f"Invalid record on line {line_number}: {line!r}"
                )
    kernel32.FlushFileBuffers(handle)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--input",
        type=Path,
        default=Path("frame_data.txt"),
        help="hex-record input file (default: frame_data.txt)",
    )
    parser.add_argument(
        "--input-pipe",
        default=r"\\.\pipe\ccsds_crc16_in",
        help="input named-pipe path",
    )
    parser.add_argument(
        "--output-pipe",
        default=r"\\.\pipe\ccsds_crc16_out",
        help="output named-pipe path",
    )
    args = parser.parse_args()

    if args.input.is_dir():
        parser.error(f"Input path is a directory: {args.input}")
    if not args.input.exists():
        parser.error(f"Input file does not exist: {args.input}")

    input_handle = create_pipe(args.input_pipe, PIPE_ACCESS_OUTBOUND)
    output_handle = create_pipe(args.output_pipe, PIPE_ACCESS_INBOUND)
    try:
        print(f"Waiting for VHDL input connection on {args.input_pipe}...", flush=True)
        connect_pipe(input_handle, args.input_pipe)
        print(f"Waiting for VHDL output connection on {args.output_pipe}...", flush=True)
        connect_pipe(output_handle, args.output_pipe)

        receiver = threading.Thread(
            target=receive_results, args=(output_handle,), daemon=True
        )
        receiver.start()
        send_input(input_handle, args.input)
        kernel32.DisconnectNamedPipe(input_handle)
        receiver.join()
    finally:
        kernel32.DisconnectNamedPipe(output_handle)
        kernel32.CloseHandle(input_handle)
        kernel32.CloseHandle(output_handle)


if __name__ == "__main__":
    if not hasattr(ctypes, "WinDLL"):
        raise SystemExit("This script requires Windows.")
    main()
