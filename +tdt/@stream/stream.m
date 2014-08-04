classdef stream < handle
    %
    %   Class:
    %   tdt.stream
    
    properties
        name
        n_channels
        data_type
        fs
    end
    
    properties (Hidden)
        n_values_at_chunk
        byte_offset_to_chunk
        chunk_channel_id
    end
    
    %These are temporary ...
    properties (Hidden)
        header_path
        data_path
    end
    
    methods
        function obj = stream(s,header_path,data_path)
            %
            %   s: tdt.block.store_info
            
            obj.header_path = header_path;
            obj.data_path = data_path;
            
            obj.name = s.name;
            obj.n_channels = s.n_channels;
            obj.data_type = s.data_type;
            obj.fs = s.fs;
            obj.n_values_at_chunk = s.n_values_at_chunk;
            obj.byte_offset_to_chunk = s.byte_offset_to_chunk;
            obj.chunk_channel_id = s.chunk_channel_id;
        end
        function data = getData(obj,varargin)
           
           in.scale_value = []; 
           in.channels  = 1:obj.n_channels; 
           in.as_double = true;
           in.units = 'Unknown';
           in.channel_labels = ''; %TODO: If numeric, change to string ...
           in = sl.in.processVarargin(in,varargin);
           temp = tdt.getData(obj.header_path,obj.data_path,obj.name,in.channels);
           if in.as_double
               temp = double(temp);
           end
           if ~isempty(in.scale_value)
              temp = temp*in.scale_value;
           end
           
           data = sci.time_series.data(temp,1/obj.fs,'units',in.units,...
               'channel_labels',in.channel_labels);
        end
    end
    
end

