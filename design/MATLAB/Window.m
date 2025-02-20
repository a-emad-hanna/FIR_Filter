function [alpha, L, window] = Window(A, delta_w, k)
    if (k)
        fprintf('Using Kaiser Window\n');
        if A > 50
            beta = 0.1102*(A - 8.7);
        elseif A > 21
            beta = 0.5842*(A - 21)^0.4 + 0.07886*(A - 21);
        else
            beta = 0;
        end
        fprintf('Beta: %f\n', beta);
        M = ceil((A - 8)/(2.285*delta_w));
        L = M + 1;
        if mod(L, 2) == 0
            L = L + 1;
        end
        window = kaiser(L, beta);
    else
        switch true
            case (A < 21)
                fprintf('Using Rectangular Window\n');
                L = ceil((1.8*pi)/delta_w);
                if mod(L, 2) == 0
                    L = L + 1;
                end
                window = rectwin(L);
            case (A < 26)
                fprintf('Using Bartlett Window\n');
                L = ceil((6.1*pi)/delta_w);
                if mod(L, 2) == 0
                    L = L + 1;
                end
                window = bartlett(L);
            case (A < 44)
                fprintf('Using Hanning Window\n');
                L = ceil((6.2*pi)/delta_w);
                    if mod(L, 2) == 0
                        L = L + 1;
                    end
                window = hann(L);
            case (A < 53)
                fprintf('Using Hamming Window\n');
                L = ceil((6.6*pi)/delta_w);
                    if mod(L, 2) == 0
                        L = L + 1;
                    end
                window = hamming(L);
            case (A < 91)
                fprintf('Using Blackman Window\n');
                L = ceil((11*pi)/delta_w);
                if mod(L, 2) == 0
                    L = L + 1;
                end
                window = blackman(L);
            otherwise
                error('Invalid stopband attenuation (A) value.');
        end
    end
    M = L - 1;
    alpha = M / 2;
end