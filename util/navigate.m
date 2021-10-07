function navigate(location)
	% NAVIGATE navigates to a location on the MATLAB path.
	%
	%	NAVIGATE(LOCATION)
	%		LOCATION (char) is either a directory code, using '-', or a
	%			file on the MATLAB path. The following options are
	%			considered valid:
	%				'-root' 			: changes current directory to the location
	%										of this script.
	%				{'-s', '-save'} 	: saves the current directory statically
	%				{'-h', '-hotswap'}	: navigates to the saved directory, (if any.)
	%				{'-r', '-rewind'} 	: goes back to the previously navigated
	%				{'-erase'}					: clear persistent memory.
	%										directory on the previous function call.
	%
	% Errors Thrown:
	%	GitLAB:navigate:InvalidSyntax
	%	GitLAB:navigate:InvalidValue
	%
	% See Also: CD
	%
	% Contact: Jordan R. Smith

	% check if the user wants info.
	if (nargin == 0)
		eval('help navigate');
		return;
	end

	% validate input arguments.
	if (~ischar(location))
		error('GitLAB:util:navigate:InvalidInput', ...
			'Input argument is not type CHAR.');
	end

	% setup the static locations.
	persistent hotswitch;
	persistent previous;

	% assign the previous directory on the function call.
	if isempty(previous)
		previous = pwd;
		hotswitch = [];
	end
	
	% hold onto the preivous working directory.
	prior = pwd;

	switch location
		case '-root'
			% go to this function's folder.
			[~] = cd(fileparts(mfilename('fullpath')));
		case {'-s', '-save'}
			% SAVE the hotswitch location.
			hotswitch = pwd;
		case {'-h', '-hotswap'}
			if isempty(hotswitch)
				return;
			else
				[~] = cd(hotswitch);
			end
		case {'-r', '-rewind'}
			% REWIND back to the previous directory.
			[~] = cd(previous);
		case '-erase'
			% in case this memory wants to be cleaned up for any reason...
			clear('previous');
			clear('hotswitch');
		otherwise
			% attempt to navigate to the folder of an M-file specified.
			try
				% find the specified application.
				fullpath = which(char(application));
				[filepath, ~, ~] = fileparts(fullpath);

				% finally navigate to the folder.
				[~] = cd(char(filepath));
			catch ME
				error('GitLAB:util:navigate:PathError', ...
					'Couldn''t navigate to folder:\n%s', ME.message);
			end % try
	end % switch

	% after exiting navigation, pass the prior.
	if ~strcmpi(location, '-erase')
		previous = prior;
	end
end % navigate
