%TDT_format_notes



%==========================================================================
%FILE FORMAT - repeat of 40 bytes, broken down below in 4 byte words
%==========================================================================
%WORD
%1   uint32 - Size          - size of data, with header, in LONGS (<- really :/  )
%2   uint32 - Type          - snip, stream, scalar - defined above
%3   uint32 - Code          - 4 character event name - MUST BE UNIQUE - IS A KEY
%4   uint16 - Channel       - numeric value to identify channel
%4   uint16 - Sort Code     - default, how does this work?
%5:6 double - Time Stamp    - event start time in seconds
%7:8 int64  - event offset  - offset in TEV file
%    OR
%7:8 double - raw value     - raw value
%9   uint32 - data format   - float, long ,etc
%10  single - Fs            - sampling frequency