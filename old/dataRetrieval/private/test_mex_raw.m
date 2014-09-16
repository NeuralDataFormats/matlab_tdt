
blockno  = 310;
cat_name = 'Import';
event    = 'raw1';

[C,C2]  = setupConvPathForCat(cat_name);
tank_root   = fullfile(C.TANK_PATH,sprintf('Block-%d',blockno));

[tev_filename,tev_found] = getFileByNumber(tank_root,'Block',blockno,'tev',0,true);
[tsq_filename,tsq_found] = getFileByNumber(tank_root,'Block',blockno,'tsq',0,true);
if ~(tev_found && tsq_found)
   formattedWarning('Could not locate TSQ and TEVs')
end

in_channels = 1;
tic
[my_data, out_channels] = mex_getContinuousData( ...
    fullfile(tank_root,tsq_filename), ...
    fullfile(tank_root,tev_filename), ...
    event,in_channels);
toc
% my_data = single(my_data);
% b_compare = true;
% if b_compare
%     b_load = false;
%     tic
%     if ~b_load
%         startConnectTDT(C.TANK_PATH,blockno)
%         tdt_data = getContinuousData(event,out_channels,false);
%         class(tdt_data)
%         save raw1 tdt_data
%     else
%         load('raw1.mat');
%     end
%     toc
%     
%     N = min(size(my_data,1),size(tdt_data,1));
%     size(my_data)
%     size(tdt_data)
%     
%     size(tdt_data,1) - N
%     
%     % Calculate error between my result and TDT result, if its larger than eps
%     % throw an error; shame Ayers
%     for iiChannel = 1:min(size(my_data,2),size(tdt_data,2))
%         err = sum(my_data(1:N,iiChannel) - tdt_data(1:N,iiChannel));
%         if abs(err) > eps
%             figure;
%             h1 = subplot(2,1,1);
%             plot(my_data(1:N,iiChannel),'r');
%             title('mine')
%             h2 = subplot(2,1,2);
%             plot(tdt_data(1:N,iiChannel),'b')
%             title('theirs')
%             linkaxes([h1 h2],'xy');
%             error('Error exceeds max');
%         end
%     end
% end