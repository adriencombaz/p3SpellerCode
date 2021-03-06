function color = selectImColor(cdata)

fh = figure( ...
    'Name', 'Pick up the transparency color', ...
    'NumberTitle', 'off', ...
    'Units', 'pixels', ...
    'Position',[500 400 size(cdata,2) size(cdata,1)], ...
    'Menu', 'none', ...
    'Toolbar', 'none');
% %     'Position',[480 300 960 600], ...

ax = axes( ...
    'Parent', fh, ...
    'units', 'normalized', ...
    'position', [0 0 1 1], ...
    'XLim',[0 1],'YLim',[0 1]);

im = image(cdata,'Parent',ax,'ButtonDownFcn', @return_color);

uiwait(fh)


    function return_color(hObject,eventdata)

        pos = get(gca,'CurrentPoint');
        color = double(cdata(round(pos(1,2)),round(pos(1,1)),:));%./255;
        uiresume;
        close(fh);

    end

end