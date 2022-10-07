%===========================
% TOOLBOX INFO
%===========================
%
% read the file in this directory, ensure we can build the object using the
% folder/fullpath syntax.
%
% second test will see if we can bump the version, (a common occurence.)

CWD = fileparts(mfilename('fullpath'));
try
    [~] = ToolboxInfo(CWD);
catch ME
    error('unable to construct data:\n%s', ME.message);
end
try
    tbx = ToolboxInfo(fullfile(CWD, 'toolbox.cfg'));
catch ME
    error('Unable to construct the tooblox data:\n%s', ME.message);
end

% check that the version bump will work...
tbx.version.v_str = '1.0.0';
newtbx = bumpversion(tbx, 'major');
assert(newtbx.version == '2.0.0');
newtbx = bumpversion(tbx, 'minor');
assert(newtbx.version == '1.1.0');
newtbx = bumpversion(tbx, 'patch');
assert(newtbx.version == '1.0.1');
newtbx = bumpversion(tbx, '0.0.1');
assert(newtbx.version == '0.0.1');
