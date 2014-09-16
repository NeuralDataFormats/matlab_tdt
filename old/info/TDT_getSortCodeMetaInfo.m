function sortCodeInfo = TDT_getSortCodeMetaInfo(c_or_tank_path,blockNr,varargin)
%TDT_getSortCodeMetaInfo  Retrieves information about available sort codes
%
%   sortCodeInfo = TDT_getSortCodeMetaInfo(c_or_tank_path,blockNr) 
%
%   This function only reads the disk to determine sort code availability,
%   not the content of sort code files
%
%   INPUTS
%   =====================================================================
%   c_or_tank_path : see TDT_getBlockFiles
%   blockNr        : numeric, block number
%
%   OUTPUTS
%   =====================================================================
%   snip_events  : (cellstr) list of all snip_events with extra sorts
%   sort_codes   : (cellstr) list of all non-default sort codes
%       THESE NEXT FIELDS ARE PAIRED (same lengths)
%   snip_pairing : (cellstr) snip event name
%   sort_pairing : (cellstr) sort code name
%   result_file_pairing: (cellstr) path to the sort code file
%
%   NOTE: The sorts exclude the default value
%
%   EXAMPLE USAGE
%   =====================================================================
%   setupConvPathForCat('Export')
%   sortCodeInfo = TDT_getSortCodeMetaInfo(C,9)
%   sortCodeInfo => 
%             snip_events: {'Snip'}
%              sort_codes: {3x1 cell}
%            snip_pairing: {'Snip'  'Snip'  'Snip'}
%            sort_pairing: {'JoostSort'  'Joost'  'MattSort'}
%     result_file_pairing: {[1x90 char]  [1x86 char]  [1x89 char]}
%
%   See Also:
%       TDT_getBlockFiles
%       TDT_readTankBlockHeader
%       TDT_getSortNamesAvailable

%MLINT
%============================
%#ok<*AGROW>

IGNORE_DIR = {'.' '..'};
SORT_DIR   = 'sort';

fStruct        = TDT_getBlockFiles(c_or_tank_path,blockNr);
sort_root_path = fullfile(fStruct.block_path,SORT_DIR);

if ~exist(sort_root_path,'dir')
    d = {{}};
    sortCodeInfo = struct(...
        'snip_events',d,...
        'sort_codes',d,...
        'snip_pairing',d,...
        'sort_pairing',d,...
        'result_file_pairing',d);
    return
end

%Read contents of the sort directory
[files,is_dir] = mex_dir(sort_root_path);

%remove directores to ignore
mask = ismember_str(files,IGNORE_DIR,true);
files(mask)    = [];
is_dir(mask)   = [];

%Any remaining folders contain sort codes (we don't know which snip events
%they hold yet until we look inside the folders)
dir_list            = files;
dir_list(~is_dir)   = [];
existing_sort_codes = dir_list;

file_list         = files;
file_list(is_dir)  = [];

%files in the sort code folder represent snip events that exist
%TDT precomputes eigenvectors to speed up their code
%At least they tried to speed up something :)
%ex.
%split files for eigenvector -> e.g. eNeu.eigenvector -> eNeu
snip_events = regexp(file_list,'(?<snip>\w{4})(?=.eigenvector)','match','once');
snip_events = snip_events(~cellfun('isempty',snip_events));

%setting up sortCodeInfo output
sortCodeInfo = struct;
sortCodeInfo.snip_events = snip_events;
sortCodeInfo.sort_codes  = existing_sort_codes;

%We'll build these together, 
snip_pairing = {};
sort_pairing = {};
result_file_pairing = {};

sort_folders = fullfileCA(sort_root_path,dir_list);

%We go through each folder, find the SortResult files, and populate the
%pairing information
for iSort = 1:length(sort_folders) 
    
    curSortCode = existing_sort_codes{iSort};
    curSortFolder = sort_folders{iSort};
    
    %NOTE: We're looking for .SortResult files
    %There are also files which describe how each channel was sorted in
    %OpenSorter, we'll ignore those by filtering in mex_dir
    resultFiles         = mex_dir(fullfile(curSortFolder,'*.SortResult'));
    sortResultSnipNames = regexp(resultFiles,'(?<snip>\w{4})(?=.SortResult)','match','once');
    
    snip_pairing = [snip_pairing sortResultSnipNames]; 
    sort_pairing = [sort_pairing repmat({curSortCode},1,length(resultFiles))];
    result_file_pairing = [result_file_pairing fullfileCA(curSortFolder,resultFiles)];
    
end

sortCodeInfo.snip_pairing = snip_pairing;
sortCodeInfo.sort_pairing = sort_pairing;
sortCodeInfo.result_file_pairing = result_file_pairing;