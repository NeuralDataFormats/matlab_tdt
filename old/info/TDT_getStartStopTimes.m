function blockTime = TDT_getStartStopTimes(c_or_tank_path,blockNr,utc_offset)
%TDT_getStartStopTimes Retrieve start and stop time for block and duration
%
%   blockTime = TDT_getStartStopTimes(c_or_tank_path,blockNr,*utc_offset)
%
%   INPUTS
%   =======================================================
%   c_or_tank_path : see TDT_getBlockFiles
%   blockNr        : (numeric) block number
%   utc_offset     : (default -5), amount to offset UTC by return time in
%                    local time zone, -5 offsets time to Eastern Standard
%                    Time (EST)
%
%   OUTPUTS
%   ========================================================
%   blockTime : (structure)
%       .startTime : (numeric), Matlab time format (supports datestr())
%                     date & time of the starting of the block
%       .stopTime  :  "                  " ending of the block
%       .duration  : (numeric), duration in seconds
%
%   See Also:
%       TDT_readTankBlockHeader
%       unixTimeToMatlabTime

if nargin == 2
    utc_offset = -5;
elseif nargin ~= 3
    error('Incorrect # of function inputs')
end

[~,extras] = TDT_readTankBlockHeader(c_or_tank_path,blockNr);

startTimeUnix = extras.start_time;
stopTimeUnix  = extras.end_time;

blockTime = struct(...
    'startTime',unixTimeToMatlabTime(startTimeUnix,utc_offset),...
    'stopTime',unixTimeToMatlabTime(stopTimeUnix,utc_offset),...
    'duration',stopTimeUnix - startTimeUnix);