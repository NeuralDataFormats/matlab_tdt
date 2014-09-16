function TDT_saveSortCodes(c_or_tank_path,blockNr_or_trialObj, snip_event, sortName, sortIDs, channels, varargin)
%TDT_saveSortCodes  Saves a set of sort codes to the tank
%
%   TDT_saveSortCodes(c_or_tank_path,blockNr_or_trialObj, snip_event, sortName, sortIDs, channels, varargin)
%
%   CAVEATS
%   =========================================================================
%   - All sort ids must be entered, including outliers, unless indices are
%       specified via the optional input
%   - If a sortName already exists a warning is display unless disabled
%   (see varargin). 'TankSort' may never be overwritten
%
% INPUTS
% =========================================================================
%  c_or_tank_path  : see TDT_readTankBlockHeader
%  blockNr_or_trialObj : block number or trial object, must be the trial
%                        object when 'save_to_db' is true
%                        NOTE: trialObj = getDBObj('trial',Cat_Name,blockNr);
%  snip_event : (char), name of the snip event
%  sortName   : (char) name to give the new sort code
%  sortIDs    : (cell) values (see below) for the sort codes
%  channels   : (numeric array) channels to assign sort ids to
%
% SORT IDS
% =========================================================================
%  As defined by the TDT software:
%  ----------------------------------
%  0: unsorted/multiunit
%  0 > & < 31: spikes sort code ids (# is generally arbitrary, sometimes
%              lower #s are better isolated)
%  31: outliers
%
% VARARGIN
% =========================================================================
%  snip_idx       : (cell) default: read from file. index values of each
%                   snippet sorted into cells by tank channel
%  force_replace  : (logical) default: false. Force replace existing sort
%                   codes with new ones without warning.
%  save_to_db     : (logical) default: true. Whether new sort IDs are
%                   immediately applied to the database. When false, IDs
%                   must be loaded using ImportCat. IF TRUE, then
%  save_to_tank   : (logical), default: true
%
%   tags:  TDT, sort code
%
%   See Also:
%   TDT_readTankBlockHeader
%   TDT_getSortCodePath
%   SpikeData.saveSortCodes

%MLINT
%---------------
%#ok<*NASGU>

varargin = sanitizeVarargin(varargin);

DEFINE_CONSTANTS
snip_idx      = [];
force_replace = false;
save_to_db    = true;
save_to_tank  = true;
END_DEFINE_CONSTANTS

CHAN_SORT_OFFSET = 1025;

assert(~strcmpi(sortName,'tanksort'),'''TankSort'' may not be replaced');

assert(save_to_db || save_to_tank,'Either saving to DB or tank must be enabled')

if isnumeric(blockNr_or_trialObj)
    blockNr = blockNr_or_trialObj;
    if save_to_db
        %NOTE: I wanted to avoid needing to use the input C2 to retrieve
        %the trial object, but that may have been unecessary and it might be
        %better to rewrite with passing in C2 to get trial object
        error('When saving to DB input must be the trialObj')
    end
else
    blockNr   = blockNr_or_trialObj.id;
    the_trial = blockNr_or_trialObj;
end

if iscell(snip_event)
    if length(snip_event) > 1
        error('Only one snip event can be handled at a time')
    end
    snip_event = snip_event{1};
end

if save_to_tank || isempty(snip_idx)
    [snipHeader,extras] = TDT_readTankBlockHeader(c_or_tank_path,blockNr,false,snip_event);
end

sortFilePath        = TDT_getSortCodePath(c_or_tank_path,blockNr,snip_event,sortName,true);

if exist(sortFilePath,'file')
    if ~force_replace
        if strcmp(questdlg('Replace Existing Sort Codes?','Replace Sorts Warning','yes','no','no'),'no')
            return;
        end
    end
    if save_to_tank
        fid = fopen(sortFilePath,'r+');
        valuesWrite = fread(fid,inf,'*uint8');
        fclose(fid);
    end
else
    if save_to_tank
        valuesWrite = zeros(1,extras.nChunks + CHAN_SORT_OFFSET,'uint8');
        valuesWrite(snipHeader.sortCodeIndex) = snipHeader.sortCodes;
    end
end

%Let's build snip_idx if not present
if isempty(snip_idx)
    idxAll = snipHeader.sortCodeIndex;
    chanIDAll = snipHeader.channelIDOfChunk;
    snip_idx = cell(1,length(channels));
    for iChan = 1:length(channels)
        curChan = channels(iChan);
        snip_idx{iChan} = idxAll(strfind(chanIDAll,curChan));
    end
end

for iChan = 1:length(channels)
    assert(length(snip_idx{iChan}) == length(sortIDs{iChan}),...
        'Chan %d: The length of sort codes and the length of the chan_idx values must match',...
        channels(iChan))
end

if save_to_tank
    for iChan = 1:length(channels)
        curChan = channels(iChan);
        valuesWrite(snip_idx{iChan}) = sortIDs{iChan};
        %Update sort status
        chanSortedIndex = channels(iChan) + 1; %1st is null, afterwards contains sorts
        valuesWrite(chanSortedIndex) = 1;
    end
    
    fid = fopen(sortFilePath,'w+');
    fwrite(fid,valuesWrite,'uint8');
    fclose(fid);
end

if save_to_db

    mutex = lockExperimentDatabase(the_trial.parent.parent.name);
    fprintf('Saving sort codes to DB\n');
    %the_trial is already assigned above
    if isa(the_trial,'RNEL_DB')
        unlock(the_trial,'-all');
    end
    spike_data = the_trial.spikeData;
    saveSortCodes(spike_data,sortName,sortIDs,channels,'force_replace',true);
    save(spike_data);
    save(the_trial);
    unlock(mutex);
end

end