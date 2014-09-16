function events = TDT_getEventList(c_or_tank_path,blockNr)
%TDT_getEventList Lists TDT events with data for a particular block
%
%   events = TDT_getEventList(c_or_tank_path,blockNr)
%
%   NOTE: This is different from TDT_getNotes which indicates whether or
%   not an event was present for recording, not whether or not data is
%   present (i.e. this is the more selective of the two)
%
%   INPUTS
%   ================================
%   c_or_tank_path : constants structure or path to tank
%   blockNr        : block number
%   
%   OUTPUTS
%   ================================
%   events : (cellstr), list of events
%
%   See Also:
%   TDT_getBlockFiles
%   mex_getEventList
%   TDT_readTankBlockHeader
%   TDT_getNotes

fStruct = TDT_getBlockFiles(c_or_tank_path,blockNr);

%NOTE: Could check if already available in TDT_readTankBlockHeader
%This is significantly faster if the answer is yes

[~,extrasHeader] = TDT_readTankBlockHeader(c_or_tank_path,blockNr,'check');

if ~isempty(extrasHeader)
    events = extrasHeader.tsq_names;
else
    events = mex_getEventList(fStruct.header_path);
end