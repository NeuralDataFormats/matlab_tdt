classdef block < sl.obj.display_class
    %
    %   Class:
    %   tdt.block
    %
    %   A TDT block can generally be thought of as a trial, although it is
    %   possible to run multiple "trials" (as defined by the user) within 
    %   a single block.
    
    properties
        block_number
        header %tdt.block.header
        paths  %tdt.block.paths
        notes  %tdt.block.notes
        stores
        store_names
    end
    
    methods
        function value = get.stores(obj)
           value = obj.header.stores; 
        end
        function value = get.store_names(obj)
           value = obj.header.store_names; 
        end
    end
    
    methods
        function obj = block(tank,block_number)
            obj.block_number = block_number;
            
            obj.paths  = tdt.block.paths(tank.tank_path,block_number);
            obj.notes  = tdt.block.notes(obj.paths.notes);
            obj.header = tdt.block.header(obj.paths.header,obj.notes);
        end
        function store = getStore(obj,store_name)           
           store_obj = obj.header.getStoreInfo(store_name);
           p = obj.paths;
           switch store_obj.tdt_type
               case 'Stream'
                   store = tdt.stream(store_obj,p.header,p.data,obj.block_number);
               otherwise
                   error('TDT type store type: %s, not yet implemented',store_obj.tdt_type)
           end
        end
    end
    
end

