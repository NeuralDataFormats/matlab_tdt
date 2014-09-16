function [spike_data,extras] = TDT_getSpikeData(c_or_tank_path,blockNr,snip_event,varargin)
%TDT_getSpikeData  Retrieves any of the following: spike times, snippets, sort codes
%
%   [spike_data,extras] = TDT_getSpikeData(c_or_tank_path,blockNr,snip_event,varargin)
%
%   INPUTS
%   ========================================================
%   c_or_tank_path  : see TDT_readTankBlockHeader
%   blockNr         : block number to retrieve data from
%   snip_event      : snip event to retrieve data from, to see
%
%   OPTIONAL INPUTS
%   ========================================================
%   channels   : (default: all available),
%   sorts_get  : (default: 'TankSort'), (string or cellstr) which sorts to retrieve
%   get_times  : (default: true), if false times are not returned
%   get_all_sorts: (default: false), if true, returns all sorts, sorts_get
%                   must not be specified (the default is ok)
%   get_waves  : (default: false), if true, returns waves
%   get_indices: (default: false), if true returns indices which can be
%                used for writing back sort codes back to a TDT sort code file
%   wave_scale_factor: (default: 1), amount to scale snippets by, this is
%                      very much dependent on the circuit ...
%
%   OUTPUTS
%   ========================================================
%   spike_data (structure array) with fields:
%       .ts         : timestamps of the each spike event
%       .sortCodes  :
%       .sameAsTankSort :
%       .chanID     : channel number
%       .snips      :
%       .idx        : this identifies each time stamp for reuploading sorts
%                     to TDT sort files
%
%   IMPORTANT: When retrieving all sorts the TankSort will always be first
%
%   extras (structure)
%       .sortCodesUsed : (cellstr), specifies sort codes returned in
%                        spike_data structure
%       .fs            : Sampling frequency of system (and snippets)
%
%   IMPLEMENTATION NOTES
%   =======================================================================
%   This function is rather simple until trying to filter based on sort
%   code outliers, which makes snippets and times dependent on sort code
%   files. I've tried to document the function well although it could still
%   probably use a little more attention ~ Jim
%
%   POSSIBLE ERRORS FROM USER INPUT REQUESTS
%   =========================================================
%   1) Requesting a sort code that doesn't exist
%   2) Specification of sort codes AND requesting all sort codes
%   3) Requesting not to include outliers with multiple sorts
%
%   EXAMPLES
%   =============================================================
%   1) Retrieval of all sort codes, extras tells you what sorts were read
%   [spikeData,extras] = TDT_getSpikeData(C,blockNr,'Snip','get_al_sorts',true);
%
%   2) Retrieval of snippets
%   spikeData = TDT_getSpikeData(C,blockNr,'Snip','get_waves',false);
%
%   3) Get sort indices & 'JoostSort'
%   spikeData = TDT_getSpikeData(C,blockNr,'Snip','get_indices',true,'sorts_get','JoostSort');
%
%   4) Getting 'JimSort' and 'JoostSort'
%   spikeData = TDT_getSpikeData(C,blockNr,'Snip','sorts_get',{'JimSort' 'JoostSort'});
%
%   IMPROVEMENT NOTES
%   =======================================================================
%   This function is a lot more complicated than it needs to be due to the
%   ability to filter the output based on the inclusion/exclusion of
%   outliers. Chris recommended that this not be supported as we basically
%   never request that outliers be excluded (and instead do that at a
%   later point). This would simplify this function ALOT.
%
%   See Also:
%   TDT_readTankBlockHeader
%   TDT_getSortNamesAvailable

%M_LINT MESSAGES
%#ok<*UNRCH>  %unreachable is ok
%#ok<*NASGU>  %not used is ok


DEFINE_CONSTANTS
channels         = [];
sorts_get        = 'TankSort';
get_times        = true;
get_all_sorts    = false;
get_waves        = false;
get_indices      = false;
wave_scale_factor = 1;
include_outliers = true; %NO LONGER USED
MIN_SKIP_SIZE = 500; %Important for reading snippets, see noTDT_Summary.m
%for a summary of file assumptions
END_DEFINE_CONSTANTS

if ~include_outliers
    error('This code no longer supports removal of outliers, please update your code accordingly')
end

if ischar(sorts_get)
    if isempty(sorts_get)
        sorts_get = {};
    else
        sorts_get = {sorts_get};
    end
end

DATA_RETRIEVAL_OPTIONS = struct(...
    'channels',             channels,...
    'sorts_get',            {sorts_get},...
    'get_times',            get_times,...
    'get_all_sorts',        get_all_sorts,...
    'get_waves',            get_waves,...
    'get_indices',          get_indices,...
    'wave_scale_factor',    wave_scale_factor);

%other variables of importance
OUTLIER_CODE  = 31;  %The value TDT uses for outliers


if nargin < 3
    error('Incorrect # of input arguments')
end

[tsq_struct,extrasHeader] = TDT_readTankBlockHeader(c_or_tank_path,blockNr);

%SNIP EVENT NAME HANDLING
%--------------------------------------------------------------------------
tsq_index  = find(strcmp(snip_event,extrasHeader.tsq_names),1);
if isempty(tsq_index)
    %Then no data was recorded, we return an empty structure
    %if the event existed (this is to match previous behavior)
    notes = extrasHeader.notes;
    if ~isfield(notes,snip_event)
        error('Specified event: "%s" was not recorded during this trial',snip_event)
    end
    snipNotes = notes.(snip_event);
    
    extras     = struct;
    extras.fs  = str2double(snipNotes.SampleFreq); %NOTE: Technically this isn't precise
    %because it is for display only ...
    
    if isempty(channels)
        channels = 1:str2double(snipNotes.NumChan);
    end
    %Could technically just assign all fields even though not requested ...
    spike_data = struct('chanID',num2cell(channels));
    
    if get_times
        [spike_data.ts] = deal(zeros(0,1));
    end
    
    if get_indices
        [spike_data.idx] = deal(zeros(0,1));
    end
    
    if get_waves
        [spike_data.snips] = deal(zeros(0,1,'single'));
    end
    
    %NOTE: Old behavior was if the sort requested didn't exist, just
    %return the tank sort ...
    if get_all_sorts || ~isempty(sorts_get)
        [spike_data.sortCodes] = deal(zeros(0,1,'int8'));
        [spike_data.sameAsTankSort] = deal(true);
        extras.sortCodesUsed = {'TankSort'};
    else
        extras.sortCodesUsed = {};
    end
    return
end
snipHeader = tsq_struct(tsq_index);
extras     = struct;
extras.fs  = snipHeader.fs;

assert(strcmpi(snipHeader.tdt_type,'Snip'),'Requested event type is not of type:Snip')

%SORT INPUT HANDLING
%--------------------------------------------------------------------------
[getSortCodes,sorts_to_use,sort_files] = ...
    getSortCodeFileInfo(c_or_tank_path,blockNr,snip_event,DATA_RETRIEVAL_OPTIONS);

%CHANNELS
%--------------------------------------------------------------------------
nChannelsAvailable = snipHeader.nChannels;
chanInfo = getChannels(nChannelsAvailable,DATA_RETRIEVAL_OPTIONS);
channels = chanInfo.channels;
nChannels = length(channels);

%GENERATING FILTER MATRIX, FILTER BASED ON OUTLIERS AND CHANNELS
%--------------------------------------------------------------------------
filterOutput = obtainFilterMask(chanInfo,snipHeader);

%chan_mask_I
%--------------------------------------------------------------------------
chanPresentMask = snipHeader.chanPresentMask;  %Indicates whether or not each channel has any events
chan_mask_I = cell(1,nChannels);
for iChan = 1:nChannels
    curChan = channels(iChan);
    if chanPresentMask(curChan)
        chan_mask_I{iChan} = strfind(filterOutput.channelIDs,curChan);
    end
end

%==========================================================================
%                       POPULATING OUTPUT
%==========================================================================
spike_data = struct('chanID',num2cell(channels));

%Retrieval of times
%----------------------------
if get_times
    if filterOutput.useMask
        timeStampsAll = snipHeader.timeStamps(filterOutput.mask_I);
    else
        timeStampsAll = snipHeader.timeStamps;
    end
    for iChan = 1:nChannels
        spike_data(iChan).ts = timeStampsAll(chan_mask_I{iChan});
    end
end

%Retrieval of indices
%--------------------------------------
if get_indices
    for iChan = 1:nChannels
        spike_data(iChan).idx = filterOutput.idxAll(chan_mask_I{iChan});
    end
end

%Retrieval of snippets
%--------------------------------------------------------------------------
if get_waves
    fStruct   = extrasHeader.fStruct;
    wave_file = fStruct.data_path;
    
    offsetWave = snipHeader.nByteOffsetToChunk;
    sizeWave   = snipHeader.nValuesAtChunk;
    
    if filterOutput.useMask
        offsetWave = offsetWave(filterOutput.mask_I);
        sizeWave   = sizeWave(filterOutput.mask_I);
    end
    
    fidR      = FileReader(wave_file,'rb');
    wavesTemp = buffered_fread2(fidR,offsetWave,sizeWave,filterOutput.channelIDs,...
        snipHeader.data_type,'pass_out_2d',true,'pass_out_raw',true,...
        'min_skip_size',MIN_SKIP_SIZE);
    
    if wave_scale_factor ~= 1
        wavesTemp = wavesTemp*wave_scale_factor;
    end
    for iChan = 1:nChannels
        spike_data(iChan).snips = wavesTemp(:,chan_mask_I{iChan});
    end
end

%Retrieval of sort codes
%--------------------------------------------------------------------------
if ~getSortCodes
    extras.sortCodesUsed = {};
else
    extras.sortCodesUsed = sorts_to_use;
    nSortFiles           = length(sort_files);
    [sortSameAsTankHeader,header_sorts] = readSortCodeFile(snipHeader,'',filterOutput.idxAll,...
        filterOutput.useMask,filterOutput.mask_I,channels);
    
    for iFile = 1:nSortFiles
        if isempty(sort_files{iFile})
            sortSameAsTank = sortSameAsTankHeader;
            sortCodesTemp  = header_sorts;
        else
        [sortSameAsTank,sortCodesTemp] = ...
            readSortCodeFile(snipHeader,sort_files{iFile},filterOutput.idxAll,...
            filterOutput.useMask,filterOutput.mask_I,channels);
        end
        
        if iFile == 1   %Initialization
            for iChan = 1:nChannels
                spike_data(iChan).sortCodes = zeros(length(chan_mask_I{iChan}),nSortFiles,'int8');
                spike_data(iChan).sameAsTankSort = true(1,nSortFiles);
            end
        end
        
        for iChan = 1:nChannels
            if ~isempty(chan_mask_I{iChan})
                if sortSameAsTank(iChan)
                    spike_data(iChan).sortCodes(:,iFile)    = header_sorts(chan_mask_I{iChan});
                else
                    spike_data(iChan).sortCodes(:,iFile)    = sortCodesTemp(chan_mask_I{iChan});
                end
                spike_data(iChan).sameAsTankSort(iFile) = sortSameAsTank(iChan);
            end
        end
    end
end

%REMAPPING OUTPUT TO MATCH INPUT
%-------------------------------------
if chanInfo.remapChannelsAtEnd
    spike_data = spike_data(chanInfo.channel_sort_I);
end

end

function filterOutput = obtainFilterMask(chanInfo,snipHeader)
%obtainFilterMask
%
%   filterOutput = ...
%       obtainFilterMask(chanInfo,snipHeader)
%
%   OUTPUTS
%   =========================================================
%   filterOutput (structure)
%       .maskI     - indices to keep from the header arrays
%       .useMask   - boolean, whether or not maskI is used
%       .idxAll - needed for returning indices & for reading from sort code files

channelIDs       = snipHeader.channelIDOfChunk;
channels         = chanInfo.channels;
allChansPresent  = chanInfo.allChansPresent;

if ~allChansPresent
    useMask = true;
    mask_I = find(ismembc(channelIDs,uint16(channels)));
else
    useMask = false;
    mask_I  = [];
end

if useMask
    channelIDs = channelIDs(mask_I);
end

if useMask
    idxAll = snipHeader.sortCodeIndex(mask_I);
else
    idxAll = snipHeader.sortCodeIndex;
end

filterOutput = struct(...
    'channelIDs',channelIDs,...
    'idxAll',idxAll,...
    'mask_I',mask_I,...
    'useMask',useMask);


end


function [sortSameAsTank,sortCodesTemp] = readSortCodeFile(snipHeader,curSortFile,idxAll,useMask,mask_I,channels)
%readSortCodeFile
%
%   [sortSameAsTank,sortCodesTemp] = ...
%       readSortCodeFile(snipHeader,curSortFile,idxAll,useMask,mask_I)
%
%   INPUTS
%   ====================================================
%   snipHeader  :
%   curSortFile :
%   idxAll      :
%   useMask     :
%   maskI       :
%
%   OUTPUTS
%   ====================================================
%   sortSameAsTank :
%   sortCodesTemp  :
%

if isempty(curSortFile) %Use default
    if useMask
        sortCodesTemp = snipHeader.sortCodes(mask_I);
    else
        sortCodesTemp = snipHeader.sortCodes;
    end
    sortSameAsTank = true(1,length(channels));
else
    %Read from file
    fid          = fopen(curSortFile,'rb');
    tempFileData = fread(fid,idxAll(end),'*uint8');
    fclose(fid);
    sortCodesTemp = tempFileData(idxAll);
    chanSorted    = tempFileData(2:1025);
    sortSameAsTank = ~logical(chanSorted(channels));
end

end


function chanInfo = getChannels(nChannelsAvailable,DATA_RETRIEVAL_OPTIONS)
%getChannels
%
%   chanInfo = getChannels(nChannelsAvailable,DATA_RETRIEVAL_OPTIONS)
%
%   OUTPUT
%   ====================================================
%   chanInfo : (structure)
%       .allChansPresent    - whether or not all channels available were requested
%       .remapChannelsAtEnd - whether or not to reshuffle outputs at end
%       .channel_sort_I     - array to use for remapping channels
%       .channels           - channels to retrieve (sorted)



channels = DATA_RETRIEVAL_OPTIONS.channels;

channel_sort_I     = [];
allChansPresent    = false;
remapChannelsAtEnd = false;
if isempty(channels)
    %This is processing the default input
    channels        = 1:nChannelsAvailable;
    allChansPresent = true;
else
    if ~issorted(channels)
        temp_channels = sort(channels);
        [~,channel_sort_I] = ismember(channels,temp_channels);
        channels = temp_channels;
        remapChannelsAtEnd = true;
    end
    if isequal(channels,1:nChannelsAvailable)
        allChansPresent = true;
    elseif any(channels < 1 | channels > nChannelsAvailable)
        error('At least one channel is out of range')
    end
end

chanInfo = struct(...
    'allChansPresent',allChansPresent,...
    'remapChannelsAtEnd',remapChannelsAtEnd,...
    'channel_sort_I',channel_sort_I,...
    'channels',uint16(channels));

end

function [getSortCodes,sorts_to_use,sort_files] = ...
    getSortCodeFileInfo(c_or_tank_path,blockNr,snip_event,DATA_RETRIEVAL_OPTIONS)
%getSortCodeFileInfo
%
%   OUTPUTS
%   =======================================
%   getSortCodes: Boolean on whether or not to retrieve sort codes
%   sorts_to_use: (cellstr) name of sorts to retrieve
%   sort_files: (cellstr), paths to files, the path for the default
%               sort code is empty
%
%   See Also:
%       TDT_getSortNamesAvailable
%       errorCheckSortCodeRequest
%       readSortCodeFile

[all_sort_names,sort_name_extras] = ...
    TDT_getSortNamesAvailable(c_or_tank_path,blockNr,snip_event);

errorCheckSortCodeRequest(all_sort_names,sort_name_extras,DATA_RETRIEVAL_OPTIONS)

sorts_get     = DATA_RETRIEVAL_OPTIONS.sorts_get;
get_all_sorts = DATA_RETRIEVAL_OPTIONS.get_all_sorts;

%Population of "sort_files" and "sorts_to_use"
%--------------------------------------------------------------------------
getSortCodes = true; %Whether or not we will be reading any sort codes
if get_all_sorts
    sorts_to_use = all_sort_names;
    sort_files   = sort_name_extras.sort_paths;
elseif ~isempty(sorts_get)
    sorts_to_use = sorts_get;
    
    %retrieval of the sort file for each sort
    sort_files = cell(1,length(sorts_to_use));
    for iSort = 1:length(sort_files)
        curFileI = find(strcmp(sorts_get{iSort},all_sort_names),1);
        %This error should never occur ...
        if isempty(curFileI)
            error('Unable to find path match for requested sort ...')
        end
        sort_files(iSort) = sort_name_extras.sort_paths(curFileI);
    end
else
    sorts_to_use = {};
    sort_files   = {};
    getSortCodes = false;
end

end

function errorCheckSortCodeRequest(all_sort_names,sort_name_extras,DATA_RETRIEVAL_OPTIONS)
%errorCheckSortCodeRequest

sorts_get     = DATA_RETRIEVAL_OPTIONS.sorts_get;
get_all_sorts = DATA_RETRIEVAL_OPTIONS.get_all_sorts;

%Some error checking ...
mask = ismember(sorts_get,all_sort_names);
if ~isempty(sorts_get) && any(~mask)
    error('Requested sort codes {''%s''} doesn''t exist',cellArrayToString(sorts_get(~mask),''','''));
end

isDefaultOnly = length(sorts_get) == 1 && strcmp(sorts_get,sort_name_extras.DEFAULT_SORT);
if get_all_sorts && ~(isempty(sorts_get) || isDefaultOnly)
    error('Sort names can not be specified if "get_all_sorts" is true')
end




end
