function mainFilterDesignGUI()

    % GUI Components
    fig = figure('Name', 'Advanced Filter Design', 'NumberTitle', 'Off', 'Position', [100, 100, 600, 400]);

    uicontrol('Style', 'text', 'Position', [50 360 100 20], 'String', 'Filter Type:');
    filterDropdown = uicontrol('Style', 'popupmenu', 'Position', [150 360 150 20], 'String', {'Butterworth', 'Chebyshev', 'Elliptic', 'Legendre'}, 'Callback', @updatePlot);

    uicontrol('Style', 'pushbutton', 'Position', [450 360 100 30], 'String', 'Save Signal', 'Callback', @saveSignal);
    uicontrol('Style', 'pushbutton', 'Position', [450 320 100 30], 'String', 'Filter Info', 'Callback', @displayFilterInfo);
    
    % Plotting areas
    ax1 = subplot(2,1,1, 'Parent', fig);
    ax2 = subplot(2,1,2, 'Parent', fig);
    
    % Function to update plot
    function updatePlot(src, event)
        filterType = filterDropdown.String{filterDropdown.Value};
        [y, z, b, a, f2] = mainFilterDesign(filterType);  % Calling the external function

        % Plotting
        plot(ax1, y), title(ax1, 'Sine Signal with Noise');
        plot(ax2, z), title(ax2, 'Filtered Sine Signal');
    end

    % Function to save signal
    function saveSignal(src, event)
        [file, path] = uiputfile('*.mat', 'Save Filtered Signal As');
        if isequal(file,0) || isequal(path,0)
            return;
        else
            save(fullfile(path, file), 'z');
        end
    end
    
    % Function to display filter information
    function displayFilterInfo(src, event)
        filterType = filterDropdown.String{filterDropdown.Value};
        [y, z, b, a, f2] = mainFilterDesign(filterType);  % Calling the external function
        
        infoStr = sprintf('Filter Type: %s\nFilter Coefficients:\nb: %s\na: %s', filterType, mat2str(b), mat2str(a));
        msgbox(infoStr, 'Filter Information');
    end
end

function [y, z, b, a, f2] = mainFilterDesign(filterType)

    % Sine Signal Parameters
    Fs = 500;                   % Sampling Frequency (Hz)
    duration = 10;              % Duration of the signal in seconds
    N = Fs * duration;          % Total number of samples
    amp = 5;                    % Amplitude
    f1 = 5;                     % Frequency (Hz)
    phase = 0;                  % Phase (radians)
    
    Ts = 1/Fs; 
    t = 0:Ts:(duration-Ts);

    % Generate Gaussian white noise samples
    noise = 0.5 * randn(size(t));

    % Generate sine signal with noise
    y = amp * sin((2*pi*f1*t) + phase) + noise;
    
    % Filter Design Parameters
    fp = 7000;                  % Pass band frequency
    fs = 8000;                  % Stop band frequency
    rp = 0.12;                  % Pass band attenuation
    rs = 50;                    % Stop band attenuation
    f2 = 50000;                 % Sampling frequency
    
    % Normalized frequencies
    wp = fp/(f2/2); 
    ws = fs/(f2/2);
    
    % Filter Design: Including Legendre
    switch filterType
        case 'Butterworth'
            [n, wn] = buttord(wp, ws, rp, rs);
            [b, a] = butter(n, wn);
        case 'Chebyshev'
            [n, wn] = cheb1ord(wp, ws, rp, rs);
            [b, a] = cheby1(n, rp, wn);
        case 'Elliptic'
            [n, wn] = ellipord(wp, ws, rp, rs);
            [b, a] = ellip(n, rp, rs, wn);
        case 'Legendre'
            % For Legendre, the order 'n' and 'wp' determines the filter
            % We use the provided 'n' and 'wp' for demonstration
            [b, a] = legendreFilter(n);
            % Convert to digital using bilinear transformation
            [b, a] = bilinear(b, a, Fs);
    end
    
    % Filtering
    z = filtfilt(b, a, y);
    
end

function [b, a] = legendreFilter(N)
    % Compute the Legendre polynomial roots
    legPoly = legendreP(N);
    r = roots(legPoly);
    
    % Keep only the left-half plane roots (analog domain)
    r = r(imag(r) < 0);
    
    % Convert the roots to a transfer function
    [b, a] = zp2tf([], r, 1);
end

function P = legendreP(N)
    % Compute Legendre polynomial of degree N
    if N == 0
        P = 1;
    elseif N == 1
        P = [1 0];
    else
        P_prev = [1 0];
        P_curr = [1 0];
        for k = 2:N
            P_next = ((2*k-1)*conv([1 0], P_curr) - (k-1)*[0 0 P_prev])/k;
            P_prev = P_curr;
            P_curr = P_next;
        end
        P = P_curr;
    end
end




