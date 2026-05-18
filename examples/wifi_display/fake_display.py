import tkinter as tk
from tkinter import font

root = tk.Tk()
root.title("Textbox 5x13")
root.resizable(False, False)

mono_font = font.Font(family="Courier New", size=12)

text = tk.Text(
    root,
    width=13,      # 13 characters per line
    height=5,      # 5 lines
    font=mono_font,
    wrap="char"    # wrap at the 14th character
)

text.pack(padx=10, pady=10)

# Example: single write of 65 characters
data = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
text.insert("1.0", data[:65])

root.mainloop()
