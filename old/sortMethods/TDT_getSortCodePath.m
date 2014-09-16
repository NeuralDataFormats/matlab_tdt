function sortFilePath = TDT_getSortCodePath(c_or_tank_path,blockNr,snipEvent,sortCodeName,createSavePath)
%sortFilePath  Generates the file path of a sort code file
%
%   sortFilePath = TDT_getSortCodePath(c_or_tank_path,blockNr,snipEvent,sortCodeName,*createSavePath)
%
%   INPUTS
%   ====================================================
%   c_or_tank_path :
%   blockNr        :
%   snipEvent      : 4 letter event name, not verified to exist in this file
%   sortCodeName   : (string), name to use for sorting
%   createSavePath : (default false), if true ensures that the folder path exists
%  
%   path:
%   sort/[snip_event]/[sortName].sortResult
%
%

SORT_RESULT_EXTENSION = '.SortResult';

if ~exist('createSavePath','var')
    createSavePath = false;
end

fStruct = TDT_getBlockFiles(c_or_tank_path,blockNr);

specificSortRoot = fullfile(fStruct.block_path,'sort',sortCodeName);

if createSavePath
   createFolderIfNoExist(specificSortRoot);
end

sortFilePath = fullfile(specificSortRoot,[snipEvent SORT_RESULT_EXTENSION]);