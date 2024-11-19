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
        ref_image = fullfile(pwd, 'T1.nii');  % Reference image
        pet_image = fullfile(pwd, 'PET.nii');  % Source PET image
        flair_image = fullfile(pwd, 'FLAIR.nii');  % Source FLAIR image
    else
        ref_image = inputs.T1;
        pet_image = inputs.PET;
        flair_image = inputs.FLAIR;
    end
    
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
    
    %% Coregister (Estimate & Reslice) PET to T1 then FLAIR to T1
    sources = {pet_image, flair_image};
    for i = 1:2
        matlabbatch{i}.spm.spatial.coreg.estwrite.ref = {ref_image};
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

    fn = {'T1', 'PET', 'FLAIR', 'cPET', 'cFLAIR'};
    [ff, nn, ee] = fileparts(pet_image); cPET = fullfile(ff, ['c' nn ee]);
    [ff, nn, ee] = fileparts(flair_image); cFLAIR = fullfile(ff, ['c' nn ee]);
    vl = {ref_image, pet_image, flair_image, cPET, cFLAIR};
    for i = 1:5
        inputs.(fn{i}) = vl{i};
    end

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
