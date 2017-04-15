classdef stream < handle
    %
    %   Class:
    %   tdt.stream
    
    properties
        name
        n_channels
        data_type
        fs
        n_samples_per_channel
        MB_memory_per_channel
    end
    
    properties (Hidden)
        n_values_at_chunk
        byte_offset_to_chunk
        chunk_channel_id
        block_number
    end
    
    %These are temporary ...
    properties (Hidden)
        header_path
        data_path
    end
    
    methods
        function obj = stream(s,header_path,data_path,block_number)
            %
            %   Inputs:
            %   -------
            %   s: tdt.block.store_info
            
            obj.block_number = block_number;
            obj.header_path = header_path;
            obj.data_path = data_path;
            
            obj.name = s.name;
            obj.n_channels = s.n_channels;
            obj.data_type = s.data_type;
            %single
            %
            obj.fs = s.fs;
            obj.n_values_at_chunk = s.n_values_at_chunk;
            obj.byte_offset_to_chunk = s.byte_offset_to_chunk;
            obj.chunk_channel_id = s.chunk_channel_id;
            %Data might not be even, so this could be off.
            %Eventually we might want to change this. Not sure what Chis
            %does with this in the mex reader ...
            obj.n_samples_per_channel = sum(double(s.n_values_at_chunk))/obj.n_channels;
            
            switch obj.data_type
                case 'single'
                    n_bytes = 4;
                case 'int16'
                    n_bytes = 2;
                otherwise
                    error('Unhandled case: %s',obj.date_type)
            end
            obj.MB_memory_per_channel = obj.n_samples_per_channel*n_bytes/1e6;
        end
        function data = getData(obj,varargin)
            %
            %   data = getData(obj,varargin)
            %
            %    Optional Inputs:
            %    ----------------
            %   as_object : logical (default true)
            %   scale_value = [];
            %   1:obj.n_channels;
            %   in.as_double = true;
            %   in.units = 'Unknown';
            %   in.channel_labels = ''; %TODO: If numeric, change to string ..
            
            in.as_object = true;
            in.scale_value = [];
            in.channels  = 1:obj.n_channels;
            in.as_double = true;
            in.units = 'Unknown';
            in.channel_labels = ''; %TODO: If numeric, change to string ...
            in = sl.in.processVarargin(in,varargin);
            
            %This leads to a mex call ...
            temp = tdt.getData(obj.header_path,obj.data_path,obj.name,in.channels);
            if in.as_double
                temp = double(temp);
            end
            if ~isempty(in.scale_value)
                temp = temp*in.scale_value;
            end
            if in.as_object
                data = sci.time_series.data(temp,1/obj.fs,'units',in.units,...
                    'channel_labels',in.channel_labels);
            else
                data = temp;
            end
        end
        function exportData(obj,folder_path,varargin)
            %
            %    exportData(obj,folder_path,varargin)
            %
            %    Options:
            %    --------
            %    1) partial reads and writes to have everything in one file
            %    2) file per channel to fit memory requirements
            %
            %    We'll implment #2 for now
            %
            %
            %   File Format - option 2
            %   ----------------------
            %   data: [1 x n]
            %   VERSION = 1
            
            VERSION = 1;
            
            in.single_file = false;
            in.base_name = '';
            in.verbose = true;
            in = sl.in.processVarargin(in,varargin);
            
            if isempty(in.base_name)
                in.base_name = sprintf('Block-%03d-%s',obj.block_number,obj.name);
            end
            
            fs = obj.fs;
            
            if in.single_file
                file_name = in.base_name;
                if in.verbose
                    fprintf('Exporting %s\n',file_name)
                end
                data = obj.getData('as_double',false,'as_object',false); %#ok<NASGU>
                file_path = fullfile(folder_path,file_name);
                save(file_path,'-v7.3','data','fs','VERSION');
            else
                for iChannel = 1:obj.n_channels
                    file_name = sprintf('%s-%03d',in.base_name,iChannel);
                    if in.verbose
                        fprintf('Exporting %s\n',file_name)
                    end
                    data = obj.getData('channels',iChannel,'as_double',false,'as_object',false); %#ok<NASGU>
                    file_path = fullfile(folder_path,file_name);
                    save(file_path,'-v7.3','data','fs','VERSION');
                end
            end
            
        end
    end
    
end

