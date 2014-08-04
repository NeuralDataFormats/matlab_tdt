classdef notes < dynamicprops
    %
    %   Class:
    %   tdt.block.notes
    
    properties
       file_path
       %NOTE: The other propertis are added dynamically
    end
    
    methods
        function obj = notes(notes_path)
            obj.file_path = notes_path;
            obj.initializeObject();
        end
    end
    
end

