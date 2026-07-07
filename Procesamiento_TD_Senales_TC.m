function Proyecto_Audio_GUI()
    % --- CONFIGURACIÓN DE LA INTERFAZ (GUI) NORMALIZADA ---
    fig = figure('Name', 'Procesador de Audio DSP - Sistemas Lineales', ...
                 'NumberTitle', 'off', 'Units', 'normalized', ...
                 'Position', [0.1, 0.1, 0.8, 0.8], ...
                 'Color', [0.95 0.95 0.95], 'MenuBar', 'none');

    % Variables globales
    d.x = []; d.fs = 0; 
    d.y_res = []; d.fs_new = 0; 
    d.y_eq = []; 
    d.filtros_eq = {}; % Para guardar las respuestas H(f) y graficarlas
    d.player = []; % OBJETO PARA CONTROLAR EL AUDIO
    
    % Panel de Controles
    panel = uipanel('Parent', fig, 'Units', 'normalized', ...
                    'Position', [0.01, 0.01, 0.25, 0.98], 'Title', 'CONTROLES');
    
    % 1. Cargar Audio
    uicontrol(panel, 'Style', 'pushbutton', 'String', '1. CARGAR AUDIO (.wav)', ...
              'Units', 'normalized', 'Position', [0.05, 0.90, 0.6, 0.05], 'Callback', @cargar_audio);
    btn_play0 = uicontrol(panel, 'Style', 'pushbutton', 'String', 'Play', ...
                          'Units', 'normalized', 'Position', [0.68, 0.90, 0.25, 0.05], ...
                          'Enable', 'off', 'Callback', @play_audio0);
                          
    % BOTÓN: STOP AUDIO
    uicontrol(panel, 'Style', 'pushbutton', 'String', '⏹ STOP', ...
              'Units', 'normalized', 'Position', [0.68, 0.84, 0.25, 0.05], ...
              'Callback', @stop_audio);
                          
    lbl_info = uicontrol(panel, 'Style', 'text', 'String', 'Sin cargar', ...
                         'Units', 'normalized', 'Position', [0.05, 0.85, 0.6, 0.03], 'HorizontalAlignment', 'left');

    % 2. Resampling
    uicontrol(panel, 'Style', 'text', 'String', '2. CONVERSOR DE TASA', ...
              'Units', 'normalized', 'Position', [0.05, 0.78, 0.9, 0.03], 'FontWeight', 'bold', 'HorizontalAlignment', 'left');
    bg_modo = uibuttongroup('Parent', panel, 'Units', 'normalized', 'Position', [0.05, 0.66, 0.9, 0.11]);
    r1 = uicontrol(bg_modo, 'Style', 'radiobutton', 'String', 'Diezmar (Bajar)', 'Units', 'normalized', 'Position', [0.05, 0.5, 0.9, 0.4]);
    r2 = uicontrol(bg_modo, 'Style', 'radiobutton', 'String', 'Interpolar (Subir)', 'Units', 'normalized', 'Position', [0.05, 0.1, 0.9, 0.4]);
    
    uicontrol(panel, 'Style', 'text', 'String', 'Factor:', 'Units', 'normalized', 'Position', [0.05, 0.60, 0.3, 0.04], 'HorizontalAlignment', 'left');
    edit_factor = uicontrol(panel, 'Style', 'edit', 'String', '2', 'Units', 'normalized', 'Position', [0.4, 0.60, 0.2, 0.04]);
    
    uicontrol(panel, 'Style', 'pushbutton', 'String', 'Aplicar Conversión', ...
              'Units', 'normalized', 'Position', [0.05, 0.54, 0.6, 0.05], 'Callback', @aplicar_resample);
    btn_play1 = uicontrol(panel, 'Style', 'pushbutton', 'String', 'Play', ...
                          'Units', 'normalized', 'Position', [0.68, 0.54, 0.25, 0.05], 'Enable', 'off', 'Callback', @play_audio1);

    % 3. Ecualizador (6 Bandas)
    uicontrol(panel, 'Style', 'text', 'String', '3. ECUALIZADOR', ...
              'Units', 'normalized', 'Position', [0.05, 0.48, 0.9, 0.03], 'FontWeight', 'bold', 'HorizontalAlignment', 'left');
          
    band_names = {'Sub-Bass (16-60Hz)', 'Bass (60-250Hz)', 'Low Mids (250-2kHz)', ...
                  'High Mids (2k-4kHz)', 'Presence (4k-6kHz)', 'Brilliance (6k-16kHz)'};
    sliders = zeros(1, 6);
    y_pos = 0.42;
    for i = 1:6
        uicontrol(panel, 'Style', 'text', 'String', band_names{i}, 'Units', 'normalized', 'Position', [0.05, y_pos, 0.45, 0.03], 'HorizontalAlignment', 'left');
        sliders(i) = uicontrol(panel, 'Style', 'slider', 'Min', 0, 'Max', 2, 'Value', 1, ...
                               'Units', 'normalized', 'Position', [0.55, y_pos, 0.4, 0.03]);
        y_pos = y_pos - 0.05;
    end

    uicontrol(panel, 'Style', 'pushbutton', 'String', 'Aplicar Ecualizador', ...
              'Units', 'normalized', 'Position', [0.05, 0.10, 0.6, 0.05], 'Callback', @aplicar_eq);
    btn_play2 = uicontrol(panel, 'Style', 'pushbutton', 'String', 'Play', ...
                          'Units', 'normalized', 'Position', [0.68, 0.10, 0.25, 0.05], 'Enable', 'off', 'Callback', @play_audio2);
                          
    uicontrol(panel, 'Style', 'pushbutton', 'String', 'Ver Respuesta Filtros |H(f)|', ...
              'Units', 'normalized', 'Position', [0.05, 0.03, 0.9, 0.05], 'Callback', @mostrar_filtros);

    % Selector de Vista
    bg_view = uibuttongroup('Parent', fig, 'Units', 'normalized', 'Position', [0.28, 0.92, 0.7, 0.06], 'SelectionChangedFcn', @actualizar_graficas);
    btn_v1 = uicontrol(bg_view, 'Style', 'radiobutton', 'String', 'Ver Original', 'Units', 'normalized', 'Position', [0.05, 0.1, 0.25, 0.8], 'Tag', 'orig');
    btn_v2 = uicontrol(bg_view, 'Style', 'radiobutton', 'String', 'Ver Resampleada', 'Units', 'normalized', 'Position', [0.35, 0.1, 0.3, 0.8], 'Tag', 'res', 'Enable', 'off');
    btn_v3 = uicontrol(bg_view, 'Style', 'radiobutton', 'String', 'Ver Ecualizada', 'Units', 'normalized', 'Position', [0.70, 0.1, 0.25, 0.8], 'Tag', 'eq', 'Enable', 'off');

    % Gráficas
    ax_time = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.33, 0.55, 0.62, 0.3]);
    title(ax_time, 'Dominio del Tiempo'); grid on;
    ax_freq = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.33, 0.1, 0.62, 0.3]);
    title(ax_freq, 'Espectro Bilateral (Frecuencia)'); grid on;

    % --- FUNCIONES CALLBACK ---

    function cargar_audio(~, ~)
        [file, path] = uigetfile('*.wav', 'Seleccione el audio');
        if isequal(file, 0), return; end
        
        stop_audio(); % Detener si algo sonaba antes
        
        [x_in, fs_in] = audioread(fullfile(path, file));
        if size(x_in, 2) > 1, x_in = mean(x_in, 2); end
        
        % ¡Carga completa del audio sin límites!
        
        d.x = x_in; d.fs = fs_in;
        set(lbl_info, 'String', sprintf('Fs: %d Hz | Muestras: %d', d.fs, length(d.x)));
        set(btn_play0, 'Enable', 'on');
        
        bg_view.SelectedObject = btn_v1; 
        actualizar_graficas();
    end

    function aplicar_resample(~, ~)
        if isempty(d.x), return; end
        factor = round(str2double(get(edit_factor, 'String')));
        if isnan(factor) || factor <= 0, errordlg('Factor inválido'); return; end
        
        stop_audio(); % Que no suene música vieja mientras procesamos
        modo = get(bg_modo.SelectedObject, 'String');
        wb = waitbar(0, 'Procesando conversión de tasa...');
        
        N_filt = 100 * factor; 
        if mod(N_filt, 2) == 0, N_filt = N_filt + 1; end 
        
        if contains(modo, 'Diezmar')
            wc = 1 / factor; 
            h = fir_hamming(wc, N_filt);
            waitbar(0.3, wb, 'Aplicando filtro Anti-Alias...');
            y_filt = convolucion_fft(d.x, h);
            d.y_res = y_filt(1:factor:end); 
            d.fs_new = round(d.fs / factor);
        else
            y_up = zeros(length(d.x) * factor, 1);
            y_up(1:factor:end) = d.x; 
            wc = 1 / factor;
            h = fir_hamming(wc, N_filt);
            waitbar(0.5, wb, 'Aplicando filtro de Interpolación...');
            d.y_res = factor * convolucion_fft(y_up, h); 
            d.fs_new = d.fs * factor;
        end
        
        close(wb);
        set(btn_play1, 'Enable', 'on');
        set(btn_v2, 'Enable', 'on');
        bg_view.SelectedObject = btn_v2;
        actualizar_graficas();
    end

    function aplicar_eq(~, ~)
        if isempty(d.y_res), errordlg('Primero aplique el conversor de tasa.'); return; end
        
        stop_audio();
        f_cortes = [16 60; 60 250; 250 2000; 2000 4000; 4000 6000; 6000 16000];
        nyquist = d.fs_new / 2;
        y_out = zeros(size(d.y_res));
        d.filtros_eq = cell(1,6); 
        
        wb = waitbar(0, 'Aplicando ecualizador por banco de filtros...');
        N_eq = 4097; 
        
        for k = 1:6
            g = get(sliders(k), 'Value');
            
            f_low = f_cortes(k, 1); f_high = f_cortes(k, 2);
            if f_low >= nyquist, continue; end
            if f_high > nyquist, f_high = nyquist * 0.99; end
            
            h_low = fir_hamming(f_high/nyquist, N_eq);
            h_high = fir_hamming(f_low/nyquist, N_eq);
            h_bp = h_low - h_high;
            d.filtros_eq{k} = h_bp; 
            
            if g > 0
                y_banda = convolucion_fft(d.y_res, h_bp);
                y_out = y_out + (g * y_banda);
            end
            waitbar(k/6, wb);
        end
        
        d.y_eq = y_out;
        close(wb);
        set(btn_play2, 'Enable', 'on');
        set(btn_v3, 'Enable', 'on');
        bg_view.SelectedObject = btn_v3;
        actualizar_graficas();
    end

    function actualizar_graficas(~, ~)
        tag = get(bg_view.SelectedObject, 'Tag');
        if strcmp(tag, 'orig')
            s = d.x; fs_plot = d.fs; c = '#0072BD'; t_str = 'Original';
        elseif strcmp(tag, 'res')
            s = d.y_res; fs_plot = d.fs_new; c = '#D95319'; t_str = 'Resampleada';
        else
            s = d.y_eq; fs_plot = d.fs_new; c = '#EDB120'; t_str = 'Ecualizada';
        end
        if isempty(s), return; end

        t = (0:length(s)-1) / fs_plot;
        plot(ax_time, t, s, 'Color', c);
        title(ax_time, ['Dominio del Tiempo - Señal ' t_str]); xlabel(ax_time, 'Segundos'); ylabel(ax_time, 'Amplitud');
        axis(ax_time, 'tight'); grid(ax_time, 'on');

        % Optimización gráfica para no congelar MATLAB si cargan una canción muy larga
        nUsado = min(length(s), 2^18); 
        s_vis = s(1:nUsado);
        N_fft = 2^nextpow2(nUsado);
        
        S_freq = abs(fftshift(fft(s_vis, N_fft)));
        S_freq_dB = 20*log10(S_freq + 1e-6); 
        f_axis = linspace(-fs_plot/2, fs_plot/2, N_fft);
        
        plot(ax_freq, f_axis, S_freq_dB, 'Color', c);
        title(ax_freq, ['Espectro Bilateral (dB) - Señal ' t_str ' (Fs = ' num2str(fs_plot) ' Hz)']); 
        xlabel(ax_freq, 'Frecuencia (Hz)'); ylabel(ax_freq, 'Magnitud (dB)');
        xlim(ax_freq, [-fs_plot/2, fs_plot/2]); 
        ylim(ax_freq, [max(S_freq_dB)-80, max(S_freq_dB)+10]); 
        grid(ax_freq, 'on');
    end

    function mostrar_filtros(~, ~)
        if isempty(d.filtros_eq) || isempty(d.filtros_eq{1})
            errordlg('Primero aplique el ecualizador para generar los filtros.'); return;
        end
        
        fig_filt = figure('Name', 'Respuesta de Filtros EQ |H(f)|', 'NumberTitle', 'off', ...
                          'Units', 'normalized', 'Position', [0.2 0.2 0.6 0.4]);
        colores = lines(6);
        N_fft = 8192;
        f_axis = linspace(0, d.fs_new/2, N_fft/2);
        
        ax1 = subplot(1, 2, 1);
        hold(ax1, 'on'); grid(ax1, 'on');
        for k = 1:6
            if ~isempty(d.filtros_eq{k})
                H = abs(fft(d.filtros_eq{k}, N_fft));
                H_dB = 20*log10(H(1:N_fft/2) + 1e-6);
                plot(ax1, f_axis, H_dB, 'Color', colores(k,:), 'LineWidth', 1.5, 'DisplayName', band_names{k});
            end
        end
        title(ax1, 'Banco de Filtros Completo (N=4097)');
        xlabel(ax1, 'Frecuencia (Hz)'); ylabel(ax1, 'Magnitud (dB)');
        ylim(ax1, [-60, 5]); xlim(ax1, [0, 16000]);
        legend(ax1, 'Location', 'southwest'); hold(ax1, 'off');
        
        ax2 = subplot(1, 2, 2);
        hold(ax2, 'on'); grid(ax2, 'on');
        for k = 1:2 
            if ~isempty(d.filtros_eq{k})
                H = abs(fft(d.filtros_eq{k}, N_fft));
                H_dB = 20*log10(H(1:N_fft/2) + 1e-6);
                plot(ax2, f_axis, H_dB, 'Color', colores(k,:), 'LineWidth', 2, 'DisplayName', band_names{k});
            end
        end
        title(ax2, 'ZOOM: Análisis Banda Sub-Bass (16-60Hz)');
        xlabel(ax2, 'Frecuencia (Hz)'); ylabel(ax2, 'Magnitud (dB)');
        ylim(ax2, [-40, 5]); xlim(ax2, [0, 300]);
        legend(ax2, 'Location', 'southwest'); hold(ax2, 'off');
    end

    % --- SISTEMA DE REPRODUCCIÓN PROTEGIDO ---
    function play_audio0(~, ~)
        reproducir_audio(d.x, d.fs);
    end

    function play_audio1(~, ~)
        reproducir_audio(d.y_res, d.fs_new);
    end

    function play_audio2(~, ~)
        reproducir_audio(d.y_eq, d.fs_new);
    end

    function reproducir_audio(sig, fs)
        if isempty(sig), return; end
        
        stop_audio(); % Cortar el audio viejo antes de empezar el nuevo
        
        % Normalizar el audio para que los parlantes no saturen ni suenen feo
        m = max(abs(sig(:)));
        if m > 0.99, sig = 0.98 * sig / m; end
        
        % INTENTO DE REPRODUCCIÓN (Protección contra límites de Hardware)
        try
            d.player = audioplayer(sig, round(fs));
            play(d.player);
        catch ME
            % Si la tarjeta de sonido rechaza la frecuencia, atajamos el error
            if contains(ME.message, 'Invalid sample rate') || contains(ME.message, 'Unanticipated host error')
                msj = sprintf('Tu tarjeta de sonido física no soporta reproducir audio a %d Hz.\n\nLa matemática, el procesamiento y las gráficas están correctas, pero el hardware no puede vibrar a esta tasa de muestreo.', round(fs));
                msgbox(msj, 'Límite de Hardware de Audio', 'warn');
            else
                errordlg(['Error de reproducción: ', ME.message], 'Error');
            end
        end
    end

    function stop_audio(~, ~)
        if ~isempty(d.player) && isplaying(d.player)
            stop(d.player);
        end
    end

    % --- FUNCIONES MATEMÁTICAS (DSP) ---

    function h_final = fir_hamming(wc_norm, N)
        if wc_norm >= 1, wc_norm = 0.99; end
        wc = wc_norm * pi;
        n = -(N-1)/2 : (N-1)/2;
        
        h_ideal = sin(wc * n) ./ (pi * n);
        h_ideal(n == 0) = wc / pi;
        
        w = 0.54 - 0.46 * cos(2 * pi * (0:N-1)' / (N-1));
        
        h = h_ideal(:) .* w;
        h_final = h / sum(h); 
    end

    function y_conv = convolucion_fft(x, h)
        L = length(x) + length(h) - 1;
        N_fft = 2^nextpow2(L); 
        X = fft(x, N_fft);
        H = fft(h, N_fft);
        Y = X .* H;
        y_tmp = real(ifft(Y, N_fft));
        
        alpha = (length(h)-1)/2;
        y_conv = y_tmp(alpha + 1 : alpha + length(x)); 
    end
end