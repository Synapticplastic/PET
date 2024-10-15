% Script to Coregister PET and FLAIR to T1 and Check Registration

% Ensure SPM12 is in your MATLAB path
if isempty(which('spm'))
    error('SPM12 not found! Please add SPM12 to your MATLAB path.');
end

% Initialize SPM
spm('Defaults','fmri');
spm_jobman('initcfg');

% Define file names
ref_image = 'T1.nii';  % Reference image
pet_image = 'PET.nii';  % Source PET image
flair_image = 'FLAIR.nii';  % Source FLAIR image

% Check that the files exist in the current directory
if ~exist(ref_image, 'file')
    error(['Reference image not found: ', ref_image]);
end
if ~exist(pet_image, 'file')
    error(['Source PET image not found: ', pet_image]);
end
if ~exist(flair_image, 'file')
    error(['Source FLAIR image not found: ', flair_image]);
end

%% Step 1: Coregister (Estimate & Reslice) PET to T1
matlabbatch{1}.spm.spatial.coreg.estwrite.ref = {fullfile(pwd, ref_image)};
matlabbatch{1}.spm.spatial.coreg.estwrite.source = {fullfile(pwd, pet_image)};
matlabbatch{1}.spm.spatial.coreg.estwrite.other = {''};  % No other images
matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.sep = [4 2 1];  % Separation
matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];
matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.interp = 1;  % Trilinear interpolation
matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.mask = 0;
matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.prefix = 'c';  % Prefix 'c' for coregistered images

%% Step 2: Coregister (Estimate & Reslice) FLAIR to T1
matlabbatch{2}.spm.spatial.coreg.estwrite.ref = {fullfile(pwd, ref_image)};
matlabbatch{2}.spm.spatial.coreg.estwrite.source = {fullfile(pwd, flair_image)};
matlabbatch{2}.spm.spatial.coreg.estwrite.other = {''};  % No other images
matlabbatch{2}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
matlabbatch{2}.spm.spatial.coreg.estwrite.eoptions.sep = [4 2 1];  % Separation
matlabbatch{2}.spm.spatial.coreg.estwrite.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
matlabbatch{2}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];
matlabbatch{2}.spm.spatial.coreg.estwrite.roptions.interp = 1;  % Trilinear interpolation
matlabbatch{2}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
matlabbatch{2}.spm.spatial.coreg.estwrite.roptions.mask = 0;
matlabbatch{2}.spm.spatial.coreg.estwrite.roptions.prefix = 'c';  % Prefix 'c' for coregistered images

% Run the Coregistration Batches
spm_jobman('run', matlabbatch);


%% Step 3: Check Registration for T1, cPET, and cFLAIR
% Use SPM's Check Registration function to compare images
disp('Opening Check Reg for T1.nii, cPET.nii, and cFLAIR.nii...');
spm_check_registration('T1.nii', 'cPET.nii', 'cFLAIR.nii');

disp('Coregistration and visual check completed successfully.');
