function p3spellerTrain

desiredScreenID = 2;
stimStyle       = 'BasicDesign\2D\';


%%                      INIT DIRECTORIES
%==========================================================================
hostName = getHostName();
switch hostName
    case 'kuleuven-24b13c'
        dataDir = 'd:\KULeuven\PhD\Work\P300basedBciSpeller\recordedData\';
        stimDir = 'd:\KULeuven\PhD\Work\P300basedBciSpeller\code\stimuliGenerator\Sessions\';
        addpath('d:\KULeuven\PhD\Work\P300basedBciSpeller\code\deps\');
    case 'neu-wrk-0158'
        dataDir = 'd:\Adrien\Work\P300basedBciSpeller\recordedData\';
        stimDir = 'd:\Adrien\Work\P300basedBciSpeller\code\stimuliGenerator\Sessions\';
        addpath('d:\Adrien\Work\P300basedBciSpeller\code\deps\');
    otherwise
        error('Unknown host');
end


%%                       EXPERIMENT PARAMETERS
%==========================================================================

% General experiment info
%--------------------------------------------------------------------------
subjectName             = 'subjectname';
nCues                   = 8;
nRepetitions            = 10;   
lenghFeedbackStr        = nCues;

% Timing information
%--------------------------------------------------------------------------
% stimDurationInSec       = [0.1 0.1];
% gapDurationInSec        = [0.1 0.15];
minStimDurInSec             = 0.1;
maxStimDurInSec             = 0.1;
minGapDurInSec              = 0.1;
maxGapDurInSec              = 0.15;
pauseBeforeCueInSec         = 2;
cueDurationInSec            = 2;
pauseAfterCueInSec          = 1;
pauseBeforeFeedbackInSec    = 1;
feedbackInSec               = 2;
pauseAfterFeedbackInSec     = 1;
pauseAfterstringUpdateInSec = 2;
fakeStopStringUpdateInSec   = 1;

% Basic info for the stimulation engine
%--------------------------------------------------------------------------
useBinaryIntensity              = true;
correctStimulusAppearanceTime   = true;
showProgressBar                 = false;

% General experiment info
%--------------------------------------------------------------------------
useLptPort                      = true;
useTcpIpSocket                  = false;
plotStenPerf                    = true;
saveData                        = true;
saveLog                         = true;
% saveUnfoldedScenario            = true;
saveStenPerf                    = true;
showLog                         = true;

% Parameters for feedback display
%--------------------------------------------------------------------------
ampFactor                       = 3;
TopStringMarginInPixels         = 25;
LeftStringMarginInPixels        = 100;

%%                       GET USER INPUT
%==========================================================================
parameterList = {
    'Subject name',                             subjectName,                'subjectName'
    'Number of targets',                        nCues,                      'nCues'
    'Numner of repetitions',                    nRepetitions,               'nRepetitions'
    'Minimum stimulus duration [sec]',          minStimDurInSec,            'minStimDurInSec' 
    'Maximum stimulus duration [sec]',          maxStimDurInSec,            'maxStimDurInSec' 
    'Minimum gap duration [sec]',               minGapDurInSec,             'minGapDurInSec' 
    'Maximum gap duration [sec]',               maxGapDurInSec,             'maxGapDurInSec' 
    'Save data',                                saveData,                   'saveData'
    'Save logs to text file',                   saveLog,                    'saveLog'
    'Save stimulation performance',             saveStenPerf,               'saveStenPerf'
    'Plot stimulation performance',             plotStenPerf,               'plotStenPerf'
    'Show logs in console output',              showLog,                    'showLog'
    };

prefGroupName = 'p3SpellerTrain';

pars = getItFromGUI( ...
    parameterList(:,1)', ...    list of parameter descriptions (cell array of strings)
    parameterList(:,2)', ...    list of default values for each parameter
    parameterList(:,3)', ...    list of variables to update
    prefGroupName, ...          name of preference group (to save parameter values for the next Round)
    sprintf( 'Input parameters of %s', prefGroupName ) ...
    );

if isempty( pars ),
    return
end

stimDurationInSec       = [minStimDurInSec maxStimDurInSec];
gapDurationInSec        = [minGapDurInSec maxGapDurInSec];
fakeStimDurInSec        = stimDurationInSec/2;
fakeStringUpdateInSec   = pauseAfterstringUpdateInSec - fakeStopStringUpdateInSec;
if fakeStimDurInSec >= 0.9*stimDurationInSec
    error('fakeStimDurInSec should be smaller than stimDurationInSec');
end
if fakeStopStringUpdateInSec >= 0.9*pauseAfterstringUpdateInSec
    error('fakeStopStringUpdateInSec should be smaller than pauseAfterstringUpdateInSec');
end

readStenPerf = plotStenPerf || saveStenPerf;
if readStenPerf
    renderTime  = cell(nCues, 2);
    flipTime    = cell(nCues, 2);
end

if useTcpIpSocket
    A       = cell(nCues, 2);
    count   = cell(nCues, 2);
    msg     = cell(nCues, 2);
end


%%                          INIT FILENAMES
%==========================================================================
currentTimeString = datestr( now, 31 );
currentTimeString(11:3:end) = '-';
currentDataDir = [dataDir currentTimeString(1:10) '-' strrep( subjectName, ' ', '-' ) '/'];
% if ~exist( currentDataDir, 'dir' ) && ( saveData || saveLog || saveUnfoldedScenario )
if ~exist( currentDataDir, 'dir' ) && ( saveData || saveLog  )
    mkdir( currentDataDir );
end
dataFilename = sprintf( '%s%s-training.mat', currentDataDir, currentTimeString );
% unScFilename = [dataFilename(1:end-4) '-unfolded-scenario.xml'];


%%            SIZES INFO FOR CORRECT DISPLAY OF SITMULI
%==========================================================================
stp = load( fullfile( stimDir, stimStyle, 'stimuli_parameters.mat' ) );
stimuli = stp.stimuli;
clear stp;
stringHeighInPixels     = stimuli.string_height-2*TopStringMarginInPixels;
stringGapInPixels       = round( stimuli.string_height / 16 );
leftStartStringInPixels = LeftStringMarginInPixels;
axisWidth               = stimuli.scr_cols/stimuli.cols;
axisHeight              = (stimuli.scr_rows-stimuli.string_height)/stimuli.rows;
cueSize                 = round( 0.8 * min( axisHeight, axisWidth ) );
cueLeftMargin           = (axisWidth - cueSize) / 2;
cueTopMargin            = (axisHeight - cueSize) / 2;


%%              SET UP THE LOGGER AND LOG EXPERIMENT INFO
%==========================================================================
logFilename  = fullfile( currentDataDir, [currentTimeString '-training-log.txt'] );

logThis( [], ...
    'logTimestamps', 'on', ...
    'logCallerInfo', 'on', ...
    'logFilename', logFilename, ...
    'logToFile', saveLog, ...
    'logToScreen', showLog ...
    );

logThis( '================================================================' );
logThis( '================================================================' );
logThis( '                     P300 SPELLER TRAINING' );
logThis( '================================================================' );
logThis( '================================================================' );
logThis( 'path to sten                          %s', which('sten') );
logThis( 'number of cues                        %g', nCues );
logThis( 'number of repetitions                 %g', nRepetitions );
logThis( 'min stimulus duration [sec]           %g', min(stimDurationInSec) );
logThis( 'max stimulus duration [sec]           %g', max(stimDurationInSec) );
logThis( 'min gap duration [sec]                %g', min(gapDurationInSec) );
logThis( 'max gap duration [sec]                %g', max(gapDurationInSec) );
logThis( 'Send markers through lpt port         %s', yesNo( useLptPort ) );
logThis( 'Read EEG data from TCP/IP socket      %s', yesNo( useTcpIpSocket ) );
logThis( 'Show logs in console output           %s', yesNo( showLog ) );
logThis( 'Show plots of sten performance        %s', yesNo( plotStenPerf ) );
logThis( 'Save logs to text file                %s', yesNo( saveLog ) );
logThis( 'Save data to mat file                 %s', yesNo( saveData ) );
logThis( 'Save sten perfromance data            %s', yesNo( saveData && saveStenPerf ) );
logThis( 'Use binary (on/off) intensity profile %s', yesNo( useBinaryIntensity ) );
% logThis( 'Save unfolded scenario                %s', yesNo( saveUnfoldedScenario ) );
logThis( 'Correct stimulus appearance time      %s', yesNo( correctStimulusAppearanceTime ) );
logThis( 'Show presentation progress bar        %s', yesNo( showProgressBar ) );



%%         INITALIZE THE STIMULATION ENGINES AND PARAMETERS
%==========================================================================

st1                 = sten( 'desiredScreenID' , desiredScreenID, 'allowStateLoop', false );
st1.sc              = generateScenario( stimuli, lenghFeedbackStr );
st1.sc.texturesDir  = fullfile( stimDir, stimStyle, 'pix' );

% define cue list and corresponding indices of target stimuli
cueList     = randperm( stimuli.n_symbols );
cueList     = cueList(1:nCues);
targetStim  = zeros(nCues, stimuli.n_groups);
for iCue = 1:nCues
    isStimTarget        = logical( cellfun( @(x) x(stimuli.i_matrix == cueList(iCue)), stimuli.matrix_masks ) );
    targetStim(iCue, :) = cellfun( @(x) x(isStimTarget(x)), stimuli.groups );
end


%%              GENERATE STATE AND DURATION SEQUENCES
%==========================================================================

% P300 and cue stimuli
%--------------------------------------------------------------------------
iP300Stimuli    = find( cellfun( @(x) strcmp(x, 'P300 stimulus'), {st1.sc.stimuli(:).description} ) );
iCueStimulus    = find( cellfun( @(x) strcmp(x, 'cue stimulus'), {st1.sc.stimuli(:).description} ) );
iP3off          = numel( st1.sc.stimuli(iP300Stimuli).states );
iCueOff         = 2;
iCueOn          = 1;

realP3StateSeqOnsets= zeros(nRepetitions*stimuli.number, nCues);
for iCue = 1:nCues
    realP3StateSeqOnsets(:, iCue) = generateFlashSequence( stimuli.number, nRepetitions, targetStim(iCue, :) );
end

expectedSeqLength   = 2*nRepetitions*stimuli.number + 3;
allocatedSeqLength  = round( 1.5 * expectedSeqLength);
p3StateSeq          = cell(nCues, 1);
p3DurationSeq       = cell(nCues, 1);
cueStateSeq         = cell(nCues, 1);
cueDurationSeq      = cell(nCues, 1);
indInSeq            = 1;

for iCue = 1:nCues
    
    p3StateSeq{iCue}          = nan(allocatedSeqLength, 1);
    p3DurationSeq{iCue}       = nan(allocatedSeqLength, 1);
    cueStateSeq{iCue}         = nan(allocatedSeqLength, 1);
    cueDurationSeq{iCue}      = nan(allocatedSeqLength, 1);
    
    % Pause before cue
    p3StateSeq{iCue}(indInSeq)     = iP3off;
    p3DurationSeq{iCue}(indInSeq)  = pauseBeforeCueInSec;
    cueStateSeq{iCue}(indInSeq)    = iCueOff;
    cueDurationSeq{iCue}(indInSeq) = pauseBeforeCueInSec;
    indInSeq = indInSeq + 1;
    
    % Cue presentataion
    p3StateSeq{iCue}(indInSeq)     = iP3off;
    p3DurationSeq{iCue}(indInSeq)  = cueDurationInSec;  
    cueStateSeq{iCue}(indInSeq)    = iCueOn;
    cueDurationSeq{iCue}(indInSeq) = cueDurationInSec;
    indInSeq = indInSeq + 1;
    
    % Pause after cue
    p3StateSeq{iCue}(indInSeq)     = iP3off;
    p3DurationSeq{iCue}(indInSeq)  = pauseAfterCueInSec;
    cueStateSeq{iCue}(indInSeq)    = iCueOff;
    cueDurationSeq{iCue}(indInSeq) = pauseAfterCueInSec;
    indInSeq = indInSeq + 1;
    
    % P300 flashing sequence
    temp = 2*realP3StateSeqOnsets(:, iCue)' - 1;
    if sum(gapDurationInSec) > 0
        stateSeq        = [temp ; iP3off*ones( 1, nRepetitions*stimuli.number )];
        stimDurationSeq = min( stimDurationInSec ) + ( max( stimDurationInSec ) - min( stimDurationInSec ) ) .* rand( 1, nRepetitions*stimuli.number );
        gapDurationSeq  = min( gapDurationInSec )  + ( max( gapDurationInSec )  - min( gapDurationInSec )  ) .* rand( 1, nRepetitions*stimuli.number );
        durationSeq     = [stimDurationSeq ; gapDurationSeq];
    else
        stateSeq        = [temp ; stateSeq+1];
        realStimDur     = min( stimDurationInSec ) + ( max( stimDurationInSec ) - min( stimDurationInSec ) ) .* rand( 1, nRepetitions*stimuli.number );
        fakeOnDurSeq    = fakeStimDurInSec .* ones( 1, nRepetitions*stimuli.number );
        fakeOffDurSeq   = realStimDur - fakeOnDurSeq;
        durationSeq     = [fakeOnDurSeq ; fakeOffDurSeq];
    end
    
    p3StateSeq{iCue}(indInSeq + (0:2*nRepetitions*stimuli.number-1))      = stateSeq(:);
    p3DurationSeq{iCue}(indInSeq + (0:2*nRepetitions*stimuli.number-1))   = durationSeq(:);
    cueStateSeq{iCue}(indInSeq)     = iCueOff;
    cueDurationSeq{iCue}(indInSeq)  = sum(durationSeq(:));

    p3StateSeq{iCue}(isnan( p3StateSeq{iCue} ))           = [];
    p3DurationSeq{iCue}(isnan( p3DurationSeq{iCue} ))     = [];
    cueStateSeq{iCue}(isnan( cueStateSeq{iCue} ))         = [];
    cueDurationSeq{iCue}(isnan( cueDurationSeq{iCue} ))   = [];

    [cueStateSeq{iCue}, cueDurationSeq{iCue}]  = shrinkSequence(cueStateSeq{iCue}, cueDurationSeq{iCue});
    [p3StateSeq{iCue}, p3DurationSeq{iCue}]    = shrinkSequence(p3StateSeq{iCue}, p3DurationSeq{iCue});
    
end

% Feedback symbol stimulus
%--------------------------------------------------------------------------
iFbSymbStimulus     = find( cellfun( @(x) strcmp(x, 'Feedback symbol'), {st1.sc.stimuli(:).description} ) );
fbSymbStateSeq      = [ 2 ; 1 ; 2 ];
fbSymbDurationSeq   = [ pauseBeforeFeedbackInSec ; feedbackInSec ; pauseAfterFeedbackInSec + fakeStringUpdateInSec + fakeStopStringUpdateInSec ];

% Feedback string stimulus
%--------------------------------------------------------------------------
iFbStringStimulus = find( cellfun( @(x) strcmp(x, 'Feedback string'), {st1.sc.stimuli(:).description} ) );

% Sequence for a absent stimulus
fbStringStateSeq0       = 3;
fbStringDurationSeq0    = sum( fbSymbDurationSeq );

% Sequence for a new appearing stimulus (symbol just detected)
fbStringStateSeq1       = [ 3 ; 1 ; 2 ];
fbStringDurationSeq1    = [ pauseBeforeFeedbackInSec + feedbackInSec + pauseAfterFeedbackInSec ; fakeStringUpdateInSec ; fakeStopStringUpdateInSec ];

% Sequence for an already present stimulus (previously detected symbols)
fbStringStateSeq2       = 2;
fbStringDurationSeq2    = sum( fbSymbDurationSeq );

% Initial sequence for all stimuli
for iSymb = 1:lenghFeedbackStr
    st1.sc.stimuli(iFbStringStimulus(iSymb)).stateSequence = fbStringStateSeq0;
end


%%              FINALIZE SCENARIO AND LOAD TEXTURES
%==========================================================================
st1.sc.useBinaryIntensity            = useBinaryIntensity;
st1.sc.correctStimulusAppearanceTime = correctStimulusAppearanceTime;
st1.sc.showProgressBar               = showProgressBar;
st1.sc.issueFrameBasedEvents         = true;
st1.sc.issueTimeBasedEvents          = false;
st1.sc.frameBasedEventIdAdjust       = 0;
st1.unfoldScenario();
st1.loadTextures();


%%                  INIT BIOSEMILABELCHANNEL object
%==========================================================================
nMaxEvents  = round( 2 * nCues *( 2 ...                             % start and stop events
                            + 2 ...                                 % cue on and cue off events
                            + 2 * nRepetitions * stimuli.number ... % flash on and flash off events
                            + 2 ...                                 % feedback symbol on and off events
                            + 2 ...                                 % feedback string on and off events
                            ) );
labChan     = biosemiLabelChannel( 'sizeListLabels', nMaxEvents , 'useTriggerCable', useLptPort);

%%                        INIT TCP/IP COMMUNICATION
%==========================================================================
if useTcpIpSocket
    nChannelsSendByTCP          = 41;
    nTCPsamplesPerChannel       = 4;
    nBytesPerSample             = 3;
    bytesInTCParray             = nBytesPerSample * nTCPsamplesPerChannel * nChannelsSendByTCP;
    maxFlashSeqDurationInSec    = ( max( stimDurationInSec ) + max( gapDurationInSec ) ) * nRepetitions * stimuli.number;
    biosemiSampleRate           = 512;
    bytesInFlashSeq             = maxFlashSeqDurationInSec * biosemiSampleRate * nBytesPerSample * nChannelsSendByTCP;
    bytesInBuffer               = 4 * bytesInTCParray * ceil( bytesInFlashSeq/bytesInTCParray );
    
    tcpSocket = tcpip( 'localhost', 778, 'InputBufferSize', bytesInBuffer );
    fopen( tcpSocket );
    fprintf( 'tcp socket just created: buffer size: %d bytes, %.1f TCP arrays; %1.f samples per channel, %.1f ms of data\n\n' ...,
        , bytesInBuffer ...
        , bytesInBuffer/bytesInTCParray ...
        , bytesInBuffer/(nBytesPerSample*nChannelsSendByTCP) ...
        , 1000*bytesInBuffer/(nBytesPerSample*nChannelsSendByTCP*biosemiSampleRate) ...
        );
end

%%                            INIT GRAPHICS
%==========================================================================
try
    st1.initGraph();
catch%#ok<*CTCH>
    Screen( 'CloseAll' );
    logThis( 'Failed to initialize PTB graphics. Exiting' )
    psychrethrow( psychlasterror );
    return
end
HideCursor();
st1.loadTexturesToPTB();
st1.setEventDispatcher( @labChan.markEvent );

logThis( 'Screen flip-interval:             %8.6f ms', st1.scr.flipInterval );
logThis( 'Screen frame-rate:                %8.5f Hz', st1.scr.FPS );
logThis( 'Screen size:                      %g x %g px', st1.scr.nCols, st1.scr.nRows );


%%                         EXPERIMENT
%==========================================================================
logThis( 'Presenting stimuli (experiment in progress)' );

for iCue = 1:nCues    
    
    %======================================================================
    %% Cue and P300 stimulation
    %======================================================================
    
    % Update state and duration sequences
    %----------------------------------------------------------------------
    
    % P300 stimulus
    st1.sc.stimuli(iP300Stimuli).stateSequence          = p3StateSeq{iCue};
    st1.sc.stimuli(iP300Stimuli).durationSequenceInSec  = p3DurationSeq{iCue};
    
    % Cue stimulus
    st1.sc.stimuli(iCueStimulus).stateSequence          = cueStateSeq{iCue};
    st1.sc.stimuli(iCueStimulus).durationSequenceInSec  = cueDurationSeq{iCue};
    [elRow, elCol]                                      = find( stimuli.i_matrix == cueList(iCue) );
    st1.sc.stimuli(iCueStimulus).states(1).position     = [ ...
                                                        round( 1 + cueLeftMargin + (elCol-1)*axisWidth )...                                        % left start
                                                        ; round( 1 + stimuli.string_height + cueTopMargin + (elRow-1)*axisHeight )...                % top start
                                                        ; round( 1 + cueSize + cueLeftMargin + (elCol-1)*axisWidth ) ...                            % left end
                                                        ; round( 1 + cueSize + stimuli.string_height + cueTopMargin + (elRow-1)*axisHeight )...     % top end
                                                        ];

    % Feedback symbol stimulus
    st1.sc.stimuli(iFbSymbStimulus).stateSequence        = 2;
    st1.sc.stimuli(iFbSymbStimulus).durationSequenceInSec= sum(cueDurationSeq{iCue});
    
    % Feedback string stimuli
    for iSymb = 1:lenghFeedbackStr
        st1.sc.stimuli(iFbStringStimulus(iSymb)).durationSequenceInSec = sum(cueDurationSeq{iCue});
    end
    
    % Get ready for stimulation
    %----------------------------------------------------------------------
    st1.sc.desired.stimulationDuration = sum(cueDurationSeq{iCue});
    st1.updateScenario();
    if iCue == 1
%         st1.preparePresentationOptimized();
        [flipTimeWarmup, renderTimeWarmup] = st1.preparePresentationOptimized();
    else
        st1.resetPresentation();
    end
    nExpectedTotalFramesToRender = ceil( sum(cueDurationSeq{iCue}) / st1.scr.flipInterval ) + 200; % add some extra frames, to avoid re-allocation
    st1.frameRenderDurationLog  = nan( 1, nExpectedTotalFramesToRender ); 
    st1.flipTimeLog             = nan( 1, nExpectedTotalFramesToRender );
    st1.texAlphaLog             = nan( numel( st1.sc.visualStimuliList ), nExpectedTotalFramesToRender );
    
    % Present stimulation
    %----------------------------------------------------------------------
    
    % flush tcp buffer
    if useTcpIpSocket
        [A{iCue,1}, count{iCue,1}, msg{iCue,1}] = fread( tcpSocket , tcpSocket.BytesAvailable );
    end
    
    % present stimulation
    logThis( 'Presenting stimulation for cue %d', iCue );
    presentationStartTime = st1.presentationStartTime;
    st1.presentScenarioRightNow();
    presentationFinishTime = st1.presentationStopTime;
    logThis( 'Presentation duration:         %8.3f seconds', presentationFinishTime-presentationStartTime );
    
    % read EEG
    if useTcpIpSocket
        [A{iCue,2}, count{iCue,2}, msg{iCue,2}] = fread( tcpSocket , tcpSocket.BytesAvailable );
    end    
    
    % collect sten perf data
    if readStenPerf
        renderTime{iCue,1} = 1000*st1.frameRenderDurationLog(1:st1.iFrame);
        flipTime{iCue,1} = 1000*st1.flipTimeLog(1:st1.iFrame);
    end
    
    %======================================================================
    %% Feedback symbol presentation and feedback string update
    %======================================================================
    
    % Update state and duration sequences
    %----------------------------------------------------------------------
    
    % P300 stimulus
    st1.sc.stimuli(iP300Stimuli).stateSequence          = iP3off;
    st1.sc.stimuli(iP300Stimuli).durationSequenceInSec  = sum(fbSymbDurationSeq);
    
    % Cue stimulus    
    st1.sc.stimuli(iCueStimulus).stateSequence          = iCueOff;
    st1.sc.stimuli(iCueStimulus).durationSequenceInSec  = sum(fbSymbDurationSeq);
    
    % Feedback symbol stimulus
    st1.sc.stimuli(iFbSymbStimulus).stateSequence           = fbSymbStateSeq;
    st1.sc.stimuli(iFbSymbStimulus).durationSequenceInSec   = fbSymbDurationSeq;
    symbolHeight                                            = ampFactor*size( stimuli.intense_symbols{ stimuli.i_matrix == cueList(iCue) }, 1 );
    symbolWidth                                             = ampFactor*size( stimuli.intense_symbols{ stimuli.i_matrix == cueList(iCue) }, 2 );
    distFromLeft                                            = (stimuli.scr_cols - symbolWidth) / 2;
    distFromTop                                             = (stimuli.scr_rows - stimuli.string_height - symbolHeight) / 2;
    st1.sc.stimuli(iFbSymbStimulus).states(1).position      = [ ...
                                                                round( 1 + distFromLeft )...                                            % left start
                                                                ; round( 1 + distFromTop + stimuli.string_height )...                   % top start
                                                                ; round( 1 + distFromLeft + symbolWidth ) ...                           % left end
                                                                ; round( 1 + distFromTop + symbolHeight + stimuli.string_height )...    % top end
                                                                ];
    st1.sc.stimuli(iFbSymbStimulus).states(1).views(1).cropRect = stimuli.intense_cropRect{ stimuli.i_matrix == cueList(iCue) }';
    
    % Feedback string stimuli
    for iSymb = 1:lenghFeedbackStr
        if iSymb < iCue
            st1.sc.stimuli(iFbStringStimulus(iSymb)).stateSequence          = fbStringStateSeq2;
            st1.sc.stimuli(iFbStringStimulus(iSymb)).durationSequenceInSec  = fbStringDurationSeq2;
        elseif iSymb > iCue
            st1.sc.stimuli(iFbStringStimulus(iSymb)).stateSequence          = fbStringStateSeq0;
            st1.sc.stimuli(iFbStringStimulus(iSymb)).durationSequenceInSec  = fbStringDurationSeq0;
        end
    end
    st1.sc.stimuli(iFbStringStimulus(iCue)).stateSequence               = fbStringStateSeq1;
    st1.sc.stimuli(iFbStringStimulus(iCue)).durationSequenceInSec       = fbStringDurationSeq1;
    symbStrPos = [
        leftStartStringInPixels
        TopStringMarginInPixels + stringHeighInPixels - size( stimuli.dimmed_symbols{ stimuli.i_matrix == cueList(iCue) }, 1 )
        leftStartStringInPixels + size( stimuli.dimmed_symbols{ stimuli.i_matrix == cueList(iCue) }, 2 )
        TopStringMarginInPixels + stringHeighInPixels
        ];
    st1.sc.stimuli(iFbStringStimulus(iCue)).states(1).position         = symbStrPos;
    st1.sc.stimuli(iFbStringStimulus(iCue)).states(2).position         = symbStrPos;
    st1.sc.stimuli(iFbStringStimulus(iCue)).states(1).views(1).cropRect= stimuli.dimmed_cropRect{ stimuli.i_matrix == cueList(iCue) }';
    st1.sc.stimuli(iFbStringStimulus(iCue)).states(2).views(1).cropRect= stimuli.dimmed_cropRect{ stimuli.i_matrix == cueList(iCue) }';

    % Get ready for stimulation
    %----------------------------------------------------------------------    
    st1.sc.desired.stimulationDuration  = sum(fbSymbDurationSeq);
    st1.updateScenario();
    st1.resetPresentation();
    
    nExpectedTotalFramesToRender = ceil( sum(fbSymbDurationSeq) / st1.scr.flipInterval ) + 200; % add some extra frames, to avoid re-allocation
    st1.frameRenderDurationLog  = nan( 1, nExpectedTotalFramesToRender );
    st1.flipTimeLog             = nan( 1, nExpectedTotalFramesToRender );
    st1.texAlphaLog             = nan( numel( st1.sc.visualStimuliList ), nExpectedTotalFramesToRender );
    
    
    % Present stimulation
    %----------------------------------------------------------------------    
    logThis( 'Presenting feedback for cue %d', iCue );
    presentationStartTime = st1.presentationStartTime;
    st1.presentScenarioRightNow();
    presentationFinishTime = st1.presentationStopTime;
    logThis( 'Presentation duration:         %8.3f seconds', presentationFinishTime-presentationStartTime );
    
    if readStenPerf
        renderTime{iCue,2} = 1000*st1.frameRenderDurationLog(1:st1.iFrame);
        flipTime{iCue,2} = 1000*st1.flipTimeLog(1:st1.iFrame);
    end
    
    % Update stuff for next loop
    %----------------------------------------------------------------------
    st1.sc.stimuli(iFbStringStimulus(iCue)).stateSequence = 2;
    leftStartStringInPixels = leftStartStringInPixels + size( stimuli.dimmed_symbols{ stimuli.i_matrix == cueList(iCue) }, 2 ) + stringGapInPixels;

end

%%                             FINISHING
%==========================================================================
logThis( 'Finishing and cleaning up' );
st1.finishPresentation();
st1.closeGraph();
ShowCursor();

if plotStenPerf
    renderTimeWarmup    = renderTimeWarmup(~isnan(renderTimeWarmup));
    flipTimeWarmup      = flipTimeWarmup(~isnan(flipTimeWarmup));
    figure
    hold on
    plot( renderTimeWarmup, 'r' );
    plot( diff(flipTimeWarmup), 'k' );
    legend('frame rendering time', 'flip interval')
    
    figure;
    indsp = 1;
    for iCue = 1:nCues
        subplot(nCues, 2, indsp)
        hold on
        plot( renderTime{iCue, 1}, 'r' );
        plot( diff(flipTime{iCue, 1}), 'k' );
        xlim( [1 numel(renderTime{iCue, 1})] );
        subplot(nCues, 2, indsp+1)
        hold on
        plot( renderTime{iCue, 2}, 'r' );
        plot( diff(flipTime{iCue, 2}), 'k' );
        xlim( [1 numel(renderTime{iCue, 2})] );
        indsp = indsp + 2;
    end
    legend('frame rendering time', 'flip interval');
end

if useTcpIpSocket
    save('tcpData.mat', 'A', 'count', 'msg');
end

%%                            SAVING DATA
%==========================================================================
if saveData
    logThis( 'Saving data into mat file: %s', dataFilename );
    timingInfo.stimDurationInSec            = stimDurationInSec;
    timingInfo.gapDurationInSec             = gapDurationInSec;
    timingInfo.fakeStimDurInSec             = fakeStimDurInSec;
    timingInfo.pauseBeforeCueInSec          = pauseBeforeCueInSec;
    timingInfo.cueDurationInSec             = cueDurationInSec;
    timingInfo.pauseAfterCueInSec           = pauseAfterCueInSec;
    timingInfo.pauseBeforeFeedbackInSec     = pauseBeforeFeedbackInSec;
    timingInfo.feedbackInSec                = feedbackInSec;
    timingInfo.pauseAfterFeedbackInSec      = pauseAfterFeedbackInSec;
    timingInfo.pauseAfterstringUpdateInSec  = pauseAfterstringUpdateInSec;
    timingInfo.fakeStopStringUpdateInSec    = fakeStopStringUpdateInSec; %#ok<STRNU>
    screenInfo      = st1.scr; %#ok<NASGU>
    scenario        = st1.sc; %#ok<NASGU>
    labChanEvents   = labChan.getListLabels(); %#ok<NASGU>
    varToSave = { ...
        'subjectName' ...
        , 'nRepetitions' ...
        , 'nCues' ...
        , 'timingInfo' ...
        , 'scenario' ...
        , 'stimuli' ...
        , 'cueList' ...
        , 'targetStim' ...
        , 'screenInfo' ...
        , 'p3StateSeq' ...
        , 'p3DurationSeq' ...
        , 'realP3StateSeqOnsets' ...
        , 'labChanEvents', ...
        };
    
    if saveStenPerf
        stenPerf.flipTimeWarmup     = flipTimeWarmup;
        stenPerf.renderTimeWarmup   = renderTimeWarmup; %#ok<STRNU>
        varToSave = [varToSave, 'stenPerf'];
    end
    
    save( dataFilename, varToSave{:} );

end

end

%==========================================================================
%==========================================================================
%==========================================================================
%==========================================================================
%==========================================================================
%==========================================================================


function [stateSeq, durationSeq] = shrinkSequence(stateSeqI, durationSeqI)

indBeforeChange = find(diff(stateSeqI));
stateSeq        = [stateSeqI(indBeforeChange) ; stateSeqI(end)];
durationSeq     = zeros(size(stateSeq));

durationSeq(1) = sum( durationSeqI( 1 : indBeforeChange(1) ) );
for i = 2:numel(indBeforeChange)
    durationSeq(i) = sum( durationSeqI( indBeforeChange(i-1)+1 : indBeforeChange(i) ) );
end
durationSeq(i+1) = sum( durationSeqI( indBeforeChange(i)+1 : end ) );


end

%==========================================================================
%==========================================================================

function sequence = generateFlashSequence( nStim, nRep, targetStim )

minDistBwTargetStim = 3;
maxIter = 200;
sequence = zeros( nStim*nRep, 1);
for iRep = 1:nRep
    sequence( (iRep-1)*nStim + (1:nStim) ) = randperm(nStim);
    minDist = min( diff( find( ismember( sequence(1:iRep*nStim), targetStim ) ) ) );
    iter = 1;
    while minDist < minDistBwTargetStim && iter < maxIter
        sequence( (iRep-1)*nStim + (1:nStim) ) = randperm(nStim);
        minDist = min( diff( find( ismember( sequence(1:iRep*nStim), targetStim ) ) ) );
        iter = iter + 1;
    end
    
%     fprintf('sequence %d: %d iterations\n', iRep, iter+1);
    if minDist < minDistBwTargetStim
        error('Optimization failed after %d iterations', iter+1);
    end
    
end

% indTarget = find( ismember( sequence, targetStim ) );
% if min( diff(indTarget) ) < minDistBwTargetStim
%     error('Optimization failed');
% end

end

%==========================================================================
%==========================================================================

function strOut = yesNo( boolInp )
if boolInp,
    strOut = 'Yes';
else
    strOut = 'No';
end
end
