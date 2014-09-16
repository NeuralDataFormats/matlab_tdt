function [data,channels] = mex_getContinuousData(tsq_file,tev_file,event,channels_get)
%mex_getContinuousData  DONT CALL ME, call TDT_getContinuousData instead
%
%   [data,channels] = mex_getContinuousData(tsq_file,tev_file,event,channels_get)
%
%   INPUTS
%   =======================================================================
%   TSQ_FILE      : path to the .tsq file (in the block folder) HEADER
%
%   TEV_FILE      : path to the .tev file (in the block folder) DATA
%   EVENT         : 4 letter string of the event to retrieve
%   CHANNELS_GET  : Array of channels to retrieve
%
%   OUTPUTS
%   =======================================================================
%   DATA          : Continuous Data, samples by channels
%   CHANNELS_USED : The channels that actually existed, this should be in
%                   the same order as those requested, with the exception 
%                   of the removal of those that didn't exist
%                   1 1000 100 => (1000 doesn't exist) => 1 100
% tags: mex, tdt, tank access

%CALLING_FUNCTION = 'TDT_getContinuousData';

%We really don't want to end up here ...
formattedWarning('mex_getContinuousData is not compiled, resorting to Matlab code')

%:/, not sure of how else to do this, we could modify
%TDT_readTankBlockHeader but I don't feel like doing that now ...
try
    c_or_tank_path = evalin('caller','c_or_tank_path');
    blockNr        = evalin('caller','blockNr');
    channelsGet    = evalin('caller','channelsGet');
catch ME
    error('The variables above must be in the caller''s workspace')
end

[tsq,extras] = TDT_readTankBlockHeader(c_or_tank_path,blockNr);
tsq_event    = tsq(strcmp(extras.tsq_names,event));
if isempty(tsq_event)
    error('The specified event: %s, was not found in the block file',event)
end

fid = FileReader(tev_file,'rb');
channelIDs = double(tsq_event.channelIDOfChunk(:));
nBytesSkip = double(tsq_event.nByteOffsetToChunk(:));
nValues    = double(tsq_event.nValuesAtChunk(:));

if ~isequal(1:tsq_event.nChannels,sort(channels_get))
    mask    = ismembc(channelIDs,sort(double(channelsGet)));
    offsets = [nBytesSkip(mask) nValues(mask) channelIDs(mask)];
end

[data,channels] = buffered_fread(fid,offsets,tsq_event.data_type,...
    'asMatrix',true,'matrixChanOrder',channelsGet);


