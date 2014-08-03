classdef header
    %
    %   Class:
    %   tdt.header
    
    properties
       file_path 
    end
    
    methods
        function obj = header(file_path)
           obj.file_path = file_path;
           obj.initializeObject(); 
        end
    end
    
end

