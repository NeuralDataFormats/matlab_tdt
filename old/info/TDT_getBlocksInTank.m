function [actualBlockNumbers,block_names] = TDT_getBlocksInTank(tankPath,chkConsistency)
%TDT_GETBLOCKSINTANK  Gets the blocks in the tank.
%
%   [BLOCK_NUMBERS,BLOCK_NAMES] = TDT_getBlocksInTank(TANK_PATH,CHK_CONSISTENCY)
%   reads the directory specified by TANK_PATH and pulls out all blocks
%   that match Block*, and returns their BLOCK_NUMBERS (as parsed from the
%   file name) and BLOCK_NAMES
%
%   ... = TDT_getBlocksInTank(TANK_PATH) uses a CHK_CONSISTENCY value true
%
%
%   Returns a list of block names in the tankPath
%
%   OUTPUTS
%   =======================================================================
%   BLOCK_NUMBERS    : numbers representing block numbers present
%   BLOCK_NAMES      : cell array containing block names
%
%   TANK_PATH        : path to data tank
%   CHK_CONSISTENCY  : default true, If true ensures that the
%                      resulting output is ordered
%
%
%   IMPROVEMENT:
%   Implement the TDT Version of checking this as well (they have an
%   activeX implementation that does this, although probably much slower
%   ???)

%NOTE: I really wanted to rename this function but it is entrenched
%in a lot of functions, perhaps Chris can do this ...

if nargin == 1
    chkConsistency = true;
elseif nargin ~= 2
    error('Incorrect # of input arguments to %s',mfilename)
end

block_names              = mex_dir(fullfile(tankPath,'Block*'));
[actualBlockNumbers,iiA] = sort(cellfun(@getEndBlock,block_names));
block_names              = block_names(iiA);
%Enforce row vector
actualBlockNumbers = actualBlockNumbers(:)';

% CAA HACK Sometimes there is a block 0 in the tank. Why? It is unknowable.
block_names(actualBlockNumbers==0)        = [];
actualBlockNumbers(actualBlockNumbers==0) = [];

% CAA Filter out blocks that have a file named "FAKE_BLOCK" in their directory.
% These are blocks created to ensure consistent naming between systems
fake_block_mask = false(length(block_names),1);
for iiBlock = 1:length(block_names)
    filepath        = fullfile(tankPath,block_names{iiBlock},'FAKE_BLOCK');
    fake_block_mask(iiBlock) = exist(filepath,'file') > 0;
end
actualBlockNumbers(fake_block_mask) = [];
block_names(fake_block_mask)        = [];
end


%HELPER FUNCTIONS
%=================================================
function y = getEndBlock(x)
%NOTE: The str2int would be faster
y = str2double(x(7:end));
end


