function initializeObject(obj)
%
%
%   This is a bit of a hack and unfortunately might break at any time ...
%

text = fileread(obj.file_path);

NOTES_HEADER      = '[USERNOTEDELIMITER]';
STORAGE_DELIMITER = '\[STOREHDRITEM\]';
%grab from [USERNOTEDELIMITER] to [USERNOTEDELIMITER]

I_NOTES_HEADER = strfind(text,NOTES_HEADER);
%Should have 3? -> use 2nd two

%Failed for Delerium block 1

%é ->STORAGE_DELIMITER
%è ->NOTES HEADER

if length(I_NOTES_HEADER) ~= 3
    %Delerium 1 WTF!
    I1 = strfind(text,'èNAME=');
    if length(I1) ~= 1
        error('Unexpected # of headers, not sure how to know what is going on')
    end
    I2 = strfind(text,'è');
    I2 = I2(find(I2 > I1,1))-1;
    STORAGE_DELIMITER = 'é';   
else
    I1 = I_NOTES_HEADER(2)+length(NOTES_HEADER);
    I2 = I_NOTES_HEADER(3)-1;
end

notes_to_parse = text(I1:I2);

event_entries = regexp(notes_to_parse,STORAGE_DELIMITER,'split');
if isempty(event_entries{end})
    event_entries(end) = []; %last one is null
else
    error('It was expected that the last notes entry would be empty')
end

for i_event = 1:length(event_entries)
   %TODO: We should make this a class as well ...
   %tdt.block.note_entry
   curEntry = event_entries{i_event};
   allProps = regexp(curEntry,'NAME=(.*?);.*?VALUE=(.*?);','tokens');
   %allProps -> cell array of cell arrays of length 2
   %first entry in the 2 is the name, 2nd is the value
   entry_name = '';
   tempStruct = struct;
   for i_prop = 1:length(allProps)
      curProp = allProps{i_prop};
      switch curProp{1}
          case 'StoreName'
              entry_name = curProp{2};
              tempStruct.(curProp{1}) = curProp{2};
          case 'TankEvType'
              temp_cell_array = tdt.eventTypeToString(str2double(curProp{2}));
              tempStruct.(curProp{1}) = temp_cell_array{1};
          otherwise
              tempStruct.(curProp{1}) = curProp{2};
      end
   end
   addprop(obj,entry_name);
   obj.(entry_name) = tempStruct;
   %notes.(entry_name) = tempStruct;
end


end