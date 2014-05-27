classdef biosemiLabelChannel < handle
   
    %----------------------------------------------------------------------------
    properties ( SetAccess = 'protected' )
        currentLabel        = 0;
        iCurrentLabel       = 1;
        listLabels          = [];
        sizeListLabels      = 10000; % default value
        sendLptMarkers      = false;
        sendSerialMarkers   = false; % does the driver actually use serial port to send markers        
        serialPortName      = 'COM1';
        serialPort          = [];
        isSerialPortOpened  = false;
        isOpened            = false;        
        lptAddress          = 0;
    end % of public-read/protected-write properties section
    
    properties ( Constant )
        allowedParameterList    = { 'sizeListLabels' , 'sendLptMarkers', 'sendSerialMarkers', 'serialPortName' };
        DEFAULT_LIST_VALUES     = -256;
        DEFAULT_MARKER_ID       = 0;
    end % of constant properties section
    

    %----------------------------------------------------------------------------    
    methods
        
        %-----------------------------------------------
        function obj = biosemiLabelChannel( varargin )
            obj.currentLabel = 0;
            parseInputParameters( obj, varargin{:} );
            obj.listLabels   = obj.DEFAULT_LIST_VALUES * ones(2, obj.sizeListLabels);
            if obj.sendLptMarkers
                obj.initLptCommunication;
            end
            if obj.sendSerialMarkers
                obj.initSerialCommunication();
            end
            obj.isOpened = true;
            
            logThis( 'Biosemi label channel object created' );
        end % of constructor BIOSEMILABELCHANNEL
        
        %-----------------------------------------------
        function markEvent( obj, markerId, timeStamp )
            if nargin < 3,
                timeStamp = GetSecs();
            end
            markers             = sum(unique(markerId));
            obj.currentLabel    = obj.currentLabel + markers;          
            if obj.sendLptMarkers
                if obj.currentLabel >= 0 && obj.currentLabel < 256
                    lptwrite(obj.lptAddress, obj.currentLabel);
                else
                    logThis( 'Out of range event values (not sent to lpt port)' );
                end 
            end
            
            % Try to send marker (encoded by statusValue) via serial port (if necessary)
            if( obj.sendSerialMarkers && obj.isSerialPortOpened && obj.currentLabel >= 0 && obj.currentLabel < 128 ), % !!!!!!!!!!
                % Here timestamps are completely neglected
                fprintf( obj.serialPort, '%c', obj.currentLabel );
                logThis( 'Just sent a marker (%d) to serial port (%s)', obj.currentLabel, obj.serialPortName );
            end % of "send marker via serial port" branch
            
            obj.listLabels(:,obj.iCurrentLabel) = [ timeStamp ; obj.currentLabel ];
            obj.iCurrentLabel = obj.iCurrentLabel + 1;
        end % of MARKEVENT method

        %-----------------------------------------------
        function labelList = getListLabels( obj )
            labelList = obj.listLabels;
            labelList( : , labelList(2,:) == obj.DEFAULT_LIST_VALUES ) = [];
        end   
        
        %-----------------------------------------------
        function initLptCommunication( obj )
            obj.sendLptMarkers = true;
            obj.lptAddress      = getLPTportIOAddress;
            lptwrite( obj.lptAddress, obj.DEFAULT_MARKER_ID );
        end
        
        %-----------------------------------------------
        function initSerialCommunication( obj )
            logThis( 'Initializing serial port communication...' );
%             obj.sendSerialMarkers = true;
            if( obj.sendSerialMarkers && ~isempty( obj.serialPortName ) ),
                if( obj.isSerialPortOpened ),
                    logThis( 'Closing serial port' );
                    fclose( obj.serialPort );
                end
                logThis( 'Opening serial port (%s)...', obj.serialPortName );
                obj.serialPort = serial( obj.serialPortName ); %#ok<TNMLP>
                fopen( obj.serialPort );
                obj.isSerialPortOpened = true;
            end            
        end
        
        %-----------------------------------------------
        function close( obj )
            if( obj.isOpened ),
                logThis( 'Closing the EEG-Device' );
                if( obj.isSerialPortOpened ),
                    logThis( 'Closing serial port' );
                    fclose( obj.serialPort );
                end                
                obj.isOpened = false;
            end % of if(isOpened) operator
        end % of CLOSE method
        
        %-----------------------------------------------
        function parseInputParameters( obj, varargin )
            iArg = 1;
            nParameters = numel( varargin );
            while ( iArg <= nParameters ),
                parameterName = varargin{iArg};
                if (iArg < nParameters),
                    parameterValue = varargin{iArg+1};
                else
                    parameterValue = [];
                end
                iParameter = find( strncmpi( parameterName, obj.allowedParameterList, numel( parameterName ) ) );
                if isempty( iParameter ),
                    error( 'biosemiLabelChannel:parseInputParameters:UnknownParameterName', ...
                        'Unknown parameter name: %s.', parameterName );
                elseif numel( iParameter ) > 1,
                    error( 'biosemiLabelChannel:parseInputParameters:AmbiguousParameterName', ...
                        'Ambiguous parameter name: %s.', parameterName );
                else
                    switch( iParameter ),
                        case 1,  % sizeListLabels
                            if isnumeric( parameterValue ) && isfinite( parameterValue ) && (parameterValue > 0),
                                obj.sizeListLabels = parameterValue;
                            else
                                error('biosemiLabelChannel:parseInputParameters:BadSizeListLabels', ...
                                    'Wrong or missing value for sizeListLabels parameter.');
                            end
                        case 2,  % sendLptMarkers
                            if parameterValue == 0 || parameterValue== 1,
                                obj.sendLptMarkers = parameterValue;
                            else
                                error('biosemiLabelChannel:parseInputParameters:BadSendLptMarkers', ...
                                    'Wrong or missing value for sendLptMarkers parameter.');
                            end
                        case 3,  % sendSerialMarkers
                            if parameterValue == 0 || parameterValue== 1,
                                obj.sendSerialMarkers = parameterValue;
                            else
                                error('biosemiLabelChannel:parseInputParameters:BadSendSerialMarkers', ...
                                    'Wrong or missing value for sendSerialMarkers parameter.');
                            end
                        case 4,  % serialPortName
                            if( ~isempty( parameterValue ) && ischar( parameterValue ) ),
                                obj.serialPortName = parameterValue;
                            else
                                error('biosemiLabelChannel:parseInputParameters:BadSerialPortName', ...
                                    'Wrong or missing value for serialPortName parameter.');
                            end
                            
                    end % of iParameter switch
                end % of unique acceptable iParameter found branch
                
                if isempty( parameterValue  ),
                    iArg = iArg + 1;
                else
                    iArg = iArg + 2;
                end
                
            end % of parameter loop
        end % of function parseInputParameters
        
        
        
    end % of methods section 
end % of BIOSEMILABELCHANNEL class definition
