function NewImProps = UIImageProps(ImProps,default,ax_size)

if isempty(ImProps)
    
    PathDimmed      = default.PathDimmed;
    PathIntense     = default.PathIntense;
    PathFB          = default.PathFB;
    XData           = default.XData;
    YData           = default.YData;
    AlphaColorDim	= default.AlphaColorDim;
    AlphaColorInt	= default.AlphaColorInt;
    AlphaColorFB	= default.AlphaColorFB;
% %     AlphaData       = default.AlphaData;
    
    NewImProps      = default;
        
else
    
    PathDimmed      = ImProps.PathDimmed;
    PathIntense     = ImProps.PathIntense;
    PathFB          = ImProps.PathFB;
    XData           = ImProps.XData;
    YData           = ImProps.YData;
    AlphaColorDim	= ImProps.AlphaColorDim;
    AlphaColorInt	= ImProps.AlphaColorInt;
    AlphaColorFB	= ImProps.AlphaColorFB;
% %     AlphaData       = ImProps.AlphaData;
        
    NewImProps    	= ImProps;

    
end


xsize = abs(XData(2)-XData(1));
ysize = abs(YData(2)-YData(1));
xcenter = XData(1) + xsize/2;
ycenter = YData(1) + ysize/2;

%% LAYOUT THE GUI

% Main Figure
fh = figure( ...
    'Name', 'Edit Image', ...
    'NumberTitle', 'off', ...
    'Units', 'pixels', ...
    'Position', [550 495 820 210], ...
    'Menu', 'none', ...
    'Toolbar', 'none');

col = get(fh,'Color');


%--------------------------------------------------------------------------
% Dimmed Image Parameters

sthDimPath = uicontrol(fh,'Style','text',...
    'String','Dimmed Image Path',...
    'BackgroundColor',col,...
    'Position',[20 180 121 21]);

ethDimPath = uicontrol(fh,'Style','edit',...
    'String',PathDimmed,...
    'Position',[180 180 350 21]);

pbhDimPath = uicontrol(fh,'Style','pushbutton',...
    'String','...',...
    'Position',[540 180 41 21],...
    'Callback',@DimPathCallback);

sthAlphaDim = uicontrol(fh,'Style','text',...
    'String','Alpha Data Dimmed',...
    'BackgroundColor',col,...
    'Position',[600 180 131 21]);

pbhAlphaDim = uicontrol(fh,'Style','pushbutton',...
    'BackgroundColor',AlphaColorDim./255,...
    'Position',[750 180 51 21],...
    'Callback',@AlphaDataDimCallback);

%--------------------------------------------------------------------------
% Intense Image Parameters

sthIntPath = uicontrol(fh,'Style','text',...
    'String','Intense Image Path',...
    'BackgroundColor',col,...
    'Position',[20 140 121 21]);

ethIntPath = uicontrol(fh,'Style','edit',...
    'String',PathIntense,...
    'Position',[180 140 350 21]);

pbhIntPath = uicontrol(fh,'Style','pushbutton',...
    'String','...',...
    'Position',[540 140 41 21],...
    'Callback',@IntensePathCallback);

sthAlphaInt = uicontrol(fh,'Style','text',...
    'String','Alpha Data Intense',...
    'BackgroundColor',col,...
    'Position',[600 140 131 21]);

pbhAlphaInt = uicontrol(fh,'Style','pushbutton',...
    'BackgroundColor',AlphaColorInt./255,...
    'Position',[750 140 51 21],...
    'Callback',@AlphaDataIntCallback);

%--------------------------------------------------------------------------
% Feedback Image Parameters

sthFBPath = uicontrol(fh,'Style','text',...
    'String','Feedback Image Path',...
    'BackgroundColor',col,...
    'Position',[20 100 121 21]);

ethFBPath = uicontrol(fh,'Style','edit',...
    'String',PathFB,...
    'Position',[180 100 350 21]);

pbhFBPath = uicontrol(fh,'Style','pushbutton',...
    'String','...',...
    'Position',[540 100 41 21],...
    'Callback',@FBPathCallback);

sthAlphaFB = uicontrol(fh,'Style','text',...
    'String','Alpha Data Feedback',...
    'BackgroundColor',col,...
    'Position',[600 100 131 21]);

pbhAlphaFB = uicontrol(fh,'Style','pushbutton',...
    'BackgroundColor',AlphaColorFB./255,...
    'Position',[750 100 51 21],...
    'Callback',@AlphaDataFBCallback);

%--------------------------------------------------------------------------
% Position Paramters

sthXCenterP = uicontrol(fh,'Style','text',...
    'String','x center position [0 1]',...
    'BackgroundColor',col,...
    'Position',[20 60 141 21]);

ethXCenterP = uicontrol(fh,'Style','edit',...
    'String',xcenter,...
    'Position',[170 60 41 21],...
    'Callback',@XCenterCallback);

sthYCenterP = uicontrol(fh,'Style','text',...
    'String','y center position [0 1]',...
    'BackgroundColor',col,...
    'Position',[20 20 141 21]);

ethYCenterP = uicontrol(fh,'Style','edit',...
    'String',ycenter,...
    'Position',[170 20 41 21],...
    'Callback',@YCenterCallback);


%--------------------------------------------------------------------------
% Size Parameters

sthXSize = uicontrol(fh,'Style','text',...
    'String','x size [0 1]',...
    'BackgroundColor',col,...
    'Position',[230 60 71 21]);

ethXSize = uicontrol(fh,'Style','edit',...
    'String',xsize,...
    'Position',[320 60 41 21],...
    'Callback',@XSizeCallback);

sthYSize = uicontrol(fh,'Style','text',...
    'String','y size [0 1]',...
    'BackgroundColor',col,...
    'Position',[230 20 71 21]);

ethYSize = uicontrol(fh,'Style','edit',...
    'String',ysize,...
    'Position',[320 20 41 21],...
    'Callback',@YSizeCallback);

cbhKeepScale = uicontrol(fh,'Style','checkbox',...
    'String','Keep original images proportions',...
    'BackgroundColor',col,...
    'Value',0, ...
    'Position',[450 60 270 21], ...
    'Callback',@KeepPropCallback);

%--------------------------------------------------------------------------
% Ok, Cancel and Delete

pbhDelete = uicontrol(fh,'Style','pushbutton',...
    'String', 'Delete',...
    'Position',[440 20 71 21],...
    'Callback',@DeleteCallback);

pbhCancel = uicontrol(fh,'Style','pushbutton',...
    'String','Cancel',...
    'Position',[550 20 71 21],...
    'Callback',@CancelCallback);

pbhOK = uicontrol(fh,'Style','pushbutton',...
    'String','OK',...
    'Position',[660 20 71 21],...
    'Callback',@OKCallback);

uiwait(fh);

%% CALLBACKS
    
    %----------------------------------------------------------------------
    % Set the path for the dimmed image
    function DimPathCallback(hObject,eventdata)
        if ~isempty(get(ethDimPath,'string'))
            [pathstr, ~, ~] = fileparts(get(ethDimPath,'string'));
        else
            pathstr = cd;
        end

        [FileName,PathName,~] = uigetfile([pathstr '\*']);
        
        if FileName ~= 0
            set(ethDimPath,'string',[PathName FileName]);
            NewImProps.PathDimmed = [PathName FileName];
        end
    end

    %----------------------------------------------------------------------
    % Set the path for the intense image
    function IntensePathCallback(hObject,eventdata)
        if ~isempty(get(ethIntPath,'string'))
            [pathstr, ~, ~] = fileparts(get(ethIntPath,'string'));
        else
            pathstr = cd;
        end

        [FileName,PathName,~] = uigetfile([pathstr '\*']);
        
        if FileName ~= 0
            set(ethIntPath,'string',[PathName FileName]);
            NewImProps.PathIntense = [PathName FileName];
        end
    end

    %----------------------------------------------------------------------
    % Set the path for the feedback image
    function FBPathCallback(hObject,eventdata)
        if ~isempty(get(ethFBPath,'string'))
            [pathstr, ~, ~] = fileparts(get(ethFBPath,'string'));
        else
            pathstr = cd;
        end

        [FileName,PathName,~] = uigetfile([pathstr '\*']);
        
        if FileName ~= 0
            set(ethFBPath,'string',[PathName FileName]);
            NewImProps.PathFB = [PathName FileName];
        end
    end

    %----------------------------------------------------------------------
    % Set Alpha Color for the dimmed image
    function AlphaDataDimCallback(hObject,eventdata)
        cdata = imread(NewImProps.PathDimmed);
        NewImProps.AlphaColorDim = selectImColor(cdata);
        set(hObject,'BackgroundColor',NewImProps.AlphaColorDim./255);
    end

    %----------------------------------------------------------------------
    % Set Alpha Color for the intense image
    function AlphaDataIntCallback(hObject,eventdata)
        cdata = imread(NewImProps.PathIntense);
        NewImProps.AlphaColorInt = selectImColor(cdata);
        set(hObject,'BackgroundColor',NewImProps.AlphaColorInt./255);
    end

    %----------------------------------------------------------------------
    % Set Alpha Color for the feedback image
    function AlphaDataFBCallback(hObject,eventdata)
        cdata = imread(NewImProps.PathFB);
        NewImProps.AlphaColorFB = selectImColor(cdata);
        set(hObject,'BackgroundColor',NewImProps.AlphaColorFB./255);
    end

    %----------------------------------------------------------------------
    % x-center position of the image
    function XCenterCallback(hObject,eventdata)
        xcenter = str2double(get(hObject,'string'));
    end

    %----------------------------------------------------------------------
    % y-center position of the image
    function YCenterCallback(hObject,eventdata)
        ycenter = str2double(get(hObject,'string'));
    end

    %----------------------------------------------------------------------
    % x-size of the image
    function XSizeCallback(hObject,eventdata)
        xsize = str2double(get(hObject,'string'));
        
        if get(cbhKeepScale,'Value') == 1 && ~isempty(NewImProps.PathDimmed)
            
            xsize_pixels    = xsize * ax_size(1);            
            cdata           = imread(NewImProps.PathDimmed);
            ysize_pixels    = xsize_pixels * size(cdata,1) / size(cdata,2);
            ysize           = ysize_pixels/ax_size(2);
            
            set(ethYSize,'String',num2str(ysize));
            
        end
        
    end

    %----------------------------------------------------------------------
    % y-size of the image
    function YSizeCallback(hObject,eventdata)
        ysize = str2double(get(hObject,'string'));
        
        if get(cbhKeepScale,'Value') == 1 && ~isempty(NewImProps.PathDimmed)
            
            ysize_pixels    = ysize * ax_size(2);            
            cdata           = imread(NewImProps.PathDimmed);
            xsize_pixels    = ysize_pixels * size(cdata,2) / size(cdata,1);
            xsize           = xsize_pixels/ax_size(1);
            
            set(ethXSize,'String',num2str(xsize));
            
        end
    end

    %----------------------------------------------------------------------
    % Keep original proportions of the image
    function KeepPropCallback(hObject,eventdata)
        
        if get(hObject,'Value') == 1
            if  ~isempty(NewImProps.PathDimmed)
                
                cdata           = imread(NewImProps.PathDimmed);
                xsize_pixels    = xsize * ax_size(1);
                ysize_pixels    = xsize_pixels * size(cdata,1) / size(cdata,2);
                ysize           = ysize_pixels/ax_size(2);
                
                set(ethYSize,'String',num2str(ysize));
                
            end
        end
        
    end

    function DeleteCallback(hObject,eventdata)
        NewImProps = [];
        uiresume;
        close(fh);
    end

    function CancelCallback(hObject,eventdata)
        if ~isfield(ImProps,'PathDimmed')
            NewImProps = [];
        else
            NewImProps = ImProps;
        end
        uiresume;
        close(fh);
    end

    function OKCallback(hObject,eventdata)
        NewImProps.XData = [xcenter-xsize/2 xcenter+xsize/2];
        NewImProps.YData = [ycenter-ysize/2 ycenter+ysize/2];
        uiresume;
        close(fh);
    end


end