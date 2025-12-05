import glob
import os

# Set the directory path
dir_path = "/Users/kemueldemelleopoldino/Desktop/DEV_KML/GITHUB/KML-1/posição_fundos/source/cda_fi_ago"
files = glob.glob(os.path.join(dir_path, "*.csv"))
files.sort()

for f in files:
    print(f"--- {os.path.basename(f)} ---")
    try:
        with open(f, 'r', encoding='utf-8', errors='replace') as file:
            for _ in range(3):
                line = file.readline()
                if not line: break
                print(line.strip())
    except Exception as e:
        print(f"Error reading {f}: {e}")
    print()
