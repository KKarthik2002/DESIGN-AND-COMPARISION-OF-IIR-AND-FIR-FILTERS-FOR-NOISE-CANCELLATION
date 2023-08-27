function mainFilterDesignGUI()
    % GUI Components
    fig = figure('Name', 'Advanced Filter Design', 'NumberTitle', 'Off', 'Position', [100, 100, 900, 650]);

    uicontrol('Style', 'text', 'Position', [50 620 100 20], 'String', 'Filter Type:');
    filterDropdown = uicontrol('Style', 'popupmenu', 'Position', [150 620 150 20], 'String', {'Butterworth', 'Chebyshev', 'Elliptic', 'Legendre'}, 'Callback', @updatePlot);

    uicontrol('Style', 'text', 'Position', [50 590 100 20], 'String', 'Pass Band (Hz):');
    passBandEdit = uicontrol('Style', 'edit', 'Position', [150 590 150 20], 'String', '7000', 'Callback', @updatePlot);
    
    uicontrol('Style', 'text', 'Position', [50 560 100 20], 'String', 'Stop Band (Hz):');
    stopBandEdit = uicontrol('Style', 'edit', 'Position', [150 560 150 20], 'String', '8000', 'Callback', @updatePlot);

    uicontrol('Style', 'pushbutton', 'Position', [650 620 120 30], 'String', 'Load Custom Signal', 'Callback', @loadCustomSignal);
    uicontrol('Style', 'pushbutton', 'Position', [650 580 120 30], 'String', 'Save Filtered Signal', 'Callback', @saveSignal);
    uicontrol('Style', 'pushbutton', 'Position', [650 540 120 30], 'String', 'Save Coefficients', 'Callback', @saveCoefficients);
    uicontrol('Style', 'pushbutton', 'Position', [650 500 120 30], 'String', 'Filter Info', 'Callback', @displayFilterInfo);

    % Filter Characteristics Text Display
    filterCharText = uicontrol('Style', 'text', 'Position', [400 600 250 100], 'String', 'Filter Characteristics:', 'HorizontalAlignment', 'left');

    % Plotting areas
    ax1 = subplot(3,1,1, 'Parent', fig, 'Position', [0.1 0.68 0.8 0.28]);
    ax2 = subplot(3,1,2, 'Parent', fig, 'Position', [0.1 0.38 0.8 0.28]);
    ax3 = subplot(3,1,3, 'Parent', fig, 'Position', [0.1 0.08 0.8 0.28]);

    hZoom = zoom;
    hPan = pan;
    set(hZoom, 'Motion', 'both', 'Enable', 'on');
    set(hPan, 'Motion', 'both', 'Enable', 'off');

    function updatePlot(~, ~)
        filterType = filterDropdown.String{filterDropdown.Value};
        fp = str2double(passBandEdit.String);
        fs = str2double(stopBandEdit.String);
        [noisySignal, filteredSignal, numeratorCoeff, denominatorCoeff, n] = mainFilterDesign(filterType, fp, fs);
        
        % Plotting
        plot(ax1, noisySignal), title(ax1, 'Sine Signal with Noise');
        plot(ax2, filteredSignal), title(ax2, 'Filtered Sine Signal');
        
        % Magnitude and Phase Response
        freqz(numeratorCoeff, denominatorCoeff, [], 500, 'whole', ax3);
        title(ax3, 'Magnitude and Phase Response');

        filterCharText.String = sprintf('Filter Characteristics:\nType: %s\nOrder: %d', filterType, n);
    end

    function loadCustomSignal(~, ~)
        [file, path] = uigetfile('*.mat', 'Load Custom Signal');
        if isequal(file,0) || isequal(path,0)
            return;
        else
            customData = load(fullfile(path, file));
            if isfield(customData, 'signal')
                noisySignal = customData.signal;
                updatePlot();
            else
                errordlg('Invalid file format. Expecting "signal" variable in the MAT file.', 'Error');
            end
        end
    end

    function saveSignal(~, ~)
        [file, path] = uiputfile('*.mat', 'Save Filtered Signal As');
        if isequal(file,0) || isequal(path,0)
            return;
        else
            z = filteredSignal;
            save(fullfile(path, file), 'z');
        end
    end

    function saveCoefficients(~, ~)
        [file, path] = uiputfile('*.mat', 'Save Filter Coefficients As');
        if isequal(file,0) || isequal(path,0)
            return;
        else
            b = numeratorCoeff;
            a = denominatorCoeff;
            save(fullfile(path, file), 'b', 'a');
        end
    end

    function displayFilterInfo(~, ~)
        filterType = filterDropdown.String{filterDropdown.Value};
        fp = str2double(passBandEdit.String);
        fs = str2double(stopBandEdit.String);
        [noisySignal, filteredSignal, numeratorCoeff, denominatorCoeff, n] = mainFilterDesign(filterType, fp, fs);
        
        infoStr = sprintf('Filter Type: %s\nOrder: %d\nFilter Coefficients:\nnumeratorCoeff: %s\ndenominatorCoeff: %s', filterType, n, mat2str(numeratorCoeff), mat2str(denominatorCoeff));
        msgbox(infoStr, 'Filter Information');
    end
end

function [noisySignal, filteredSignal, numeratorCoeff, denominatorCoeff, n] = mainFilterDesign(filterType, fp, fs)
    % Sine Signal Parameters
    Fs = 500; 
    duration = 10;
    amp = 5;
    f1 = 5; 
    phase = 0; 

    Ts = 1/Fs; 
    t = 0:Ts:(duration-Ts);
    noise = 0.5 * randn(size(t));
    noisySignal = amp * sin((2*pi*f1*t) + phase) + noise;

    % Filter Design Parameters
    rp = 0.12; 
    rs = 50; 
    f2 = 50000; 

    wp = fp/(f2/2); 
    ws = fs/(f2/2);
    
    switch filterType
        case 'Butterworth'
            [n, wn] = buttord(wp, ws, rp, rs);
            [numeratorCoeff, denominatorCoeff] = butter(n, wn);
        case 'Chebyshev'
            [n, wn] = cheb1ord(wp, ws, rp, rs);
            [numeratorCoeff, denominatorCoeff] = cheby1(n, rp, wn);
        case 'Elliptic'
            [n, wn] = ellipord(wp, ws, rp, rs);
            [numeratorCoeff, denominatorCoeff] = ellip(n, rp, rs, wn);
        case 'Legendre'
            [numeratorCoeff, denominatorCoeff] = legendreFilter(n);
            [numeratorCoeff, denominatorCoeff] = bilinear(numeratorCoeff, denominatorCoeff, Fs);
    end
    
    filteredSignal = filtfilt(numeratorCoeff, denominatorCoeff, noisySignal);
end

function [numeratorCoeff, denominatorCoeff] = legendreFilter(N)
    legPoly = legendreP(N);
    r = roots(legPoly);
    r = r(imag(r) < 0);
    [numeratorCoeff, denominatorCoeff] = zp2tf([], r, 1);
end

function P = legendreP(N)
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





