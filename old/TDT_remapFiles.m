function TDT_remapFiles(c_or_tank_path,blockNr,oldNumbers,newNumbers)

error('Function not yet implemented')

%JAH TODO: Implement file checking ...

WORDS_PER_ENTRY = 10;

fStruct = TDT_getBlockFiles(c_or_tank_path,blockNr);

fid   = fopen(fStruct.header_path,'r');
words = fread(fid,[2*WORDS_PER_ENTRY inf],'*uint16'); %Notice change to uint16 and reading by 2
fclose(fid);

%words 1 - 3 are indices 1 - 6 now
%channel is now 7

%Oops, it isn't that easy
%This only works if the event is what we want
%i.e. don't do this for analog ...

words(7,:) = substituteValues(words(7,:),oldNumbers,newNumbers);


