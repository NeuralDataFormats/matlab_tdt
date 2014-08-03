classdef block < handle
    %
    %   Class:
    %   tdt.block
    
    properties
        block_number
        header
    end
    
    methods
        function obj = block(tank,block_number)
            obj.block_number = block_number;
            %TODOL Implement below
            obj.header = tdt.block.header(tank,block_number);
        end
    end
    
end

