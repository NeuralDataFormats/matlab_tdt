function notes = TDT_getNotes(c_or_tank_path,blockNr)
%TDT_getNotes Retrieves TDT notes, mainly useful for getting # of channels
%
%   notes = TDT_getNotes(c_or_tank_path,blockNr)
%
%   EXAMPLE OUTPUT
%   =====================================================================
%   notes (structure) : TDT event names are fields
%         uSti: [1x1 struct]
%         tSti: [1x1 struct]
%         TrgA: [1x1 struct]
%         Dig1: [1x1 struct]
%         Dig2: [1x1 struct]
%         Tick: [1x1 struct]
%         Sync: [1x1 struct]
%         CNT1: [1x1 struct]
%         CNT2: [1x1 struct]
%         BLNK: [1x1 struct]
%         OTPT: [1x1 struct]
%         Stim: [1x1 struct]
%         eNeu: [1x1 struct]
%         pNeu: [1x1 struct]
%         Wave: [1x1 struct]
%   EXAMPLE OF AN EVENT ENTRY
%       StoreName: 'uSti'
%        HeadName: 'uSti/'
%         Enabled: '1'
%        CircType: '3'
%         NumChan: '0'
%      StrobeMode: '1'
%     StrobeBuddy: ''
%          SecTag: ''
%      TankEvType: 'Strobe+'
%       NumPoints: '0'
%      DataFormat: '4'
%      SampleFreq: '0'
%
%   NOTES
%   =====================================================================
%   Notes are primarily used for Workbench display and other UI windows.
%   Presence of an event in this file indicates it was possible to exist,
%   not that any events of that type were captured.
%   
%   See Also:
%   TDT_eventTypeToString
%   TDT_getEventList

%NOTE: The file we are reading has a lot more than just the notes, not sure
%what is actually in the file besides the notes, might contain start and
%end times ...

fStruct = TDT_getBlockFiles(c_or_tank_path,blockNr);

persistent notes_path notesOutput

if strcmp(notes_path,fStruct.notes_path)
    notes = notesOutput;
    return
end

notes_path = fStruct.notes_path;
text = fileread(notes_path);

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

notes = struct;
for i_event = 1:length(event_entries)
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
              temp_cell_array = TDT_eventTypeToString(str2double(curProp{2}));
              tempStruct.(curProp{1}) = temp_cell_array{1};
          otherwise
              tempStruct.(curProp{1}) = curProp{2};
      end
   end
   notes.(entry_name) = tempStruct;
end

notesOutput = notes;

