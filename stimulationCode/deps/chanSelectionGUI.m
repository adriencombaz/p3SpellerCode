function toShowNew = chanSelectionGUI(chanList, toShow)

%% Check input data
if ~iscellstr( chanList ) || sum(size( chanList )) ~= numel( chanList ) + 1, 
    error('chanSelectionGUI:chanList', 'list of channels must be a 1D cell of strings'); 
end
if ~islogical( toShow ) || sum(size( toShow )) ~= numel( toShow ) + 1, 
    error('chanSelectionGUI:toShow', 'variable toShow must be a 1D array containing 0s and 1s only'); 
end
if ~isequal( numel(toShow), numel(chanList) ), 
    error('chanSelectionGUI:toShow', 'variables toShow and chanList must be of the same size'); 
end

toShowNew = toShow;

%% Initialize parameters
pbList = {'none', 'all', 'cancel', 'ok'};
nPB = numel(pbList);
nCB = numel(toShow);

FS                  = 12; % font size
nMaxEltPerCol       = 22;
nCols               = ceil( (nCB+nPB) / nMaxEltPerCol );
if nCols == 1
    nLines = nCB+nPB;
else
    nLines = nMaxEltPerCol;
end
maxCharElt          = max( max(cellfun(@numel, chanList)), max(cellfun(@numel, pbList)) );
xEltSize            = (maxCharElt+2)*FS;
yEltSize            = 2*FS;
ySpaceBetweenElts   = FS;
xSpaceBetweenElts   = 2*FS;
rightMargin         = FS;
leftMargin          = FS;
topMargin           = FS;
bottomMargin        = FS;

scrUnit = get(0, 'units');
set(0, 'units', 'points');
scrSize = get(0, 'ScreenSize');
nScrCols = scrSize(3);
nScrRows = scrSize(4);
set(0, 'units', scrUnit);


%% Laying out the gui

% Lay out the main figure
figWidth = leftMargin + nCols*xEltSize + (nCols-1)*xSpaceBetweenElts + rightMargin;
fighHeight = bottomMargin + nLines*yEltSize + (nLines-1)*ySpaceBetweenElts + topMargin;
figStartX = (nScrCols - figWidth) / 2;
figStartY = (nScrRows - fighHeight) / 2;
mfig = figure( ...
    'Name', 'select channels to display', ...
    'NumberTitle', 'off', ...
    'MenuBar', 'none', ...
    'Toolbar', 'none', ...
    'Units', 'points', ... 
    'Position', [figStartX figStartY figWidth fighHeight] ...
    );


for iElt = 1:nCB+nPB
    
    iCol = ceil( iElt / nMaxEltPerCol );
    iLine = iElt - (iCol-1)*nMaxEltPerCol;
    
    eltPos = [ ...
        leftMargin + (iCol-1)*(xEltSize+xSpaceBetweenElts) ...
        fighHeight - topMargin - yEltSize - (iLine-1)*(yEltSize+ySpaceBetweenElts) ...
        xEltSize ...
        yEltSize ...
        ];
    
    if iElt <= nCB
        CB(iElt) = uicontrol( ...
            mfig, ...
            'Style', 'checkbox', ...
            'String', chanList{iElt}, ...
            'Value', toShowNew(iElt), ...
            'Units', 'points', ...
            'Position', eltPos, ...
            'callback', {@cbCallback, iElt} ...
            );
    else
        PB(iElt-nCB) = uicontrol( ...
            mfig, ...
            'Style', 'pushbutton', ...
            'String', pbList{iElt-nCB}, ...
            'Units', 'points', ...
            'Position', eltPos, ...
            'callback', @pbCallback ...
            );
    end
    
end

uiwait( mfig );

%% programming callbacks
function cbCallback(hObject, eventdata, iElt)
    
    if (get(hObject,'Value') == get(hObject,'Max'))
        toShowNew(iElt) = true;
    else
        toShowNew(iElt) = false;
    end
    
end

function pbCallback(hObject, eventdata)
    
    hStr = get(hObject, 'String');
    switch hStr
        case 'none'
            for i = 1:nCB
                set(CB(i), 'Value', 0);
                toShowNew(i) = false;
            end
        case 'all'
            for i = 1:nCB
                set(CB(i), 'Value', 1);
                toShowNew(i) = true;
            end
        case 'cancel'
            toShowNew = toShow;
            uiresume( mfig );
            close( mfig );            
        case 'ok'
            uiresume( mfig );
            close( mfig );                        
    end    
    
    
end

end