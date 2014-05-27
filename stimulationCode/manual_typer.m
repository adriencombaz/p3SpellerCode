function code = manual_typer(stimuli, typed_codes, screen_width, screen_height, button_width, button_height)

    if ~exist('typed_codes', 'var'), typed_codes = []; end
    if ~exist('screen_width', 'var')  || isempty(screen_width),  screen_width  = 1920; end
    if ~exist('screen_height', 'var') || isempty(screen_height), screen_height = 1200; end
    if ~exist('button_width', 'var')  || isempty(button_width),  button_width  = 100;  end
    if ~exist('button_height', 'var') || isempty(button_height), button_height = button_width; end

    %% =============================================================================================
    %                                   NESTED FUNCTIONS SECTION
    %===============================================================================================
    
    %-------------------------------------------------------------------
    function img = code2img(symbol_codes)
        img = [];        
        for s_i = 1:numel(symbol_codes),
            [sRow sCol] = find(stimuli.i_matrix == symbol_codes(s_i));
            symbol_img = stimuli.dimmed_symbols{sRow,sCol};
            symbol_img = imresize(symbol_img, [button_height NaN]);
            img = [img symbol_img]; %#ok<AGROW>
        end        
        if size(img, 2) > fig_width,
            img = imresize(img, [NaN fig_width]);
        end        
    end % of nested function code2img
    
    %-------------------------------------------------------------------
    function add_symbol(hObject,eventdata) %#ok<INUSD>
        n = get(hObject, 'UserData');
        switch n
            case matrix_cols*matrix_rows, % end of text
                code = [code n];
                close(manual_typer_fig);
                return
            otherwise
                code = [code n];
        end
        
        text_button_img = code2img(code);
        set(text_button, 'CData', text_button_img);
        
    end % of nested function add_symbol


    function backspace(hObject,eventdata) %#ok<INUSD>
        
        code = code(1:numel(code)-1);
        text_button_img = code2img(code);
        set(text_button, 'CData', text_button_img);
        
    end % of nested function backspace


    %% =============================================================================================
    %                                     MANUAL TYPER GUI
    %===============================================================================================
    
    % Load the stimuli parameters
    %------------------------------
    stimuli.BGColor = [0 0 0];
    
    % Initialize the GUI figure
    %---------------------------
    matrix_rows = size(stimuli.intense_symbols, 1);
    matrix_cols = size(stimuli.intense_symbols, 2);
    if isempty(typed_codes),
        fig_height = button_height*(matrix_rows + 1);
    else
        fig_height = button_height*(matrix_rows + 2);
    end
    fig_width  = button_width*matrix_cols;
    text_button_img = [];

    
    manual_typer_fig = figure( ...
        'Name', 'Please enter the text you wanted to braintype...', ...
        'NumberTitle', 'off', ...
        'Units', 'pixels', ...
        'Color', [0 0 0], ...
        'Position', [(screen_width-fig_width)/2 (screen_height-fig_height)/2 fig_width fig_height], ...
        'Toolbar', 'none', ...
        'Menu', 'none');

    
    code = [];
    for r = 1:matrix_rows,
        for c = 1:matrix_cols,
            img = stimuli.intense_symbols{r,c};
            if size(img,1) > size(img,2)
                diff = size(img,1) - size(img,2);
                left = floor(diff/2);
                right = diff - left;
                paddLeft    = repmat(reshape(stimuli.BGColor,1,1,3),size(img,1),left);
                paddRight   = repmat(reshape(stimuli.BGColor,1,1,3),size(img,1),right);
                img         = cat(2,paddLeft,img,paddRight);
            else
                diff = size(img,2) - size(img,1);
                top         = floor(diff/2);
                bottom      = diff - top;
                paddTop     = repmat(reshape(stimuli.BGColor,1,1,3),top,size(img,2));
                paddBottom  = repmat(reshape(stimuli.BGColor,1,1,3),bottom,size(img,2));
                img         = cat(1,paddTop,img,paddBottom);
            end
            uicontrol( ...
                'Style', 'pushbutton', ...
                'Units', 'pixels', ...
                'BackgroundColor', stimuli.BGColor, ...
                'Position', [(c-1)*button_width button_height*(matrix_rows-r) button_width button_height], ...
                'String','', ...
                'CData', img, ... imresize(stimuli.intense_symbols{r,c}, [button_width button_height]), ...
                'Callback', @add_symbol, ...
                'UserData', (r-1)*matrix_cols+c);
        end
    end
    
    text_button = uicontrol( ...
        'Style', 'pushbutton', ...
        'Units', 'pixels', ...
        'Position', [0 button_height*matrix_rows fig_width button_height], ...
        'BackgroundColor', stimuli.BGColor, ...
        'CData', [], ... 
        'String', '', ...
        'Callback', @add_symbol, ...
        'UserData', matrix_cols*matrix_rows);

    if ~isempty(typed_codes),
        uicontrol( ...
            'Style', 'pushbutton', ...
            'Units', 'pixels', ...
            'Position', [0 button_height*(matrix_rows+1) fig_width button_height], ...
            'BackgroundColor', stimuli.BGColor, ...
            'CData',  code2img(typed_codes) );
    end
    
    
    % Menu button for backspace
    menu_button_bakspace = uimenu( ...
            manual_typer_fig, ...
            'Label','Backspace', ...
            'Callback', @backspace); %#ok<NASGU>

    
    waitfor(manual_typer_fig);
    
end