function [sort_names,extras] = TDT_getSortNamesAvailable(c_or_tank_path,blockNr,snip_event)
%TDT_getSortNamesAvailable Returns available sorts for a given snip_event
%
%   [sort_names,extras] = TDT_getSortNamesAvailable(c_or_tank_path,blockNr,snip_event)
%
%   This is meant to be the main interface for a user into sort codes
%   as opposed to TDT_getSortCodeMetaInfo
%
%   INPUTS
%   =======================================================
%   c_or_tank_path : see TDT_getBlockFiles
%   blockNr        : (numeric) block number
%
%   OUTPUTS
%   =======================================================
%   sort_names : (cellstr), list of available sort names
%   extras     : (structure)
%       .DEFAULT_SORT - 'TankSort'
%       .sort_paths   - (cellstr), path to sort code file for each sort name
%
%   EXAMPLE
%   ========================================================
%   [sort_names,extras] = TDT_getSortNamesAvailable(C,9);
%   sort_names =>
%       {'TankSort'    'JoostSort'    'Joost'    'MattSort'}
%   extras =>
%   	DEFAULT_SORT: 'TankSort'
%       sort_paths: {1x4 cell}
%
%   See Also: 
%       TDT_getBlockFiles
%       TDT_getSortCodeMetaInfo
%       TDT_getNotes


DEFAULT_SORT = 'TankSort';

%Ensure snip_event requested exists
notes = TDT_getNotes(c_or_tank_path,blockNr);
if ~isfield(notes,snip_event)
    error('Specified snip event: %s, does not exist',snip_event)
end

extras = struct;
extras.DEFAULT_SORT = DEFAULT_SORT;

%Find additional sorts
sortCodeMeta = TDT_getSortCodeMetaInfo(c_or_tank_path,blockNr);

if isempty(sortCodeMeta)
    sort_names = DEFAULT_SORT;
    extras.sort_paths = {''};
else
    mask       = strcmp(sortCodeMeta.snip_pairing,snip_event);
    %NOTE: This is important that the default sort comes first
    sort_names = [{DEFAULT_SORT} sortCodeMeta.sort_pairing(mask)];
    extras.sort_paths = [{''} sortCodeMeta.result_file_pairing(mask)];
end

