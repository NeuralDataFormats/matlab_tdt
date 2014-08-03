classdef paths < handle
    %
    %   Class:
    %   tdt.block.paths
    
    properties
        block_number
    end
    
    %PATHS =============================
    properties
        block
        header
        data
        tank
        notes
        %sorts???
    end
    
    methods
        function obj = paths(tank_path,block_number,varargin)
            
           %This would allow us to override this behavior
           in.block_resolver = @tdt.block.paths.getBlockPath;
           in = sl.in.processVarargin(in,varargin);
           
           obj.tank = tank_path;
           obj.block_number = block_number;
           obj.block = in.block_resolver(tank_path,block_number);
           
           f = sl.dir.getFilesInFolder(obj.block);

           obj.header = f.file_paths{sl.str.findSingularMatch('\.tsq',f.file_names,'use_regexp',true)};
           obj.data   = f.file_paths{sl.str.findSingularMatch('\.tev',f.file_names,'use_regexp',true)};
           obj.notes  = f.file_paths{sl.str.findSingularMatch('\.Tbk',f.file_names,'use_regexp',true)};
           
        end
    end
    methods (Static)
        function block_path = getBlockPath(tank_path,block_number)
            
           files = sl.dir.getFilesInFolder(tank_path,...
               'match_number',block_number,'type',1,'check_single_match',true);

           block_path = files.file_paths{1};
        end
    end
end

