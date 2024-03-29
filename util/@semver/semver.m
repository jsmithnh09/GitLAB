classdef semver
    % semver follows Semantic Versioning 2.0
    %
    %   OBJ = semver(STR) returns a version object of the form:
    %       <MAJOR>.<MINOR>.<PATCH>-[PRERELEASE]+[BUILD]
    %
    % Since MATLAB does not have direct CI/CD management or the need for 
    % build tracking, we can assume build is less often used. Prerelease 
    % likely will be used for denoting toolbox types, i.e. alpha, beta, 
    % stable, branches, etc.
    %
    % For more information, go to <a href 
    % ="matlab:web('https://semver.org/', '-browser')">The page.</a>


    properties(SetAccess = private, GetAccess = public)
        major uint32 = uint32(0);
        minor uint32 = uint32(0);
        patch uint32 = uint32(0);
        prerelease char = '';
        build char = '';
    end

    properties(Constant)
        RE_BUILD = '((^|.)[0-9a-zA-Z-]+)+';
        RE_PRE = '((^|.)[0-9a-zA-Z-](((?<!0)\d+)|([0-9a-zA-Z-]*[a-zA-Z][0-9a-zA-Z-]*))?)+$';
        RE_TOKENS = '(\d+)\.?(\d+)\.?(\d+)(-[^+]+)?(\+.+)?';
    end

    properties(Dependent)
        v_str
    end

    methods(Static)
        function newval = convert_version(val)
            % CONVERT_VERSION converts the input to a recognized non-negative version integer.
            %
            %   NEWVAL = CONVERT_VERSION(VAL)
            %       NEWVAL (uint32) is the recognized version data-type.
            %
            % See Also: SSCANF, ISSTRPROP

            isinteger = @(x)(x == floor(x));
            if isnumeric(val)
                if ~isinteger(val) || (val < 0)
                    error('Version must be non-negative integer values.');
                end
                newval = val;
            elseif ischar(val)
                if (~all(isstrprop(val, 'digit')) || ~isinteger(sscanf(val, '%i')))
                    error('Version must be non-negative integer values.');
                end
                newval = uint32(sscanf(val, '%i'));
            else
                error('Unknown input type ''%s''. Input must be a numeric or string.', class(val));
            end
        end

        function prstr = convert_prerelease(val)
            % CONVERT_PRERELEASE converts a pre-release or raises errors.
            %
            %      PSTR = CONVERT_PRERELEASE(VAL)
            %           VAL (char) is the converted value.
            %
            % See Also: REGEXP

            if ~ischar(val)
                error('Input pre-release must be a valid string.');
            end
            match = regexp(val, semver.RE_PRE, 'match', 'once');
            if (~strcmp(match, val))
                error('Input consists of 1+ dot-separated/hyphenated alphanumeric identifiers.')
            end
            prstr = val;
        end

        function bstr = convert_build(val)
            % CONVERT_BUILD converts a build string or raises errors.
            %
            %   BSTR = CONVERT_BUILD(VAL)
            %
            % See Also: REGEXP

            if ~ischar(val)
                error('Input pre-release must be a valid string.');
            end
            match = regexp(val, semver.RE_BUILD, 'match', 'once');
            if (~strcmp(match, val))
                error('Input consists of 1+ dot-separated/hyphenated alphanumeric identifiers.')
            end
            bstr = val;
        end

        function flag = prerelease_lt(x, y)
            % PRERELEASE_LT pre-release less than comparison.
            %
            %       FLAG = PRERELEASE_LT(X, Y)
            %           X (char) is the pre-release of X.
            %           Y (char) is the pre-release of Y.
            %           FLAG (logical) indicates true if X < Y.
            %
            % See Also: GT, NE, EQ, LT, LE
            %
            % See rule #11-4 in the Semantic Versioning 2.0 docs.

            if isa(x, 'semver'), x = char(x); end
            if isa(y, 'semver'), y = char(y); end
            x = semver.convert_prerelease(x);
            y = semver.convert_prerelease(y);
            flag = false;
            if (strcmp(x, y))
                return;
            elseif (~isempty(x) && isempty(y))
                flag = true;
                return;
            elseif (isempty(x) && ~isempty(y))
                return;
            else
                prx = regexp(x, '\.', 'split');
                pry = regexp(y, '\.', 'split');
                nprx = numel(prx); npry = numel(pry);
                maxidents = min(nprx, npry);
                identIdx = 0;
                while ((identIdx < maxidents) && ~flag)
                    identIdx = identIdx + 1;
                    prxnum = uint32(sscanf(prx{identIdx}, '%i'));
                    prynum = uint32(sscanf(pry{identIdx}, '%i'));
                    numflags = [~isnan(prxnum), ~isnan(prynum)];
                    if numflags(1) && numflags(2)
                        % both numeric, simple comparison.
                        flag = (prxnum < prynum);
                    elseif numflags(1) && ~numflags(2)
                        % numeric is lower in importance.
                        flag = true;
                    elseif all(~numflags)
                        % both alpha-numeric strings. rule #11-4-2.
                        if ~strcmp(prx{identIdx}, pry{identIdx})
                            flag = issorted({prxnum{identIdx}, prynum{identIdx}});
                            identIdx = maxidents + 1;
                        end
                    end
                end
                % max-case
                if (~flag && identIdx == maxidents)
                    flag = (nprx < npry);
                end
            end
        end % prerelease_lt

        function flag = prerelease_gt(x, y)
            % PRERELEASE_GT tests greater than case.
            %
            %   FLAG = PRERELEASE_GT(X, Y)
            %       FLAG (logical) is the same as ~(x < y).
            %
            % See Also: PRERELEASE_LT

            flag = semver.prerelease_lt(y, x);
        end
    end

    methods
        function obj = semver(version)
            % semver constructor.
            if (nargin > 0)
                if (isa(version, 'semver'))
                    obj = version;
                else
                    obj.v_str = version;
                end
            else
                % assumed default of version 1.
                obj.v_str = '1.0.0';
            end
        end

        function y = char(obj)
            % return the underlying version string.
            y = obj.v_str;
        end

        function varargout = expand(obj)
            % EXPAND the versions into individual values.
            %
            %   [MAJOR, MINOR, PATCH, PRE, BLD] = EXPAND(OBJ)
            %
            % See Also: LT

            out = cell(1, 5);
            out{1} = obj.major;
            out{2} = obj.minor;
            out{3} = obj.patch;
            out{4} = obj.prerelease;
            out{5} = obj.build;
            varargout{1:nargout} = out{1:nargout};
        end

        function val = nextmajor(obj)
            % NEXTMAJOR returns the next major version number.
            %
            %   VAL = NEXTMAJOR(OBJ)
            %
            % See Also: NEXTMINOR, NEXTPATCH

            val = obj;
            val.major = uint32(val.major + 1);
            val.minor = uint32(0);
            val.patch = uint32(0);
        end

        function val = nextminor(obj)
            % NEXTMAJOR returns the next major version number.
            %
            %   VAL = NEXTMINOR(OBJ)
            %
            % See Also: NEXTMINOR, NEXTPATCH

            val = obj;
            val.minor = uint32(val.minor + 1);
            val.patch = uint32(0);
        end

        function val = nextpatch(obj)
            % NEXTPATCH returns the next patch version number.
            %
            %   VAL = NEXTPATCH(OBJ)
            %
            % See Also: NEXTMAJOR, NEXTMINOR

            val = obj;
            val.patch = uint32(val.patch + 1);
        end

        function disp(obj)
            % DISP displays the versions.
            N = numel(obj);
            if (N == 1)
                out = ['v', obj.v_str];
            else
                out = cell(numel(obj), 1);
                for svIdx = 1:numel(obj)
                    out{svIdx} = ['v', obj(svIdx).v_str];
                end
                out = sprintf('[ %s ]', strjoin(out, ', '));
            end
            disp(out);
        end

        function str = get.v_str(obj)
            % GET.V_STR returns the underlying version string.
            %
            % String follows semantics:
            %   <MAJOR>.<MINOR>.<PATCH>-<PRERELEASE>+<BUILD>
            %
            % See Also: DISP

            str = sprintf('%i.%i.%i', obj.major, obj.minor, obj.patch);
            if (~isempty(obj.prerelease))
                str = sprintf('%s-%s', str, obj.prerelease);
            end
            if (~isempty(obj.build))
                str = sprintf('%s+%s', str, obj.build);
            end
        end

        %%% COMPARISON METHODS %%%
        function flag = eq(obj, x)
            % EQ equal to (==).
            if ischar(x), x = semver(x); end
            flag = isequal(obj, x);
        end
        function flag = ne(obj, x)
            % NE not equal to (~=).
            if ischar(x), x = semver(x); end
            flag = ~isequal(obj, x);
        end
        function flag = ge(obj, x)
            % GE greater than or equal to (>=).
            if ischar(x), x = semver(x); end
            flag = (eq(obj, x) | gt(obj, x));
        end
        function flag = gt(obj, x)
            % GT greater than (>).
            if ischar(x), x = semver(x); end
            flag = ~le(obj, x);
        end
        function flag = le(obj, x)
            % LE less than or equal to (<=).
            if ischar(x), x = semver(x); end
            flag = (eq(obj, x) | lt(obj, x));
        end
        function flag = lt(obj, x)
            % LT less than determines if O1 < O2.
            %
            % If O1 expands to X.Y.Z, and O2 expands to A.B.C:
            %   1: X < A
            %   2: X == A, Y < B
            %   3: X == A, Y == B, Z < C
            %   4: X == A, Y == B, Z == C, pre1 < pre2

            % instead of layered-if like in Julia, we'll use logical short-circuiting.
            if ischar(x), x = semver(x); end
            flag = ((obj.major < x.major) || ...
                (obj.major == x.major && obj.minor < x.minor) || ...
                (obj.major == x.major && obj.minor == x.minor && obj.patch < x.patch) || ...
                (obj.major == x.major && obj.minor == x.minor && obj.patch == x.patch && obj.prerelease_lt(obj, x)));
            return;
        end

        %%% SET METHODS %%%

        function obj = set.major(obj, val)
            val = convertStringsToChars(val);
            obj.major = obj.convert_version(val);
        end
        function obj = set.minor(obj, val)
            val = convertStringsToChars(val);
            obj.minor = obj.convert_version(val);
        end
        function obj = set.patch(obj, val)
            val = convertStringsToChars(val);
            obj.patch = obj.convert_version(val);
        end
        function obj = set.prerelease(obj, val)
            val = convertStringsToChars(val);
            obj.prerelease = obj.convert_prerelease(val);
        end
        function obj = set.build(obj, val)
            val = convertStringsToChars(val);
            obj.build = obj.convert_build(val);
        end

        function obj = set.v_str(obj, val)
            % SET.V_STR sets the entire version string.
            %
            %   OBJ = SET.V_STR(OBJ, VAL)
            %       OBJ (semver) is the version number.
            %       VAL (char) is the new version number to assign.
            %
            % See Also: REGEXP

            val = convertStringsToChars(val);
            tokens = regexp(val, obj.RE_TOKENS, 'tokens', 'once');
            ntoks = numel(tokens);
            if (ntoks < 3)
                error('Version numbers must have at least <MAJOR>.<MINOR>.<PATCH> format.');
            end
            obj.major = uint32(sscanf(tokens{1}, '%i'));
            obj.minor = uint32(sscanf(tokens{2}, '%i'));
            obj.patch = uint32(sscanf(tokens{3}, '%i'));
            if (ntoks > 3) && ~isempty(tokens{4})
                % strip hyphen guard in <...>-<PRERELEASE>+<BUILD>
                obj.prerelease = tokens{4}(2:end);
            end
            if (ntoks > 4) && ~isempty(tokens{5})
                % strip plus guard.
                obj.build = tokens{5}(2:end);
            end
            if (~strcmp(val, obj.v_str))
                error('Malformed semantic version "%s" specified', val);
            end
        end

        function obj = sort(obj)
            % SORT does a bubble-sort based on the object comparison methods.
            %
            %   OBJ = SORT(OBJ)
            %
            % See Also: LE

            num = numel(obj);
            for j = 0:num-1
                for i = 1:num-j-1
                    if obj(i) > obj(i+1)
                        swap = obj(i);
                        obj(i) = obj(i+1);
                        obj(i+1) = swap;
                    end
                end
            end
        end
    end
end
