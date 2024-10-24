
% Script to Reslice and Flip NIfTI Image Left-to-Right
% This script handles complex affine transformations by first reslicing the NIfTI file

% Specify the input file path
input_file = 'cPET.nii';  % Replace 'X.nii' with your original image filename

% Generate output file names dynamically
[filepath, name, ext] = fileparts(input_file);
resliced_file = fullfile(filepath, ['resliced_' name ext]);  % Temporary resliced file
output_file = fullfile(filepath, ['flip' name ext]);  % Final output file name: 'flipX.nii'

% Step 1: Reslice the NIfTI image to standard orientation
disp('Reslicing the image...');
reslice_nii(input_file, resliced_file);

% Step 2: Load the resliced image
disp('Loading the resliced image...');
nii = load_nii(resliced_file);

% Step 3: Flip the image along the first dimension (Left-Right)
disp('Flipping the image left-right...');
flipped_img = flip(nii.img, 1);  % Flip along dimension 1 (Left-Right for resliced images)

% Step 4: Update the image data with the flipped image
nii.img = flipped_img;

% Step 5: Save the flipped image to the new file
disp(['Saving the flipped image as ', output_file, '...']);
save_nii(nii, output_file);

% Output message
disp(['Flipped image saved successfully as: ', output_file]);


% MATLAB Script to Use SPM12's Check Reg to Compare PET.nii and flipPET.nii

% Ensure SPM12 is in your MATLAB path
if isempty(which('spm'))
    error('SPM12 not found! Please add SPM12 to your MATLAB path.');
end

% Specify the file names for comparison
file1 = 'cPET.nii';  % Original PET image
file2 = 'flipcPET.nii';  % Flipped PET image


% Check if the files exist
if ~exist(file1, 'file')
    error(['File not found: ', file1]);
end

if ~exist(file2, 'file')
    error(['File not found: ', file2]);
end

% Run SPM12 Check Reg with the specified files
disp('Loading SPM Check Reg for comparison...');
spm_check_registration(file1, file2);

disp('Check Reg complete. Please inspect the images in SPM12.');


% Display message to user
disp('Viewer is open. Press any key in the command window to continue.');

% Wait for a key press in the command window
pause;  % Waits for any key press in the command window

% Resume the script after key press
disp('Key pressed. Script resumed.');


% Script to Reslice and Flip NIfTI Image Left-to-Right
% This script handles complex affine transformations by first reslicing the NIfTI file

% Specify the input file path
input_file = 'T1.nii';  % Replace 'X.nii' with your original image filename

% Generate output file names dynamically
[filepath, name, ext] = fileparts(input_file);
resliced_file = fullfile(filepath, ['resliced_' name ext]);  % Temporary resliced file
output_file = fullfile(filepath, ['flip' name ext]);  % Final output file name: 'flipX.nii'

% Step 1: Reslice the NIfTI image to standard orientation
disp('Reslicing the image...');
reslice_nii(input_file, resliced_file);

% Step 2: Load the resliced image
disp('Loading the resliced image...');
nii = load_nii(resliced_file);

% Step 3: Flip the image along the first dimension (Left-Right)
disp('Flipping the image left-right...');
flipped_img = flip(nii.img, 1);  % Flip along dimension 1 (Left-Right for resliced images)

% Step 4: Update the image data with the flipped image
nii.img = flipped_img;

% Step 5: Save the flipped image to the new file
disp(['Saving the flipped image as ', output_file, '...']);
save_nii(nii, output_file);

% Output message
disp(['Flipped image saved successfully as: ', output_file]);


% MATLAB Script to Use SPM12's Check Reg to Compare PET.nii and flipPET.nii

% Ensure SPM12 is in your MATLAB path
if isempty(which('spm'))
    error('SPM12 not found! Please add SPM12 to your MATLAB path.');
end

% Specify the file names for comparison
file1 = 'T1.nii';  % Original PET image
file2 = 'flipT1.nii';  % Flipped PET image

% Check if the files exist
if ~exist(file1, 'file')
    error(['File not found: ', file1]);
end

if ~exist(file2, 'file')
    error(['File not found: ', file2]);
end

% Run SPM12 Check Reg with the specified files
disp('Loading SPM Check Reg for comparison...');
spm_check_registration(file1, file2);

disp('Check Reg complete. Please inspect the images in SPM12.');



% Display message to user
disp('Viewer is open. Press any key in the command window to continue.');

% Wait for a key press in the command window
pause;  % Waits for any key press in the command window

% Resume the script after key press
disp('Key pressed. Script resumed.');



% Script to Reslice and Flip NIfTI Image Left-to-Right
% This script handles complex affine transformations by first reslicing the NIfTI file

% Specify the input file path
input_file = 'cFLAIR.nii';  % Replace 'X.nii' with your original image filename

% Generate output file names dynamically
[filepath, name, ext] = fileparts(input_file);
resliced_file = fullfile(filepath, ['resliced_' name ext]);  % Temporary resliced file
output_file = fullfile(filepath, ['flip' name ext]);  % Final output file name: 'flipX.nii'

% Step 1: Reslice the NIfTI image to standard orientation
disp('Reslicing the image...');
reslice_nii(input_file, resliced_file);

% Step 2: Load the resliced image
disp('Loading the resliced image...');
nii = load_nii(resliced_file);

% Step 3: Flip the image along the first dimension (Left-Right)
disp('Flipping the image left-right...');
flipped_img = flip(nii.img, 1);  % Flip along dimension 1 (Left-Right for resliced images)

% Step 4: Update the image data with the flipped image
nii.img = flipped_img;

% Step 5: Save the flipped image to the new file
disp(['Saving the flipped image as ', output_file, '...']);
save_nii(nii, output_file);

% Output message
disp(['Flipped image saved successfully as: ', output_file]);


% MATLAB Script to Use SPM12's Check Reg to Compare PET.nii and flipPET.nii

% Ensure SPM12 is in your MATLAB path
if isempty(which('spm'))
    error('SPM12 not found! Please add SPM12 to your MATLAB path.');
end

% Specify the file names for comparison
file1 = 'cFLAIR.nii';  % Original PET image
file2 = 'flipcFLAIR.nii';  % Flipped PET image

% Check if the files exist
if ~exist(file1, 'file')
    error(['File not found: ', file1]);
end

if ~exist(file2, 'file')
    error(['File not found: ', file2]);
end

% Run SPM12 Check Reg with the specified files
disp('Loading SPM Check Reg for comparison...');
spm_check_registration(file1, file2);

disp('Check Reg complete. Please inspect the images in SPM12.');


