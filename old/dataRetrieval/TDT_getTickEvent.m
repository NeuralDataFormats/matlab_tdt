function output = TDT_getTickEvent(c_or_tank_path,blockNr,event_name)
%TDT_getTickEvent  Returns times and values of a strobe (tick) event
%
%   output = TDT_getTickEvent(c_or_tank_path,blockNr,event_name)
%
%   OUTPUTS
%   ============================================
%   output (structure)
%       .times  : array of times
%       .values : array of values

[tsq_struct,extras] = TDT_readTankBlockHeader(c_or_tank_path,blockNr);

I_Event = find(strcmp(event_name,extras.tsq_names),1);

if isempty(I_Event)
    notes = extras.notes;
    %No events recorded but it was recordable
    if isfield(notes,event_name)
        output = struct('times',[],'values',[]);
        return
    else
        error('Unable to find requested event: %s',event_name)
    end
end

output = struct;
output.times  = tsq_struct(I_Event).timeStamps;
output.values = tsq_struct(I_Event).values;

