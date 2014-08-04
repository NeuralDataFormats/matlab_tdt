classdef tank < sl.obj.display_class
    %
    %   Class:
    %   tdt.tank
    
    properties
        tank_path
        tank_name
    end
    
    methods
        function obj = tank(tank_path)
           %TODO: Can we resolve path using TDTs registry?
           obj.tank_path = tank_path;
           %TODO: Get name
           [~,obj.tank_name] = fileparts(tank_path);
        end
        function block = getBlock(obj,block_number)
           %TODO: Implement this! 
           block = tdt.block(obj,block_number);
        end
    end
    
end

