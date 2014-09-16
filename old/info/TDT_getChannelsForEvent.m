function channels = TDT_getChannelsForEvent(c_or_tank_path,block,eventName)
% whichEventsExist Returns the events that were recorded for each event
%
%   channels = getChannelsForEvent(obj,C,C2,block,eventName)
%
% INPUTS
% =============================================================
%   C,C2
%   block     - (numeric)
%   eventName - (char)
%
% OUTPUTS
% =============================================================
%   channels - (numeric) channels used by this event. For snip events this
%   may include channels that were not actually used because there were not 
%   enough physical channels on the electrode
%
% tags:
% see also: TDT_readTankBlockHeader
channels = [];
try
    header = TDT_readTankBlockHeader(c_or_tank_path,block,false,eventName);
    type   = lower(header.tdt_type);
    switch type
        case 'stream'
            channels = double(unique(header.channelIDOfChunk));
        case 'snip'
            channels = 1:header.nChannels;
        case {'unknown', 'mark', 'strobe+','strobe-', 'scalar'}
            channels = 1;
        otherwise
            error('Unhandled TDT Type :''%s''',type)
    end
catch ME
    % exceptions are thrown when events DNE. This can happen for snips when
    % the event is enabled but none are recorded. In this case you can get
    % the number of channels from the notes.
    
    notes = TDT_getNotes(c_or_tank_path,block);
    if isfield(notes,eventName) && strcmp(notes.(eventName).TankEvType,'Snip')
        % This is going to overestimate the number of channels because
        % there are Snips available for 
        channels = 1:str2num(notes.(eventName).NumChan);
    end
end

end