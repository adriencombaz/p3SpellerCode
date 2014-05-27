function trainSVM

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
refChanNames        = {'EXG1', 'EXG2'};
classifChanNames    = {'Fz', 'Cz', 'P3', 'Pz', 'P4', 'PO3', 'PO4', 'O1', 'Oz', 'O2'};
tBeforeOnset        = 0.2; % lower time range in secs - for baseline correction (if 0 no baseine correction)
tAfterOnset         = 0.8; % upper time range in secs
filtLowMargin       = .5;
filtHighMargin      = 20;
filtOrder           = 3;
DSFactor            = 2;
iAve                = 10;
changeClassChan     = false;


%%                      LOAD RELEVANT DATA
%==========================================================================

% load EEG data (bdf file)
[FileName, PathName]    = uigetfile( fullfile( dataDir, '*.bdf' ), 'Select the bdf data file' );
bdfFilename             = fullfile( PathName, FileName );
hdr                     = sopen( bdfFilename );
[sig, hdr]              = sread(hdr);
fclose(hdr.FILE.FID);
statusChannel           = bitand(hdr.BDF.ANNONS, 255);
hdr.BDF                 = rmfield(hdr.BDF, 'ANNONS'); % just saving up some space...
sampleRate              = hdr.SampleRate;
chanList                = hdr.Label;
chanList(strcmp(chanList, 'Status')) = [];

% load experiment parameters (mat file)
pars = load( [bdfFilename(1:end-3) 'mat'] );

% pars.stimuli = rmfield( pars.stimuli, 'dimmed_symbols' );
% pars.stimuli = rmfield( pars.stimuli, 'intense_symbols' );
pars.stimuli = rmfield( pars.stimuli, 'textures' );
pars.scenario = rmfield( pars.scenario, 'textures' );


%%                          USER INPUT
%==========================================================================
minSampleRate       = 32;
maxDSfactor         = round( log2( sampleRate/minSampleRate ) );
dsFactList          = 2.^(0:1:maxDSfactor);
sampleRateList      = sampleRate ./ dsFactList;
sampleRateListStr   = cellfun( @num2str, num2cell( sampleRateList ),'UniformOutput', false );
newSampleRate       = num2str( sampleRate/DSFactor );
parameterList       = {
    'Number of averages',                           num2cell( pars.nRepetitions:-1:1 ),	'iAve'
    'Baseline Duration (s)',                        tBeforeOnset,                       'tBeforeOnset'
    'Epoch duration (s) ',                          tAfterOnset,                        'tAfterOnset'
    'Filter low margin (Hz)',                       filtLowMargin,                      'filtLowMargin' 
    'Filter high margin (Hz)',                      filtHighMargin,                     'filtHighMargin' 
    'Filter order',                                 filtOrder,                          'filtOrder' 
    'new sampel rate (Hz)',                         sampleRateListStr,                  'newSampleRate' 
    'change default channels for calssification',   changeClassChan,                    'changeClassChan'
    };

prefGroupName = 'p3SpellerSvmTrain';

parsGifg = getItFromGUI( ...
    parameterList(:,1)', ...    list of parameter descriptions (cell array of strings)
    parameterList(:,2)', ...    list of default values for each parameter
    parameterList(:,3)', ...    list of variables to update
    prefGroupName, ...          name of preference group (to save parameter values for the next Round)
    sprintf( 'Input parameters of %s', prefGroupName ) ...
    );

if isempty( parsGifg ),
    return
end

iAve                = str2double(iAve);
filtPar.lowMargin   = filtLowMargin;
filtPar.highMargin  = filtHighMargin;
filtPar.order       = filtOrder;
newSampleRate       = str2double(newSampleRate);
DSFactor            = dsFactList(sampleRateList==newSampleRate);

if changeClassChan
    indClassChan        = chanSelectionGUI( chanList, ismember(chanList, classifChanNames) ); %#ok<UNRCH>
    classifChanNames    = chanList(indClassChan);
end
% str     = textscan( num2str( pars.nRepetitions:-1:1 ), '%s' );
% str     = str{1}';
% [s, ~]  = listdlg( 'PromptString','Select the number of averages:', 'SelectionMode', 'single', 'ListSize', [200, 20*pars.nRepetitions], 'ListString', str );
% iAve    = str2double( str{s} );


%%               INITIALIZE OUTPUT FOLDER AND FILE NAME
%==========================================================================
classDir = fullfile( PathName, 'classifiers', FileName(1:end-4) );
if ~exist( classDir, 'dir' )
    mkdir( classDir );
end
classFilename = sprintf( 'linSVM_%.2dAverages.mat', iAve );


%%                      INITIALIZE DATA INFO
%==========================================================================

% List of channels
classifChanInd                          = cell2mat( cellfun( @(x) find(strcmp(chanList, x)), classifChanNames, 'UniformOutput', false ) );
refChanInd                              = cell2mat( cellfun( @(x) find(strcmp(chanList, x)), refChanNames, 'UniformOutput', false ) );
nChan                                   = numel(classifChanNames);

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
nl          = round( tBeforeOnset*sampleRate );
nh          = round( tAfterOnset*sampleRate );
range       = nh+1;
nBins       = floor( range / DSFactor );

%%                        PREPROCESSING STEP
%==========================================================================

% discard unused channels and reference signals
refSig  = sig(:,refChanInd);
sig     = sig(:, classifChanInd);
sig     = bsxfun( @minus, sig, mean( refSig , 2 ) );

% filter the EEG signals
[filtPar.a, filtPar.b] = butter( filtPar.order, [filtPar.lowMargin filtPar.highMargin] / (sampleRate/2) );
for i = 1:size(sig, 2)
    sig(:,i) = filtfilt( filtPar.a, filtPar.b, sig(:,i) );
end

% remove the mean from the EEG signals (probably not necessary)
sig = bsxfun( @minus, sig, mean(sig, 1) );


%%                  CUT AND DOWNSAMPLE DATA
%==========================================================================
nEv  = numel( eventPos );
cuts = zeros( nBins, nChan, nEv );
for iEv = 1:nEv
    if tBeforeOnset == 0
        baseline = zeros(1, nChan);
    else
        baseline = mean( sig( (eventPos(iEv)-nl) : (eventPos(iEv)-1), : ), 1);
    end
    temp            = mean( reshape( sig( eventPos(iEv) : (eventPos(iEv)+nBins*DSFactor-1), : ), DSFactor, nBins*nChan ), 1 );
    temp            = reshape( temp, nBins, nChan );
    cuts(:, :, iEv) = bsxfun(@minus, temp, baseline);
    
%     test = bsxfun(@minus, sig( eventPos(iEv) : (eventPos(iEv)+nh), : ), baseline);
%     test2 = zeros(nBins, nChan);
%     for iBin = 1:nBins
%         test2(iBin, :) = mean( test((iBin-1)*DSFactor+1:iBin*DSFactor, :), 1 );
%     end
%     test1 = cuts(:, :, iEv);
%     if ~isequal( test1, test2 ), error('something wrong with the downsampling/cutting!'); end
    
end


%%                          GET FEATURES
%==========================================================================

% select/balance/average trials w.r.t. the desired number of repetitions
%------------------------------------------------------------------------------
nT_train    = 1000;
nNT_train   = 1000;
featTrain_T = zeros( nT_train, nBins*nChan ); %, 'single' );
featTrain_NT= zeros( nNT_train, nBins*nChan ); %, 'single' );

indTargetEvents = find( eventLabel == 1 );
for iT = 1:nT_train
    selection           = randperm( numel(indTargetEvents) );
    selection           = selection(1:iAve);
    temp                = mean( cuts( :, :, indTargetEvents(selection) ), 3 );
    featTrain_T(iT,:)   = temp(:)';
end

indNonTargetEvents = find( eventLabel == 0 );
for iNT = 1:nNT_train
    selection           = randperm( numel(indNonTargetEvents) );
    selection           = selection(1:iAve);
    temp                = mean( cuts( :, :, indNonTargetEvents(selection) ), 3 );
    featTrain_NT(iNT,:) = temp(:)';
end


% normalization
%------------------------------------------------------------------------------
Xtrain = [featTrain_T ; featTrain_NT];
Ytrain = [ones(nT_train,1); -ones(nNT_train,1)];
clear featTrain_T featTrain_NT

maxx    = max(Xtrain);
minx    = min(Xtrain);
Xtrain  = bsxfun(@minus, Xtrain, minx);
Xtrain  = bsxfun(@rdivide, Xtrain, maxx-minx);


%%                          TRAIN THE SVM
%==========================================================================
igam        = 1;                    % Central value of the regularization paramter for the first line search
nfolds      = 10;       %#ok<NASGU> % Number of subsets for the cross-validation
B_init      = [];
error_type  = 1;        %#ok<NASGU> % 1: calculate mean square error on misclassified data
                                    % 2: calculate mean square error on active data (data that are not beyond the margin...even if correctly classified)

ntrain      = size(Xtrain,1);
Xtrain      = [Xtrain ones(ntrain,1)];

[B_init, ~] = Lin_SVM_Keerthi( Xtrain, Ytrain, B_init, igam );
linesearch_algo;
best_gamma  = exp(Xm);
[B, ~]      = Lin_SVM_Keerthi( Xtrain, Ytrain, B_init, best_gamma ); %#ok<ASGLU>


%%                          SAVING DATA
%==========================================================================
varsToSave = { ...
    'iAve' ...
    , 'refChanNames' ...
    , 'classifChanNames' ...
    , 'refChanInd' ...
    , 'classifChanInd' ...
    , 'tBeforeOnset' ...
    , 'tAfterOnset' ...
    , 'filtPar' ...
    , 'DSFactor' ...
    , 'bdfFilename' ...
    , 'pars' ...
    , 'sampleRate' ...
    , 'nT_train' ...
    , 'nNT_train' ...
    , 'Xtrain' ...
    , 'Ytrain' ...
    , 'maxx' ...
    , 'minx' ...
    , 'nfolds' ...
    , 'error_type' ...
    , 'B' ...
    };

save( fullfile( classDir, classFilename ), varsToSave{:} );

end




