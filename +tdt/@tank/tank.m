classdef tank < sl.obj.display_class
    %
    %   Class:
    %   tdt.tank
    %
    %   A tank holds a collection of blocks.
    
    properties
        tank_path
        tank_name
       block_list 
    end
    
    methods
        function obj = tank(tank_path)
           obj.tank_path     = tank_path;
           [~,obj.tank_name] = fileparts(tank_path);
           
           temp = sl.dir.listNonHiddenFolders(tank_path)';
           temp(strcmp(temp,'TempBlk')) = [];
           obj.block_list = temp;
        end
        function block = getBlock(obj,block_number)
            %
            %   Inputs:
            %   -------
            %   block_number: #
            %       
            
           %TODO: Technically blocks don't need to be numbered
           %We should allow string inputs as well ...
           block = tdt.block(obj,block_number);
        end
    end
    
end

