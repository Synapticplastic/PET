% Script to Reslice and Flip NIfTI Image Left-to-Right
% This script handles complex affine transformations by first reslicing the NIfTI file

function inputs = Step3(inputs)

    % Ensure SPM12 is in your MATLAB path
    if isempty(which('spm'))
        error('SPM12 not found! Please add SPM12 to your MATLAB path.');
    end

    % Specify the input file path
    if ~nargin
        input_files = {'cPET.nii', 'T1.nii', 'cFLAIR.nii'}; 
        inputs.output_dir = fileparts(mfilename('fullpath'));
    else
        input_files = {inputs.cPET, inputs.T1, inputs.cFLAIR};
    end

    output_files = cell(3, 1);

    for i = 1:3
    
        % Generate output file names dynamically
        [filepath, name, ext] = fileparts(input_files{i});
        resliced_file = fullfile(inputs.output_dir, ['resliced_' name ext]);  % Temporary resliced file
        output_files{i} = fullfile(inputs.output_dir, ['flip' name ext]);  % Final output file name: 'flipX.nii'

        % Step 1: Reslice the NIfTI image to standard orientation
        disp('Reslicing the image...');
        reslice_nii(input_files{i}, resliced_file);
        
        % Step 2: Load the resliced image
        disp('Loading the resliced image...');
        nii = load_nii(resliced_file);
        
        % Step 3: Flip the image along the first dimension (Left-Right)
        disp('Flipping the image left-right...');
        flipped_img = flip(nii.img, 1);  % Flip along dimension 1 (Left-Right for resliced images)
        
        % Step 4: Update the image data with the flipped image
        nii.img = flipped_img;
        
        % Step 5: Save the flipped image to the new file
        disp(['Saving the flipped image as ', output_files{i}, '...']);
        save_nii(nii, output_files{i});
        
        % Output message
        disp(['Flipped image saved successfully as: ', output_files{i}]);        
        
        % MATLAB Script to Use SPM12's Check Reg to Compare X.nii and flipX.nii
        if ~exist(output_files{i}, 'file')
            error(['File not found: ', output_files{2}]);
        end
    
        if inputs.viz
    
            % Run SPM12 Check Reg with the specified files
            disp('Loading SPM Check Reg for comparison...');
            spm_check_registration(input_files{i}, output_files{i});
            disp('Check Reg complete. Please inspect the images in SPM12.');            
            
            % Display message to user
            disp('Viewer is open. Press any key in the command window to continue.');
            
            % Wait for a key press in the command window
            pause;  % Waits for any key press in the command window
            
            % Resume the script after key press
            disp('Key pressed. Script resumed.');
        end
    end
    
    fn = {'flipcPET', 'flipT1', 'flipcFLAIR'};
    for i = 1:3
        inputs.(fn{i}) = output_files{i};
    end

end