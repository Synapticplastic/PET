% Script to Coregister PET and FLAIR to T1 and Check Registration
function params = PET_AI_Step2(params)  

    sources = {'PET', 'FLAIR'};

    % reslice T1
    params.resliced.T1 = strrep(params.original.T1, 'original', 'resliced');
    PET_AI_reslice(params.original.T1, params.resliced.T1);

    % Rewrite header affines so image's centre-of-mass is mapped 
    % onto T1's centre-of-mass in world coordinates
    if ~isfield(params.settings, 'centre_of_mass') || params.settings.centre_of_mass
        [T1_CoM, T1_ctr] = centre_of_mass(params.resliced.T1);
        T1_vec = T1_CoM(:) + T1_ctr(:);
        for i = 1:2
            params.CoM.(sources{i}) = strrep(params.original.(sources{i}), 'original', 'CoM');
            centre_of_mass(params.original.(sources{i}), params.CoM.(sources{i}), T1_vec');
        end
        current = 'CoM';
    else
        current = 'original';
    end

    % Initialize SPM
    spm('Defaults','fmri');
    spm_jobman('initcfg');
    
    %% Coregister (Estimate & Reslice) PET to T1 then FLAIR to T1    
    curdir = cd(params.outdir); % spm forces registration report into current directory
    for i = 1:2
        output_path = strrep(params.original.(sources{i}), 'original', 'hdr_reg');
        copyfile(params.(current).(sources{i}), output_path);
        params.hdr_reg.(sources{i}) = output_path; 
        matlabbatch{i}.spm.spatial.coreg.estwrite.ref = {params.resliced.T1};
        matlabbatch{i}.spm.spatial.coreg.estwrite.source = {params.hdr_reg.(sources{i})};
        matlabbatch{i}.spm.spatial.coreg.estwrite.other = {''};  % No other images
        matlabbatch{i}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
        matlabbatch{i}.spm.spatial.coreg.estwrite.eoptions.sep = [8 4 2 1];  % Separation
        matlabbatch{i}.spm.spatial.coreg.estwrite.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0 0 0 0 0 0]; % restrict to 6 degrees
        matlabbatch{i}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];
        matlabbatch{i}.spm.spatial.coreg.estwrite.roptions.interp = 1;  % Trilinear interpolation
        matlabbatch{i}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
        matlabbatch{i}.spm.spatial.coreg.estwrite.roptions.mask = 0;
        matlabbatch{i}.spm.spatial.coreg.estwrite.roptions.prefix = 'reg_check_';  % coregistered & resliced images
    end
    spm_jobman('run', matlabbatch);
    cd(curdir); % return

    for i = 1:2

        % check for unintended flips
        original_mat = spm_vol(params.original.(sources{i})).mat;
        coregist_mat = spm_vol(params.hdr_reg.(sources{i})).mat;
        affine = coregist_mat / original_mat;
        if det(affine(1:3, 1:3)) < 0
            warndlg('An undesired flip may have occurred during registration.', 'Undesired Flip');
        end
        current = strrep(params.original.(sources{i}), 'original', 'reg_check_hdr_reg');
        renamed = strrep(params.original.(sources{i}), 'original', 'resliced');
        movefile(current, renamed);
        params.resliced.(sources{i}) = renamed;

    end    

    % Use SPM's Check Registration function to compare images
    if ~isfield(params.settings, 'viz') || params.settings.viz
        disp('Opening Check Reg for T1, PET, and FLAIR...'); 
        close all
        spm_check_registration(params.resliced.T1, params.resliced.PET, params.resliced.FLAIR);
        spm_orthviews('Caption', 1, sprintf('Check registration quality between\nT1, PET, and FLAIR'));
        spm_orthviews('Redraw');
        disp('Viewer is open. Press any key in the command window to continue.');        
        pause; % Waits for any key press in the command window            
        disp('Coregistration and visual check completed successfully.');
        close all
    else
        disp('Coregistration completed successfully.');
    end

end

function [new_centre, old_centre] = centre_of_mass(img_path, varargin)

    % varargin{1}: output path
    % varargin{2}: shift centre to match this point

    hdr = spm_vol(img_path);
    vol = spm_read_vols(hdr); 
    [I, J, K] = ind2sub(size(vol), find(~isnan(vol))); % Only non-NaN values
    vox = [I(:) J(:) K(:)];
    cds = (hdr.mat(1:3, 1:3) * vox')';
    old_centre = hdr.mat(1:3, 4);
    new_centre = sum(cds .* vol(:)) / sum(vol(:));
    if nargin > 1
        if nargin > 2
            hdr.mat(1:3, 4) = varargin{2} - new_centre;
        else
            hdr.mat(1:3, 4) = -new_centre;
        end
        hdr.fname = varargin{1};
        spm_write_vol(hdr, vol);
    end

end