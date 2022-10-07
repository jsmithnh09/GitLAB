function v = readversion(fpath)
% READVERSION performs a fileread and extracts the first version string.
%
%   V = READVERSION(STR)
%    STR (char) is a string to parse for a semantic version.
%
%   V = READVERSION(FILEPATH)
%    FILEPATH (char) is a filepath to a file to read.
%
% See Also: VERSIONNUMBER

if (nargin < 1) || (~ischar(fpath))
    error('At least one input argument was expected.');
end
if isfile(fpath)
    fstr = strsplit(fileread(fpath), newline);
    for lineIdx = 1:numel(fstr)
        try
            v = readversion(fstr{lineIdx});
        catch
            continue;
        end
        break;
    end
else
    % perform the string parsing.
    match = regexp(fpath, VersionNumber.RE_TOKENS, 'tokens');
    if isempty(match)
        error('No semvers compliant string was found.');
    else
        [major, minor, patch, pre, build] = match{1}{:};
        vstr = sprintf('%s.%s.%s', major, minor, patch);
        if (~isempty(pre))
            vstr = strcat(vstr, pre);
        end
        if (~isempty(build))
            vstr = strcat(vstr, build);
        end
        v = VersionNumber(vstr);
    end
end

end