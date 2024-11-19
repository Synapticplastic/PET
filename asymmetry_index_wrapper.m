function asymmetry_index_wrapper(inputs_file)
    
    % Parse inputs
    if ~nargin || ~isfile(inputs_file)
        current_dir = fileparts(mfilename('fullpath'));

        % use similar structure in input text file - paths can be to DCM dirs or NIfTIs        
        inputs = ['{' ...
            '"PET": "' current_dir '", ' ...
            '"T1": "' current_dir '" , ' ...
            '"FLAIR": "' current_dir '", ' ...
            '"output_dir": "' current_dir '", ' ...
            '"viz": 1' ...
            '}']; 

    else
        fid = fopen(inputs_file, 'r'); inputs = fscanf(fid, '%c'); fclose(fid);
    end
    inputs(strfind(inputs,'\'))='/';
    inputs = jsondecode(inputs);

    for i = 1:5
        inputs = feval(['Step' num2str(i)], inputs);
    end

end