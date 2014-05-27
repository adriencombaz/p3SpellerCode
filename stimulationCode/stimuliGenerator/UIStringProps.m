function [SymbolProps Delete] = UIStringProps(default)


%% INITIALIZATION

String          = default.String;    
HAlign          = default.HAlign;
VAlign          = default.VAlign;
FontSize        = default.FontSize;
Position        = default.Position;
DimmedColor     = default.DimmedColor;
IntenseColor     = default.IntenseColor;
FBColor         = default.FBColor;

Delete          = 0;

SymbolProps.String          = [];
SymbolProps.HAlign          = [];
SymbolProps.VAlign          = [];
SymbolProps.FontSize        = [];
SymbolProps.Position        = [];
SymbolProps.DimmedColor     = [];
SymbolProps.IntenseColor    = [];
SymbolProps.FBColor         = [];

switch HAlign
    case 'left',    HA = 1;
    case 'center',  HA = 2;
    case 'right',   HA = 3;
end

switch VAlign
    case 'top',         VA = 1;
    case 'cap',         VA = 2;
    case 'middle',      VA = 3;
    case 'baseline',	VA = 4;
    case 'bottom',      VA = 5;
end


%% LAYOUT THE GUI

% Main Figure
fh = figure( ...
    'Name', 'Edit Symbol', ...
    'NumberTitle', 'off', ...
    'Units', 'pixels', ...
    'Position', [745 400 280 460], ...
    'Menu', 'none', ...
    'Toolbar', 'none');

col = get(fh,'Color');

sthString = uicontrol(fh,'Style','checkbox',...
    'String','String',...
    'BackgroundColor',col,...
    'Value',0, ...
    'Position',[20 420 141 21], ...
    'Callback',@StringCheckBoxCallback);

ethString = uicontrol(fh,'Style','edit',...
    'String',String,...
    'Position',[180 420 41 21],...
    'Enable','off', ...
    'Callback',@StringCallback);

sthFontSize = uicontrol(fh,'Style','checkbox',...
    'String','Font Size [0 1]',...
    'BackgroundColor',col,...
    'Value',0, ...
    'Position',[20 380 141 21], ...
    'Callback',@FontSizeCheckBoxCallback);

ethFontSize = uicontrol(fh,'Style','edit',...
    'String',FontSize,...
    'Position',[180 380 41 21],...
    'Enable','off', ...
    'Callback',@FontSizeCallback);

sthHAlign = uicontrol(fh,'Style','checkbox',...
    'String','Horizontal Alignment',...
    'BackgroundColor',col,...
    'Value',0, ...
    'Position',[20 340 141 21], ...
    'Callback',@HalignCheckBoxCallback);


pmhHAlign = uicontrol(fh,'Style','popupmenu',...
    'String',{'left','center','right'},...
    'Value',HA,'Position',[180 340 61 21],...
    'Enable','off', ...
    'Callback',@HalignCallback);
            
sthVAlign = uicontrol(fh,'Style','checkbox',...
    'String','Vertical Alignment',...
    'BackgroundColor',col,...
    'Value',0, ...
    'Position',[20 300 141 21], ...
    'Callback',@ValignCheckBoxCallback);

pmhVAlign = uicontrol(fh,'Style','popupmenu',...
    'String',{'top','cap','middle','baseline','bottom'},...
    'Value',VA,'Position',[180 300 81 21],...
    'Enable','off', ...
    'Callback',@ValignCallback);

            
sthXpos = uicontrol(fh,'Style','checkbox',...
    'String','x-position [0 1]',...
    'BackgroundColor',col,...
    'Value',0, ...
    'Position',[20 260 141 21], ...
    'Callback',@PosCheckBoxCallback);

ethXpos = uicontrol(fh,'Style','edit',...
    'String',Position(1),...
    'Position',[180 260 41 21],...
    'Enable','off', ...
    'Callback',@xPosCallback);

sthYpos = uicontrol(fh,'Style','checkbox',...
    'String','y-position [0 1]',...
    'BackgroundColor',col,...
    'Value',0, ...
    'Position',[20 220 141 21], ...
    'Callback',@PosCheckBoxCallback);

ethYpos = uicontrol(fh,'Style','edit',...
    'String',Position(2),...
    'Position',[180 220 41 21],...
    'Enable','off', ...
    'Callback',@yPosCallback);

sthDimCol = uicontrol(fh,'Style','checkbox',...
    'String','Dimmed color',...
    'BackgroundColor',col,...
    'Value',0, ...
    'Position',[20 180 141 21], ...
    'Callback',@dimmedColCheckBoxCallback);

pbhDimCol = uicontrol(fh,'Style','pushbutton',...
    'BackgroundColor',DimmedColor,...
    'Position',[180 180 41 21],...
    'Enable','off', ...
    'Callback',@dimmedColCallback);

sthIntCol = uicontrol(fh,'Style','checkbox',...
    'String','Intense color',...
    'BackgroundColor',col,...
    'Value',0, ...
    'Position',[20 140 141 21], ...
    'Callback',@intenseColCheckBoxCallback);

pbhIntCol = uicontrol(fh,'Style','pushbutton',...
    'BackgroundColor',IntenseColor,...
    'Position',[180 140 41 21],...
    'Enable','off', ...
    'Callback',@intenseColCallback);

sthFBCol = uicontrol(fh,'Style','checkbox',...
    'String','Feedback color',...
    'BackgroundColor',col,...
    'Value',0, ...
    'Position',[20 100 141 21], ...
    'Callback',@feedbackColCheckBoxCallback);

pbhFBCol = uicontrol(fh,'Style','pushbutton',...
    'BackgroundColor',FBColor,...
    'Position',[180 100 41 21],...
    'Enable','off', ...
    'Callback',@feedbackColCallback);

pbhDelete = uicontrol(fh,'Style','pushbutton',...
    'String', 'Delete',...
    'Position',[20 20 71 41],...
    'Callback',@DeleteCallback);

pbhCancel = uicontrol(fh,'Style','pushbutton',...
    'String','Cancel',...
    'Position',[105 20 71 41],...
    'Callback',@CancelCallback);

pbhOK = uicontrol(fh,'Style','pushbutton',...
    'String','OK',...
    'Position',[190 20 71 41],...
    'Callback',@OKCallback);


uiwait(fh);


%% CALLBACKS

    %----------------------------------------------------------------------
    % Set String
    function StringCheckBoxCallback(hObject,eventdata)
        if (get(hObject,'Value') == get(hObject,'Max'))
            set(ethString,'Enable','on');
            SymbolProps.String = get(ethString,'string');
        else
            set(ethString,'Enable','off');
            SymbolProps.String = '';
        end
    end

    function StringCallback(hObject,eventdata)
        SymbolProps.String = get(hObject,'string');
    end


    %----------------------------------------------------------------------
    % Set Font Size
    function FontSizeCheckBoxCallback(hObject,eventdata)
        if (get(hObject,'Value') == get(hObject,'Max'))
            set(ethFontSize,'Enable','on');
            SymbolProps.FontSize = str2double(get(ethFontSize,'string'));
        else
            set(ethFontSize,'Enable','off');
            SymbolProps.FontSize = [];
        end
    end

    function FontSizeCallback(hObject,eventdata)
        SymbolProps.FontSize = str2double(get(hObject,'string'));
    end



    %----------------------------------------------------------------------
    % Set Horizontal Alignment
    function HalignCheckBoxCallback(hObject,eventdata)
        if (get(hObject,'Value') == get(hObject,'Max'))
            set(pmhHAlign,'Enable','on');
            val = get(pmhHAlign,'Value');
            str = get(pmhHAlign,'String');
            SymbolProps.HAlign = str{val};
        else
            set(pmhHAlign,'Enable','off');
            SymbolProps.HAlign = [];
        end
    end

    function HalignCallback(hObject,eventdata)
        val = get(hObject,'Value');
        str = get(hObject,'String');
        SymbolProps.HAlign = str{val};
    end



    %----------------------------------------------------------------------
    % Set Vertical Alignment
    function ValignCheckBoxCallback(hObject,eventdata)
        if (get(hObject,'Value') == get(hObject,'Max'))
            set(pmhVAlign,'Enable','on');
            val = get(pmhVAlign,'Value');
            str = get(pmhVAlign,'String');
            SymbolProps.VAlign = str{val};
        else
            set(pmhVAlign,'Enable','off');
            SymbolProps.VAlign = [];
        end
    end

    function ValignCallback(hObject,eventdata)
        val = get(hObject,'Value');
        str = get(hObject,'String');
        SymbolProps.VAlign = str{val};
    end



    %----------------------------------------------------------------------
    % Set x- and y-position Size
    function PosCheckBoxCallback(hObject,eventdata)
        if (get(hObject,'Value') == get(hObject,'Max'))
            set(ethXpos,'Enable','on');
            set(ethYpos,'Enable','on');
            set(sthHAlign,'Value',1);
            set(sthVAlign,'Value',1);
            SymbolProps.Position(1) = str2double(get(ethXpos,'string'));
            SymbolProps.Position(2) = str2double(get(ethYpos,'string'));
        else
            set(ethXpos,'Enable','off');
            set(ethYpos,'Enable','off');
            set(sthHAlign,'Value',0);
            set(sthVAlign,'Value',0);
            SymbolProps.Position = [];
        end
    end

    function xPosCallback(hObject,eventdata)
        SymbolProps.Position(1) = str2double(get(hObject,'string'));
    end

    function yPosCallback(hObject,eventdata)
        SymbolProps.Position(2) = str2double(get(hObject,'string'));
    end



    %----------------------------------------------------------------------
    % Set dimmed color
    function dimmedColCheckBoxCallback(hObject,eventdata)
        if (get(hObject,'Value') == get(hObject,'Max'))
            set(pbhDimCol,'Enable','on');
            SymbolProps.DimmedColor = (get(pbhDimCol,'BackgroundColor'));
        else
            set(pbhDimCol,'Enable','off');
            SymbolProps.DimmedColor = [];
        end
    end

    function dimmedColCallback(hObject,eventdata)
        SymbolProps.DimmedColor = uisetcolor;
        set(hObject,'BackgroundColor',SymbolProps.DimmedColor);
    end



    %----------------------------------------------------------------------
    % Set intense color
    function intenseColCheckBoxCallback(hObject,eventdata)
        if (get(hObject,'Value') == get(hObject,'Max'))
            set(pbhIntCol,'Enable','on');
            SymbolProps.IntenseColor = (get(pbhIntCol,'BackgroundColor'));
        else
            set(pbhIntCol,'Enable','off');
            SymbolProps.IntenseColor = [];
        end
    end


    function intenseColCallback(hObject,eventdata)
        SymbolProps.IntenseColor = uisetcolor;
        set(hObject,'BackgroundColor',SymbolProps.IntenseColor);
    end


    %----------------------------------------------------------------------
    % Set feedback color
    function feedbackColCheckBoxCallback(hObject,eventdata)
        if (get(hObject,'Value') == get(hObject,'Max'))
            set(pbhFBCol,'Enable','on');
            SymbolProps.FBColor = (get(pbhFBCol,'BackgroundColor'));
        else
            set(pbhFBCol,'Enable','off');
            SymbolProps.FBColor = [];
        end
    end


    function feedbackColCallback(hObject,eventdata)
        SymbolProps.FBColor = uisetcolor;
        set(hObject,'BackgroundColor',SymbolProps.FBColor);
    end


    %----------------------------------------------------------------------
    % Delete
    function DeleteCallback(hObject,eventdata)
        Delete      = 1;
        SymbolProps = [];
        uiresume;
        close(fh);
    end


    %----------------------------------------------------------------------
    % Cancel
    function CancelCallback(hObject,eventdata)
        SymbolProps = [];
        uiresume;
        close(fh);
    end


    %----------------------------------------------------------------------
    % Validate
    function OKCallback(hObject,eventdata)
        uiresume;
        close(fh);
    end





end