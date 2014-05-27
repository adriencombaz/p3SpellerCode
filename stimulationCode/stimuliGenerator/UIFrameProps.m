function [NewFrameProps Delete] = UIFrameProps(default)

%% INITIALIZATION
    
Position        = default.Position;
Curvature       = default.Curvature;
EdgeSize        = default.EdgeSize;
DimmedColor  	= default.DimmedColor;
IntenseColor    = default.IntenseColor;
DimmedBGColor   = default.DimmedBGColor;
IntenseBGColor  = default.IntenseBGColor;

Delete          = 0;

NewFrameProps.Position          = [];
NewFrameProps.Curvature         = [];
NewFrameProps.EdgeSize          = [];
NewFrameProps.DimmedColor       = [];
NewFrameProps.IntenseColor      = [];
NewFrameProps.DimmedBGColor     = [];
NewFrameProps.IntenseBGColor    = [];

        


%% LAYOUT THE GUI

% Main Figure
fh = figure( ...
    'Name', 'Frame Properties', ...
    'NumberTitle', 'off', ...
    'Units', 'pixels', ...
    'Position', [745 460 530 280], ...
    'Menu', 'none', ...
    'Toolbar', 'none');

col = get(fh,'Color');


sth1 = uicontrol(fh,'Style','checkbox',...
    'String','x-size [0 1]',...
    'BackgroundColor',col,...
    'Value',0, ...
    'Position',[20 220 121 21], ...
    'Callback',@sizeCheckBoxCallback);

eth1 = uicontrol(fh,'Style','edit',...
    'String',Position(3),...
    'enable','off',...
    'Position',[160 220 41 21],...
    'Callback',@xsizeCallback);

sth2 = uicontrol(fh,'Style','checkbox',...
    'String','y-size [0 1]',...
    'BackgroundColor',col,...
    'Value',0, ...
    'Position',[20 180 121 21],...
    'Callback',@sizeCheckBoxCallback);

eth2 = uicontrol(fh,'Style','edit',...
    'String',Position(4),...
    'enable','off',...
    'Position',[160 180 41 21],...
    'Callback',@ysizeCallback);

sth3 = uicontrol(fh,'Style','checkbox',...
    'String','x-curvature [0 1]',...
    'BackgroundColor',col,...
    'Value',0, ...
    'Position',[20 140 121 21],...
    'Callback',@curvCheckBoxCallback);

eth3 = uicontrol(fh,'Style','edit',...
    'String',Curvature(1),...
    'enable','off',...
    'Position',[160 140 41 21],...
    'Callback',@xcurvCallback);

sth4 = uicontrol(fh,'Style','checkbox',...
    'String','y-curvature [0 1]',...
    'BackgroundColor',col,...
    'Value',0, ...
    'Position',[20 100 121 21],...
    'Callback',@curvCheckBoxCallback);

eth4 = uicontrol(fh,'Style','edit',...
    'String',Curvature(2),...
    'enable','off',...
    'Position',[160 100 41 21],...
    'Callback',@ycurvCallback);

sth5 = uicontrol(fh,'Style','checkbox',...
    'String','Edge Size',...
    'BackgroundColor',col,...
    'Value',0, ...
    'Position',[20 60 121 21],...
    'Callback',@edgesizeCheckBoxCallback);

eth5 = uicontrol(fh,'Style','edit',...
    'String',EdgeSize,...
    'enable','off',...
    'Position',[160 60 41 21],...
    'Callback',@edgesizeCallback);


sth6 = uicontrol(fh,'Style','checkbox',...
    'String','Dimmed color :',...
    'Value',0, ...
    'BackgroundColor',col,...
    'Position',[260 220 181 21],...
    'Callback',@dimmedColCheckBoxCallback);

pbh1 = uicontrol(fh,'Style','pushbutton',...
    'BackgroundColor',DimmedColor,...
    'enable','off',...
    'Position',[450 220 41 21],...
    'Callback',@dimmedColCallback);

sth7 = uicontrol(fh,'Style','checkbox',...
    'String','Intense Color :',...
    'Value',0, ...
    'BackgroundColor',col,...
    'Position',[260 180 181 21],...
    'Callback',@intenseColCheckBoxCallback);

pbh2 = uicontrol(fh,'Style','pushbutton',...
    'BackgroundColor',IntenseColor,...
    'enable','off',...
    'Position',[450 180 41 21],...
    'Callback',@intenseColCallback);

sth8 = uicontrol(fh,'Style','checkbox',...
    'String','Dimmed Background Color :',...
    'Value',0, ...
    'BackgroundColor',col,...
    'Position',[260 140 181 21],...
    'Callback',@dimmedBGColCheckBoxCallback);

pbh3 = uicontrol(fh,'Style','pushbutton',...
    'enable','off',...
    'BackgroundColor',DimmedBGColor,...
    'Position',[450 140 41 21],...
    'Callback',@dimmedBGColCallback);

sth9 = uicontrol(fh,'Style','checkbox',...
    'Value',0, ...
    'String','Intense Background Color :',...
    'BackgroundColor',col,...
    'Position',[260 100 181 20],...
    'Callback',@intenseBGColCheckBoxCallback);

pbh4 = uicontrol(fh,'Style','pushbutton',...
    'enable','off',...
    'BackgroundColor',IntenseBGColor,...
    'Position',[450 100 41 21],...
    'Callback',@intenseBGColCallback);

pbh5 = uicontrol(fh,'Style','pushbutton',...
    'String','Delete',...
    'Position',[260 20 61 41],...
    'Callback',@deleteCallback);

pbh6 = uicontrol(fh,'Style','pushbutton',...
    'String','Cancel',...
    'Position',[345 20 61 41],...
    'Callback',@cancelCallback);

pbh7 = uicontrol(fh,'Style','pushbutton',...
    'String','OK',...
    'Position',[430 20 61 41],...
    'Callback',@okCallback);

uiwait(fh);


%% CALLBACKS

    %----------------------------------------------------------------------
    % Set x- and y-position
    function sizeCheckBoxCallback(hObject,eventdata)
        if (get(hObject,'Value') == get(hObject,'Max'))
            set(eth1,'Enable','on');
            set(eth2,'Enable','on');
            set(sth1,'Value',1);
            set(sth2,'Value',1);
            NewFrameProps.Position(3) = str2double(get(eth1,'string'));
            NewFrameProps.Position(1) = (1 - NewFrameProps.Position(3)) / 2;
            NewFrameProps.Position(4) = str2double(get(eth2,'string'));
            NewFrameProps.Position(2) = (1 - NewFrameProps.Position(4)) / 2;
        else
            set(eth1,'Enable','off');
            set(eth2,'Enable','off');
            set(sth1,'Value',0);
            set(sth2,'Value',0);
            SymbolProps.Position = [];
        end
    end

    function xsizeCallback(hObject,eventdata)
        NewFrameProps.Position(3) = str2double(get(hObject,'string'));
        NewFrameProps.Position(1) = (1 - NewFrameProps.Position(3)) / 2;
    end

    function ysizeCallback(hObject,eventdata)
        NewFrameProps.Position(4) = str2double(get(hObject,'string'));
        NewFrameProps.Position(2) = (1 - NewFrameProps.Position(4)) / 2;
    end

    %----------------------------------------------------------------------
    % Set x- and y-curvature
    function curvCheckBoxCallback(hObject,eventdata)
        if (get(hObject,'Value') == get(hObject,'Max'))
            set(eth3,'Enable','on');
            set(eth4,'Enable','on');
            set(sth3,'Value',1);
            set(sth4,'Value',1);
            NewFrameProps.Curvature(1) = str2double(get(hObject,'string'));
            NewFrameProps.Curvature(2) = str2double(get(hObject,'string'));
        else
            set(eth3,'Enable','off');
            set(eth4,'Enable','off');
            set(sth3,'Value',0);
            set(sth4,'Value',0);
            NewFrameProps.Curvature = [];
        end
    end

    function xcurvCallback(hObject,eventdata)
        NewFrameProps.Curvature(1) = str2double(get(hObject,'string'));
    end

    function ycurvCallback(hObject,eventdata)
        NewFrameProps.Curvature(2) = str2double(get(hObject,'string'));
    end


    %----------------------------------------------------------------------
    % Set the edge size
    function edgesizeCheckBoxCallback(hObject,eventdata)
        if (get(hObject,'Value') == get(hObject,'Max'))
            set(eth5,'Enable','on');
            NewFrameProps.EdgeSize = str2double(get(eth5,'string'));
        else
            set(eth5,'Enable','off');
            NewFrameProps.EdgeSize = [];
        end
    end

    function edgesizeCallback(hObject,eventdata)
        NewFrameProps.EdgeSize = str2double(get(hObject,'string'));
    end

    %----------------------------------------------------------------------
    % Set the dimmed frame color
    function dimmedColCheckBoxCallback(hObject,eventdata)
        if (get(hObject,'Value') == get(hObject,'Max'))
            set(pbh1,'Enable','on');
            NewFrameProps.DimmedColor = (get(pbh1,'BackgroundColor'));
        else
            set(pbh1,'Enable','off');
            NewFrameProps.DimmedColor = [];
        end
    end

    function dimmedColCallback(hObject,eventdata)
        NewFrameProps.DimmedColor = uisetcolor;
        set(hObject,'BackgroundColor',NewFrameProps.DimmedColor);
    end

    %----------------------------------------------------------------------
    % Set the intense frame color
    function intenseColCheckBoxCallback(hObject,eventdata)
        if (get(hObject,'Value') == get(hObject,'Max'))
            set(pbh2,'Enable','on');
            NewFrameProps.IntenseColor = (get(pbh2,'BackgroundColor'));
        else
            set(pbh2,'Enable','off');
            NewFrameProps.IntenseColor = [];
        end
    end

    function intenseColCallback(hObject,eventdata)
        NewFrameProps.IntenseColor = uisetcolor;
        set(hObject,'BackgroundColor',NewFrameProps.IntenseColor);
    end

    %----------------------------------------------------------------------
    % Set the dimmed frame backgroung color
    function dimmedBGColCheckBoxCallback(hObject,eventdata)
        if (get(hObject,'Value') == get(hObject,'Max'))
            set(pbh3,'Enable','on');
            NewFrameProps.DimmedBGColor = (get(pbh3,'BackgroundColor'));
        else
            set(pbh3,'Enable','off');
            NewFrameProps.DimmedBGColor = [];
        end
    end

    function dimmedBGColCallback(hObject,eventdata)
        NewFrameProps.DimmedBGColor = uisetcolor;
        set(hObject,'BackgroundColor',NewFrameProps.DimmedBGColor);
    end

    %----------------------------------------------------------------------
    % Set the intense frame backgroung color
    function intenseBGColCheckBoxCallback(hObject,eventdata)
        if (get(hObject,'Value') == get(hObject,'Max'))
            set(pbh4,'Enable','on');
            NewFrameProps.IntenseBGColor = (get(pbh4,'BackgroundColor'));
        else
            set(pbh4,'Enable','off');
            NewFrameProps.IntenseBGColor = [];
        end
    end

    function intenseBGColCallback(hObject,eventdata)
        NewFrameProps.IntenseBGColor = uisetcolor;
        set(hObject,'BackgroundColor',NewFrameProps.IntenseBGColor);
    end

    %----------------------------------------------------------------------
    % Delete
    function deleteCallback(hObject,eventdata)
        Delete          = 1;
        NewFrameProps   = [];
        uiresume;
        close(fh);
    end

    %----------------------------------------------------------------------
    % Cancel
    function cancelCallback(hObject,eventdata)
        NewFrameProps = [];
        uiresume;
        close(fh);
    end

    %----------------------------------------------------------------------
    % Validate
    function okCallback(hObject,eventdata)
        uiresume;
        close(fh);
    end



end