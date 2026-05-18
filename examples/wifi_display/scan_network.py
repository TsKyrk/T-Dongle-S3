import socket
import os
import urllib.parse
import urllib.request

BROADCAST_IP = "255.255.255.255"
PORT = 4210
MESSAGE = b"DISCOVER_TDONGLE"
TIMEOUT = 5.0  # seconds

# Discover the T-Dongle device on the network
def find_device():
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

    # Enable broadcast
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)

    # Timeout so it doesn't block
    sock.settimeout(TIMEOUT)

    try:
        print("Sending broadcast...")
        sock.sendto(MESSAGE, (BROADCAST_IP, PORT))

        print("Waiting for response...")
        while True:
            data, addr = sock.recvfrom(1024)
            msg = data.decode(errors='ignore')
            print(f"Received response from {addr[0]}: {msg}")
            return addr[0]  # Return the IP address of the discovered device

    except socket.timeout:
        print("No response received")
        return None

    finally:
        sock.close()

# Send text to the T-Dongle device at the given IP address
def tdongle_set_text(ip_address, text):
    if not ip_address:
        print("No IP address provided")
        return None

    # Build URL: http://<ip_address>?msg=<url-encoded-text>
    encoded = urllib.parse.quote(str(text))
    url = f"http://{ip_address}?msg={encoded}"

    try:
        with urllib.request.urlopen(url, timeout=5) as resp:
            body = resp.read().decode(errors='ignore')
            print(f"Sent text to {ip_address}, response: {body}")
            return body
    except Exception as e:
        print(f"Failed to send text to {ip_address}: {e}")
        return None


# Read keyboard input and send it to the T-Dongle device
def read_keyboard_and_send(ip_address):
    print("Type text to send to T-Dongle (empty line to quit):")
    while True:
        try:
            line = input()
            if line == "":
                break
            tdongle_set_text(ip_address, line)
        except EOFError:
            break


def main():
    ip_address = find_device()
    if ip_address is not None:
        tdongle_set_text(ip_address,f"Hello from   {os.path.basename(__file__)}")
        read_keyboard_and_send(ip_address)


if __name__ == "__main__":
    main()