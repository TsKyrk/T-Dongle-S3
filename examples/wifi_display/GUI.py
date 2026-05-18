import tkinter as tk
from tkinter import font, ttk
import threading
import socket
import urllib.parse
import urllib.request

BROADCAST_IP = "255.255.255.255"
PORT = 4210
DISCOVER_MSG = b"DISCOVER_TDONGLE"
SCAN_TIMEOUT = 5.0
MAX_CHARS = 65  # 5 lines × 13 cols


class TDongleGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("T-Dongle Controller")
        self.root.resizable(False, False)
        self._build_ui()

    def _build_ui(self):
        # --- Device Discovery ---
        disc = tk.LabelFrame(self.root, text="Device Discovery", padx=8, pady=6)
        disc.pack(padx=10, pady=(10, 4), fill="x")

        self.btn_scan = tk.Button(disc, text="Scan", width=7, command=self._start_scan)
        self.btn_scan.grid(row=0, column=0, padx=(0, 6))

        self.device_var = tk.StringVar()
        self.combo = ttk.Combobox(disc, textvariable=self.device_var, state="readonly", width=20)
        self.combo.grid(row=0, column=1, sticky="w")

        tk.Label(disc, text="or IP:").grid(row=1, column=0, sticky="e", pady=(4, 0))
        self.manual_ip = tk.Entry(disc, width=22)
        self.manual_ip.grid(row=1, column=1, sticky="w", pady=(4, 0))

        self.status_label = tk.Label(disc, text="Not scanned.", fg="gray", anchor="w")
        self.status_label.grid(row=2, column=0, columnspan=2, sticky="w", pady=(4, 0))

        # --- Message Editor ---
        mono = font.Font(family="Courier New", size=12)
        edit = tk.LabelFrame(self.root, text="Message  (5 × 13 chars)", padx=8, pady=6)
        edit.pack(padx=10, pady=4, fill="x")

        self.text = tk.Text(edit, width=13, height=5, font=mono, wrap="char",
                            undo=False, maxundo=0)
        self.text.grid(row=0, column=0)

        self.char_label = tk.Label(edit, text="chars: 0/65", anchor="w")
        self.char_label.grid(row=0, column=1, padx=(8, 0), sticky="n")

        self.text.bind("<<Modified>>", self._on_text_modified)

        # --- Send ---
        self.btn_send = tk.Button(self.root, text="Send to Device", width=20,
                                  command=self._start_send)
        self.btn_send.pack(pady=(4, 10))

    # ------------------------------------------------------------------ scan

    def _start_scan(self):
        self.btn_scan.config(state="disabled")
        self.combo.config(values=[])
        self.device_var.set("")
        self._set_status("Scanning…", "blue")
        threading.Thread(target=self._scan_thread, daemon=True).start()

    def _scan_thread(self):
        found = []
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        sock.settimeout(SCAN_TIMEOUT)
        try:
            sock.sendto(DISCOVER_MSG, (BROADCAST_IP, PORT))
            while True:
                _, addr = sock.recvfrom(1024)
                ip = addr[0]
                if ip not in found:
                    found.append(ip)
        except socket.timeout:
            pass
        finally:
            sock.close()
        self.root.after(0, self._on_scan_done, found)

    def _on_scan_done(self, found):
        self.btn_scan.config(state="normal")
        if found:
            self.combo.config(values=found)
            self.combo.current(0)
            self._set_status(f"Found {len(found)} device(s).", "green")
        else:
            self._set_status("No devices found.", "red")

    # ------------------------------------------------------------------ text

    def _on_text_modified(self, _event):
        content = self.text.get("1.0", "end-1c")
        if len(content) > MAX_CHARS:
            # hard-cap: strip excess characters
            self.text.delete(f"1.0+{MAX_CHARS}c", "end")
            content = content[:MAX_CHARS]
        self.char_label.config(text=f"chars: {len(content)}/{MAX_CHARS}")
        self.text.edit_modified(False)  # reset flag so next edit fires the event again

    # ------------------------------------------------------------------ send

    def _start_send(self):
        ip = self.manual_ip.get().strip() or self.device_var.get().strip()
        if not ip:
            self._set_status("No device selected.", "red")
            return
        text = self.text.get("1.0", "end-1c")
        self._set_status(f"Sending to {ip}…", "blue")
        self.btn_send.config(state="disabled")
        threading.Thread(target=self._send_thread, args=(ip, text), daemon=True).start()

    def _send_thread(self, ip, text):
        url = f"http://{ip}?msg={urllib.parse.quote(text)}"
        try:
            with urllib.request.urlopen(url, timeout=5) as resp:
                body = resp.read().decode(errors="ignore").strip()
            self.root.after(0, self._set_status, f"Sent OK — {body[:40]}", "green")
        except Exception as exc:
            self.root.after(0, self._set_status, f"Error: {exc}", "red")
        finally:
            self.root.after(0, self.btn_send.config, {"state": "normal"})

    # ------------------------------------------------------------------ util

    def _set_status(self, msg, color="gray"):
        self.status_label.config(text=msg, fg=color)


def main():
    root = tk.Tk()
    TDongleGUI(root)
    root.mainloop()


if __name__ == "__main__":
    main()
