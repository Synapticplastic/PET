function asymmetry_index_wrapper(inputs_file)
    
    % Ensure SPM12 is in MATLAB path
    if isempty(which('spm'))
        error('SPM12 not found! Please add SPM12 to your MATLAB path.');
    end

    % Parse inputs
    fid = fopen(inputs_file, 'r'); inputs = fscanf(fid, '%c'); fclose(fid);        
    inputs = jsondecode(strrep(inputs, '\', '/'));

    % Check that all files exist
    img_types = {'T1', 'PET', 'FLAIR'};
    for i = 1:3
        if ~exist(inputs.(img_types{i}), 'file')
            error(['Source image not found: ', inputs.(img_types{i})]);
        end
    end

    % Check output directory exists or create it
    if ~exist(inputs.output_dir, 'dir')
        mkdir(inputs.output_dir)
    end

    % Execute the workflow
    for i = 1:5
        save([inputs.output_dir filesep 'inputs_step_' num2str(i) '.mat'], 'inputs');
        inputs = feval(['Step' num2str(i)], inputs);
    end

end