classdef ToolboxInfo
    % TOOLBOXINFO tracks information around the toolbox.
    %
    %   TOOLBOXINFO provides configuration information for a toolbox,
    %   including info on the remote source code and installation, (namely
    %   dependencies and path alterations.)
    %
    % See Also: VERSIONNUMBER
    
    properties
        name char                 % filename valid unique title.
        title char                % more-descript string of the toolbox.
        version VersionNumber     % the software version #.
        paths cell                % sub-paths that ought to be added.
        deps cell                 % other pkg's the tbx. is reliant on.
        url char                  % the remote source URL.
        branch char               % the branch of code, (assumed "master".)
        exclude cell              % files/folders to exclude from install.
    end

    % Keep the UUID immutable since that is unique to the toolbox.
    properties(GetAccess = public, SetAccess = immutable)
        uuid char
    end

    properties(Constant, Hidden)
        DEFAULT_FNAME = 'toolbox.cfg';
        RE_URL = ['^(?:(?<proto>git|ssh|https)://)' ...
            '?(?:[\w\.\+\-:]+@)?(?<hostname>.+?)(?(<proto>)/|:)' ...
            '(?<path>.+?)(?:\.git)?$'];
    end

    methods
        function obj = ToolboxInfo(state)

            if (nargin < 1) || (~isstruct(state) && ~ischar(state))
                error('Input must be stateful or a filepath.');
            end

            % initialize the state.
            [obj.name, obj.title, obj.url, obj.branch] = deal('');
            obj.version = VersionNumber('0.0.1');
            obj.uuid    = char(javaMethod('toString', java.util.UUID.randomUUID));
            obj.deps    = {''};
            obj.exclude = {''};
            obj.paths   = {''};

            % check if we have something stateful from the input.
            if ischar(state) && isfolder(state)
                targ = fullfile(state, obj.DEFAULT_FNAME);
                if isfile(targ)
                    state = jsondecode(fileread(targ));
                else
                    error('No %s found in specified folder.', ...
                        upper(obj.DEFAULT_FNAME));
                end
            elseif ischar(state) && isfile(state)
                state = jsondecode(fileread(state));
            end

            if isstruct(state)
                keys = fieldnames(state);
                props = properties(obj);
                optprops = {'uuid'; 'deps'; 'paths'; 'exclude'}; % optional
                reqprops = setdiff(props, optprops);
                badInds = ~ismember(reqprops, keys);
                if any(badInds)
                    error('Missing required fields: "%s".', ...
                        strjoin(reqprops(badInds), ', '));
                end
                for kIdx = 1:numel(keys)
                    kname = keys{kIdx};
                    kval = state.(kname);
                    switch lower(kname)
                        case 'name'
                            if ~ischar(kval) || ~isvarname(kval)
                                error('Invalid name-string.');
                            end
                        case {'branch', 'uuid'}
                            if (~ischar(kval))
                                error('Invalid string for field "%s".', kname);
                            end
                        case 'title'
                            if ~ischar(kval) || (numel(kval) >= 70)
                                error('Title must be a string < 70 characters.');
                            end
                        case 'version'
                            kval = VersionNumber(kval);
                        case {'exclude', 'deps', 'paths'}
                            if ischar(kval)
                                kval = {kval};
                            end
                            if (~iscellstr(kval))
                                error('Input "%s" must be a cell-string', kname);
                            end
                        case 'url'
                            if ~isempty(kval) && ...
                                    isempty(regexp(kval, obj.RE_URL, 'tokens'))
                                error('Input URL "%s" is failing the Git regex.', kval);
                            end
                        otherwise
                            continue;
                    end % switch
                    obj.(kname) = kval;
                end
            else
                error('Input state was not a filepath or a valid struct.');
            end
        end

        function obj = bumpversion(obj, vstr)
            % BUMPVERSION bumps the version in the info-state.
            %
            %   OBJ = BUMPVERSION(OBJ, VTYPE)
            %     OBJ (ToolboxInfo) is the toolbox data.
            %     VTYPE (char) indicates "major", "minor", or "patch".
            %
            %   OBJ = BUMPVERSION(OBJ, VSTR)
            %    OBJ (ToolboxInfo) is the toolbox data.
            %    VSTR (char) is the new verison-compliant string.
            %
            % See Also: VERSIONNUMBER

            if isa(vstr, 'VersionNumber')
                vstr = char(vstr);
            end
            if (~ischar(vstr))
                error('Input Version-string is type CHAR.');
            end
            switch vstr
                case 'major'
                    obj.version = nextmajor(obj.version);
                case 'minor'
                    obj.version = nextminor(obj.version);
                case 'patch'
                    obj.version = nextpatch(obj.version);
                otherwise
                    obj.version = VersionNumber(vstr);
            end % v_str
        end

        function write(obj, fpath)
            % WRITE writes the current state to a file.
            %
            %   WRITE(OBJ[, FPATH])
            %       OBJ (ToolboxInfo) is the toolbox data.
            %       FPATH (char, optional) is the filepath to a folder.
            %           Default: PWD
            %
            % See Also: JSONENCODE

            if (nargin < 2)
                fpath = pwd;
            end
            if (ischar(fpath))
                if isfile(fpath)
                    [fpath, ~, ~] = fileparts(fpath);
                elseif (~isfolder(fpath))
                    error('Invalid filepath specified.');
                end
                fpath = fullfile(fpath, obj.DEFAULT_FNAME);
            else
                error('Input FPATH must be type CHAR.');
            end
            props = properties(obj);
            state = cell2struct(repmat({''}, numel(props), 1), props, 1);
            for pIdx = 1:numel(props)
                if strcmp(props{pIdx}, 'version')
                    pval = obj.version.v_str;
                else
                    pval = obj.(props{pIdx});
                end
                state.(props{pIdx}) = pval;
            end
            fid = fopen(fpath, 'wt');
            if (fid == -1)
                error('Unable to open FILEPATH.');
            end
            fprintf(fid, '%s\n', jsonencode(state, 'PrettyPrint', true));
            fclose(fid);
        end % write
            
        function disp(obj)
            % DISPLAY method.
            if (numel(obj) ~= 1)
                fprintf(1, '1x%i ToolboxInfo\n', numel(obj));
            else
                fprintf(1, '[ %s ]\n', upper(obj.name));
                props = properties(obj);
                cprops = setdiff(props, {'name'; 'paths'; 'deps'; 'exclude'});
                for pIdx = 1:numel(cprops)
                    pName = cprops{pIdx};
                    if strcmp(pName, 'version')
                        fprintf(1, '%s = "%s"\n', 'version', obj.version.v_str);
                    else
                        fprintf(1, '%s = "%s"\n', pName, obj.(pName));
                    end
                end
                arrprops = {'paths'; 'deps'; 'exclude'};
                for pIdx = 1:numel(arrprops)
                    pName = arrprops{pIdx};
                    if isempty(obj.(pName){1})
                        continue;
                    end
                    fprintf(1, '%s = ["%s"]\n', pName, ...
                        strjoin(obj.(pName), '", "'));
                end
            end
        end
                


    end
end


