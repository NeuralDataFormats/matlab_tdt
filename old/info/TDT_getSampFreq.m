function fs = TDT_getSampFreq(c_or_tank_path,blockNr,event_name)
%TDT_getSampFreq Retrieve sampling frequency for an event
%
%   fs = TDT_getSampFreq(c_or_tank_path,blockNr,event_name)

[tsq_struct,extras] = TDT_readTankBlockHeader(c_or_tank_path,blockNr);

I_Event = find(strcmp(event_name,extras.tsq_names),1);

if isempty(I_Event)
    error('Unable to find requested event: %s',event_name)
end

fs = tsq_struct(I_Event).fs;

