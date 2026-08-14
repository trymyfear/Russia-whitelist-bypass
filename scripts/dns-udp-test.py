#!/usr/bin/env python3
import socket
import struct


def qname(name: str) -> bytes:
    return b"".join(bytes([len(label)]) + label.encode("ascii") for label in name.split(".")) + b"\x00"


transaction_id = 0x5742
query = struct.pack("!HHHHHH", transaction_id, 0x0100, 1, 0, 0, 0)
query += qname("example.com") + struct.pack("!HH", 1, 1)

with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
    sock.settimeout(10)
    sock.sendto(query, ("127.0.0.1", 10953))
    response, peer = sock.recvfrom(4096)

received_id, flags, questions, answers, authority, additional = struct.unpack("!HHHHHH", response[:12])
if received_id != transaction_id or not flags & 0x8000 or flags & 0x000F:
    raise SystemExit("invalid DNS response")
if answers < 1:
    raise SystemExit("DNS response contains no answers")

print(f"UDP_DNS_OK peer={peer[0]}:{peer[1]} answers={answers} bytes={len(response)}")
