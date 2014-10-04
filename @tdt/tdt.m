classdef (Hidden) tdt
    %
    %   Class:
    %   tdt
    
    properties
    end
    
    methods (Static)
        function names = eventTypeToString(types)
            %TDT_eventTypeToString Converts numerical value to string type
            %
            %   names = TDT_eventTypeToString(types)
            %
            %   INPUT
            %   ================================================
            %   types : an array of numerical values
            %
            %   OUTPUT
            %   ================================================
            %   names : (cellstr) names of types
            %
            %   EXAMPLE
            %   =============================================
            %   names = TDT_eventTypeToString(33281)
            %   names => {'Snip'}
            
            %DOCUMENTATION: -> EvTypeToString function in OpenDeveloper
            %hex                 0         101       102       201      8101     8201   8801   8000
            %decimal conversion ...
            EV_TYPES   = uint32([0         257       258       513      33025    33281  34817  33025]);
            %EV_NAMES   =       {'Unknown' 'Strobe+' 'Strobe-' 'Scalar' 'Stream' 'Snip' 'Mark' 'HasData'}; Based on documentation
            EV_NAMES   =       {'Unknown' 'Strobe+' 'Strobe-' 'Scalar' 'Stream' 'Snip' 'Unknown' 'Stream'}; %reality
            
            [~,loc] = ismember(types,EV_TYPES);
            
            if any(loc == 0)
                error('Some of the event types were not recognized')
            end
            
            names = EV_NAMES(loc);
        end
        function data = getData(header_path,data_path,event_name,channels)
            %
            %   data = tdt.getData(header_path,data_path,channels)
            
            data = mex_getContinuousData(header_path,data_path,event_name,channels);
        end
    end
end
    
