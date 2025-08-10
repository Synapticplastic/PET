function params = asymmetry_index_wrapper(inputs_file)
    
    % Ensure SPM12 is in MATLAB path
    if isempty(which('spm'))
        error('SPM12 not found! Please add SPM12 to your MATLAB path.');
    end

    % Parse inputs
    fid = fopen(inputs_file, 'r'); inputs = fscanf(fid, '%c'); fclose(fid);        
    params.settings = jsondecode(strrep(inputs, '\', '/'));
    
    % Prepare output directory
    params.settings.output_dir = strtrim(params.settings.output_dir);
    if strcmp(params.settings.output_dir(end), filesep)
        params.settings.output_dir(end) = [];
    end
    if ~exist(params.settings.output_dir, 'dir')
        mkdir(params.settings.output_dir)        
    end
    params.outdir = params.settings.output_dir;

    % Execute the workflow
    for i = 1:5
        save([params.outdir filesep 'params_step_' num2str(i) '.mat'], 'params');
        params = feval(['Step' num2str(i)], params);
    end

end