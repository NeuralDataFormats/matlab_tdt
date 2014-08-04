function initializeObject(obj,notes)

% OUTPUTS
% =========================================================================
% tsq_struct - (structure array) OR (false) OR (structure)
%   .name       : name of the event
%   .nChannels  : # of channels (for things with data)
%   .tdt_type   : TDT's data type, Snip, Stream, etc
%   .data_type  : class of data (Matlab style), 'int8', 'single', etc
%   .fs         : Accurate sampling frequency
%   .timeStamps : time stamps in seconds since start of block
%   .values     : values associated with each timestamp (events only, not snips)
%   .nValuesAtChunk     : # of values to read at each data chunk
%   .nByteOffsetToChunk : # of bytes to skip before reading data chunk
%   .channelIDOfChunk   : Channel ID of all data at a particular data chunk
%   .sortCodes          : Sort code values for 'TankSort'
%   .sortCodeIndex      : index of the snip events for reading sort code files
%   .chanPresentMask    : whether or not a snip channel has data
%
% extras - (structure)
%   .special_events     : same format as tsq_struct entries but for special
%                         TDT events (known entries, 0001 -> length of file, 0002 -> start time
%                         0003 -> end time
%   .tsq_names          : SAME AS {tsq_struct.name}
%   .fStruct            : first output from TDT_getBlockFiles
%   .startTime          : start time of block in unix time
%   .endTime            : end time "                "
%   .tdt_types          : SAME AS {tsq_struct.tdt_type}
%   .notes              : output from TDT_getNotes
%   .nChunks            :
%
%
%   EXAMPLE: tsq_struct(#)
%                   name: 'eNeu'
%              nChannels: 100
%               tdt_type: 'Snip'
%              data_type: 'single'
%                     fs: 2.4414e+004
%             timeStamps: [1x145023 double]
%                 values: []
%         nValuesAtChunk: [1x145023 uint32]
%     nByteOffsetToChunk: [1x145023 int64]
%       channelIDOfChunk: [1x145023 uint16]
%              sortCodes: [1x145023 uint16]
%          sortCodeIndex: [1x145023 double]
%        chanPresentMask: [1x100 logical]
%
%   EXAMPLE USAGE
%   =======================================================================
%   [C,C2]  = setupConvPathForCat('Fruity');
%   blockNr = 12;
%   [tsq_struct,extras] = TDT_readTankBlockHeader(C,blockNr)
%
%   See Also:
%   TDT_getBlockFiles
%   TDT_eventTypeToString
%   TDT_getNotes


%CONSTANTS
%==========================================================================
ADDL_SORT_CODE_OFFSET = 1023; %amount to correct for sort codes
% -2 => where is this coming from?????,
% +1 => for a null at the beginning of the sort file
% +1024 => channel specification in sort code file, sorted or not
%
%   Index - 0 based
%   0 -> 1025 NOPE
%   1 -> 1025 NOPE
%   


%DATA_TYPES = uint32(0:4);  %NOTE: 0 based indexing, we'll take the value
%from the file and add 1 later
DATA_NAMES      = {'single' 'uint32' 'int16' 'int8' 'double'};
SIZE_SC_FACTOR  = {1        1         2      4      0.5};

WORDS_PER_ENTRY = 10; %See format in TDT\private\TDT_format_notes

%READING THE FILE
%=========================================================
fid = fopen(obj.file_path,'r');
%Assumption: header is small, so read the entire thing
words = fread(fid,[WORDS_PER_ENTRY inf],'*uint32');
fclose(fid);

%WTF, FOUND ONE WITH ONE EVENT AFTERWARDS
%TODO: replace 2 with event name
if words(3,end-1) == 2
    words(:,end) = [];
end

evNameValues = words(3,:);
xs = sort(evNameValues);
n  = find(diff(xs) ~= 0);
uniqueEvNameValues = [xs(1) xs(n+1)];

%I went to assuming this format to avoid some other code
%Notably the "I" output from unique for getting the
%starting timestamp before looping
%first chunk  -> 0000 - size  - value specifies length
%second chunk -> 0001 - start - time specifies start time
%last chunk   -> 0002 - end   - time specifies end time
if words(3,1) ~= 0 || words(3,2) ~= 1
    startWordIndex = find(words(3,:) == 1);
    if isempty(startWordIndex)
        error('Start word index not found')
    elseif length(startWordIndex) > 1
        error('Multiple start word indices found')
    end
    
    fileSizeWord = find(words(3,:) == 0);
    if length(fileSizeWord) ~= 1
        error('Invalid assumption on TDT header format')
    end
else
startWordIndex = 2;    
end



%NOTE: I've run across one file that only had 2 words, 0 and something else
%so the above error was thrown, we should probably just work around that
%and throw a warning ..., the trial itself is marked as an error in the
%constants file

fixEndTime = false;
if words(3,end) ~= 2
    if any(uniqueEvNameValues == 2)
        error('Violation of assumption on format')
    else
        fixEndTime = true;
    end
end

%We move everything into a cell array, could keep as a character matrix
%since everything is 4 characters
evNames = cellfun(@(x) char(typecast(x,'uint8')),num2cell(uniqueEvNameValues),'UniformOutput',false);

%SPECIAL EVENTS HANDLING
%===========================================================
remaining_names = evNames;
if fixEndTime
    remaining_names(1:2) = [];  
else
    remaining_names(1:3) = [];
end

if ~all(cellfun(@(x) all(isstrprop(x,'alphanum') | x == '_'),remaining_names))
    error('One of the remaining TDT event names has a non-alpha numeric char.')
end

startTime = typecast(words(5:6,startWordIndex),'double'); %needed for correct timestamps

n_events = length(evNames);
temp = struct(...
    'name',         evNames,...
    'nChannels',    0,...
    'tdt_type',     [],...
    'data_type',    [],...
    'fs',           [],...
    'timeStamps',   [],...
    'values',       [],...
    'nValuesAtChunk',[],...
    'nByteOffsetToChunk', [],...
    'channelIDOfChunk',[],...
    'sortCodes',      [],...
    'sortCodeIndex',  [],...
    'chanPresentMask',[]);

%'channels',     [],...  %Do we want to do some more preprocessing? -> yes
%    'sort_code',    [],...




for iEvent = 1:n_events
    curNameValue = uniqueEvNameValues(iEvent);
    mask_I       = strfind(evNameValues,curNameValue);
    
    %2  - Type
    %9  - Data Foramt
    %10 - Fs
    tempType               = tdt.eventTypeToString(words(2,mask_I(1)));
    temp(iEvent).tdt_type  = tempType{1};
    temp(iEvent).data_type = DATA_NAMES{words(9,mask_I(1))+1}; %they use 0 based, switching to 1 based
    temp(iEvent).fs        = typecast(words(10,mask_I(1)),'single');
    switch temp(iEvent).tdt_type
        case {'Unknown' 'Mark' 'Strobe+' 'Strobe-' 'Scalar'}
            %time stamps
            timeStamps = words(5:6,mask_I); %two lines to allow correct orientation
            temp(iEvent).timeStamps = typecast(timeStamps(:),'double')' - startTime;
            
            %values
            valueAll = words(7:8,mask_I);
            temp(iEvent).values = typecast(valueAll(:),'double')';
            
        case {'Stream' 'Snip' 'HasData'}
            curEventName = temp(iEvent).name; %Needed for channel setup
            
            temp(iEvent).nChannels = str2double(notes.(curEventName).NumChan);
            
            %size
            temp(iEvent).nValuesAtChunk = (words(1,mask_I) - WORDS_PER_ENTRY)*SIZE_SC_FACTOR{words(9,mask_I(1))+1} ; %Size includes this header
            
            %offset
            tempOffset = words(7:8,mask_I);
            temp(iEvent).nByteOffsetToChunk = typecast(tempOffset(:),'int64')';
            
            %Break into channel (low -> odd) & sort code (high, even)
            tempChansAndSorts      = typecast(words(4,mask_I),'uint16'); %from uint32
            temp(iEvent).channelIDOfChunk   = tempChansAndSorts(1:2:end);
            
            if strcmpi(temp(iEvent).tdt_type,'snip')
                tempSorts      = tempChansAndSorts(2:2:end);
                tempTimeStamps = words(5:6,mask_I);
                temp(iEvent).timeStamps    = typecast(tempTimeStamps(:),'double')' - startTime;
                temp(iEvent).sortCodes     = tempSorts;
                temp(iEvent).sortCodeIndex = mask_I + ADDL_SORT_CODE_OFFSET;
                
                nChannels   = temp(iEvent).nChannels;
                chanPresent = ismembc(uint16(1:nChannels),sort(temp(iEvent).channelIDOfChunk));
                temp(iEvent).chanPresentMask = chanPresent;
            end
    end
    
end


tsq_struct = temp;

n_stores = length(tsq_struct);
all_stores_ca = cell(1,n_stores);

for iStore = 1:n_stores
   all_stores_ca{iStore} = tdt.block.store_info(tsq_struct(iStore)); 
end

all_stores = [all_stores_ca{:}];

%removal of special events and specification of end time
%What a hack :/
if fixEndTime
    error('This part was not translated yet')
    [~,tankName] = fileparts(fStruct.tank_path);
    formattedWarning('End time missing for %s, block %d',tankName,blockNr);
    
    obj.special_events = tsq_struct(1:2);
    tsq_struct(1:2) = [];
    
    maxTime = 0;
    for iEvent = 1:length(tsq_struct)
        curEntry = tsq_struct(iEvent);
        if ~isempty(curEntry.timeStamps)
            if maxTime < curEntry.timeStamps(end)
                maxTime = curEntry.timeStamps(end);
            end
        elseif ~isempty(curEntry.nValuesAtChunk)
            %NOTE: We don't check that channels are even here ...
            samplesPerChan = floor(sum(curEntry.nValuesAtChunk)/curEntry.nChannels);
            tempMax = (samplesPerChan-1)/curEntry.fs;
            if maxTime < tempMax
                maxTime = tempMax;
            end
        end
    end
    endTime = maxTime;
else
    endTime   = typecast(words(5:6,end),'double');
    obj.special_events = all_stores(1:3);
    all_stores(1:3) = [];
end

%Specification of the other extras
obj.stores           = all_stores;
obj.store_names      = {all_stores.name};
obj.start_time       = startTime;
obj.end_time         = endTime;
obj.tdt_data_types   = {tsq_struct.tdt_type};
obj.n_chunks         = size(words,2);
obj.incomplete_block = fixEndTime;


end