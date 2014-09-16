blockno   =248;
cat       = 'Quadzilla';
event     = 'Snip';
b_compare = true;
[C,C2]    = setupConvPathForCat(cat);
tank_root = fullfile(C.TANK_PATH,sprintf('Block-%d',blockno));

[tev_filename,tev_found] = getFileByNumber(...
    tank_root,...
    'Block',...
    blockno,...
    'tev',...
    0,...
    true);

[tsq_filename,tsq_found] = getFileByNumber(...
    tank_root,...
    'Block',...
    blockno,...
    'tsq',...
    0,...
    true);

if ~(tev_found && tsq_found)
    formattedWarning('Could not locate TSQ and TEVs')
end

in_channels = [1:4];
tic
[my_data,out_channels ] = mex_getContinuousData(...
    fullfile(tank_root,tsq_filename),...
    fullfile(tank_root,tev_filename),...
    event,in_channels);
mex_time = toc;


if b_compare
    tic
    tdt_data = getGenericTDTData(C,C2,blockno,event, ...
        'channels',in_channels,'buffer_size',2^30);
    %     startConnectTDT(C.TANK_PATH,blockno)
    %     tdt_data = getContinuousData(event,out_channels,false);
    %     class(tdt_data)
    tdt_time = toc;
    
    fprintf('TDT: %g v Mex: %g: %g speed increas\n',tdt_time,mex_time,tdt_time/mex_time);
    % When retrieved using TDT interface there is a good deal of zero
    % padding this code tests that, and determines the offset so the two
    % vectors can be compared
    N = min(size(my_data,1),size(tdt_data,1));
    size(my_data)
    size(tdt_data)
    
    % Calculate error between my result and TDT result, if its larger than eps
    % throw an error; shame Ayers
    for iiChannel = 1:size(my_data,2)
        error = sum(my_data(1:N,iiChannel) - tdt_data(1:N,iiChannel));
        if abs(error) > eps
            figure;
            h1 = subplot(2,1,1);
            plot(my_data(1:N,iiChannel),'r'); hold all;
            h2 = subplot(2,1,2);
            plot(tdt_data(1:N,iiChannel),'b')
            linaxes([h1 h2],'xy');
            legend('mine','theirs')
            error('Error exceeds max');
        end
    end
else 
    fprintf('%g\n',mex_time);
end
% clear my_data lfpData