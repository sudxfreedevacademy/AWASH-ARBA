import os
import subprocess

pawncc = "/data/data/com.termux/files/home/pawncc"
script = "gamemodes/gamemode.pwn"

if os.path.exists(pawncc) and os.path.exists(script):
    print("Compiling gamemode...")
    result = subprocess.run([pawncc, script])
    if result.returncode == 0:
        print("Compilation Successful!")
    else:
        print("Compilation Failed!")
else:
    print("Compiler or script path not found!")
