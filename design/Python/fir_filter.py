import numpy as np
from functions import design_filter, generate_verilog
import re

# Input Signal
Fs = 30720000                       # Sampling frequency = 30.72 MHz
Ts = 1 / Fs                         # Sampling period
t = np.arange(0, 1, Ts)             # Time vector

# Filter Specifications
wp = 0.25 * np.pi                   # Passband frequency (rad/sample)
ws = 0.35 * np.pi                   # Stopband frequency (rad/sample)
wc = (wp + ws) / 2                  # Cutoff frequency (rad/sample)
fc = (wc / (2 * np.pi)) * Fs        # Cutoff frequency in Hz

#  Filter Design Parameters
Ap = 0.1                            # Passband ripple (dB)
As = 50                             # Stopband attenuation (dB)
delta_w = ws - wp

# Compute delta values
delta_p = (10 ** (Ap / 20) - 1) / (10 ** (Ap / 20) + 1)
delta_s = (1 + delta_p) / (10 ** (As / 20))
delta = min(delta_p, delta_s)
A = -20 * np.log10(delta)           # Attenuation

# User selects window type
print("Select the design type:")
print("1: Standard Window (Rectangular, Barlett, Hamming, Hanning or Blackman)")
print("2: Kaiser Window")
print("3: Equiripple Filter (Parks-McClellan)")
choice = input("Enter your choice (1, 2 or 3): ").strip()

design_way = int(choice)

# Design filter
h = design_filter(A, delta_w, wc, delta_p, delta_s, design_way)
L = len(h) 

# Convert coefficients to signed int16
int_coeffs = np.int16(np.round(h * 2 ** 15))  # Scale to int16 range

# Generat verilog file for simulink verification
generate_verilog(int_coeffs, L)

# Define paths
coe_file_path = "../../src/coeffs.coe"
sv_file_path = "../../src/FIR_Filter.sv"
tb_file_path = "../../src/FIR_Filter_tb.sv"

# Save the full coefficients to a .COE file
coe_data = """Radix=10;
Coefficient_Width=16;
COEFDATA= """ + ", ".join(map(str, int_coeffs)) + ";"

with open(coe_file_path, "w") as file:
    file.write(coe_data)

# Write only half the coefficients (symmetric FIR) to the SV file
sym_taps = (L + 1) // 2  
half_coeffs = int_coeffs[:sym_taps]  

# Format as Verilog array
coeffs_sv = "'{" + ", ".join(map(str, half_coeffs)) + "}"

# Write the updated SV file
with open(sv_file_path, "r") as file:
    sv_lines = file.readlines()

coeffs_pattern = re.compile(r"(localparam\s+logic\s+signed\s+\[COEFF_WIDTH-1:0\]\s+COEFFS\s+\[SYM_TAPS\]\s*=\s*)'\{[^}]*\};")
taps_pattern = re.compile(r"(parameter\s+TAPS\s*=\s*)\d+\s*,")

updated_lines = []
for line in sv_lines:
    if coeffs_pattern.search(line):
        line = coeffs_pattern.sub(rf"\1{coeffs_sv};", line)  # Insert new half coefficients
    if taps_pattern.search(line):
        line = taps_pattern.sub(rf"parameter TAPS = {L},", line)
    updated_lines.append(line)

with open(sv_file_path, "w") as file:
    file.writelines(updated_lines)

# Write the TB file
with open(tb_file_path, "r") as file:
    tb_lines = file.readlines()

taps_tb_pattern = re.compile(r"(localparam\s+TAPS\s*=\s*)\d+\s*;")
coeffs_tb_pattern = re.compile(r"(bit\s+signed\s+\[COEFF_WIDTH-1:0\]\s+COEFFS\s+\[TAPS\]\s*=\s*)'\{[^}]*\};")

updated_tb_lines = []
for line in tb_lines:
    if taps_tb_pattern.search(line):
        line = taps_tb_pattern.sub(rf"localparam TAPS = {L};", line)
    if coeffs_tb_pattern.search(line):
        line = coeffs_tb_pattern.sub(rf"\1{coeffs_sv};", line)
    updated_tb_lines.append(line)

with open(tb_file_path, "w") as file:
    file.writelines(updated_tb_lines)

