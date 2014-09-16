function fStruct = TDT_getBlockFiles(c_or_tank_path,blockNr)
%TDT_getBlockFiles  Returns paths for processing TDT files
%
%   fStruct = TDT_getBlockFiles(c_or_tank_path,blockNr)
%
%   INPUTS
%   =======================================================================
%   c_or_tank_path - (structure or path)
%                    STRUCTURE: (with fields)
%                       .TANK_PATH - REQUIRED
%                       .TEMP_PATH - OPTIONAL
%                    PATH:
%                       value points to the tank pathb
%   blockNr        - (numeric), block of interest
%
%
%   OUTPUTS
%   =======================================================================
%   fStruct (struct)
%       .header_path        -
%       .data_path          - path to file with data
%           %for caching purposes%
%       .tank_path          - path to requested tank
%       .blockNr            - block number requested
%           %for saving temp files%
%       .header_save_root   - might not exist
%
%   IMPLEMENTATION NOTES
%   =======================================================================
%   I tried to make some effort to not have this examine the disk every
%   time it runs, which is why I used the persistent variable and don't
%   check if the temporary files exist.
%   In addition, since the sort codes may change between calls, I don't
%   check that here and leave that to another function in which calling
%   that function means that you explicitly want the sort code information
%
%   See Also:
%   TDT_readTankBlockHeader
%   TDT_getSortCodeMetaInfo



HEADER_EXT = 'tsq';
DATA_EXT   = 'tev';
NOTES_EXT  = 'Tbk';

if nargin ~= 2
    error('2 input arguments needed')
end

%The following allows for rehashing our results
persistent fStruct_cache

temp_save_root = '';
if isstruct(c_or_tank_path)
    C = c_or_tank_path;
    %Handle accordingly
    tank_path = C.TANK_PATH;   
    if isfield(C,'TDT_HEADER_MAT_PATH')
        temp_save_root = C.TDT_HEADER_MAT_PATH;
    else
        if isfield(C,'DATA_ROOT')
            [~,dataName] = fileparts(C.DATA_ROOT);
            formattedWarning('Constants path structure for %s lacking "TDT_HEADER_MAT_PATH" temp data path',dataName)
        else
            formattedWarning('Constants path structure lacking "TDT_HEADER_MAT_PATH" temp data path')
        end
    end 
else
    tank_path = c_or_tank_path;
end

if ~isempty(fStruct_cache) && fStruct_cache.blockNr == blockNr && strcmpi(fStruct_cache.tank_path,tank_path)
    fStruct = fStruct_cache;
    return
end

block_dir = fullfile(tank_path,['Block-' int2str(blockNr)]);

%Could we cache this as well?
header_name = getFileByNumber(block_dir,'Block',blockNr,HEADER_EXT,1,true);
header_path = fullfile(block_dir,header_name);
data_name   = getFileByNumber(block_dir,'Block',blockNr,DATA_EXT,1,true);
data_path   = fullfile(block_dir,data_name);
notes_name  = getFileByNumber(block_dir,'Block',blockNr,NOTES_EXT,1,true);
notes_path  = fullfile(block_dir,notes_name);


fStruct.header_path = header_path;
fStruct.data_path   = data_path;
fStruct.tank_path   = tank_path;
fStruct.blockNr     = blockNr;
fStruct.block_path  = block_dir;
fStruct.header_save_root = temp_save_root;
fStruct.notes_path  = notes_path;

fStruct_cache = fStruct;