function TDT_saveSortCodes_old(c_or_tank_path,blockNr,snipEvent,sortName,values,channels,varargin)
%
%
%   INPUTS
%   ===================================================
%   c_or_tank_path : see TDT_readTankBlockHeader
%   blockNr        : (numeric), block number
%   snipEvent      : (4 letter string) name of the snip event (like 'Snip' or 'eNeu')
%   sortName       : (string) name to save the sort as
%   values         : 
%
%   OPTIONAL INPUTS
%   ===================================================
%   
%
%   See Also:
%   TDT_readTankBlockHeader
%   TDT_getSortCodePath

%POSSIBLE IMPROVEMENT


DEFINE_CONSTANTS
eventFilter   = {};
END_DEFINE_CONSTANTS

%Possible gotchas
%- If the sort file doesn't exist, then we need to create it
%- If the snip event doesn't exist, error
%- length of values must equal length of channels
%- length of each entry in values must equal the # of events




%1) Get the path of the new file
sortPath = TDT_getSortCodePath(c_or_tank_path,blockNr,snipEvent,sortCodeName);

%If it exists, then we are all set
%If it doesn't, then we copy everything from the tank
%[tsq,extras] = TDT_readTankBlockHeader(c_or_tank_path,blockNr);
%
%

snipHeader = tsq(strcmp(extras.tsq_names,snipEvent));

%note -> extras.nChunks specifies # of bytes to write
%
%   Need to get snip event from tsq and use the indices to write the
%   defaults for all of the other channels

%1) Resolve everything to indices & get chan sorted matrix


%----------------------------------------------------------------
%                           FORMAT OF SORT FILE 
%----------------------------------------------------------------
%null byte (0)
%channel vector (1024 bytes, whether or not channels are sorted)
%the values, if not already present init with:
%   zeros(1,nChunks,'uint8'), then overwrite with the values
%   you are actually going to write, you'll 


%FOR NEW FILES
%============================
if exist(sortPath,'file');
valuesWrite = zeros(1,nChunks + 1025,'uint8');
fid = fopen(sortPath,'w');
else
%for old files, start with twhat is already there

end

onChannels = []; %fill this in based on inputs, either unique(channels) or

fclose(fid)