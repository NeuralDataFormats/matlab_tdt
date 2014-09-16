function make_getcontinuousdata

this_dir    = getMfileDirectory;
matlab_root = MATLAB_SVN_ROOT;
mex_support_root = fullfile(matlab_root,'mexSupport');

params.include_path = {mex_support_root};
params.lib_path     = {mex_support_root};
params.libs         = {};
params.objs         = {fullfile(mex_support_root,mexext,['MexSupport.',objext])};
params.src          = ...
    {'TankDataType.cpp', ...
    'ReadTank.cpp',...
    'TankHeaderType.cpp'};
params.target       = 'mex_getContinuousData.cpp';
params.flags        = {};
params.output_dir   = fullfile(fileparts(this_dir),'mex_getContinuousData');
try
    make(params)
catch ME
    simpleExceptionDisplay(ME)
    formattedWarning('Compile Failed\n')
end