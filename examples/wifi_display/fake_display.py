import tkinter as tk
from tkinter import font

root = tk.Tk()
root.title("Textbox 5x13")
root.resizable(False, False)

mono_font = font.Font(family="Courier New", size=12)

text = tk.Text(
    root,
    width=13,      # 13 caractères par ligne
    height=5,      # 5 lignes
    font=mono_font,
    wrap="char"    # passage à la ligne au 14e caractère
)

text.pack(padx=10, pady=10)

# Exemple : écriture UNIQUE de 65 caractères
data = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
text.insert("1.0", data[:65])

root.mainloop()
