function p3CopySpellerTrain

desiredScreenID = 2;
stimStyle       = 'copySpelling\2D\';
% stimStyle       = 'copySpelling\2D_simple\';


%%                      INIT DIRECTORIES
%==========================================================================
hostName = getHostName();
switch hostName
    case 'kuleuven-24b13c'
        dataDir = 'd:\KULeuven\PhD\Work\P300basedBciSpeller\recordedData\';
        stimDir = 'd:\KULeuven\PhD\Work\P300basedBciSpeller\p3SpellerCode\stimulationCode\stimuliGenerator\Sessions\';
        addpath('d:\KULeuven\PhD\Work\P300basedBciSpeller\p3SpellerCode\stimulationCode\deps\');
    case 'neu-wrk-0158'
        dataDir = 'd:\Adrien\Work\P300basedBciSpeller\recordedData\';
        stimDir = 'd:\Adrien\Work\P300basedBciSpeller\p3SpellerCode\stimulationCode\stimuliGenerator\Sessions\';
        addpath('d:\Adrien\Work\P300basedBciSpeller\p3SpellerCode\stimulationCode\deps\');
    case 'neu-wrk-0198'
        dataDir = 'c:\data\EEG-recordings\P300-speller\';
        stimDir = '.\stimuliGenerator\Sessions\';
        addpath( '.\deps\' );        
    otherwise
        error('Unknown host');
end
texturesDir  = fullfile( stimDir, stimStyle, 'pix' );


%%                       EXPERIMENT PARAMETERS
%==========================================================================

% General experiment info
%--------------------------------------------------------------------------
subjectName             = 'subjectname';
nCues                   = 8;
nRepetitions            = 10;   

% Timing information
%--------------------------------------------------------------------------
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
useLptPort                      = false;
useSerialPort                   = false;
serialPortName                  = 'COM1'; % could be in the GUI
useTcpIpSocket                  = false;
plotStenPerf                    = true;
saveData                        = true;
saveLog                         = true;
% saveUnfoldedScenario            = true;
saveStenPerf                    = true;
showLog                         = true;

% Parameters for feedback display
%--------------------------------------------------------------------------
nIncorrectFb                    = 0;
ampFactor                       = 3;
TopStringMarginInPixels         = 25;
LeftStringMarginInPixels        = 100;

%%                       GET USER INPUT
%==========================================================================
parameterList = {
    'Subject name',                             subjectName,                'subjectName'
    'Number of targets',                        nCues,                      'nCues'
    'Number of wrong feedback',                 nIncorrectFb,               'nIncorrectFb'
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
    'Send markers via parallel port',           useLptPort,                 'useLptPort'
    'Send markers via serial port',             useSerialPort,              'useSerialPort'
    
    };

prefGroupName = 'p3CopySpellerTrain';

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
% stringHeighInPixels     = stimuli.string_height-2*TopStringMarginInPixels;
stringHeighInPixels     = round( (stimuli.string_height-3*TopStringMarginInPixels) / 2 );
stringGapInPixels       = round( stimuli.string_height / 16 );
% leftStartStringInPixels = LeftStringMarginInPixels;
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
logThis( 'Send markers through parallel port    %s', yesNo( useLptPort ) );
logThis( 'Send markers through serial port      %s', yesNo( useSerialPort ) );
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


% 	
%%         INITALIZE THE STIMULATION ENGINES AND PARAMETERS
%==========================================================================

% Scenario
%--------------------------------------------------------------------------
st1                 = sten( 'desiredScreenID' , desiredScreenID, 'allowStateLoop', false );
st1.sc              = generateScenarioCopySpellTrain( stimuli );
st1.sc.texturesDir  = texturesDir;

% define cue list and corresponding indices of target stimuli
%--------------------------------------------------------------------------
if nCues == 8
    wordList    = dataset('File', 'wordList8Letters.txt', 'ReadVarNames', false, 'VarNames', 'string');
    temp        = randperm( numel(wordList.string) );
    string      = upper( wordList.string{temp(1)} );
    cueList     = zeros(1, nCues);
    for iCue = 1:nCues
        cueList(iCue) = stimuli.stringSymbols.code( ismember( stimuli.stringSymbols.str, string(iCue) ) );
    end    
else
    cueList     = randperm( stimuli.n_symbols );
    cueList     = cueList(1:nCues);
end
targetStim  = zeros(nCues, stimuli.n_groups);
for iCue = 1:nCues
    isStimTarget        = logical( cellfun( @(x) x(stimuli.i_matrix == cueList(iCue)), stimuli.matrix_masks ) );
    targetStim(iCue, :) = cellfun( @(x) x(isStimTarget(x)), stimuli.groups );
end

cueListFB = cueList;
if nIncorrectFb > 0
    temp = randperm(nCues);
    temp( ismember(temp, [1 2]) ) = [];
    temp = temp(1:nIncorrectFb);
    for iL = 1:nIncorrectFb
        choice = stimuli.symbol_codes( ~ismember(stimuli.symbol_codes, cueList(temp(iL))) );
        choice = choice(randperm( numel(choice) ));
        cueListFB(temp(iL)) = choice(1);
    end
end

% create image for top and feedback strings
%--------------------------------------------------------------------------
if numel(cueList) ~= numel(cueListFB), error('not similar size of top string and feedback string'); end
hSize       = numel(cueList)*( max( cellfun(@(x) max(size(x,2)), stimuli.dimmed_symbols(:)) ) + stringGapInPixels );
vSize       = max( cellfun(@(x) max(size(x,1)), stimuli.dimmed_symbols(:)) );
topText     = zeros(vSize, hSize, 3, 'uint8');
fbText      = zeros(vSize, hSize, 3, 'uint8');
hPixIndTop  = 1;   
hPixIndFb   = 1;
fbStrRectLimits     = zeros(nCues+1, 1);
fbStrRectLimits(1)  = hPixIndFb;
for iS = 1:nCues
    im = stimuli.dimmed_symbols{ stimuli.i_matrix==cueList(iS) };
    topText(vSize-size(im,1)+1:end, hPixIndTop:hPixIndTop+size(im,2)-1, :) = im;
    hPixIndTop = hPixIndTop + size(im,2) + stringGapInPixels;    

    im = stimuli.dimmed_symbols{ stimuli.i_matrix==cueListFB(iS) };
    fbText(vSize-size(im,1)+1:end, hPixIndFb:hPixIndFb+size(im,2)-1, :) = im;
    hPixIndFb = hPixIndFb + size(im,2) + stringGapInPixels;    
    fbStrRectLimits(iS+1) = hPixIndFb - round(stringGapInPixels/2);
end
topText(:, hPixIndTop+1:end, :) = [];
fbText(:, hPixIndFb+1:end, :)   = [];
topText             = imresize(topText, [stringHeighInPixels, NaN]);
fbText              = imresize(fbText, [stringHeighInPixels, NaN]);
resizeStringFactor  = stringHeighInPixels / vSize;
fbStrRectLimits     = fbStrRectLimits * resizeStringFactor;
imwrite(topText, fullfile(texturesDir, 'topString.png'));
imwrite(fbText, fullfile(texturesDir, 'fbString.png'));





%%              GENERATE STATE AND DURATION SEQUENCES
%==========================================================================

% P300 and cue stimuli
%--------------------------------------------------------------------------
iP300Stimuli    = find( cellfun( @(x) strcmp(x, 'P300 stimulus'), {st1.sc.stimuli(:).description} ) );
iCueStimulus    = find( cellfun( @(x) strcmp(x, 'cue stimulus'), {st1.sc.stimuli(:).description} ) );
iP3off          = numel( st1.sc.stimuli(iP300Stimuli).states );
iTopStrStim     = find( cellfun( @(x) strcmp(x, 'top string'), {st1.sc.stimuli(:).description} ) );
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
st1.sc.stimuli(iFbStringStimulus).states(1).position         = [0 0 0 0]';
st1.sc.stimuli(iFbStringStimulus).states(2).position         = [0 0 0 0]';
st1.sc.stimuli(iFbStringStimulus).states(1).views(1).cropRect= [0 0 0 0]';
st1.sc.stimuli(iFbStringStimulus).states(2).views(1).cropRect= [0 0 0 0]';

% Top string stimulus
%--------------------------------------------------------------------------
st1.sc.stimuli(iTopStrStim).desired.position         = [LeftStringMarginInPixels TopStringMarginInPixels LeftStringMarginInPixels+resizeStringFactor*hPixIndTop TopStringMarginInPixels + stringHeighInPixels];
st1.sc.stimuli(iTopStrStim).states(1).position       = st1.sc.stimuli(iTopStrStim).desired.position;



%%              FINALIZE SCENARIO AND LOAD TEXTURES
%==========================================================================
st1.sc.useBinaryIntensity            = useBinaryIntensity;
st1.sc.correctStimulusAppearanceTime = correctStimulusAppearanceTime;
st1.sc.showProgressBar               = showProgressBar;
st1.sc.issueFrameBasedEvents         = true;
st1.sc.issueTimeBasedEvents          = false;
st1.sc.frameBasedEventIdAdjust       = 0;
st1.sc.scenarioDir                   = '';
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
labChan = biosemiLabelChannel( ...
    'sizeListLabels', nMaxEvents , ...
    'sendLptMarkers', useLptPort, ...
    'sendSerialMarkers', useSerialPort, ...
    'serialPortName', serialPortName );

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


%====================================================================================================================================================
%====================================================================================================================================================
%====================================================================================================================================================
%%                                                               EXPERIMENT
%====================================================================================================================================================
%====================================================================================================================================================
%====================================================================================================================================================
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
    st1.sc.stimuli(iCueStimulus).states(1).desired.position     = [ ...
                                                        round( 1 + cueLeftMargin + (elCol-1)*axisWidth )...                                        % left start
                                                        ; round( 1 + stimuli.string_height + cueTopMargin + (elRow-1)*axisHeight )...                % top start
                                                        ; round( 1 + cueSize + cueLeftMargin + (elCol-1)*axisWidth ) ...                            % left end
                                                        ; round( 1 + cueSize + stimuli.string_height + cueTopMargin + (elRow-1)*axisHeight )...     % top end
                                                        ];

    % Feedback symbol stimulus
    st1.sc.stimuli(iFbSymbStimulus).stateSequence        = 2;
    st1.sc.stimuli(iFbSymbStimulus).durationSequenceInSec= sum(cueDurationSeq{iCue});
    
    % Feedback string stimuli
    st1.sc.stimuli(iFbStringStimulus).stateSequence        = 1;
    st1.sc.stimuli(iFbStringStimulus).durationSequenceInSec= sum(cueDurationSeq{iCue});
    
    % top string stimulus
    st1.sc.stimuli(iTopStrStim).stateSequence        = 1;
    st1.sc.stimuli(iTopStrStim).durationSequenceInSec= sum(cueDurationSeq{iCue});

    
    % Get ready for stimulation
    %----------------------------------------------------------------------
    st1.sc.desired.stimulationDuration = sum(cueDurationSeq{iCue});
    st1.updateScenario();
    if iCue == 1
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
    symbolHeight                                            = ampFactor*size( stimuli.intense_symbols{ stimuli.i_matrix == cueListFB(iCue) }, 1 );
    symbolWidth                                             = ampFactor*size( stimuli.intense_symbols{ stimuli.i_matrix == cueListFB(iCue) }, 2 );
    distFromLeft                                            = (stimuli.scr_cols - symbolWidth) / 2;
    distFromTop                                             = (stimuli.scr_rows - stimuli.string_height - symbolHeight) / 2;
    st1.sc.stimuli(iFbSymbStimulus).states(1).desired.position      = [ ...
                                                                round( 1 + distFromLeft )...                                            % left start
                                                                ; round( 1 + distFromTop + stimuli.string_height )...                   % top start
                                                                ; round( 1 + distFromLeft + symbolWidth ) ...                           % left end
                                                                ; round( 1 + distFromTop + symbolHeight + stimuli.string_height )...    % top end
                                                                ];
    st1.sc.stimuli(iFbSymbStimulus).states(1).views(1).cropRect = stimuli.intense_cropRect{ stimuli.i_matrix == cueListFB(iCue) }';
    
    % Feedback string stimuli
    st1.sc.stimuli(iFbStringStimulus).stateSequence                 = [1 3 2];
    st1.sc.stimuli(iFbStringStimulus).durationSequenceInSec         = [ pauseBeforeFeedbackInSec + feedbackInSec + pauseAfterFeedbackInSec ; fakeStringUpdateInSec ; fakeStopStringUpdateInSec ];
    fbStrRect = [ 1, 1, fbStrRectLimits(iCue+1), stringHeighInPixels ]';
    fbStrPos  = fbStrRect + [LeftStringMarginInPixels, 2*TopStringMarginInPixels+stringHeighInPixels, LeftStringMarginInPixels, 2*TopStringMarginInPixels+stringHeighInPixels]';
    st1.sc.stimuli(iFbStringStimulus).states(2).desired.position    = fbStrPos;
    st1.sc.stimuli(iFbStringStimulus).states(3).desired.position    = fbStrPos;
    st1.sc.stimuli(iFbStringStimulus).states(2).views(1).cropRect   = fbStrRect;
    st1.sc.stimuli(iFbStringStimulus).states(3).views(1).cropRect   = fbStrRect;

    % top string stimulus
    st1.sc.stimuli(iTopStrStim).stateSequence        = 1;
    st1.sc.stimuli(iTopStrStim).durationSequenceInSec= sum(fbSymbDurationSeq);

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
    st1.sc.stimuli(iFbStringStimulus).states(1).desired.position  = fbStrPos;
    st1.sc.stimuli(iFbStringStimulus).states(1).views(1).cropRect = fbStrRect;

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
        , 'cueListFB' ...
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
