function p3_matrix_generator


%%                            INTIALIZATION
%==========================================================================

%--------------------------------------------------------------------------
% Init sessions directory
sessions_dir = [cd '\Sessions\'];
if ~exist(sessions_dir,'dir')
    mkdir(sessions_dir);
end


%--------------------------------------------------------------------------
% Get the number of rows and columns of the P300 matrix:
prompt              = {'Enter number of rows:', ...
                        'Enter number of columns:', ...
                        'Screen Width (pixels)', ...
                        'Screen Height (pixels)', ...
                        'Top Feedback String Height (pixels)'};
dlg_title           = 'Size Parameters';
num_lines           = 1;
%def_size            = {'6','6','1920','1200','120'};
def_size            = {'6','6','1920','1080','120'};
size_matrix         = inputdlg(prompt,dlg_title,num_lines,def_size);
sharedata.rows      = str2double(size_matrix{1});
sharedata.cols      = str2double(size_matrix{2});
sharedata.scr_cols  = str2double(size_matrix{3});
sharedata.scr_rows  = str2double(size_matrix{4});
sharedata.FB_str_hi = str2double(size_matrix{5});
sharedata.stim_rows = sharedata.scr_rows - sharedata.FB_str_hi;
sharedata.ax        = zeros(sharedata.rows,sharedata.cols);

%--------------------------------------------------------------------------
% default parameters

sharedata.DEFOPTS.alphabet = {'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O', ...
    'P','Q','R','S','T','U','V','W','X','Y','Z','0','1','2','3', ...
    '4', '5','6','7','8','9'};

% sharedata.DEFOPTS.frame.Visibility          = 'on';
sharedata.DEFOPTS.frame.Position            = [.1 .1 .8 .8]; % Frame position (Normalized with respect to axes)
sharedata.DEFOPTS.frame.Curvature           = [.6 .6];
sharedata.DEFOPTS.frame.EdgeSize            = 6;
sharedata.DEFOPTS.frame.DimmedColor         = 'w';
sharedata.DEFOPTS.frame.IntenseColor        = 'k';
sharedata.DEFOPTS.frame.DimmedBGColor       = 'k';
sharedata.DEFOPTS.frame.IntenseBGColor      = 'w';

sharedata.DEFOPTS.symbol.HAlign             = 'center';
sharedata.DEFOPTS.symbol.VAlign             = 'middle';
sharedata.DEFOPTS.symbol.Position           = [.5 .5];
sharedata.DEFOPTS.symbol.FontSize           = 0.8;     % Font Size (Normalized with respect to axes)
sharedata.DEFOPTS.symbol.String             = 'Str';
sharedata.DEFOPTS.symbol.DimmedColor        = 'w';
sharedata.DEFOPTS.symbol.IntenseColor       = 'k';
sharedata.DEFOPTS.symbol.FBColor            = sharedata.DEFOPTS.symbol.DimmedColor;

sharedata.DEFOPTS.image.PathDimmed          = '';
sharedata.DEFOPTS.image.PathIntense         = '';
sharedata.DEFOPTS.image.PathFB              = '';
sharedata.DEFOPTS.image.XData               = [0 1];
sharedata.DEFOPTS.image.YData               = [0 1];
sharedata.DEFOPTS.image.AlphaColorDim       = [0 0 0];
sharedata.DEFOPTS.image.AlphaColorInt       = [255 255 255];
sharedata.DEFOPTS.image.AlphaColorFB        = [0 0 0];
sharedata.DEFOPTS.view                      = 'dimmed'; % or 'intense'
% % sharedata.DEFOPTS.image.AlphaData           = [];

sharedata.BGColor       = [0 0 0]; 	% Background Color
% sharedata.frame       = 'on';
sharedata.Nstim         = 0;
sharedata.GroupsCoord   = {};
sharedata.StimStyle     = '';
sharedata.n_groups      = [];
sharedata.groups        = [];
sharedata.StopSymbol    = [];

%--------------------------------------------------------------------------
% Initialization: set parameters to default

for i_row = 1:sharedata.rows
    for i_col = 1:sharedata.cols
        sharedata.ax_content(i_row,i_col).view                    = sharedata.DEFOPTS.view;
        
        sharedata.ax_content(i_row,i_col).frame.Position          = sharedata.DEFOPTS.frame.Position; % Frame position (Normalized with respect to axes)
        sharedata.ax_content(i_row,i_col).frame.Curvature         = sharedata.DEFOPTS.frame.Curvature;
        sharedata.ax_content(i_row,i_col).frame.EdgeSize          = sharedata.DEFOPTS.frame.EdgeSize;
        sharedata.ax_content(i_row,i_col).frame.DimmedColor       = sharedata.DEFOPTS.frame.DimmedColor;
        sharedata.ax_content(i_row,i_col).frame.IntenseColor      = sharedata.DEFOPTS.frame.IntenseColor;
        sharedata.ax_content(i_row,i_col).frame.DimmedBGColor     = sharedata.DEFOPTS.frame.DimmedBGColor;
        sharedata.ax_content(i_row,i_col).frame.IntenseBGColor    = sharedata.DEFOPTS.frame.IntenseBGColor;
        
        sharedata.ax_content(i_row,i_col).symbol.Position       = sharedata.DEFOPTS.symbol.Position;
        sharedata.ax_content(i_row,i_col).symbol.FontSize       = sharedata.DEFOPTS.symbol.FontSize;
        sharedata.ax_content(i_row,i_col).symbol.String         = sharedata.DEFOPTS.alphabet{mod((i_row-1)*sharedata.cols+i_col-1,numel(sharedata.DEFOPTS.alphabet)) + 1};
        sharedata.ax_content(i_row,i_col).symbol.DimmedColor    = sharedata.DEFOPTS.symbol.DimmedColor;
        sharedata.ax_content(i_row,i_col).symbol.IntenseColor   = sharedata.DEFOPTS.symbol.IntenseColor;
        sharedata.ax_content(i_row,i_col).symbol.FBColor        = sharedata.DEFOPTS.symbol.FBColor;
        sharedata.ax_content(i_row,i_col).symbol.HAlign         = sharedata.DEFOPTS.symbol.HAlign;
        sharedata.ax_content(i_row,i_col).symbol.VAlign         = sharedata.DEFOPTS.symbol.VAlign;
        
        sharedata.ax_content(i_row,i_col).image                 = [];
    end
end

%%                  CONSTRUCT THE GUI COMPONENTS
%==========================================================================

%--------------------------------------------------------------------------
% Lay out the main figure
mfig = figure( ...
    'Name', 'P300 Stimuli Matrix Designer', ...
    'NumberTitle', 'off', ...
    'Units', 'pixels', ... % 'normalized', ...
    'Position', [0 0 sharedata.scr_cols sharedata.stim_rows], ... % [0 0 1 1], ...
    'Color', sharedata.BGColor, ...
    'Menu', 'none', ...
    'Toolbar', 'none');


%--------------------------------------------------------------------------
% Create the context menu (right click)
cmenu               = uicontextmenu('Parent',mfig);

% File Menu
MenuFile            = uimenu(cmenu,'Label','File');
MenuSaveSession     = uimenu(MenuFile,'Label','Save Session','Callback',@CallbackSaveSession);
MenuLoadSession     = uimenu(MenuFile,'Label','Load Session','Callback',@CallbackLoadSession);
MenuSaveTextures    = uimenu(MenuFile,'Label','Generate Symbols and Stimuli Textures','Callback',@CallbackSaveTextures);

% View Menu
MenuView            = uimenu(cmenu,'Label','View');
MenuViewAllDimmed   = uimenu(MenuView,'Label','All Dimmed','Checked', 'on','Callback',@CallbackViewAllDimmed);
MenuViewAllIntense  = uimenu(MenuView,'Label','All Intense','Checked', 'off','Callback',@CallbackViewAllIntense);
MenuViewAllFB       = uimenu(MenuView,'Label','All Feedback','Checked', 'off','Callback',@CallbackViewAllFB);
MenuViewGroup       = uimenu(MenuView,'Label','View Group','Enable','off');

% Background Color Menu
MenuBGColor         = uimenu(cmenu,'Label','Set Background Color','Callback',@CallbackSetBGColor);

% String Edit Option Menu
MenuString          = uimenu(cmenu,'Label','Edit String');
MenuStringAll       = uimenu(MenuString,'Label','All','Callback',@CallbackEditAllSymbol);
MenuStringGroup     = uimenu(MenuString,'Label','Select Group','Callback',@CallbackEditGroupSymbol);
MenuStringSingle    = uimenu(MenuString,'Label','Current Position','Callback',@CallbackEditSingleSymbol);

% Frame Edit Option Menu
MenuFrame           = uimenu(cmenu,'Label','Edit Frame');
MenuFrameAll        = uimenu(MenuFrame,'Label','All','Callback',@CallbackEditAllFrame);
MenuFrameGroup      = uimenu(MenuFrame,'Label','Select Group','Callback',@CallbackEditGroupFrame);
MenuFrameSingle     = uimenu(MenuFrame,'Label','Current Position','Callback',@CallbackEditSingleFrame);

% Image Edit Option Menu
MenuImage           = uimenu(cmenu,'Label','Edit Image');
% MenuImageAll        = uimenu(MenuImage,'Label','All','Callback',@CallbackEditAllImage);
% MenuImageGroup      = uimenu(MenuImage,'Label','Select Group','Callback',@CallbackEditGroupImage);
MenuImageSingle     = uimenu(MenuImage,'Label','Current Position','Callback',@CallbackEditSingleImage);

% Single Axis Options Menu
MenuSymbol          = uimenu(cmenu,'Label','Single Element Options');
MenuMoveElement    	= uimenu(MenuSymbol,'Label','Move Element','Callback',@CallbackMoveElement);
MenuExchangeElement = uimenu(MenuSymbol,'Label','Exchange Element','Callback',@CallbackExchangeElement);
MenuCopyElement     = uimenu(MenuSymbol,'Label','Copy Element','Callback',@CallbackCopyElement);

MenuDelete      	= uimenu(MenuSymbol,'Label','Delete');
MenuDeleteSymbol	= uimenu(MenuDelete,'Label','Symbol','Callback',@CallbackDelSymbol);
MenuDeleteImage     = uimenu(MenuDelete,'Label','Image','Callback',@CallbackDelImage);
MenuDeleteFrame     = uimenu(MenuDelete,'Label','Frame','Callback',@CallbackDelFrame);
MenuDeleteAll       = uimenu(MenuDelete,'Label','All','Callback',@CallbackDelAll);

MenuLoadSymbol      = uimenu(MenuSymbol,'Label','Load Symbol','Callback',@CallbackLoadSymbol);
MenuSaveSymbol      = uimenu(MenuSymbol,'Label','Save Symbol','Callback',@CallbackSaveSymbol);


% Stimuli Group Options Menu
MenuCreateGroups	= uimenu(cmenu,'Label','Create Stimuli Groups');
MenuSingleSymbGp	= uimenu(MenuCreateGroups,'Label','Single Symbol Groups (1D)','Callback',@CallbackSingleSymbGp);
MenuRowColStimGp	= uimenu(MenuCreateGroups,'Label','Row Columns Groups (2D)','Callback',@CallbackRowColStimGp);
MenuCustomGp2d      = uimenu(MenuCreateGroups,'Label','2D Customized Groups','Callback',@CumstomStimGp2d);
MenuCustomGp        = uimenu(MenuCreateGroups,'Label','Customized Groups','Callback',@CumstomStimGp);

% Stop Symbol Option Menu
MenuStopSymbol          = uimenu(cmenu,'Label','Stop Symbol');
MenuShowStopSymbol      = uimenu(MenuStopSymbol,'Label','Show', 'Callback', @CallbackShowStoptSymbol);
MenuSelectStopSymbol    = uimenu(MenuStopSymbol,'Label','Select (Left Click on the desired symbol)', 'Callback', @CallbackSelectStoptSymbol);
MenuNoStopSymbol        = uimenu(MenuStopSymbol,'Label','No stop symbol', 'Callback', @CallbackNoStoptSymbol);


guidata(mfig,sharedata);
initialize;
updateview;



%%               INITIALIZATION OF THE P300 MATRIX FUNCTION
%==========================================================================
    function initialize
        
        sharedata = guidata(mfig);
        %--------------------------------------------------------------------------
        % Set the intial element properties and create the axes
        for i_row = 1:sharedata.rows
            for i_col = 1:sharedata.cols
                
                sharedata.ax_content(i_row,i_col).frameHandle	= [];
                sharedata.ax_content(i_row,i_col).symbolHandle	= [];
                sharedata.ax_content(i_row,i_col).imageHandle	= [];
                
                sharedata.ax(i_row,i_col) = axes( ...
                    'Parent', mfig, ...
                    'units', 'normalized', ...
                    'position', [(i_col-1)/sharedata.cols (sharedata.rows-i_row)/sharedata.rows 1/sharedata.cols 1/sharedata.rows], ...
                    'UIContextMenu', cmenu, ...
                    'visible', 'off', ...
                    'XGrid', 'on', 'YGrid', 'on', ...
                    'XLim',[0 1],'YLim',[0 1]);
                
            end
        end
        guidata(mfig,sharedata);

    end


%%                          DRAWING FUNCTION
%==========================================================================
    function updateview
        
        sharedata = guidata(mfig);

        set(mfig,'Color',sharedata.BGColor);
        
        for i_row = 1:sharedata.rows
            for i_col = 1:sharedata.cols
                
                %----------------------------------------------------------
                %                   Draw the image
                %----------------------------------------------------------
                if ~isempty(sharedata.ax_content(i_row,i_col).image)
                    % Select the color according to the desired view (dimmed or intense)
                    if strcmp(sharedata.ax_content(i_row,i_col).view,'dimmed')
                        path = sharedata.ax_content(i_row,i_col).image.PathDimmed;
                        alphaColor = sharedata.ax_content(i_row,i_col).image.AlphaColorDim;
                    elseif strcmp(sharedata.ax_content(i_row,i_col).view,'intense')
                        path = sharedata.ax_content(i_row,i_col).image.PathIntense;
                        alphaColor = sharedata.ax_content(i_row,i_col).image.AlphaColorInt;
                    elseif strcmp(sharedata.ax_content(i_row,i_col).view,'feedback')
                        path = sharedata.ax_content(i_row,i_col).image.PathFB;
                        alphaColor = sharedata.ax_content(i_row,i_col).image.AlphaColorFB;
                    end
                    
                    
                    if ~isempty(sharedata.ax_content(i_row,i_col).imageHandle)
                        
                        delete(sharedata.ax_content(i_row,i_col).imageHandle);
                        sharedata.ax_content(i_row,i_col).imageHandle = [];
                        
                    end
                    
                    % Read the image
                    cdata = imread(path);
                    set(sharedata.ax(i_row,i_col),'Units','pixels');
                    ax_size = get(sharedata.ax(i_row,i_col),'position');
                    set(sharedata.ax(i_row,i_col),'Units','normalized');
                    cdata = imresize(cdata,[ax_size(3) NaN]);
                    
                    % Set the transparency data
                    mask = false(size(cdata,1),size(cdata,2));
                    for dim  = 1:3
                        mask = mask | ( cdata(:,:,dim) ~= squeeze(alphaColor(dim)) );
                    end
                    sharedata.ax_content(i_row,i_col).image.AlphaData = mask;
                    
                        sharedata.ax_content(i_row,i_col).imageHandle = image( ...
                            cdata(end:-1:1,:,:), ...
                            'Parent',sharedata.ax(i_row,i_col), ...
                            'AlphaData',sharedata.ax_content(i_row,i_col).image.AlphaData(end:-1:1,:), ...
                            'UIContextMenu', cmenu);
                        set(sharedata.ax_content(i_row,i_col).imageHandle, ...
                            'Xdata',sharedata.ax_content(i_row,i_col).image.XData, ...
                            'Ydata',sharedata.ax_content(i_row,i_col).image.YData);
                        set(sharedata.ax(i_row,i_col),'YDir','normal');
                        set(sharedata.ax(i_row,i_col),'Xlim',[0 1],'Ylim',[0 1])
                        set(sharedata.ax(i_row,i_col),'visible','off');
                        
                    
                    % the image function deletes anyway everything that's on the selected axes
                    sharedata.ax_content(i_row,i_col).frameHandle   = [];
                    sharedata.ax_content(i_row,i_col).symbolHandle  = [];
                    
                % Delete the image (the properties data are empty but the image is still present and the handle still exist)
                elseif ~isempty(sharedata.ax_content(i_row,i_col).imageHandle)
                    
                    delete(sharedata.ax_content(i_row,i_col).imageHandle);
                    sharedata.ax_content(i_row,i_col).imageHandle = [];
                    
                end
    
                %----------------------------------------------------------
                %                   Set the frames
                %----------------------------------------------------------
%                 if strcmp(sharedata.frame,'on') && ~isempty(sharedata.ax_content(i_row,i_col).frame)
                if ~isempty(sharedata.ax_content(i_row,i_col).frame)
                    
                    % Select the color according to the desired view (dimmed or intense)
                    if strcmp(sharedata.ax_content(i_row,i_col).view,'dimmed')
                        FrameCol = sharedata.ax_content(i_row,i_col).frame.DimmedColor;
                        FrameBGCol = sharedata.ax_content(i_row,i_col).frame.DimmedBGColor;
                    elseif strcmp(sharedata.ax_content(i_row,i_col).view,'intense')
                        FrameCol = sharedata.ax_content(i_row,i_col).frame.IntenseColor;
                        FrameBGCol = sharedata.ax_content(i_row,i_col).frame.IntenseBGColor;
                    elseif strcmp(sharedata.ax_content(i_row,i_col).view,'feedback')
                        FrameCol = sharedata.BGColor;
                        FrameBGCol = sharedata.BGColor;
                    end
                    
                    
                    % If the frame already exists
                    if ~isempty(sharedata.ax_content(i_row,i_col).frameHandle)
                    
                        set(sharedata.ax_content(i_row,i_col).frameHandle, ...
                            'Position', sharedata.ax_content(i_row,i_col).frame.Position,...
                            'Curvature', sharedata.ax_content(i_row,i_col).frame.Curvature,...
                            'LineWidth', sharedata.ax_content(i_row,i_col).frame.EdgeSize, ...
                            'FaceColor', FrameBGCol, ...
                            'EdgeColor', FrameCol);

                    % If the frame does not exist
                    else
                        
                        sharedata.ax_content(i_row,i_col).frameHandle = rectangle( ...
                            'Parent', sharedata.ax(i_row,i_col), ...
                            'UIContextMenu', cmenu, ...
                            'Position', sharedata.ax_content(i_row,i_col).frame.Position,...
                            'Curvature', sharedata.ax_content(i_row,i_col).frame.Curvature,...
                            'LineWidth', sharedata.ax_content(i_row,i_col).frame.EdgeSize, ...
                            'FaceColor', FrameBGCol, ...
                            'EdgeColor', FrameCol);
                        
                    end
                    
                % Remove the frame    
                else
                    
                    if ~isempty(sharedata.ax_content(i_row,i_col).frameHandle)
                        delete(sharedata.ax_content(i_row,i_col).frameHandle);
                        sharedata.ax_content(i_row,i_col).frameHandle = [];
                        sharedata.ax_content(i_row,i_col).frame = [];
                    end

                    
                end
                
                
                %----------------------------------------------------------
                %                   Draw the symbols
                %----------------------------------------------------------
                if ~isempty(sharedata.ax_content(i_row,i_col).symbol)
                    
                    % Select the color according to the desired view (dimmed or intense)
                    if strcmp(sharedata.ax_content(i_row,i_col).view,'dimmed')
                        SymbolCol = sharedata.ax_content(i_row,i_col).symbol.DimmedColor;
                    elseif strcmp(sharedata.ax_content(i_row,i_col).view,'intense')
                        SymbolCol = sharedata.ax_content(i_row,i_col).symbol.IntenseColor;
                    elseif strcmp(sharedata.ax_content(i_row,i_col).view,'feedback')
                        SymbolCol = sharedata.ax_content(i_row,i_col).symbol.FBColor;
                    end
                    
                   
                    % If the symbol already exists
                    if ~isempty(sharedata.ax_content(i_row,i_col).symbolHandle)
                    
                        set(sharedata.ax_content(i_row,i_col).symbolHandle, ...
                            'HorizontalAlignment',sharedata.ax_content(i_row,i_col).symbol.HAlign, ...
                            'VerticalAlignment',sharedata.ax_content(i_row,i_col).symbol.VAlign, ...
                            'position', sharedata.ax_content(i_row,i_col).symbol.Position, ...
                            'fontsize',sharedata.ax_content(i_row,i_col).symbol.FontSize, ...
                            'string',sharedata.ax_content(i_row,i_col).symbol.String, ...
                            'Color',SymbolCol);

                    % If the symbol does not exist
                    else
                        
                        sharedata.ax_content(i_row,i_col).symbolHandle = text( ...
                            'Parent', sharedata.ax(i_row,i_col), ...
                            'UIContextMenu', cmenu, ...
                            'HorizontalAlignment',sharedata.ax_content(i_row,i_col).symbol.HAlign, ...
                            'VerticalAlignment',sharedata.ax_content(i_row,i_col).symbol.VAlign, ...
                            'units','normalized', ...
                            'position', sharedata.ax_content(i_row,i_col).symbol.Position, ...
                            'fontunit','normalized', ...
                            'fontsize',sharedata.ax_content(i_row,i_col).symbol.FontSize, ...
                            'string',sharedata.ax_content(i_row,i_col).symbol.String, ...
                            'Color',SymbolCol);
                        
                    end
                    
                % Delete the symbol (the properties data are empty but the symbol is still present and the handle still exist)
                elseif ~isempty(sharedata.ax_content(i_row,i_col).symbolHandle)
                    
                    delete(sharedata.ax_content(i_row,i_col).symbolHandle);
                    sharedata.ax_content(i_row,i_col).symbolHandle = [];
                    
                end

                
                %----------------------------------------------------------
                %               Set the proper children order
                %----------------------------------------------------------
                orderedChildren = [ findobj('Parent',sharedata.ax(i_row,i_col),'Type','image') ...
                    findobj('Parent',sharedata.ax(i_row,i_col),'Type','text') ...
                    findobj('Parent',sharedata.ax(i_row,i_col),'Type','rectangle') ];
                set(sharedata.ax(i_row,i_col),'Children',orderedChildren);

            end
        end
        
        guidata(mfig,sharedata);

    end




%%                     CALLBACKS PROGRAMMATION
%==========================================================================

%%                              FILE MENU
%--------------------------------------------------------------------------

    %----------------------------------------------------------------------
    % Save current session
    function CallbackSaveSession(hObject,eventdata)
        
        sharedata = guidata(mfig);
        uisave('sharedata','design');
        
    end

    %----------------------------------------------------------------------
    % Load previously saved session
    function CallbackLoadSession(hObject,eventdata)
        
        sharedata = guidata(mfig);

        [FileName,PathName,~] = uigetfile;
        newdata = load([PathName FileName]);
        
        delete(sharedata.ax);

        sharedata = newdata.sharedata;

        set(mfig,'Position', [0 0 sharedata.scr_cols sharedata.stim_rows], 'Color', sharedata.BGColor);

        guidata(mfig,sharedata);
        initialize;
        updateview;
        
    end


    %----------------------------------------------------------------------
    % Save stimuli parameters and symbols textures
    function CallbackSaveTextures(hObject,eventdata)
        
        sharedata = guidata(mfig);
        
        % Select/create the session directory
        session_dir = uigetdir([cd '\Sessions\']);
        
        pix_dir = [session_dir '\pix\'];
        if ~exist(pix_dir,'dir')
            mkdir(pix_dir);
        end
        
        bottom_cut = 5;  % pixels (get rid of thee white line at the bottom of the figure, 
                         % do the cut also for the symbols that are not on the last line, 
                         % so that they all have the same size)
        
                         

        % Get the textures of all stimuli
        %---------------------------------
        CallbackViewAllDimmed;        
        for i_gp = 1:sharedata.Nstim
            
            for i_s = 1:size(sharedata.GroupsCoord{i_gp},1)
                ind = sharedata.GroupsCoord{i_gp}(i_s,:);
                sharedata.ax_content(ind(1),ind(2)).view = 'intense';
            end
            guidata(mfig,sharedata);
            updateview;
            pause(0.1);
            cap = getframe(mfig);
            stimulus_textures{i_gp} = cap.cdata(1:end-bottom_cut,:,:);
            
            imwrite(stimulus_textures{i_gp}, sprintf('%sstimulus-%02g.png', pix_dir, i_gp));
            
            for i_s = 1:size(sharedata.GroupsCoord{i_gp},1)
                ind = sharedata.GroupsCoord{i_gp}(i_s,:);
                sharedata.ax_content(ind(1),ind(2)).view = 'dimmed';
            end
            guidata(mfig,sharedata);
            updateview;
            
        end
        
        % Get the texture with all stimuli dimmed
        %------------------------------------------
        pause(0.1);
        cap = getframe(mfig);
        stimulus_textures{sharedata.Nstim+1} = cap.cdata(1:end-bottom_cut,:,:);
        imwrite(stimulus_textures{sharedata.Nstim+1}, sprintf('%sstimulus-%02g.png', pix_dir, sharedata.Nstim+1));

        % Get feedback symbols textures
        %--------------------------------
        CallbackViewAllFB;
        cut_margin = 3; % pixels
        dimmed_symbols  = cell(sharedata.rows,sharedata.cols);
        dimmed_cropRect = cell(sharedata.rows,sharedata.cols);
        for ir = 1:sharedata.rows
            for ic = 1:sharedata.cols
                
                set(sharedata.ax(ir,ic),'units','pixels');
                pos = get(sharedata.ax(ir,ic),'position');
                wfh = figure('Units','pixels','Position',pos,'Color', sharedata.BGColor); % working figure handle
                wah = copyobj(sharedata.ax(ir,ic),wfh);
                set(wah,'position',[1 1 pos(3) pos(4)]);
                set(sharedata.ax(ir,ic),'units','normalized');
                
                delete(findobj('Parent',wah,'Type','rectangle'));
                cap = getframe(wfh);
                cap.cdata = cap.cdata(1:end-bottom_cut,:,:);
                
                hproj   = sum(sum(cap.cdata,3),1);
                diff    = hproj(2:end) - hproj(1:end-1);
                start   = find(diff,1) - cut_margin;
                finish  = length(diff) - find(diff(end:-1:1),1) + cut_margin;

                vproj   = sum(sum(cap.cdata,3),2);
                diff    = vproj(2:end) - vproj(1:end-1);
                vstart  = find(diff,1) - cut_margin;
                vfinish = length(diff) - find(diff(end:-1:1),1) + cut_margin;

%                 fprintf('size cdata: %d %d %d\n', size(cap.cdata,1), size(cap.cdata,2), size(cap.cdata,3));
%                 fprintf('cuts: %d-%d, %d-%d\n\n', vstart, vfinish, start, finish);
                
                dimmed_symbols{ir,ic} = cap.cdata(vstart:vfinish,start:finish,:);
                dimmed_cropRect{ir,ic} = [ ...
                                            pos(1) + start ...
                                            , sharedata.stim_rows - pos(2) - pos(4) + 1 + vstart ...
                                            , pos(1) + finish ...
                                            , sharedata.stim_rows - pos(2) - pos(4) + 1 + vfinish ...
                                            ];
%                 intense_symbols{ir,ic} = cap.cdata(:,start:finish,:);

                close(wfh);
                
%                 imwrite(intense_symbols{ir,ic}, sprintf('%sintense-symbol-%02g.png', pix_dir, (ir-1)*sharedata.cols + ic))
                imwrite(dimmed_symbols{ir,ic}, sprintf('%sdimmed-symbol-%02g.png', pix_dir, (ir-1)*sharedata.cols + ic))

            end
        end
        
        % Get the texture with all stimuli intense
        %------------------------------------------
        pause(0.1);
        CallbackViewAllIntense;
        cap = getframe(mfig);
        stimulus_textures{sharedata.Nstim+1} = cap.cdata(1:end-bottom_cut,:,:);
        imwrite(stimulus_textures{sharedata.Nstim+1}, sprintf('%sall-intense.png', pix_dir));

        % Get intense symbols textures
        %------------------------------------------
        intense_symbols = cell(sharedata.rows,sharedata.cols);
        intense_cropRect = cell(sharedata.rows,sharedata.cols);
        for ir = 1:sharedata.rows
            for ic = 1:sharedata.cols
                
                set(sharedata.ax(ir,ic),'units','pixels');
                pos = get(sharedata.ax(ir,ic),'position');
                wfh = figure('Units','pixels','Position',pos,'Color', sharedata.BGColor); % working figure handle
                wah = copyobj(sharedata.ax(ir,ic),wfh);
                set(wah,'position',[1 1 pos(3) pos(4)]);
                set(sharedata.ax(ir,ic),'units','normalized');
                
% %                 delete(findobj('Parent',wah,'Type','rectangle'));
                cap = getframe(wfh);
                cap.cdata = cap.cdata(1:end-bottom_cut,:,:);

                hproj = sum(sum(cap.cdata,3),1);
                diff = hproj(2:end) - hproj(1:end-1);
%                 start = find(diff,1); % - cut_margin;
%                 finish = length(diff) - find(diff(end:-1:1),1); % + cut_margin;
                start = find(diff,1) - cut_margin;
                finish = length(diff) - find(diff(end:-1:1),1) + cut_margin;

                vproj   = sum(sum(cap.cdata,3),2);
                diff    = vproj(2:end) - vproj(1:end-1);
%                 vstart  = find(diff,1); % - cut_margin;
%                 vfinish = length(diff) - find(diff(end:-1:1),1); % + cut_margin;
                vstart  = find(diff,1) - cut_margin;
                vfinish = length(diff) - find(diff(end:-1:1),1) + cut_margin;

                intense_symbols{ir,ic} = cap.cdata(vstart:vfinish,start:finish,:);
                intense_cropRect{ir,ic} = [ ...
                                            pos(1) + start ...
                                            , sharedata.stim_rows - pos(2) - pos(4) + 1 + vstart ...
                                            , pos(1) + finish ...
                                            , sharedata.stim_rows - pos(2) - pos(4) + 1 + vfinish ...
                                            ];
                
                close(wfh);
                
                imwrite(intense_symbols{ir,ic}, sprintf('%sintense-symbol-%02g.png', pix_dir, (ir-1)*sharedata.cols + ic))

            end
        end
        CallbackViewAllDimmed;
        
%         save([out_dir 'stimulus-textures.mat'], 'stimulus_textures');
%         save([out_dir 'symbol-images.mat'], 'dimmed_symbols', 'intense_symbols');
        stimuli.BGColor             = sharedata.BGColor;
        stimuli.rows                = sharedata.rows;
        stimuli.cols                = sharedata.cols;
        stimuli.scr_cols            = sharedata.scr_cols;
        stimuli.scr_rows            = sharedata.scr_rows;
        stimuli.string_height       = sharedata.FB_str_hi;
        stimuli.style               = sharedata.StimStyle;
        stimuli.textures            = stimulus_textures;
        stimuli.dimmed_symbols      = dimmed_symbols;
        stimuli.intense_symbols     = intense_symbols;
        stimuli.n_symbols           = sharedata.rows*sharedata.cols;
        stimuli.number              = sharedata.Nstim;
        stimuli.n_groups            = sharedata.n_groups;
        stimuli.groups              = sharedata.groups;
        stimuli.intense_cropRect    = intense_cropRect;
        stimuli.dimmed_cropRect     = dimmed_cropRect;
% %         stimuli.axSize              = [sharedata.scr_cols/sharedata.cols sharedata.stim_rows/sharedata.rows];

        % Create matrix masks
        for i_gp = 1:sharedata.n_groups
           
            for i_stim = 1:length(sharedata.groups{i_gp})
                % for ind_stim = sharedata.groups{i_gp} ???
                ind_stim = sharedata.groups{i_gp}(i_stim);
                mask = zeros(sharedata.rows,sharedata.cols);
                for i_coord = 1:size(sharedata.GroupsCoord{ind_stim},1)
                    mask(sharedata.GroupsCoord{ind_stim}(i_coord,1), ...
                        sharedata.GroupsCoord{ind_stim}(i_coord,2)) = 1;
                end
                
                stimuli.matrix_masks{ind_stim} = mask;
                
            end
            
        end
        
        % Create symbol_codes and i_matrix
        stimuli.i_matrix = zeros(sharedata.rows,sharedata.cols);
        stimuli.symbol_codes = zeros(sharedata.rows*sharedata.cols,1);
        for i = 1:sharedata.rows
            for j = 1:sharedata.cols
                stimuli.symbol_codes((i-1)*sharedata.cols+j) = (i-1)*sharedata.cols+j;
                stimuli.i_matrix(i,j) = (i-1)*sharedata.cols+j;
            end
        end
        
        if ~isempty(sharedata.StopSymbol)
            stimuli.stopsymbol_code = stimuli.i_matrix(sharedata.StopSymbol(1),sharedata.StopSymbol(2));
        end
        stimuli.stringSymbols.str   = cell( numel( sharedata.ax_content ), 1 );
        stimuli.stringSymbols.code  = nan( numel( sharedata.ax_content ), 1 );
        ind = 1;
        for i = 1:sharedata.rows
            for j = 1:sharedata.cols
                if ~isempty( sharedata.ax_content(i,j).symbol )
                    stimuli.stringSymbols.str{ind}  = sharedata.ax_content(i,j).symbol.String;
                    stimuli.stringSymbols.code(ind) = stimuli.i_matrix(i,j);
                    ind = ind + 1;
                end
            end
        end
        stimuli.stringSymbols.str(ind:end)  = [];
        stimuli.stringSymbols.code(ind:end) = [];
        
        save([session_dir '\stimuli_parameters.mat'], 'stimuli');

        
    end

%%                              VIEW MENU
%--------------------------------------------------------------------------

    %----------------------------------------------------------------------
    % View all symbols dimmed
    function CallbackViewAllDimmed(hObject,eventdata)
        
        sharedata = guidata(mfig);

        if strcmp(get(MenuViewAllDimmed,'Checked'),'off')

            for i_row = 1:sharedata.rows
                for i_col = 1:sharedata.cols
                    sharedata.ax_content(i_row,i_col).view = 'dimmed';
                end
            end
            
            set(MenuViewAllDimmed,'Checked','on');
            set(MenuViewAllIntense,'Checked','off');
            set(MenuViewAllFB,'Checked','off');
            
        end
        
        guidata(mfig,sharedata);
        updateview;
       
    end

    %----------------------------------------------------------------------
    % View all symbols intense
    function CallbackViewAllIntense(hObject,eventdata)
        
        sharedata = guidata(mfig);

        if strcmp(get(MenuViewAllIntense,'Checked'),'off')
            
            for i_row = 1:sharedata.rows
                for i_col = 1:sharedata.cols
                    sharedata.ax_content(i_row,i_col).view = 'intense';
                end
            end
            set(MenuViewAllIntense,'Checked','on');
            set(MenuViewAllDimmed,'Checked','off');
            set(MenuViewAllFB,'Checked','off');
            
        end
        
        guidata(mfig,sharedata);
        updateview;
        
    end

    %----------------------------------------------------------------------
    % View feedback symbols
    function CallbackViewAllFB(hObject,eventdata)
        
        sharedata = guidata(mfig);
        
        if strcmp(get(MenuViewAllFB,'Checked'),'off')
            
            for i_row = 1:sharedata.rows
                for i_col = 1:sharedata.cols
                    sharedata.ax_content(i_row,i_col).view = 'feedback';
                end
            end
            set(MenuViewAllFB,'Checked','on');
            set(MenuViewAllIntense,'Checked','off');
            set(MenuViewAllDimmed,'Checked','off');
            
        end
        
        guidata(mfig,sharedata);
        updateview;
        
    end
%%                          GLOBAL OPTIONS MENU
%--------------------------------------------------------------------------

    %----------------------------------------------------------------------
    % Set the background color
    function CallbackSetBGColor(hObject,eventdata)
        
        sharedata = guidata(mfig);
        
        newColor = uisetcolor;
        if numel(newColor) == 3
            sharedata.BGColor = newColor;
        end
        guidata(mfig,sharedata);
        updateview;
                
    end



%%                      STRING EDIT OPTION MENU
%--------------------------------------------------------------------------

    %----------------------------------------------------------------------
    % Callback for editing all the symbols of the matrix
    function CallbackEditAllSymbol(hObject,eventdata)
        
        sharedata = guidata(mfig);
        

        % Set default properties
        def = sharedata.DEFOPTS.symbol;
        for i_row = 1:sharedata.rows
            for i_col = 1:sharedata.cols
                if ~isempty(sharedata.ax_content(i_row,i_col).symbol)
                    def = sharedata.ax_content(i_row,i_col).symbol;
                    break
                end
            end
        end
        
        % Edit desired Properties
        [SymbolProps Delete] = UIStringProps(def);
        
        % Apply modified properties
        for i_row = 1:sharedata.rows
            for i_col = 1:sharedata.cols
                
                if Delete == 1
                    
                    % Delete all symbols
                    sharedata.ax_content(i_row,i_col).symbol = [];
                    delete(sharedata.ax_content(i_row,i_col).symbolHandle);
                    sharedata.ax_content(i_row,i_col).symbolHandle = [];
                    
                elseif ~isempty(SymbolProps) && ~isempty(sharedata.ax_content(i_row,i_col).symbol)
                    
                    % If some properties were edited, apply only on already existing strings
                    
                    if ~isempty(SymbolProps.String)
                        sharedata.ax_content(i_row,i_col).symbol.String = SymbolProps.String;
                    end
                    if ~isempty(SymbolProps.HAlign)
                        sharedata.ax_content(i_row,i_col).symbol.HAlign = SymbolProps.HAlign;
                    end
                    if ~isempty(SymbolProps.VAlign)
                        sharedata.ax_content(i_row,i_col).symbol.VAlign = SymbolProps.VAlign;
                    end
                    if ~isempty(SymbolProps.FontSize)
                        sharedata.ax_content(i_row,i_col).symbol.FontSize = SymbolProps.FontSize;
                    end
                    if ~isempty(SymbolProps.Position)
                        sharedata.ax_content(i_row,i_col).symbol.Position = SymbolProps.Position;
                    end
                    if ~isempty(SymbolProps.DimmedColor)
                        sharedata.ax_content(i_row,i_col).symbol.DimmedColor = SymbolProps.DimmedColor;
                    end
                    if ~isempty(SymbolProps.IntenseColor)
                        sharedata.ax_content(i_row,i_col).symbol.IntenseColor = SymbolProps.IntenseColor;
                    end
                    if ~isempty(SymbolProps.FBColor)
                        sharedata.ax_content(i_row,i_col).symbol.FBColor = SymbolProps.FBColor;
                    end
                    
                end
                
            end
        end
        
        guidata(mfig,sharedata);
        updateview;
        
    end

    %----------------------------------------------------------------------
    % Callback for editing chosen symbols of the matrix
    function CallbackEditGroupSymbol(hObject,eventdata)
        
        sharedata = guidata(mfig);
        
        ngps    = 1;
        Group   = UISetGroup(sharedata.rows,sharedata.cols,ngps);
        
        if isempty(Group)
            return
        end
        
        Group = Group{1};
        
        % Set default properties
        def = sharedata.DEFOPTS.symbol;
        for i_gr = 1:size(Group,1)
            if ~isempty(sharedata.ax_content(Group(i_gr,1),Group(i_gr,2)).symbol)
                def = sharedata.ax_content(Group(i_gr,1),Group(i_gr,2)).symbol;
                break
            end
        end
        
        % Edit desired Properties
        [SymbolProps Delete] = UIStringProps(def);
        
        % Apply modified properties
       for i_gr = 1:size(Group,1)
            
            if Delete == 1
                
                % Delete the symbols
                sharedata.ax_content(Group(i_gr,1),Group(i_gr,2)).symbol = [];
                delete(sharedata.ax_content(Group(i_gr,1),Group(i_gr,2)).symbolHandle);
                sharedata.ax_content(Group(i_gr,1),Group(i_gr,2)).symbolHandle = [];
               
            elseif ~isempty(SymbolProps) && ~isempty(sharedata.ax_content(Group(i_gr,1),Group(i_gr,2)).symbol)
                
                % If some properties were edited, apply only on already existing strings
                if ~isempty(SymbolProps.String)
                    sharedata.ax_content(Group(i_gr,1),Group(i_gr,2)).symbol.String = SymbolProps.String;
                end
                if ~isempty(SymbolProps.HAlign)
                    sharedata.ax_content(Group(i_gr,1),Group(i_gr,2)).symbol.HAlign = SymbolProps.HAlign;
                end
                if ~isempty(SymbolProps.VAlign)
                    sharedata.ax_content(Group(i_gr,1),Group(i_gr,2)).symbol.VAlign = SymbolProps.VAlign;
                end
                if ~isempty(SymbolProps.FontSize)
                    sharedata.ax_content(Group(i_gr,1),Group(i_gr,2)).symbol.FontSize = SymbolProps.FontSize;
                end
                if ~isempty(SymbolProps.Position)
                    sharedata.ax_content(Group(i_gr,1),Group(i_gr,2)).symbol.Position = SymbolProps.Position;
                end
                if ~isempty(SymbolProps.DimmedColor)
                    sharedata.ax_content(Group(i_gr,1),Group(i_gr,2)).symbol.DimmedColor = SymbolProps.DimmedColor;
                end
                if ~isempty(SymbolProps.IntenseColor)
                    sharedata.ax_content(Group(i_gr,1),Group(i_gr,2)).symbol.IntenseColor = SymbolProps.IntenseColor;
                end
                if ~isempty(SymbolProps.FBColor)
                    sharedata.ax_content(Group(i_gr,1),Group(i_gr,2)).symbol.FBColor = SymbolProps.FBColor;
                end
                
            end
            
        end
        
        guidata(mfig,sharedata);
        updateview;
        
    end


    %----------------------------------------------------------------------
    % Callback for editing a single symbol of the matrix
    function CallbackEditSingleSymbol(hObject,eventdata)
        
        sharedata = guidata(mfig);
 
        % Get current Position
        pos     = get(gca,'position');
        row     = round(sharedata.rows - pos(2)*sharedata.rows);
        col     = round(pos(1)*sharedata.cols + 1);

        
        % Set default properties
        if ~isempty(sharedata.ax_content(row,col).symbol)
            def = sharedata.ax_content(row,col).symbol;
        else
            def = sharedata.DEFOPTS.symbol;
        end
        
        % Edit desired properties
        [SymbolProps Delete] = UIStringProps(def);

        
        % Apply modified properties
        if Delete == 1
            
            sharedata.ax_content(row,col).symbol = [];
            delete(sharedata.ax_content(row,col).symbolHandle);
            sharedata.ax_content(row,col).symbolHandle = [];
            
        elseif ~isempty(SymbolProps)
            
                if ~isempty(SymbolProps.String)
                    sharedata.ax_content(row,col).symbol.String = SymbolProps.String;
                end
                if ~isempty(SymbolProps.HAlign)
                    sharedata.ax_content(row,col).symbol.HAlign = SymbolProps.HAlign;
                end
                if ~isempty(SymbolProps.VAlign)
                    sharedata.ax_content(row,col).symbol.VAlign = SymbolProps.VAlign;
                end
                if ~isempty(SymbolProps.FontSize)
                    sharedata.ax_content(row,col).symbol.FontSize = SymbolProps.FontSize;
                end
                if ~isempty(SymbolProps.Position)
                    sharedata.ax_content(row,col).symbol.Position = SymbolProps.Position;
                end
                if ~isempty(SymbolProps.DimmedColor)
                    sharedata.ax_content(row,col).symbol.DimmedColor = SymbolProps.DimmedColor;
                end
                if ~isempty(SymbolProps.IntenseColor)
                    sharedata.ax_content(row,col).symbol.IntenseColor = SymbolProps.IntenseColor;
                end
                if ~isempty(SymbolProps.FBColor)
                    sharedata.ax_content(row,col).symbol.FBColor = SymbolProps.FBColor;
                end
                
        end
        
        
        guidata(mfig,sharedata);
        updateview;
        
    end




%%                      FRAME EDIT OPTION MENU
%--------------------------------------------------------------------------

    %----------------------------------------------------------------------
    % Callback for editing all the frames of the matrix
    function CallbackEditAllFrame(hObject,eventdata)
        
        sharedata = guidata(mfig);
        

        % Set default properties
        def = sharedata.DEFOPTS.frame;
        for i_row = 1:sharedata.rows
            for i_col = 1:sharedata.cols
                if ~isempty(sharedata.ax_content(i_row,i_col).frame)
                    def = sharedata.ax_content(i_row,i_col).frame;
                    break
                end
            end
        end
        
        % Edit desired Properties
        [FrameProps Delete] = UIFrameProps(def);
        
        % Apply modified properties
        for i_row = 1:sharedata.rows
            for i_col = 1:sharedata.cols
                
                if Delete == 1
                    
                    % Delete all frames
                    sharedata.ax_content(i_row,i_col).frame = [];
                    delete(sharedata.ax_content(i_row,i_col).frameHandle);
                    sharedata.ax_content(i_row,i_col).frameHandle = [];
                    
                elseif ~isempty(FrameProps) && ~isempty(sharedata.ax_content(i_row,i_col).frame)
                    
                    % If some properties were edited, apply only on already existing frames
                    
                    if ~isempty(FrameProps.Position)
                        sharedata.ax_content(i_row,i_col).frame.Position = FrameProps.Position;
                    end
                    if ~isempty(FrameProps.Curvature)
                        sharedata.ax_content(i_row,i_col).frame.Curvature = FrameProps.Curvature;
                    end
                    if ~isempty(FrameProps.EdgeSize)
                        sharedata.ax_content(i_row,i_col).frame.EdgeSize = FrameProps.EdgeSize;
                    end
                    if ~isempty(FrameProps.DimmedColor)
                        sharedata.ax_content(i_row,i_col).frame.DimmedColor = FrameProps.DimmedColor;
                    end
                    if ~isempty(FrameProps.IntenseColor)
                        sharedata.ax_content(i_row,i_col).frame.IntenseColor = FrameProps.IntenseColor;
                    end
                    if ~isempty(FrameProps.DimmedBGColor)
                        sharedata.ax_content(i_row,i_col).frame.DimmedBGColor = FrameProps.DimmedBGColor;
                    end
                    if ~isempty(FrameProps.IntenseBGColor)
                        sharedata.ax_content(i_row,i_col).frame.IntenseBGColor = FrameProps.IntenseBGColor;
                    end
                    
                end
                
            end
        end
        
        guidata(mfig,sharedata);
        updateview;
        
    end

    %----------------------------------------------------------------------
    % Callback for editing all the frames of the matrix
    function CallbackEditGroupFrame(hObject,eventdata)
        
        sharedata = guidata(mfig);
        
        
        ngps    = 1;
        Group   = UISetGroup(sharedata.rows,sharedata.cols,ngps);
        
        if isempty(Group)
            return
        end
        
        Group = Group{1};

        % Set default properties
        def = sharedata.DEFOPTS.frame;
        for i_gr = 1:size(Group,1)
            if ~isempty(sharedata.ax_content(Group(i_gr,1),Group(i_gr,2)).frame)
                def = sharedata.ax_content(Group(i_gr,1),Group(i_gr,2)).frame;
                break
            end
        end
        
        % Edit desired Properties
        [FrameProps Delete] = UIFrameProps(def);
        
        % Apply modified properties
        for i_gr = 1:size(Group,1)
            
            if Delete == 1
                
                % Delete all frames
                sharedata.ax_content(Group(i_gr,1),Group(i_gr,2)).frame = [];
                delete(sharedata.ax_content(Group(i_gr,1),Group(i_gr,2)).frameHandle);
                sharedata.ax_content(Group(i_gr,1),Group(i_gr,2)).frameHandle = [];
                
            elseif ~isempty(FrameProps) && ~isempty(sharedata.ax_content(Group(i_gr,1),Group(i_gr,2)).frame)
                
                % If some properties were edited, apply only on already existing frames
                
                if ~isempty(FrameProps.Position)
                    sharedata.ax_content(Group(i_gr,1),Group(i_gr,2)).frame.Position = FrameProps.Position;
                end
                if ~isempty(FrameProps.Curvature)
                    sharedata.ax_content(Group(i_gr,1),Group(i_gr,2)).frame.Curvature = FrameProps.Curvature;
                end
                if ~isempty(FrameProps.EdgeSize)
                    sharedata.ax_content(Group(i_gr,1),Group(i_gr,2)).frame.EdgeSize = FrameProps.EdgeSize;
                end
                if ~isempty(FrameProps.DimmedColor)
                    sharedata.ax_content(Group(i_gr,1),Group(i_gr,2)).frame.DimmedColor = FrameProps.DimmedColor;
                end
                if ~isempty(FrameProps.IntenseColor)
                    sharedata.ax_content(Group(i_gr,1),Group(i_gr,2)).frame.IntenseColor = FrameProps.IntenseColor;
                end
                if ~isempty(FrameProps.DimmedBGColor)
                    sharedata.ax_content(Group(i_gr,1),Group(i_gr,2)).frame.DimmedBGColor = FrameProps.DimmedBGColor;
                end
                if ~isempty(FrameProps.IntenseBGColor)
                    sharedata.ax_content(Group(i_gr,1),Group(i_gr,2)).frame.IntenseBGColor = FrameProps.IntenseBGColor;
                end
                
                
            end
        end
        
        guidata(mfig,sharedata);
        updateview;
        
    end

    %----------------------------------------------------------------------
    % Callback for editing a single frames of the matrix
    function CallbackEditSingleFrame(hObject,eventdata)
        
        sharedata = guidata(mfig);
 
        % Get current Position
        pos     = get(gca,'position');
        row     = round(sharedata.rows - pos(2)*sharedata.rows);
        col     = round(pos(1)*sharedata.cols + 1);

        
        % Set default properties
        def = sharedata.DEFOPTS.frame;
        if ~isempty(sharedata.ax_content(row,col).frame)
            def = sharedata.ax_content(row,col).frame;
        end
        
        % Edit desired Properties
        [FrameProps Delete] = UIFrameProps(def);
        
        % Apply modified properties
        
        if Delete == 1
            
            % Delete all frames
            sharedata.ax_content(row,col).frame = [];
            delete(sharedata.ax_content(row,col).frameHandle);
            sharedata.ax_content(row,col).frameHandle = [];
            
        elseif ~isempty(FrameProps) && ~isempty(sharedata.ax_content(row,col).frame)
            
            % If some properties were edited, apply only on already existing frames
            
            if ~isempty(FrameProps.Position)
                sharedata.ax_content(row,col).frame.Position = FrameProps.Position;
            end
            if ~isempty(FrameProps.Curvature)
                sharedata.ax_content(row,col).frame.Curvature = FrameProps.Curvature;
            end
            if ~isempty(FrameProps.EdgeSize)
                sharedata.ax_content(row,col).frame.EdgeSize = FrameProps.EdgeSize;
            end
            if ~isempty(FrameProps.DimmedColor)
                sharedata.ax_content(row,col).frame.DimmedColor = FrameProps.DimmedColor;
            end
            if ~isempty(FrameProps.IntenseColor)
                sharedata.ax_content(row,col).frame.IntenseColor = FrameProps.IntenseColor;
            end
            if ~isempty(FrameProps.DimmedBGColor)
                sharedata.ax_content(row,col).frame.DimmedBGColor = FrameProps.DimmedBGColor;
            end
            if ~isempty(FrameProps.IntenseBGColor)
                sharedata.ax_content(row,col).frame.IntenseBGColor = FrameProps.IntenseBGColor;
            end
            
            
        end
        
        guidata(mfig,sharedata);
        updateview;

    
    end


%%                          IMAGE EDIT OPTION MENU
%--------------------------------------------------------------------------

%----------------------------------------------------------------------
    % Edit a single image
    function CallbackEditSingleImage(hObject,eventdata)
        
        sharedata = guidata(mfig);

        pos     = get(gca,'position');
        row     = round(sharedata.rows - pos(2)*sharedata.rows);
        col     = round(pos(1)*sharedata.cols + 1);
        
        set(sharedata.ax(row,col),'Units','pixels');
        ax_size = get(sharedata.ax(row,col),'Position');
        ax_size(1:2) = [];
        set(sharedata.ax(row,col),'Units','normalized');

        sharedata.ax_content(row,col).image = UIImageProps(sharedata.ax_content(row,col).image,sharedata.DEFOPTS.image,ax_size);

        if isempty(sharedata.ax_content(row,col).image)
            delete(sharedata.ax_content(row,col).imageHandle);
            sharedata.ax_content(row,col).imageHandle = [];
        else
            sharedata.frame = 'on';
        end
                
        guidata(mfig,sharedata);
        updateview;
        
    end



%%                          SYMBOL OPTIONS MENU
%--------------------------------------------------------------------------

    %----------------------------------------------------------------------
    % Move a symbol
    function CallbackMoveElement(hObject,eventdata)
        sharedata = guidata(mfig);
        pos     = get(gca,'position');
        row1    = round(sharedata.rows - pos(2)*sharedata.rows);
        col1    = round(pos(1)*sharedata.cols + 1);
        sel     = inputdlg({'destination row number:','destination column number:'},'Move Symbol',1);
        row2	= str2double(sel{1});
        col2	= str2double(sel{2});
        
        sharedata.ax_content(row2,col2).symbol	= sharedata.ax_content(row1,col1).symbol;
        sharedata.ax_content(row2,col2).image	= sharedata.ax_content(row1,col1).image;
        sharedata.ax_content(row2,col2).frame	= sharedata.ax_content(row1,col1).frame;

        % Delete what contains the origin axis
        if ~isempty(sharedata.ax_content(row1,col1).symbolHandle)
            delete(sharedata.ax_content(row1,col1).symbolHandle);
            sharedata.ax_content(row1,col1).symbolHandle = [];
        end
        sharedata.ax_content(row1,col1).symbol = [];
        
        if ~isempty(sharedata.ax_content(row1,col1).imageHandle)
            delete(sharedata.ax_content(row1,col1).imageHandle);
            sharedata.ax_content(row1,col1).imageHandle = [];
        end
        sharedata.ax_content(row1,col1).image = [];

        if ~isempty(sharedata.ax_content(row1,col1).frameHandle)
            delete(sharedata.ax_content(row1,col1).frameHandle);
            sharedata.ax_content(row1,col1).frameHandle = [];
        end
        sharedata.ax_content(row1,col1).frame = [];

        guidata(mfig,sharedata);

        updateview;
    end

    %----------------------------------------------------------------------
    % Exchange 2 symbol positions
    function CallbackExchangeElement(hObject,eventdata)
        sharedata = guidata(mfig);
        pos     = get(gca,'position');
        row1    = round(sharedata.rows - pos(2)*sharedata.rows);
        col1    = round(pos(1)*sharedata.cols + 1);
        sel	= inputdlg({'destination row number:','destination column number:'},'Move Symbol',1);
        row2	= str2double(sel{1});
        col2	= str2double(sel{2});


        temp = sharedata.ax_content(row2,col2);
        
        sharedata.ax_content(row2,col2).symbol         	= sharedata.ax_content(row1,col1).symbol;
        sharedata.ax_content(row2,col2).image           = sharedata.ax_content(row1,col1).image;
        sharedata.ax_content(row2,col2).frame           = sharedata.ax_content(row1,col1).frame;
        sharedata.ax_content(row1,col1).symbol         	= temp.symbol;
        sharedata.ax_content(row1,col1).image           = temp.image;
        sharedata.ax_content(row1,col1).frame           = temp.frame;
                
        guidata(mfig,sharedata);

        updateview;
    
    end

    %----------------------------------------------------------------------
    % copy a symbol to another position
    function CallbackCopyElement(hObject,eventdata)
        sharedata = guidata(mfig);
        pos     = get(gca,'position');
        row1    = round(sharedata.rows - pos(2)*sharedata.rows);
        col1    = round(pos(1)*sharedata.cols + 1);
        sel     = inputdlg({'destination row number:','destination column number:'},'Move Symbol',1);
        row2	= str2double(sel{1});
        col2	= str2double(sel{2});
        
        sharedata.ax_content(row2,col2).symbol         	= sharedata.ax_content(row1,col1).symbol;
        sharedata.ax_content(row2,col2).image           = sharedata.ax_content(row1,col1).image;
        sharedata.ax_content(row2,col2).frame           = sharedata.ax_content(row1,col1).frame;

        guidata(mfig,sharedata);

        updateview;
    end


    %----------------------------------------------------------------------
    % Delete a symbol
    function CallbackDelSymbol(hObject,eventdata)
        
        sharedata = guidata(mfig);
        
        pos     = get(gca,'position');
        row     = round(sharedata.rows - pos(2)*sharedata.rows);
        col     = round(pos(1)*sharedata.cols + 1);
        
        if ~isempty(sharedata.ax_content(row,col).symbolHandle)
            delete(sharedata.ax_content(row,col).symbolHandle);
            sharedata.ax_content(row,col).symbolHandle = [];
        end
        sharedata.ax_content(row,col).symbol = [];
        
        guidata(mfig,sharedata);
        updateview;
        
    end

    %----------------------------------------------------------------------
    % Delete an image
    function CallbackDelImage(hObject,eventdata)

        sharedata = guidata(mfig);

        pos     = get(gca,'position');
        row     = round(sharedata.rows - pos(2)*sharedata.rows);
        col     = round(pos(1)*sharedata.cols + 1);

        if ~isempty(sharedata.ax_content(row,col).imageHandle)
            delete(sharedata.ax_content(row,col).imageHandle);
            sharedata.ax_content(row,col).imageHandle = [];
        end
        sharedata.ax_content(row,col).image = [];

        guidata(mfig,sharedata);
        updateview;

    end

    %----------------------------------------------------------------------
    % Delete a frame
    function CallbackDelFrame(hObject,eventdata)

        sharedata = guidata(mfig);

        pos     = get(gca,'position');
        row     = round(sharedata.rows - pos(2)*sharedata.rows);
        col     = round(pos(1)*sharedata.cols + 1);

        if ~isempty(sharedata.ax_content(row,col).frameHandle)
            delete(sharedata.ax_content(row,col).frameHandle);
            sharedata.ax_content(row,col).frameHandle = [];
        end
        sharedata.ax_content(row,col).frame = [];

        guidata(mfig,sharedata);
        updateview;

    end

    %----------------------------------------------------------------------
    % Delete all element of an axis
    function CallbackDelAll(hObject,eventdata)

        sharedata = guidata(mfig);

        pos     = get(gca,'position');
        row     = round(sharedata.rows - pos(2)*sharedata.rows);
        col     = round(pos(1)*sharedata.cols + 1);

        if ~isempty(sharedata.ax_content(row,col).imageHandle)
            delete(sharedata.ax_content(row,col).imageHandle);
            sharedata.ax_content(row,col).imageHandle = [];
        end
        sharedata.ax_content(row,col).image = [];

        if ~isempty(sharedata.ax_content(row,col).symbolHandle)
            delete(sharedata.ax_content(row,col).symbolHandle);
            sharedata.ax_content(row,col).symbolHandle = [];
        end
        sharedata.ax_content(row,col).symbol = [];

        if ~isempty(sharedata.ax_content(row,col).frameHandle)
            delete(sharedata.ax_content(row,col).frameHandle);
            sharedata.ax_content(row,col).frameHandle = [];
        end
        sharedata.ax_content(row,col).frame = [];

        guidata(mfig,sharedata);
        updateview;

    end


    %----------------------------------------------------------------------
    % Save the content of an axis
    function CallbackSaveSymbol(hObject,eventdata)
        
        sharedata = guidata(mfig);

        pos     = get(gca,'position');
        row     = round(sharedata.rows - pos(2)*sharedata.rows);
        col     = round(pos(1)*sharedata.cols + 1);

        axis_data = sharedata.ax_content(row,col);
        uisave('axis_data','symbol');
        
    end

    %----------------------------------------------------------------------
    % Load the content of an axis
    function CallbackLoadSymbol(hObject,eventdata)
        
        sharedata = guidata(mfig);

        pos     = get(gca,'position');
        row     = round(sharedata.rows - pos(2)*sharedata.rows);
        col     = round(pos(1)*sharedata.cols + 1);

        [FileName,PathName,~] = uigetfile;
        newdata = load([PathName FileName]);

        sharedata.ax_content(row,col).image     = newdata.axis_data.image;
        sharedata.ax_content(row,col).frame     = newdata.axis_data.frame;
        sharedata.ax_content(row,col).symbol    = newdata.axis_data.symbol;
        

        guidata(mfig,sharedata);
        updateview;
        
    end



%%                  STIMULI GROUP CREATION OPTIONS
%--------------------------------------------------------------------------    
    
    %----------------------------------------------------------------------
    % Generate single symbol stimuli groups    
    function CallbackSingleSymbGp(hObject,eventdata)

        sharedata = guidata(mfig);
        sharedata.GroupsCoord	= {};
        sharedata.Nstim         = 36;
        sharedata.StimStyle     = '1D';
        sharedata.n_groups      = 1;
        sharedata.groups        = cell(sharedata.n_groups,1);
        sharedata.groups{1}     = [];
        for i = 1:6
            for j = 1:6
                sharedata.GroupsCoord{(i-1)*6+j} = [i j];
                sharedata.groups{1} = [sharedata.groups{1} (i-1)*6+j];
            end
        end
        
        guidata(mfig,sharedata);
        
    end


    %----------------------------------------------------------------------
    % Generate orws/columns stimuli groups    
    function CallbackRowColStimGp(hObject,eventdata)
        
        sharedata = guidata(mfig);
        sharedata.GroupsCoord	= {};
        sharedata.Nstim         = 12;
        sharedata.StimStyle     = '2D';
        sharedata.n_groups      = 2;
        sharedata.groups        = cell(sharedata.n_groups,1);
        sharedata.groups{1}     = [];
        for i = 1:6
            sharedata.GroupsCoord{i} = [(1:6)' i*ones(6,1)];
            sharedata.groups{1} = [sharedata.groups{1} i];
        end
        sharedata.groups{2}     = [];
        for i = 1:6
            sharedata.GroupsCoord{6+i} = [i*ones(6,1) (1:6)'];
            sharedata.groups{2} = [sharedata.groups{2} 6+i];
        end
            
        guidata(mfig,sharedata);
        
    end

    %----------------------------------------------------------------------
    % Generate customized stimuli groups    
    function CumstomStimGp2d(hObject,eventdata)
        sharedata = guidata(mfig);

       Groups   = UISetGroup(sharedata.rows,sharedata.cols,12);
        
        if isempty(Groups)
            return
        end

        sharedata.GroupsCoord	= {};
        sharedata.Nstim         = 12;
        sharedata.StimStyle     = '2DS';
        sharedata.n_groups      = 2;
        sharedata.groups        = cell(sharedata.n_groups,1);
        for i = 1:6
            sharedata.groups{1} = [sharedata.groups{1} i];
        end
        sharedata.groups{2}     = [];
        for i = 1:6
            sharedata.groups{2} = [sharedata.groups{2} 6+i];
        end        
        sharedata.GroupsCoord    = Groups;
        
        guidata(mfig,sharedata);
        
    end

    %----------------------------------------------------------------------
    % Generate customized stimuli groups    
    function CumstomStimGp(hObject,eventdata)
        sharedata = guidata(mfig);

        ngps = str2double(inputdlg('Please enter the desired number of groups'));
        if isempty(ngps)
            return
        end
        
        Groups  = UISetGroup(sharedata.rows,sharedata.cols,ngps);
        
        if isempty(Groups)
            return
        end
        
        sharedata.Nstim   = ngps;
        sharedata.GroupsCoord    = Groups;
        guidata(mfig,sharedata);
        
    end

%%                      STOP SYMBOL OPTIONS
%--------------------------------------------------------------------------    

    %----------------------------------------------------------------------
    % Show the stop symbol
    function CallbackShowStoptSymbol(hObject,eventdata)
        sharedata = guidata(mfig);

        if ~isempty(sharedata.StopSymbol)
            sharedata.ax_content(sharedata.StopSymbol(1),sharedata.StopSymbol(2)).view = 'intense';
            guidata(mfig,sharedata);
            updateview;
            sharedata.ax_content(sharedata.StopSymbol(1),sharedata.StopSymbol(2)).view = 'dimmed';
        end
        
        pause(1);
        guidata(mfig,sharedata);
        updateview;
    
    end

    %----------------------------------------------------------------------
    % Select the stop symbol
    function CallbackSelectStoptSymbol(hObject,eventdata)
        sharedata = guidata(mfig);

        KP = 1;
        while KP == 1
            KP = waitforbuttonpress;
        end
        pos     = get(gca,'Position');
        row     = round(sharedata.rows - pos(2)*sharedata.rows);
        col     = round(pos(1)*sharedata.cols + 1);
        sharedata.ax_content(row,col).view = 'intense';
        guidata(mfig,sharedata);
        updateview;
        pause(0.5);
        sharedata.ax_content(row,col).view = 'dimmed';
        sharedata.StopSymbol = [row col];
        guidata(mfig,sharedata);
        updateview;

    end

    %----------------------------------------------------------------------
    % Delete the stop symbol
    function CallbackNoStoptSymbol(hObject,eventdata)
        sharedata = guidata(mfig);
        sharedata.StopSymbol = [];
        guidata(mfig,sharedata);
    end


end


