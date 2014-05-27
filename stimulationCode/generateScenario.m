function sc1 = generateScenario( stimuli, lenghFeedbackStr )

sc1 = [];
sc1.description         = 'P300 speller';
sc1.desired.scr.nCols   = stimuli.scr_cols;
sc1.desired.scr.nRows   = stimuli.scr_rows;

%%                              TEXTURES
%==========================================================================
iTex = 1;

% P300 stimuli indices: 1 -> stimuli.number+1
for i = 1:stimuli.number+1
    sc1.textures(iTex).filename = sprintf('stimulus-%.2d.png', i);
    iTex = iTex + 1;
end

% Cue stimulus indices: stimuli.number+2
sc1.textures(iTex).filename = sprintf('target-crosshair-yellow2.png');
iTex = iTex + 1;

% instense symbols indices (for feedback symbol): 
sc1.textures(iTex).filename = sprintf('all-intense.png');
% % instense symbols indices (for feedback symbol): 
% %       stimuli.number+3 -> stimuli.number+2+stimuli.n_symbols
% for i = 1:stimuli.n_symbols
%     sc1.textures(iTex).filename = sprintf('intense-symbol-%.2d.png', i);
%     iTex = iTex + 1;
% end
% 
% % dimmed symbols indices (for feedback string): 
% %       stimuli.number+stimuli.n_symbols+3 -> stimuli.number+2*stimuli.n_symbols+2
% for i = 1:stimuli.n_symbols
%     sc1.textures(iTex).filename = sprintf('dimmed-symbol-%.2d.png', i);
%     iTex = iTex + 1;
% end
% sc1.textures(iTex).filename = 'black-pixel.png';

%%                              EVENTS
%==========================================================================
sc1.events(1).desc = 'start event';
sc1.events(1).id = 1;
sc1.events(2).desc = 'end event';
sc1.events(2).id = -1;

sc1.events(3).desc = 'Cue on';
sc1.events(3).id = 2;
sc1.events(4).desc = 'Cue off';
sc1.events(4).id = -2;

sc1.events(5).desc = 'P300 stim on';
sc1.events(5).id = 4;
sc1.events(6).desc = 'P300 stim off';
sc1.events(6).id = -4;

sc1.events(7).desc = 'Feedback on';
sc1.events(7).id = 8;
sc1.events(8).desc = 'Feedback off';
sc1.events(8).id = -8;

sc1.events(9).desc = 'Feedback string on';
sc1.events(9).id = 16;
sc1.events(10).desc = 'Feedback string off';
sc1.events(10).id = -16;

%%                          ADDITIONAL INFO
%==========================================================================
sc1.iStartEvent                      = find( cellfun( @(x) strcmp(x, 'start event'), {sc1.events(:).desc} ) );
sc1.iEndEvent                        = find( cellfun( @(x) strcmp(x, 'end event'), {sc1.events(:).desc} ) );
sc1.frameBasedEventIdAdjust          = 0;
sc1.issueFrameBasedEvents            = 1;
sc1.issueTimeBasedEvents             = 0;
sc1.correctStimulusAppearanceTime    = 1;
sc1.useBinaryIntensity               = 0;


%%                              STIMULI
%==========================================================================

iStim = 0;

% P300 stimuli
%--------------------------------------------------------------------------
iStim                                       = iStim + 1;
sc1.stimuli(iStim).description              = 'P300 stimulus';
sc1.stimuli(iStim).stateSequence            = 1;
sc1.stimuli(iStim).durationSequenceInSec    = Inf;
sc1.stimuli(iStim).desired.position         = [1 stimuli.string_height+1 stimuli.scr_cols stimuli.scr_rows];
iState                                      = 1;
sc1.stimuli(iStim).eventMatrix              = zeros(2*stimuli.number+1);

for iS = 1:stimuli.number
    sc1.stimuli(iStim).states(iState).views.iTexture  = iS;    % real
    sc1.stimuli(iStim).states(iState+1).views.iTexture  = iS;  % fake
    sc1.stimuli(iStim).eventMatrix(iState, 2:2:2*stimuli.number) = find( cellfun( @(x) strcmp(x, 'P300 stim off'), {sc1.events(:).desc} ) ); % from real to fake (reset binary marker)
    sc1.stimuli(iStim).eventMatrix(iState+1, 1:2:2*stimuli.number-1) = find( cellfun( @(x) strcmp(x, 'P300 stim on'), {sc1.events(:).desc} ) ); % from fake to real (set binary marker)
    iState = iState+2;
end

sc1.stimuli(iStim).states(iState).views.iTexture  = stimuli.number+1;
sc1.stimuli(iStim).eventMatrix(2*stimuli.number+1, 1:2:2*stimuli.number-1) = ...
    find( cellfun( @(x) strcmp(x, 'P300 stim on'), {sc1.events(:).desc} ) ); % from nothing to real (set binary marker)
sc1.stimuli(iStim).eventMatrix(1:2:2*stimuli.number-1, 2*stimuli.number+1) = ...
    find( cellfun( @(x) strcmp(x, 'P300 stim off'), {sc1.events(:).desc} ) ); % from real to nothing (reset binary marker)


% Cue stimulus
%--------------------------------------------------------------------------
iStim                                       = iStim + 1;
% axisWidth                                   = stimuli.scr_cols/stimuli.cols;
% axisHeight                                  = (stimuli.scr_rows-stimuli.string_height)/stimuli.rows;
% cueSize                                     = round( 0.8 * min( axisHeight, axisWidth ) );
% cueLeftMargin                               = (axisWidth - cueSize) / 2;
% cueTopMargin                                = (axisHeight - cueSize) / 2;
sc1.stimuli(iStim).description              = 'cue stimulus';
sc1.stimuli(iStim).stateSequence            = 1;
sc1.stimuli(iStim).durationSequenceInSec    = Inf;
sc1.stimuli(iStim).desired.position         = [0 0 0 0];

sc1.stimuli(iStim).states(1).position       = [0 0 0 0];
sc1.stimuli(iStim).states(1).views.iTexture = stimuli.number+2;
sc1.stimuli(iStim).states(1).frequency      = 2;
sc1.stimuli(iStim).states(2).position       = [0 0 0 0];
sc1.stimuli(iStim).states(2).views.iTexture = 0;
sc1.stimuli(iStim).states(2).frequency      = 0;
sc1.stimuli(iStim).eventMatrix              = zeros(2);
sc1.stimuli(iStim).eventMatrix(2, 1)        = find( cellfun( @(x) strcmp(x, 'Cue on'), {sc1.events(:).desc} ) );
sc1.stimuli(iStim).eventMatrix(1, 2)        = find( cellfun( @(x) strcmp(x, 'Cue off'), {sc1.events(:).desc} ) );


% for iEl = 1:stimuli.n_symbols
%     [elRow, elCol] = find( stimuli.i_matrix == iEl );
%     sc1.stimuli(iStim).states(iEl).position = [ ...
%                                             round( 1 + cueLeftMargin + (elCol-1)*axisWidth )...                                        % left start
%                                             , round( 1 + stimuli.string_height + cueTopMargin + (elRow-1)*axisHeight )...                % top start
%                                             , round( 1 + cueSize + cueLeftMargin + (elCol-1)*axisWidth ) ...                            % left end
%                                             , round( 1 + cueSize + stimuli.string_height + cueTopMargin + (elRow-1)*axisHeight )...     % top end
%                                             ];
%     sc1.stimuli(iStim).states(iEl).views.iTexture = stimuli.number+2;
%     sc1.stimuli(iStim).states(iEl).frequency      = 2;
% end
% 
% sc1.stimuli(iStim).states(stimuli.n_symbols+1).position         = [0 0 0 0];
% sc1.stimuli(iStim).states(stimuli.n_symbols+1).views.iTexture   = 0;
% sc1.stimuli(iStim).states(stimuli.n_symbols+1).frequency        = 0;
% sc1.stimuli(iStim).eventMatrix                                  = zeros(stimuli.n_symbols+1);
% sc1.stimuli(iStim).eventMatrix(stimuli.n_symbols+1, 1:stimuli.n_symbols) = ...
%     find( cellfun( @(x) strcmp(x, 'Cue on'), {sc1.events(:).desc} ) );
% sc1.stimuli(iStim).eventMatrix(1:stimuli.n_symbols, stimuli.n_symbols+1) = ...
%     find( cellfun( @(x) strcmp(x, 'Cue off'), {sc1.events(:).desc} ) );


% Feedback symbol stimuli
%--------------------------------------------------------------------------
iStim                                       = iStim + 1;
sc1.stimuli(iStim).description              = 'Feedback symbol';
sc1.stimuli(iStim).stateSequence            = 1;
sc1.stimuli(iStim).durationSequenceInSec    = Inf;
sc1.stimuli(iStim).desired.position         = [0 0 0 0];
sc1.stimuli(iStim).states(1).position       = [0 0 0 0];
sc1.stimuli(iStim).states(1).views.iTexture = stimuli.number + 3;
sc1.stimuli(iStim).states(2).position       = [0 0 0 0];
sc1.stimuli(iStim).states(2).views.iTexture = 0;
sc1.stimuli(iStim).eventMatrix              = zeros(2);
sc1.stimuli(iStim).eventMatrix(2, 1)        = find( cellfun( @(x) strcmp(x, 'Feedback on'), {sc1.events(:).desc} ) );
sc1.stimuli(iStim).eventMatrix(1, 2)        = find( cellfun( @(x) strcmp(x, 'Feedback off'), {sc1.events(:).desc} ) );


% Feedback string stimuli
%--------------------------------------------------------------------------
for iS = 1:lenghFeedbackStr
    iStim                                       = iStim + 1;
    sc1.stimuli(iStim).description              = 'Feedback string';
    sc1.stimuli(iStim).stateSequence            = 1;
    sc1.stimuli(iStim).durationSequenceInSec    = Inf;
    sc1.stimuli(iStim).desired.position         = [0 0 0 0];%[1 stimuli.string_height-25-size(stimuli.dimmed_symbols{1,1}, 2) + 1 size(stimuli.dimmed_symbols{1,1}, 1) stimuli.string_height-25];
    sc1.stimuli(iStim).states(1).views.iTexture = stimuli.number + 1;%stimuli.number + stimuli.n_symbols + 3;   % on
    sc1.stimuli(iStim).states(1).position       = [0 0 0 0];%[1 stimuli.string_height-25-size(stimuli.dimmed_symbols{1,1}, 2) + 1 size(stimuli.dimmed_symbols{1,1}, 1) stimuli.string_height-25];
    sc1.stimuli(iStim).states(2).views.iTexture = stimuli.number + 1;%stimuli.number + stimuli.n_symbols + 3;   % fake off (still on, but sends marker)
    sc1.stimuli(iStim).states(2).position       = [0 0 0 0];%[1 stimuli.string_height-25-size(stimuli.dimmed_symbols{1,1}, 2) + 1 size(stimuli.dimmed_symbols{1,1}, 1) stimuli.string_height-25];
    sc1.stimuli(iStim).states(3).views.iTexture = 0;   % off
    sc1.stimuli(iStim).states(3).position       = [0 0 0 0];%[1 stimuli.string_height-25-size(stimuli.dimmed_symbols{1,1}, 2) + 1 size(stimuli.dimmed_symbols{1,1}, 1) stimuli.string_height-25];
    sc1.stimuli(iStim).eventMatrix              = zeros(3);
    sc1.stimuli(iStim).eventMatrix(3, 1)        = find( cellfun( @(x) strcmp(x, 'Feedback string on'), {sc1.events(:).desc} ) );
    sc1.stimuli(iStim).eventMatrix(1, 2)        = find( cellfun( @(x) strcmp(x, 'Feedback string off'), {sc1.events(:).desc} ) );
end



end