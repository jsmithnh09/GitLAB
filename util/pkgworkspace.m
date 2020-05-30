function out = pkgworkspace()
    % PKGWORKSPACE packages the current workspace into a struct.
    %   OUT = PKGWORKSPACE
    %       OUT (struct) is a struct in ('Name1', Value1, ...) format.
    %
    % Errors Thrown:
    %   None
    %
    % See Also: EVALIN
    %
    % Contact: Jordan R. Smith
    
    % get the workspace names.
    workvars = evalin('caller', 'who');
    workvars = workvars(:).';
    
    % pre-allocate the contents of the struct.
    contents = cell(2, numel(workspacevars));
    contents(1,:) = workvars;
    
    for iVar = 1 : size(contents, 2)
        contents{2, iVar} = evalin('caller', contents{1, iVar});
    end
    out = struct(contents{:});
end
        
    


