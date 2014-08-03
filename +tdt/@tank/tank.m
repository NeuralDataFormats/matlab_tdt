classdef tank < handle
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
        end
        function readBlock(obj,block_number)
           %TODO: Implement this! 
        end
    end
    
end

