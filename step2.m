% Script to Coregister PET and FLAIR to T1 and Check Registration
function inputs = Step2(inputs)

    % Ensure SPM12 is in your MATLAB path
    if isempty(which('spm'))
        error('SPM12 not found! Please add SPM12 to your MATLAB path.');
    end
    
    % Initialize SPM
    spm('Defaults','fmri');
    spm_jobman('initcfg');
    
    % Define file names
    if ~nargin
        inputs.T1 = fullfile(pwd, 'T1.nii');  % Reference image
        inputs.PET = fullfile(pwd, 'PET.nii');  % Source PET image
        inputs.FLAIR = fullfile(pwd, 'FLAIR.nii');  % Source FLAIR image
        inputs.output_dir = fileparts(mfilename('fullpath'));
    end
    
    % Check that the files exist in the current directory
    if ~exist(inputs.T1, 'file')
        error(['Reference image not found: ', inputs.T1]);
    end
    if ~exist(inputs.PET, 'file')
        error(['Source PET image not found: ', inputs.PET]);
    end
    if ~exist(inputs.FLAIR, 'file')
        error(['Source FLAIR image not found: ', inputs.FLAIR]);
    end
    
    %% Coregister (Estimate & Reslice) PET to T1 then FLAIR to T1
    sources = {inputs.PET, inputs.FLAIR};
    for i = 1:2
        matlabbatch{i}.spm.spatial.coreg.estwrite.ref = {inputs.T1};
        matlabbatch{i}.spm.spatial.coreg.estwrite.source = {sources{i}};
        matlabbatch{i}.spm.spatial.coreg.estwrite.other = {''};  % No other images
        matlabbatch{i}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
        matlabbatch{i}.spm.spatial.coreg.estwrite.eoptions.sep = [4 2 1];  % Separation
        matlabbatch{i}.spm.spatial.coreg.estwrite.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
        matlabbatch{i}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];
        matlabbatch{i}.spm.spatial.coreg.estwrite.roptions.interp = 1;  % Trilinear interpolation
        matlabbatch{i}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
        matlabbatch{i}.spm.spatial.coreg.estwrite.roptions.mask = 0;
        matlabbatch{i}.spm.spatial.coreg.estwrite.roptions.prefix = 'c';  % Prefix 'c' for coregistered images
    end    
    spm_jobman('run', matlabbatch);

    [~, nn, ee] = fileparts(inputs.PET);
    inputs.cPET = fullfile(inputs.output_dir, ['c' nn ee]);
    [~, nn, ee] = fileparts(inputs.FLAIR);
    inputs.cFLAIR = fullfile(inputs.output_dir, ['c' nn ee]);

    %% Check Registration for T1, cPET, and cFLAIR
    % Use SPM's Check Registration function to compare images
    if nargin && inputs.viz
        disp('Opening Check Reg for T1.nii, cPET.nii, and cFLAIR.nii...');
        spm_check_registration(inputs.T1, inputs.cPET, inputs.cFLAIR);
        disp('Coregistration and visual check completed successfully.');
    else
        disp('Coregistration completed successfully.');
    end

end
