classdef store_info
    %
    %   Class:
    %   tdt.block.store_info
    
    properties
        name %: 'wave'
        n_channels %: 16
        tdt_type %: 'Stream'
        data_type %: 'single'
        fs %: 2.4414e+04
        time_stamps %: []
        values %: []
        n_values_at_chunk %: [1x148640 uint32]
        byte_offset_to_chunk %: [1x148640 int64]
        chunk_channel_id %: [1x148640 uint16]
        sort_codes %: []
        sort_code_index %: []
        chan_present_mask %: ???? What is this? I think this is for snip
        %events where sometimes a channel may have never crossed threshold
    end
    
    methods
        function obj = store_info(s)
            obj.name = s.name; %: 'wave'
            obj.n_channels = s.nChannels;%: 16
            obj.tdt_type = s.tdt_type; %: 'Stream'
            obj.data_type = s.data_type; %: 'single'
            obj.fs = double(s.fs); %: 2.4414e+04
            obj.time_stamps = s.timeStamps; %: []
            obj.values = s.values; %: []
            obj.n_values_at_chunk = s.nValuesAtChunk; %: [1x148640 uint32]
            obj.byte_offset_to_chunk = s.nByteOffsetToChunk; %: [1x148640 int64]
            obj.chunk_channel_id = s.channelIDOfChunk; %: [1x148640 uint16]
            obj.sort_codes = s.sortCodes; %: []
            obj.sort_code_index = s.sortCodeIndex; %: []
            obj.chan_present_mask = s.chanPresentMask; %: []
        end
    end
    
end

