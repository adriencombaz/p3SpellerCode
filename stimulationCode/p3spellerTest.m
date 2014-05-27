function p3spellerTest

desiredScreenID         = 2;
stimStyle               = 'BasicDesign\2D\';
lenghFeedbackStr        = 20;
nMaxRounds              = 80;
nTCPsamplesPerChannel   = 2;
ipAddress               = '10.35.6.29'; %'localhost';
tcpPortNb               = 778;

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

% Load classifier fiel and experiment parameters
%--------------------------------------------------------------------------
[FileName, PathName]    = uigetfile( fullfile( dataDir, '*.mat' ), 'Select the classifier file' );
trainFilename           = fullfile( PathName, FileName );
% train                   = load( trainFilename, '-regexp', '^(?!Xtrain)...' );
train                   = load( trainFilename );

% General experiment info
%--------------------------------------------------------------------------
subjectName             = train.pars.subjectName;
nRepetitions            = train.iAve;   


% User input
%--------------------------------------------------------------------------
parameterList = {
    'subject name',                                 subjectName,                'subjectName'
    'Number of repetitions',                        nRepetitions,               'nRepetitions'
    'number of TCP samples per channel',            nTCPsamplesPerChannel,      'nTCPsamplesPerChannel'
    'ip address',                                   ipAddress,                  'ipAddress'
    'port numer',                                   tcpPortNb,                  'tcpPortNb'
    };

pars = getItFromGUI( ...
    parameterList(:,1)', ...    list of parameter descriptions (cell array of strings)
    parameterList(:,2)', ...    list of default values for each parameter
    parameterList(:,3)'  ...    list of variables to update
    );

if isempty( pars ),
    return
end

% nRepetitions = str2double(nRepStr);


% Timing information
%--------------------------------------------------------------------------
pauseBetweenRoundsInSec     = 3;
pauseBeforeFeedbackInSec    = train.pars.timingInfo.pauseBeforeFeedbackInSec;
feedbackInSec               = train.pars.timingInfo.feedbackInSec;
pauseAfterFeedbackInSec     = train.pars.timingInfo.pauseAfterFeedbackInSec;
pauseAfterstringUpdateInSec = train.pars.timingInfo.pauseAfterstringUpdateInSec;
fakeStopStringUpdateInSec   = train.pars.timingInfo.fakeStopStringUpdateInSec;

% Basic info for the stimulation engine
%--------------------------------------------------------------------------
useBinaryIntensity              = train.pars.scenario.useBinaryIntensity;
correctStimulusAppearanceTime   = train.pars.scenario.correctStimulusAppearanceTime;
showProgressBar                 = train.pars.scenario.showProgressBar;

% General experiment info
%--------------------------------------------------------------------------
useLptPort                      = true;
useTcpIpSocket                  = true;
plotStenPerf                    = true;
saveData                        = true;
saveLog                         = true;
saveStenPerf                    = true;
showLog                         = true;
stimDurationInSec       = train.pars.timingInfo.stimDurationInSec;
gapDurationInSec        = train.pars.timingInfo.gapDurationInSec;
fakeStimDurInSec        = train.pars.timingInfo.fakeStimDurInSec;
fakeStringUpdateInSec   = pauseAfterstringUpdateInSec - fakeStopStringUpdateInSec;
if fakeStimDurInSec >= 0.9*stimDurationInSec
    error('fakeStimDurInSec should be smaller than stimDurationInSec');
end
if fakeStopStringUpdateInSec >= 0.9*pauseAfterstringUpdateInSec
    error('fakeStopStringUpdateInSec should be smaller than pauseAfterstringUpdateInSec');
end

% Parameters for feedback display
%--------------------------------------------------------------------------
ampFactor                       = 3;
TopStringMarginInPixels         = 25;
LeftStringMarginInPixels        = 100;

%
%--------------------------------------------------------------------------
readStenPerf = plotStenPerf || saveStenPerf;
if readStenPerf
    renderTime  = cell(nMaxRounds, 2);
    flipTime    = cell(nMaxRounds, 2);
end

if useTcpIpSocket
    A       = cell(nMaxRounds, 2);
    count   = cell(nMaxRounds, 2);
    msg     = cell(nMaxRounds, 2);
end

%%                          INIT FILENAMES
%==========================================================================
currentTimeString = datestr( now, 31 );
currentTimeString(11:3:end) = '-';
currentDataDir = [dataDir currentTimeString(1:10) '-' strrep( subjectName, ' ', '-' ) '/'];
if ~exist( currentDataDir, 'dir' ) && ( saveData || saveLog  )
    mkdir( currentDataDir );
end
dataFilename = sprintf( '%s%s-testing.mat', currentDataDir, currentTimeString );


%%            SIZES INFO FOR CORRECT DISPLAY OF SITMULI
%==========================================================================
stimuli                 = train.pars.stimuli;
stringHeighInPixels     = stimuli.string_height-2*TopStringMarginInPixels;
stringGapInPixels       = round( stimuli.string_height / 16 );
leftStartStringInPixels = LeftStringMarginInPixels;

%%              SET UP THE LOGGER AND LOG EXPERIMENT INFO
%==========================================================================
logFilename  = fullfile( currentDataDir, [currentTimeString '-testing-log.txt'] );

logThis( [], ...
    'logTimestamps', 'on', ...
    'logCallerInfo', 'on', ...
    'logFilename', logFilename, ...
    'logToFile', saveLog, ...
    'logToScreen', showLog ...
    );

logThis( '================================================================' );
logThis( '================================================================' );
logThis( '                     P300 SPELLER TESTING' );
logThis( '================================================================' );
logThis( '================================================================' );
logThis( 'path to sten                          %s', which('sten') );
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
logThis( 'Correct stimulus appearance time      %s', yesNo( correctStimulusAppearanceTime ) );
logThis( 'Show presentation progress bar        %s', yesNo( showProgressBar ) );



%%         INITALIZE THE STIMULATION ENGINES AND PARAMETERS
%==========================================================================

st1                 = sten( 'desiredScreenID' , desiredScreenID, 'allowStateLoop', false );
st1.sc              = generateScenario( stimuli, lenghFeedbackStr );
st1.sc.texturesDir  = fullfile( stimDir, stimStyle, 'pix' );

%%              GENERATE STATE AND DURATION SEQUENCES
%==========================================================================

% P300 and cue stimuli
%--------------------------------------------------------------------------
iP300Stimuli    = find( cellfun( @(x) strcmp(x, 'P300 stimulus'), {st1.sc.stimuli(:).description} ) );
iP3off          = numel( st1.sc.stimuli(iP300Stimuli).states );


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
for iStrSymb = 1:lenghFeedbackStr
    st1.sc.stimuli(iFbStringStimulus(iStrSymb)).stateSequence = fbStringStateSeq0;
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
nMaxEvents  = round( nMaxRounds *( 2 ...                             % start and stop events
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
%     nTCPsamplesPerChannel       = 4;
    nBytesPerSample             = 3;
    bytesInTCParray             = nBytesPerSample * nTCPsamplesPerChannel * nChannelsSendByTCP;
    maxFlashSeqDurationInSec    = ( max( stimDurationInSec ) + max( gapDurationInSec ) ) * nRepetitions * stimuli.number;
    biosemiSampleRate           = 512;
    bytesInFlashSeq             = (pauseBetweenRoundsInSec + maxFlashSeqDurationInSec) * biosemiSampleRate * nBytesPerSample * nChannelsSendByTCP;
    bytesInBuffer               = 2 * bytesInTCParray * ceil( bytesInFlashSeq/bytesInTCParray );
    
    tcpSocket = tcpip( ipAddress, tcpPortNb, 'InputBufferSize', bytesInBuffer );
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

iRound                  = 1;
keyPressed              = false;
lastDetectedSymbolCode  = 0;
detectedSymbolCode      = zeros( nMaxRounds, 1 );
stimuliStateSeqOnsets   = zeros( stimuli.number*nRepetitions, nMaxRounds );
while ( iRound <= nMaxRounds ) && ( ~keyPressed ) && ( lastDetectedSymbolCode~=stimuli.stopsymbol_code )
    
    %======================================================================
    %% Cue and P300 stimulation
    %======================================================================
    
    % Update state and duration sequences
    %----------------------------------------------------------------------
    
    % P300 stimulus
    stimuliStateSeqOnsets(:, iRound) = generateFlashSequenceTest( stimuli.number, nRepetitions );
    temp = 2*stimuliStateSeqOnsets(:, iRound)' - 1;
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

    stateSeq                                            = [iP3off ; stateSeq(:) ; iP3off];
    durationSeq                                         = [pauseBetweenRoundsInSec ; durationSeq(:) ; 2*train.tAfterOnset];
    [stateSeq, durationSeq]                             = shrinkSequence( stateSeq, durationSeq );
    st1.sc.stimuli(iP300Stimuli).stateSequence          = stateSeq;
    st1.sc.stimuli(iP300Stimuli).durationSequenceInSec  = durationSeq;
    
    % Feedback symbol stimulus
    st1.sc.stimuli(iFbSymbStimulus).stateSequence        = 2;
    st1.sc.stimuli(iFbSymbStimulus).durationSequenceInSec= sum(durationSeq);
    
    % Feedback string stimuli
    for iStrSymb = 1:lenghFeedbackStr
        st1.sc.stimuli(iFbStringStimulus(iStrSymb)).durationSequenceInSec = sum(durationSeq);
    end
    
    % Get ready for stimulation
    %----------------------------------------------------------------------
    st1.sc.desired.stimulationDuration = sum(durationSeq);
    st1.updateScenario();
    if iRound == 1
%         st1.preparePresentationOptimized();
        [flipTimeWarmup, renderTimeWarmup] = st1.preparePresentationOptimized();
    else
        st1.resetPresentation();
    end
    nExpectedTotalFramesToRender = ceil( sum(durationSeq) / st1.scr.flipInterval ) + 200; % add some extra frames, to avoid re-allocation
    st1.frameRenderDurationLog  = nan( 1, nExpectedTotalFramesToRender ); 
    st1.flipTimeLog             = nan( 1, nExpectedTotalFramesToRender );
    st1.texAlphaLog             = nan( numel( st1.sc.visualStimuliList ), nExpectedTotalFramesToRender );
    
    % Present stimulation
    %----------------------------------------------------------------------
    
    % flush tcp buffer
    if useTcpIpSocket
        [A{iRound,1}, count{iRound,1}, msg{iRound,1}] = fread( tcpSocket , tcpSocket.BytesAvailable );
    end
    
    % present stimulation
    logThis( 'Presenting stimulation for round %d', iRound );
    presentationStartTime = st1.presentationStartTime;
    st1.presentScenarioRightNow();
    presentationFinishTime = st1.presentationStopTime;
    logThis( 'Presentation duration:         %8.3f seconds', presentationFinishTime-presentationStartTime );
    
    % read EEG
    if useTcpIpSocket
        [A{iRound,2}, count{iRound,2}, msg{iRound,2}] = fread( tcpSocket , tcpSocket.BytesAvailable );
    end    
    
    % Apply classifier
    winnerSymbol = findTargetSymbol( train, A{iRound,2}, stimuliStateSeqOnsets(:, iRound), nRepetitions );
%     winnerSymbol.code = iRound;
%     [sRow, sCol] = find( stimuli.i_matrix == winnerSymbol.code );
%     winnerSymbol.iRowCol = [sRow, sCol];
    
    % collect sten perf data
    if readStenPerf
        renderTime{iRound,1} = 1000*st1.frameRenderDurationLog(1:st1.iFrame);
        flipTime{iRound,1} = 1000*st1.flipTimeLog(1:st1.iFrame);
    end
    
    %======================================================================
    %% Feedback symbol presentation and feedback string update
    %======================================================================
    
    % Update state and duration sequences
    %----------------------------------------------------------------------
    
    % P300 stimulus
    st1.sc.stimuli(iP300Stimuli).stateSequence          = iP3off;
    st1.sc.stimuli(iP300Stimuli).durationSequenceInSec  = sum(fbSymbDurationSeq);
    
    % Feedback symbol stimulus
    st1.sc.stimuli(iFbSymbStimulus).stateSequence           = fbSymbStateSeq;
    st1.sc.stimuli(iFbSymbStimulus).durationSequenceInSec   = fbSymbDurationSeq;
    symbolHeight                                            = ampFactor*size( stimuli.intense_symbols{ winnerSymbol.iRowCol }, 1 );
    symbolWidth                                             = ampFactor*size( stimuli.intense_symbols{ winnerSymbol.iRowCol }, 2 );
    distFromLeft                                            = (stimuli.scr_cols - symbolWidth) / 2;
    distFromTop                                             = (stimuli.scr_rows - stimuli.string_height - symbolHeight) / 2;
    st1.sc.stimuli(iFbSymbStimulus).states(1).position      = [ ...
                                                                round( 1 + distFromLeft )...                                            % left start
                                                                ; round( 1 + distFromTop + stimuli.string_height )...                   % top start
                                                                ; round( 1 + distFromLeft + symbolWidth ) ...                           % left end
                                                                ; round( 1 + distFromTop + symbolHeight + stimuli.string_height )...    % top end
                                                                ];
    st1.sc.stimuli(iFbSymbStimulus).states(1).views(1).cropRect = stimuli.intense_cropRect{ winnerSymbol.iRowCol }';
    
    % Feedback string stimuli
    iStrSymbUpdate = min( iRound, lenghFeedbackStr );
    for iStrSymb = 1:lenghFeedbackStr
        if iStrSymb < iStrSymbUpdate
            st1.sc.stimuli(iFbStringStimulus(iStrSymb)).stateSequence          = fbStringStateSeq2;
            st1.sc.stimuli(iFbStringStimulus(iStrSymb)).durationSequenceInSec  = fbStringDurationSeq2;
        elseif iStrSymb > iStrSymbUpdate
            st1.sc.stimuli(iFbStringStimulus(iStrSymb)).stateSequence          = fbStringStateSeq0;
            st1.sc.stimuli(iFbStringStimulus(iStrSymb)).durationSequenceInSec  = fbStringDurationSeq0;
        end
    end
    st1.sc.stimuli(iFbStringStimulus(iStrSymbUpdate)).stateSequence               = fbStringStateSeq1;
    st1.sc.stimuli(iFbStringStimulus(iStrSymbUpdate)).durationSequenceInSec       = fbStringDurationSeq1;
    
    if iRound > lenghFeedbackStr
        
        firstSymbPos    = st1.sc.stimuli(iFbStringStimulus(1)).states(1).position;
        shift           = firstSymbPos(3) - firstSymbPos(1) + 1 + stringGapInPixels;
        for iStrSymb = 1:lenghFeedbackStr-1
            st1.sc.stimuli(iFbStringStimulus(iStrSymb)).states(1).position         = st1.sc.stimuli(iFbStringStimulus(iStrSymb+1)).states(1).position - [shift 0 shift 0]';
            st1.sc.stimuli(iFbStringStimulus(iStrSymb)).states(2).position         = st1.sc.stimuli(iFbStringStimulus(iStrSymb+1)).states(2).position - [shift 0 shift 0]';
            st1.sc.stimuli(iFbStringStimulus(iStrSymb)).states(1).views(1).cropRect= st1.sc.stimuli(iFbStringStimulus(iStrSymb+1)).states(1).views(1).cropRect;
            st1.sc.stimuli(iFbStringStimulus(iStrSymb)).states(2).views(1).cropRect= st1.sc.stimuli(iFbStringStimulus(iStrSymb+1)).states(2).views(1).cropRect;
        end
        leftStartStringInPixels = leftStartStringInPixels - shift;
    end
    symbStrPos = [
        leftStartStringInPixels
        TopStringMarginInPixels + stringHeighInPixels - size( stimuli.dimmed_symbols{ winnerSymbol.iRowCol }, 1 )
        leftStartStringInPixels + size( stimuli.dimmed_symbols{ winnerSymbol.iRowCol }, 2 )
        TopStringMarginInPixels + stringHeighInPixels
        ];
    st1.sc.stimuli(iFbStringStimulus(iStrSymbUpdate)).states(1).position         = symbStrPos;
    st1.sc.stimuli(iFbStringStimulus(iStrSymbUpdate)).states(2).position         = symbStrPos;
    st1.sc.stimuli(iFbStringStimulus(iStrSymbUpdate)).states(1).views(1).cropRect= stimuli.dimmed_cropRect{ winnerSymbol.iRowCol }';
    st1.sc.stimuli(iFbStringStimulus(iStrSymbUpdate)).states(2).views(1).cropRect= stimuli.dimmed_cropRect{ winnerSymbol.iRowCol }';
    
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
    logThis( 'Presenting feedback for round %d', iRound );
    presentationStartTime = st1.presentationStartTime;
    st1.presentScenarioRightNow();
    presentationFinishTime = st1.presentationStopTime;
    logThis( 'Presentation duration:         %8.3f seconds', presentationFinishTime-presentationStartTime );
    
    if readStenPerf
        renderTime{iRound,2} = 1000*st1.frameRenderDurationLog(1:st1.iFrame);
        flipTime{iRound,2} = 1000*st1.flipTimeLog(1:st1.iFrame);
    end
    
    % exit the loop if a key was pressed
    %----------------------------------------------------------------------
    keyPressed = keyPressed || CharAvail;
    if keyPressed,
        logThis( 'Keystroke detected. Exiting. Last flashing sequence discarded.' );
        break
    end
    
    % Update stuff for next loop
    %----------------------------------------------------------------------
    st1.sc.stimuli(iFbStringStimulus(iStrSymbUpdate)).stateSequence = 2;
    leftStartStringInPixels     = leftStartStringInPixels + size( stimuli.dimmed_symbols{ winnerSymbol.iRowCol }, 2 ) + stringGapInPixels;
    detectedSymbolCode(iRound)  = winnerSymbol.code;
    lastDetectedSymbolCode      = winnerSymbol.code;
    iRound                      = iRound + 1;

end

%%                             FINISHING
%==========================================================================
logThis( 'Finishing and cleaning up' );
st1.finishPresentation();
st1.closeGraph();
ShowCursor();

detectedSymbolCode( iRound:end )        = [];
stimuliStateSeqOnsets(:, iRound:end )   = [];
nRounds                                 = iRound - 1;


%%                        GET SUBJECT FEEDBACK
%==========================================================================
realStringCodes = manual_typer( stimuli, detectedSymbolCode );
while numel( realStringCodes ) < numel( detectedSymbolCode )
    realStringCodes = [realStringCodes stimuli.stopsymbol_code];
end

nCorrectSymbols = 0;
for i = 1:min(numel(detectedSymbolCode), numel(realStringCodes)),
    nCorrectSymbols = nCorrectSymbols + (detectedSymbolCode(i) == realStringCodes(i));
end

logThis('Number of correctly braintyped symbols: %g\n', nCorrectSymbols);
logThis('Number of braintyped symbols:           %g\n', numel( detectedSymbolCode ));    


%%                        PLOT PERFORMANCE
%==========================================================================

if plotStenPerf
    renderTime(iRound:end, : )  = [];
    flipTime(iRound:end, : )    = [];
    renderTimeWarmup            = renderTimeWarmup(~isnan(renderTimeWarmup));
    flipTimeWarmup              = flipTimeWarmup(~isnan(flipTimeWarmup));
    
    figure
    hold on
    plot( renderTimeWarmup, 'r' );
    plot( diff(flipTimeWarmup), 'k' );
    legend('frame rendering time', 'flip interval')
    
    figure;
    indsp = 1;
    for iR = 1:nRounds
        subplot(nRounds, 2, indsp)
        hold on
        plot( renderTime{iR, 1}, 'r' );
        plot( diff(flipTime{iR, 1}), 'k' );
        xlim( [1 numel(renderTime{iR, 1})] );
        subplot(nRounds, 2, indsp+1)
        hold on
        plot( renderTime{iR, 2}, 'r' );
        plot( diff(flipTime{iR, 2}), 'k' );
        xlim( [1 numel(renderTime{iR, 2})] );
        indsp = indsp + 2;
    end
    legend('frame rendering time', 'flip interval');
end

if useTcpIpSocket
    A(iRound:end, :)	= [];
    count(iRound:end, :)= [];
    msg(iRound:end, :)  = [];
    save('tcpData.mat', 'A', 'count', 'msg');
end

%%                            SAVING DATA
%==========================================================================
if saveData
    logThis( 'Saving data into mat file: %s', dataFilename );
    screenInfo      = st1.scr; %#ok<NASGU>
    scenario        = st1.sc; %#ok<NASGU>
    labChanEvents   = labChan.getListLabels(); %#ok<NASGU>
    varToSave = { ...
        'trainFilename' ...
        , 'train' ...
        , 'pauseBetweenRoundsInSec' ...
        , 'screenInfo' ...
        , 'scenario' ...
        , 'labChanEvents' ...
        , 'nRounds' ...
        , 'detectedSymbolCode' ...
        , 'stimuliStateSeqOnsets' ...
        , 'realStringCodes' ...
        , 'nCorrectSymbols' ...
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

function sequence = generateFlashSequenceTest( nStim, nRep )

minDistBwSameStim = 3;
maxIter = 200;
sequence = zeros( nStim*nRep, 1);
sequence(1:nStim) = randperm(nStim);
for iRep = 2:nRep    
    keepSequence = false;
    iter = 1;
    while ~keepSequence && iter < maxIter
        sequence( (iRep-1)*nStim + (1:nStim) ) = randperm(nStim);
        for ind = ((iRep-1)*nStim-minDistBwSameStim+1):((iRep-1)*nStim)
            if isequal( unique( sequence(ind:ind+minDistBwSameStim) ), sort( sequence(ind:ind+minDistBwSameStim) ) )
                keepSequence = true;
            else
                keepSequence = false;
                break
            end
        end
    end
    
    if ~keepSequence
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

%==========================================================================
%==========================================================================

function winnerSymbol = findTargetSymbol( train, data, stimuliStateSeqOnsets, nRepetitions )

nChannels       = 41;
nBytesPerSample = 3;
nSamples        = numel( data ) / (nChannels*nBytesPerSample);
sampleRate      = train.sampleRate;
chanOfInterest  = [train.classifChanInd train.refChanInd nChannels];
classifChanInd  = ismember( chanOfInterest, train.classifChanInd ) ;
refChanInd      = ismember( chanOfInterest, train.refChanInd ) ;
statChanInd     = numel( chanOfInterest );


if nSamples ~= round(nSamples), 
    logThis('Error TCP data reconstruction: not an exact number of samples! Rounding it and continuing but something is wrong!!');
    nSamples = floor( nSamples );
end


% cuts limits and sizes in samples
nl          = round( train.tBeforeOnset*sampleRate );
nh          = round( train.tAfterOnset*sampleRate );
range       = nh+1;
nBins       = floor( range / train.DSFactor );



%%           RECONSTRUCT EEG DATA FOR CHANNELS OF INTEREST
%==========================================================================
sig = zeros( nSamples, numel( chanOfInterest ) );
for iCh = 1:numel(chanOfInterest)
        for iSample = 1:nSamples
            offset = (iSample-1)*nChannels*nBytesPerSample + (chanOfInterest(iCh)-1)*nBytesPerSample + 1;
            sig(iSample, iCh) = data(offset) + data(offset+1) * 256 + data(offset+2) * 65536;            
        end
end


%%                    GET EVENT ONSETS AND LABELS
%==========================================================================
onsetEventInd   = cellfun( @(x) strcmp(x, 'P300 stim on'), {train.pars.scenario.events(:).desc} );
onsetEventValue = train.pars.scenario.events( onsetEventInd ).id;
eventChan       = logical( bitand( sig(:, statChanInd), onsetEventValue ) );
eventPos        = find( diff( eventChan ) == 1 ) + 1;
stimId          = stimuliStateSeqOnsets(:);
if numel( stimId ) ~= numel( eventPos ), error('different number of flashes read from the bdf and mat files'); end


%%                          PREPROCESS
%==========================================================================

% reference
refSig  = sig(:,refChanInd);
sig     = sig(:, classifChanInd);
sig     = bsxfun( @minus, sig, mean( refSig , 2 ) );

% Filter
for i = 1:size(sig, 2)
    sig(:,i) = filtfilt( train.filtPar.a, train.filtPar.b, sig(:,i) );
end

% remove mean
sig = bsxfun( @minus, sig, mean(sig, 1) );


%%                  CUT AVERAGE AND DOWNSAMPLE DATA
%==========================================================================
nEv     = numel( eventPos );
nChan   = sum( classifChanInd );
cuts    = zeros( nBins, nChan, train.pars.stimuli.number );
count   = zeros( train.pars.stimuli.number, 1 );
for iEv = 1:nEv
    if train.tBeforeOnset == 0
        baseline = zeros(1, nChan);
    else
        baseline = mean( sig( (eventPos(iEv)-nl) : (eventPos(iEv)-1), : ), 1);
    end
    temp            = mean( reshape( sig( eventPos(iEv) : (eventPos(iEv)+nBins*train.DSFactor-1), : ), train.DSFactor, nBins*nChan ), 1 );
    temp            = reshape( temp, nBins, nChan );
    cuts(:, :, stimId(iEv)) = cuts(:, :, stimId(iEv)) + bsxfun(@minus, temp, baseline);
    count(stimId(iEv))      = count(stimId(iEv)) + 1;
end

% if unique( count ) ~= train.pars.nRepetitions, error('Unexpected number of repetitions per stimuli!!'); end
if unique( count ) ~= nRepetitions, error('Unexpected number of repetitions per stimuli!!'); end

cuts = cuts / nRepetitions;


%%              NORMALIZE FEATURES AND APPLY CLASSIFIER
%==========================================================================
Xtest       = reshape( cuts, nBins*nChan, train.pars.stimuli.number )';
Xtest       = bsxfun(@minus, Xtest, train.minx);
Xtest       = bsxfun(@rdivide, Xtest, train.maxx-train.minx);
Xtest       = [Xtest ones( train.pars.stimuli.number, 1 )];
stimScore   = Xtest*train.B;



%%                  FIND WINNER STIMULI AND SYMBOL
%==========================================================================
winnerSymbol.indStimInGroup = zeros( train.pars.stimuli.n_groups, 1 );
winnerSymbol.indStim        = zeros( train.pars.stimuli.n_groups, 1 );
for iGp = 1:train.pars.stimuli.n_groups
        groupIndices                        = train.pars.stimuli.groups{iGp};
        [~, bestStimuliInGroup]             = max( stimScore(train.pars.stimuli.groups{iGp}) );
        winnerSymbol.indStimInGroup(iGp)    = bestStimuliInGroup;
        winnerSymbol.indStim(iGp)           = groupIndices(bestStimuliInGroup);    
end

intersectionMask = train.pars.stimuli.matrix_masks{winnerSymbol.indStim(1)};
for iGp = 2:train.pars.stimuli.n_groups,
    intersectionMask = intersectionMask & train.pars.stimuli.matrix_masks{winnerSymbol.indStim(iGp)};
end
intersection = find(intersectionMask);
if numel(intersection)~=1, error('Check intersection!!!'); end

winnerSymbol.code  = train.pars.stimuli.i_matrix(intersection);
% [sRow, sCol] = find(train.pars.stimuli.i_matrix == winnerSymbol.code);
% winnerSymbol.iRowCol = [sRow, sCol];
winnerSymbol.iRowCol = find(train.pars.stimuli.i_matrix == winnerSymbol.code);

end