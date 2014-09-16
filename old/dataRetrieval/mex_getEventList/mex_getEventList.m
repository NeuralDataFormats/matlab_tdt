function events = mex_getEventList(tsq_filename)
% MEX_GETEVENTLIST Retrieve the list of events for an experiment
%
% function events = mex_getEventList(tsq_filename)
%
% INPUTS
% =========================================================================
%   tsq_filename - (char) The header file of the desired tank to read
%
% OUTPUTS
% =========================================================================
%   events - (cell) cell array of event names
%
% tags: mex, tdt, tank access

WORDS_PER_ENTRY = 10;

formattedWarning('mex available: slower method being used')

%WARNING: not tested

fid = fopen(tsq_filename,'r');
words = fread(fid,[WORDS_PER_ENTRY inf],'*uint32');
fclose(fid);

evNameValues = words(3,:);

%Poor man's unique
xs = sort(evNameValues);
n  = find(diff(xs) ~= 0);
uniqueEvNameValues = [xs(1) xs(n+1)];

%NOTE: we truncate the first 3 as these are special codes, length, start, & stop
events = cellfun(@(x) char(typecast(x,'uint8')),num2cell(uniqueEvNameValues(4:end)),'UniformOutput',false);



