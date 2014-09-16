cat_name = 'Olympia';
[C,C2]   = setupConvPathForCat(cat_name);

events = getEventsByTrial(cat_name, 133, true);
