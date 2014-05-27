function plotTrainingSession


%%                  INIT DIRECTORIES AND FILENAMES
%==========================================================================
hostName = getHostName();
switch hostName
    case 'kuleuven-24b13c'
        dataDir = 'd:\KULeuven\PhD\Work\P300basedBciSpeller\recordedData\';
        addpath('d:\KULeuven\PhD\Work\P300basedBciSpeller\code\deps\');
        addpath('d:\KULeuven\PhD\Work\P300basedBciSpeller\code\deps\Linear_SVM_tool_for_BCI_2\');
    case 'neu-wrk-0158'
        dataDir = 'd:\Adrien\Work\P300basedBciSpeller\recordedData\';
        addpath('d:\Adrien\Work\P300basedBciSpeller\code\deps\');
        addpath('d:\Adrien\Work\P300basedBciSpeller\code\deps\Linear_SVM_tool_for_BCI_2\');
    otherwise
        error('Unknown host');
end

%%                  INITIALIZE PROCESSING STUFF
%==========================================================================
refChanNames         = {'EXG1', 'EXG2'};
discardChanNames     = {'EXG3', 'EXG4', 'EXG5', 'EXG6', 'EXG7', 'EXG8'};
% classifChanNames     = {'Fz', 'Cz', 'P3', 'Pz', 'P4', 'PO3', 'PO4', 'O1', 'Oz', 'O2'};
tBeforeOnset         = 0.2; % lower time range in secs - for baseline correction (if 0 no baseine correction)
tAfterOnset          = 0.8; % upper time range in secs
filtPar.lowMargin    = .5;
filtPar.highMargin   = 20;
filtPar.order        = 3;


%%                      LOAD RELEVANT DATA
%==========================================================================
% bdfFilename = 'd:\KULeuven\PhD\Work\P300basedBciSpeller\recordedData\2014-04-17-test-subject\2014-04-17-15-10-39-training.bdf';
[FileName, PathName]    = uigetfile( fullfile( dataDir, '*.bdf' ), 'Select the bdf data file' );
bdfFilename             = fullfile( PathName, FileName);
hdr                     = sopen( bdfFilename );
[sig, hdr]              = sread(hdr);
fclose(hdr.FILE.FID);
statusChannel           = bitand(hdr.BDF.ANNONS, 255);
hdr.BDF                 = rmfield(hdr.BDF, 'ANNONS'); % just saving up some space...
sampleRate              = hdr.SampleRate;

pars = load( [bdfFilename(1:end-3) 'mat'] );


%%                      INITIALIZE DATA INFO
%==========================================================================

% List of channels
chanList                                = hdr.Label;
chanList(strcmp(chanList, 'Status'))    = [];
discardChanInd                          = cell2mat( cellfun( @(x) find(strcmp(chanList, x)), discardChanNames, 'UniformOutput', false ) );
chanList(discardChanInd)                = [];
refChanInd                              = cell2mat( cellfun( @(x) find(strcmp(chanList, x)), refChanNames, 'UniformOutput', false ) );
nChan                                   = numel(chanList);

% collect event information: onset of flashes
onsetEventInd   = cellfun( @(x) strcmp(x, 'P300 stim on'), {pars.scenario.events(:).desc} );
onsetEventValue = pars.scenario.events( onsetEventInd ).id;
eventChan       = logical( bitand( statusChannel, onsetEventValue ) );
eventPos        = find( diff( eventChan ) == 1 ) + 1;
stimId          = pars.realP3StateSeqOnsets;
if numel( stimId ) ~= numel( eventPos ), error('different number of flashes read from the bdf and mat files'); end
eventLabel      = nan( size( stimId ) );
for iCue = 1:pars.nCues
    eventLabel( :, iCue ) = ismember( stimId( :, iCue ), pars.targetStim( iCue, : ) );
end
eventLabel = eventLabel(:);

% cuts limits and sizes in samples
nl      = round( tBeforeOnset*sampleRate );
nh      = round( tAfterOnset*sampleRate );
range   = nh+nl+1;


%%                        PREPROCESSING STEP
%==========================================================================

% discard unused channels and reference signals
sig(:, discardChanInd)  = [];
sig = bsxfun( @minus, sig, mean( sig(:,refChanInd) , 2 ) );

% filter the EEG signals
[filtPar.a, filtPar.b] = butter( filtPar.order, [filtPar.lowMargin filtPar.highMargin] / (sampleRate/2) );
for i = 1:size(sig, 2)
    sig(:,i) = filtfilt( filtPar.a, filtPar.b, sig(:,i) );
end

% remove the mean from the EEG signals (probably not necessary)
sig = bsxfun( @minus, sig, mean(sig, 1) );

% reorder channels from frontal to occipital (for nicer plots)
[sig, chanList] = reorderEEGChannels(sig, chanList);


%%                          MEAN CUT DATA
%==========================================================================
% get mean target cuts
targetEventPos = eventPos( eventLabel==1 );
meanTargetCut = zeros( range, nChan );
for iEv = 1:numel(targetEventPos)
    if tBeforeOnset == 0
        baseline = zeros(1, nChan);
    else
        baseline = mean( sig( (targetEventPos(iEv)-nl) : (targetEventPos(iEv)-1), : ), 1);
    end
    meanTargetCut = meanTargetCut + bsxfun(@minus, sig( (targetEventPos(iEv)-nl) : (targetEventPos(iEv)+nh), : ), baseline);
end
meanTargetCut = meanTargetCut / numel(targetEventPos);

% get non-target cuts
nonTargetEventPos = eventPos( eventLabel==0 );
meanNonTargetCut = zeros( range, nChan );
for iEv = 1:numel(nonTargetEventPos)
    if tBeforeOnset == 0
        baseline = zeros(1, nChan);
    else
        baseline = mean( sig( (nonTargetEventPos(iEv)-nl) : (nonTargetEventPos(iEv)-1), : ), 1);
    end
    meanNonTargetCut = meanNonTargetCut + bsxfun(@minus, sig( (nonTargetEventPos(iEv)-nl) : (nonTargetEventPos(iEv)+nh), : ), baseline);
end
meanNonTargetCut    = meanNonTargetCut / numel(nonTargetEventPos);


%%                    PLOT CONTINUOUS AND CUT DATA
%==========================================================================

plotEEGChannels( sig ...
    , 'eventLoc', eventPos ...
    , 'eventType', eventLabel ...
    , 'samplingRate', sampleRate ...
    , 'chanLabels', chanList ...
    );


plotERPsFromCutData2( {meanTargetCut, meanNonTargetCut} ...
    , 'samplingRate', sampleRate ...
    , 'chanLabels', chanList ...
    , 'timeBeforeOnset', tBeforeOnset ...
    , 'nMaxChanPerAx', 8 ...
    , 'axisOfEvent', [1 1] ...
    , 'legendStr', {'target', 'non-target'} ...
    , 'EventColors', [1 0 0 ; 0 0 0] ...
    );

end