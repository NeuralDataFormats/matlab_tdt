classdef header < handle
    %
    %   Class:
    %   tdt.block.header
    
    
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
    
    properties
        file_path
        stores   %tdt.block.store_info
        start_time  %(s, unix time)
        end_time    %(s, unix time)
        n_chunks %This is really more for internal use rather than being all
        %that useful to the user.
        incomplete_block %I think this happens when the block crashes
        store_names %This order matches that of 'stores'
        tdt_data_types
    end
    
    properties (Dependent)
        block_duration %(s)
    end
    
    methods
        function value = get.block_duration(obj)
            value = obj.end_time - obj.start_time;
        end
    end
    
    properties
        special_events
    end
    
    methods
        function obj = header(tsq_path,notes)
            obj.file_path = tsq_path;
            
            %tdt.block.header.initializeObject
            obj.initializeObject(notes);
        end
        function store_info = getStoreInfo(obj,store_name)
            %
            %   store_info = obj.getStoreInfo(store_name)
            %
            %   Outputs:
            %   --------
            %   store_info: tdt.block.store_info
            
            %TODO: Include a check on existence
            
            store_info = obj.stores(strcmp(obj.store_names,store_name));
        end
    end
    
end

