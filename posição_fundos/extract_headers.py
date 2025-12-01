import glob
import os

dir_path = "/Users/kemueldemelleopoldino/Desktop/DEV_KML/GITHUB/KML-1/posição_fundos/source/cda_fi_ago"
output_file = "/Users/kemueldemelleopoldino/Desktop/DEV_KML/GITHUB/KML-1/posição_fundos/headers.txt"
files = glob.glob(os.path.join(dir_path, "*.csv"))
files.sort()

with open(output_file, 'w', encoding='utf-8') as out:
    for f in files:
        out.write(f"--- {os.path.basename(f)} ---\n")
        try:
            with open(f, 'r', encoding='utf-8', errors='replace') as file:
                for _ in range(3):
                    line = file.readline()
                    if not line: break
                    out.write(line)
        except Exception as e:
            out.write(f"Error reading {f}: {e}\n")
        out.write("\n")
print("Headers extracted to headers.txt")
