function Group = UISetGroup(nrows,ncols,nb_gp)

%% INTIALIZATION
%==========================================================================

xPbSize     = 30;
yPbSize     = 20;
margin      = 10;
fName       = sprintf('Select the elements of each of the %d groups', nb_gp);
figSize     = [ncols*xPbSize+(ncols+3)*margin nrows*yPbSize+(nrows+3)*margin];
activeGroup = 1;

Group = cell(nb_gp,1);
for gp_i = 1:nb_gp
    Group{gp_i} = [];
end

%% LAYING OUT THE GUI
%==========================================================================

% Main figure
fh = figure( ...
    'Name', fName, ...
    'NumberTitle', 'off', ...
    'Units', 'pixels', ...
    'Position',[(1920-figSize(1))/2 (1200-figSize(2))/2 figSize(1) figSize(2)], ...
    'Menu', 'none', ...
    'Toolbar', 'none');

% Menu to select the active group
mh1 = uimenu(fh,'Label','Active Group');
for i_gp = 1:nb_gp
    
    checkVal = 'off';
    if i_gp == activeGroup, 
        checkVal = 'on'; 
    end
    
    eh1(i_gp) = uimenu(mh1, ...
        'Label', sprintf('Group %d',i_gp), ...
        'Checked',checkVal, ...
        'UserData', i_gp, ...
        'Callback', @ehCallback);

end

% Action menu (validate, cancel)
mh2 = uimenu(fh,'Label','Action');
eh2 = uimenu(mh2, ...
    'Label', 'Validate', ...
    'Callback', @ValidateCallback);
eh3 = uimenu(mh2, ...
    'Label', 'Cancel', ...
    'Callback', @CancelCallback);


% elements of the gui
for i = 1:nrows
    for j = 1:ncols
        
        left = 2*margin + (j-1)*(xPbSize+margin);
        bottom = 2*margin + (nrows-i)*(yPbSize+margin);
        
        pbh(i,j) = uicontrol(fh,'Style','pushbutton',...
            'BackgroundColor','w',...
            'Position',[left bottom xPbSize yPbSize],...
            'UserData',[i j],...
            'Callback',@pbhCallback);

        
    end
end

uiwait(fh)

%% CALLBACKS
%==========================================================================

    %----------------------------------------------------------------------
    % Validate the stimuli group selection
    function ValidateCallback(hObject,eventdata)
        
        % Check that no empty group is left
        for i_g = 1:nb_gp
            if isempty(Group{i_g})
                warndlg(sprintf('The group %d is empty!!',i_g),'!! Warning !!');
                return
            end
        end
        uiresume;
        close(fh);
    end

    %----------------------------------------------------------------------
    % Cancel the stimuli group selection
    function CancelCallback(hObject,eventdata)
        Group = {};
        uiresume;
        close(fh);
    end


    %----------------------------------------------------------------------
    % Select the active group
    function ehCallback(hObject,eventdata)
        
        % If the selected group is not already the active one
        if strcmp(get(hObject,'Checked'),'off')
            
            % Uncheck the previously active group and check the new one
            set(eh1(activeGroup),'Checked','off');
            set(hObject,'Checked','on');
            
            % Update the active group
            activeGroup = get(hObject, 'UserData');
            
            % Set all elements white
            prevElts = findobj('Parent',fh,'Style','pushbutton','BackgroundColor','k');
            set(prevElts,'BackgroundColor','w');
            
            % Set the element of the active group black
            if ~isempty(Group{activeGroup})
                for i_el = 1:size(Group{activeGroup},1)
                    
                    set(pbh(Group{activeGroup}(i_el,1),Group{activeGroup}(i_el,2)), ...
                        'BackgroundColor','k');
                    
                end
            end
            
        end
        
    end


    %----------------------------------------------------------------------
    % Add an element to the active group
    function pbhCallback(hObject,eventdata)
        
        pos = get(hObject, 'UserData');
        col = get(hObject, 'BackgroundColor');
        
        if isequal(col,[1 1 1]) % from white to black, add the element to the group
            Group{activeGroup} = [Group{activeGroup} ; pos];
            set(hObject, 'BackgroundColor','k');
        elseif isequal(col,[0 0 0]) % from black to white, delete the element from the group
            ind1 = find(Group{activeGroup}(:,1) == pos(1));
            ind2 = find(Group{activeGroup}(:,2) == pos(2));
            ind  = intersect(ind1,ind2);
            Group{activeGroup}(ind,:) = [];            
            set(hObject, 'BackgroundColor','w');
        end
        
        
        
    end


end