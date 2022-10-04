% ==========================
% VERSION NUMBER TESTING
% ==========================
%
% Using the positive and negative test result cases from the regex examples
% provided <a href="matlab:web('https://regex101.com/r/vkijKf/1/', '-browser')">through this site</a>


% PASS...test the splat string is correct.
cwd = fileparts(mfilename('fullpath'));
fdata = strsplit(fileread(fullfile(cwd, "test_vnum_positive.txt")), newline);
for fIdx = 1:size(fdata, 1)
    input = fdata{fIdx};
    if (input(end) == newline) || (input(end) == char(13))
        input = input(1:end-1);
    end
    vnum = VersionNumber(input);
    assert(strcmp(vnum.v_str, input), ...
        "Malformed VersionNumber string using case on line %d.", fIdx);
end

% FAIL...test that they fail to construct.
fdata = strsplit(fileread(fullfile(cwd, "test_vnum_negative.txt")), newline);
for fIdx = 1:size(fdata, 1)
    input = fdata{fIdx};
    if (input(end) == newline) || (input(end) == char(13))
        input = input(1:end-1);
    end
    failure = false;
    try
        vnum = VersionNumber(input);
    catch
        failure = true;
    end
    if (~failure)
        error("Did not experience expected fail from case on line %d.", fIdx);
    end
end
