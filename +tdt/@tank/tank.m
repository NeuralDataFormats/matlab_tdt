classdef tank < sl.obj.display_class
    %
    %   Class:
    %   tdt.tank
    %
    %   A tank holds a collection of blocks.
    
    properties
        tank_path
        tank_name
    end
    
    properties (Dependent)
       block_list 
    end
    
    methods
        function value = get.block_list(obj)
           %TODO: Implement this ...
           value = [];
        end
    end
    
    methods
        function obj = tank(tank_path)
           obj.tank_path     = tank_path;
           [~,obj.tank_name] = fileparts(tank_path);
        end
        function block = getBlock(obj,block_number)
           %TODO: Technically blocks don't need to be numbered
           %We should allow string inputs as well ...
           block = tdt.block(obj,block_number);
        end
    end
    
end

