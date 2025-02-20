import numpy as np
import scipy.signal as signal
import matplotlib.pyplot as plt

def design_filter(A, delta_w, wc, delta_p, delta_s, design_way):
    fs = 1000  # Sampling frequency

    if design_way == 3:  # Equiripple filter (Parks-McClellan)
        M = (-20 * np.log10(np.sqrt(delta_p * delta_s)) - 13) / (2.324 * delta_w)
        L = int(np.ceil(M) + 1)
        if L % 2 == 0:
            L += 1  # Ensure odd number of taps

        wp  = (wc - delta_w / 2) * (fs / (2 * np.pi))
        ws = (wc + delta_w / 2) * (fs / (2 * np.pi))
        bands = [0, wp, ws, 0.5 * fs]
        desired = [1, 0]
        weights = [1, delta_p / delta_s]

        taps = signal.remez(L, bands, desired, weight=weights, fs=fs)

        # Plot impulse response
        plt.figure()
        plt.stem(taps)
        plt.title("Impulse Response (h(n)) - Equiripple Filter")
        plt.xlabel("n")
        plt.ylabel("Amplitude")
        plt.grid()

        # Frequency response
        w_freq, h_freq = signal.freqz(taps, 1, 1024)
        magnitude_db = 20 * np.log10(np.abs(h_freq))

        plt.figure()
        plt.plot(w_freq / np.pi, magnitude_db)
        plt.title("Frequency Response - Equiripple Filter")
        plt.xlabel("Normalized Frequency (×π rad/sample)")
        plt.ylabel("Magnitude (dB)")
        plt.grid()

        # Compute ripple
        passband_ripple = np.max(np.abs(magnitude_db[w_freq * fs / (2 * np.pi) <= wp] - 20*np.log10(1))) 
        stopband_ripple = np.max(magnitude_db[w_freq * fs / (2 * np.pi) >= ws])  

        print(f"Passband Ripple: {passband_ripple:.2f} dB")
        print(f"Stopband Attenuation: {-stopband_ripple:.2f} dB")
        print(f"Filter Order: {L}")

        plt.axhline(y=stopband_ripple, color='r', linestyle='--')
        plt.show()
        return taps

    # Windowed FIR filter design
    if design_way == 2:  # Kaiser window
        window_name = "Kaiser"
        beta = 0 if A < 21 else (0.5842 * (A - 21) ** 0.4 + 0.07886 * (A - 21)) if A <= 50 else 0.1102 * (A - 8.7)
        print(f"Beta: {beta:.4f}")

        M = int(np.ceil((A - 8) / (2.285 * delta_w)))
        L = M + 1
        if L % 2 == 0:
            L += 1
        window = signal.windows.kaiser(L, beta, sym=True)

    else:  # Classical Windows
        window_types = [
            (21, "Rectangular", lambda L: signal.windows.boxcar(L), (1.8 * np.pi)),
            (26, "Bartlett", lambda L: signal.windows.bartlett(L), (6.1 * np.pi)),
            (44, "Hanning", lambda L: signal.windows.hann(L), (6.2 * np.pi)),
            (53, "Hamming", lambda L: signal.windows.hamming(L), (6.6 * np.pi)),
            (91, "Blackman", lambda L: signal.windows.blackman(L), (11 * np.pi))
        ]

        for threshold, window_name, window_func, coeff in window_types:
            if A < threshold:
                L = int(np.ceil(coeff / delta_w))
                if L % 2 == 0:
                    L += 1
                window = window_func(L)
                break
        else:
            raise ValueError("Invalid stopband attenuation (A) value.")

    # Compute impulse response
    M, alpha = L - 1, (L - 1) / 2
    n = np.arange(L)
    hd = np.zeros_like(n, dtype=float)
    for i in range(len(n)):
        if n[i] == alpha:
            hd[i] = wc / np.pi  # Handle singularity at n = alpha
        else:
            hd[i] = np.sin(wc * (n[i] - alpha)) / (np.pi * (n[i] - alpha))

    h = hd * window

    # Plot impulse response
    plt.figure()
    plt.stem(n, h)
    plt.title(f"Impulse Response (h(n)) - {window_name} Window")
    plt.xlabel("n")
    plt.ylabel("Amplitude")
    plt.grid()

    # Plot frequency response
    w_freq, h_freq = signal.freqz(h, 1, 1024)
    plt.figure()
    plt.plot(w_freq / np.pi, 20 * np.log10(np.abs(h_freq)))
    plt.title(f"Frequency Response - {window_name} Window")
    plt.xlabel("Normalized Frequency (×π rad/sample)")
    plt.ylabel("Magnitude (dB)")
    plt.grid()
    plt.show()

    return h

def generate_verilog(coeffs, L):
    verilog_code = f"""
module FIR_Filter  
#(  
    parameter TAPS = {L},                                            // Number of taps  
    parameter DATA_WIDTH = 16,                                      // Data width  
    parameter COEFF_WIDTH = 16                                      // Coefficient width
)  
(  
    input   wire                                         clk,        // Clock signal  
    input   wire                                         rst,        // Reset signal  
    input   wire signed  [DATA_WIDTH-1:0]                x,          // Input data  
    output  reg  signed  [DATA_WIDTH+COEFF_WIDTH-1:0]    y           // Output data  
);  

    // Accumulator registers
    reg signed [DATA_WIDTH+COEFF_WIDTH-1:0] acc [0:TAPS-2];
    integer i;
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            // Reset all accumulators and output
            for (i = 0; i < TAPS-1; i = i + 1) begin
                acc[i] <= 0;
            end
            y <= 0;
        end
        else begin
            // Unrolled computation with hardcoded coefficients
"""
    
    for i in range(L-1):
        if i == 0:
            verilog_code += f"            acc[{i}]  <= x * {coeffs[i]};   \n"
        else:
            verilog_code += f"            acc[{i}]  <= acc[{i-1}]  + (x * {coeffs[i]});  \n"
    
    verilog_code += f"""
            y      <= acc[{L-2}] + (x * {coeffs[L-1]});
        end
    end

endmodule
"""

    with open("../../src/FIR_Filter.v", "w") as file:
        file.write(verilog_code)