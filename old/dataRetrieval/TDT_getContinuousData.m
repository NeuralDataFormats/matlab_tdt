function data = TDT_getContinuousData(c_or_tank_path,blockNr,event,channelsGet)
%TDT_getContinuousData
%
%   data = TDT_getContinuousData(c_or_tank_path,blockNr,event,channelsGet)
%
%   Essentially serves as a wrapper for mex_getContinuousData with some
%   handling around it to make it more consistent with the other functions
%   of similar type
%
%   INPUTS
%   =======================================================================
%   c_or_tank_path : see TDT_readTankBlockHeader
%   blockNr        :
%   event          : (char) length 4, name of the event to retrieve
%   channelsGet    : (numeric array), channels to retrieve
%
%
%   OUTPUTS
%   =======================================================================
%   data : Continuous Data, samples by channels
%
%
%   tags: tdt, tank access
%
%   See Also:
%   TDT_readTankBlockHeader
%   TDT_getBlockFiles
%   TDT_getNotes
%   mex_getContinuousData

fStruct = TDT_getBlockFiles(c_or_tank_path,blockNr);
notes   = TDT_getNotes(c_or_tank_path,blockNr);

%NOTE: This doesn't nececessarily guarantee we collected this data
%however for streaming data, it should, note that this method is only
%really valid for streamed data
if ~isfield(notes,event)
   error('Requested event does not exist for this block') 
end

nChannels = str2double(notes.(event).NumChan);

%COULD REDO ABOVE WITH CALL TO TDT_readTankBlockHeader, might be slower ...

isPresent = ismember(channelsGet,1:nChannels);

if ~all(isPresent)
    error('Some of the requested channels do not exist')
end

[data,channels] = mex_getContinuousData(fStruct.header_path,fStruct.data_path,event,channelsGet);

%Not sure why the following would ever happen ...
if ~isequal(channelsGet(:),channels(:))
    error('For some reason the requested channels were not retrieved')
end