% Script to Coregister PET and FLAIR to T1 and Check Registration
function inputs = Step2(inputs)
    
    % Rewrite header affines using image centre-of-mass
    if inputs.centre_of_mass
        cellfun(@centre_of_mass, {inputs.T1, inputs.PET, inputs.FLAIR});
    end

    % Initialize SPM
    spm('Defaults','fmri');
    spm_jobman('initcfg');
    
    %% Coregister (Estimate & Reslice) PET to T1 then FLAIR to T1
    sources = {'PET', 'FLAIR'};
    curdir = cd(inputs.output_dir); % spm forces registration report into current directory
    for i = 1:2
        matlabbatch{i}.spm.spatial.coreg.estwrite.ref = {inputs.T1};
        matlabbatch{i}.spm.spatial.coreg.estwrite.source = {inputs.(sources{i})};
        matlabbatch{i}.spm.spatial.coreg.estwrite.other = {''};  % No other images
        matlabbatch{i}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
        matlabbatch{i}.spm.spatial.coreg.estwrite.eoptions.sep = [8 4 2 1];  % Separation
        matlabbatch{i}.spm.spatial.coreg.estwrite.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0 0 0 0 0 0]; % restrict to 6 degrees
        matlabbatch{i}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];
        matlabbatch{i}.spm.spatial.coreg.estwrite.roptions.interp = 1;  % Trilinear interpolation
        matlabbatch{i}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
        matlabbatch{i}.spm.spatial.coreg.estwrite.roptions.mask = 0;
        matlabbatch{i}.spm.spatial.coreg.estwrite.roptions.prefix = 'c';  % Prefix 'c' for coregistered images
    end    
    spm_jobman('run', matlabbatch);
    cd(curdir); % return

    for i = 1:2
        [~, nn, ee] = fileparts(inputs.(sources{i}));
        current = fullfile(inputs.output_dir, ['c' nn ee]);
        renamed = strrep(inputs.(sources{i}), 'original', 'coregistered');
        movefile(current, renamed);
        inputs.(['coregistered_' sources{i}]) = renamed;
        original_mat = spm_vol(inputs.(sources{i})).mat;
        coregist_mat = spm_vol(renamed).mat;
        affine = coregist_mat / original_mat;
        if det(affine(1:3, 1:3)) < 0
            warndlg('An undesired flip may have occurred during registration.', 'Undesired Flip');
        end
    end

    % Use SPM's Check Registration function to compare images
    if inputs.viz
        disp('Opening Check Reg for T1, PET, and FLAIR...');
        spm_check_registration(inputs.T1, inputs.coregistered_PET, inputs.coregistered_FLAIR);
        disp('Viewer is open. Press any key in the command window to continue.');
        pause; % Waits for any key press in the command window            
        disp('Coregistration and visual check completed successfully.');
    else
        disp('Coregistration completed successfully.');
    end

end

function centre_of_mass(img_path)

    hdr = spm_vol(img_path);
    vol = spm_read_vols(hdr); 
    [I, J, K] = ind2sub(size(vol), find(~isnan(vol))); % Only non-NaN values
    vox = [I(:) J(:) K(:)];
    cds = (hdr.mat(1:3, 1:3) * vox')';
    centre = sum(cds .* vol(:)) / sum(vol(:));
    new_mat = hdr.mat;
    new_mat(1:3, 4) = -centre;
    spm_get_space(img_path, new_mat);

end
