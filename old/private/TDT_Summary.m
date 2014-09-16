%   =======================================================================
%                           TDT FILE INFORMATION
%   =======================================================================
%   .tsq file -> header, read by TDT_readTankBlockHeader (SHOULDN'T CHANGE)
%   .tev file -> data file, it also shouldn't change but isn't reasonable
%                to keep in memory
%
%   SEE TankFormat.pdf in private
%
%   .Tbk file -> notes file, read by TDT_getNotes (SHOULDN'T CHANGE)
%
%   The format of the .tbk file is ambiguous and at some point I hope to
%   get more information from TDT as to what is in it, as it could be
%   useful
%
%   sort code files -> these may change as things are sorted, paths for
%                       this are handled by TDT_getSortCodeMetaInfo
%
%   FORMAT: all bytes should be read as uint8
%   1) 1 byte Null
%   2) 1024 bytes of true/false on whether or not channel has been sorted
%   3) sort codes for index values
%       31 -> unsorted
%   NOTE: If a channel is specified as being unsorted, the sort data file
%   will include unsorted values (zeros). The general implementation of TDT
%   is then to return the TankSort sort codes (ones set upon data capture),
%   instead of just returning an array of zeros (0 is the unsorted sort code value).
%
%   =======================================================================
%            MEMORY ISSUES AND ASSUMPTIONS WHEN READING FILES
%   =======================================================================
%   1) The header is small enough to read into memory
%   2) Sort code files are small enough to read into memory (they will
%       always be smaller than the header) by approximately a factor of 40
%   3) Snippets are written to the buffer in chunks with large spaces in
%   between the chunks. In general I have found it most efficient to read
%   the entirety of the chunks and to then discard what is not needed
%   (after reading all chunks). This may lead to memory issues ...
%       (FileReader.buffered_fread2)
%   4) Continuous data is the same but here memory precautions are taken
%   ... (FileReader.buffered_fread)
%
%   =======================================================================
%                               MAIN FILES:
%   =======================================================================
%   TDT_getBlockFiles -> gets list of block files (except sort codes), in
%                        this way it keep persistence (less disk reading)
%   TDT_readTankBlockHeader -> reads the header, which contains most of the
%                       information for tick events (optional save to disk,
%                       persistent across calls)
%       OTHER NOTES:
%       1) I assume you can read the entire header into memory
%       2) Splitting of the channels isn't done in this file
%               - saves on running time
%               - speeds up saving and loading file
%
%   TDT_getNotes -> reads the notes file, persistent across calls
%
%   The notes files is the only known way of getting the # of channels
%   that were declared in hardware