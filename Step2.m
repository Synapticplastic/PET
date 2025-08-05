% Script to Coregister PET and FLAIR to T1 and Check Registration
function params = Step2(params)
    
    % Begin by reorienting and reslicing T1-weighted image

    % Our goal is to align i,j,k coordinates of the final voxel box to
    % the X,Y,Z axes of MNI space; and have 1mm isotropic voxel grid

    % This will later ensure we are flipping the X-axis correctly, 
    % facilitate downstream processing, and also enable nicer viz

    % We update the header transform such that the world coordinates of 
    % the resliced data remain the same as of the original, such that 
    % the final outputs can be overlaid on the original T1-weighted image
    
    params.resliced.T1 = strrep(params.original.T1, 'original', 'resliced');
    reslice_MNI(params.original.T1, params.resliced.T1);

    sources = {'PET', 'FLAIR'};

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
        spm_check_registration(params.resliced.T1, params.resliced.PET, params.resliced.FLAIR);
        disp('Viewer is open. Press any key in the command window to continue.');
        pause; % Waits for any key press in the command window            
        disp('Coregistration and visual check completed successfully.');
    else
        disp('Coregistration completed successfully.');
    end

end

function reslice_MNI(input_T1, output_T1)

    % Prepare
    in_MNI_hdr = strrep(input_T1, 'original', 'in_MNI_hdr');
    copyfile(input_T1, in_MNI_hdr); % SPM rewrites the header transform of inputs hence a copy    
    MNI = fullfile(fileparts(which('spm')), 'canonical', 'avg152T1.nii');    
    spm('defaults','fmri');
    spm_jobman('initcfg');
    
    % Run registration to MNI (affine 12 DOF)
    matlabbatch{1}.spm.spatial.coreg.estimate.ref = {MNI};
    matlabbatch{1}.spm.spatial.coreg.estimate.source = {in_MNI_hdr};
    matlabbatch{1}.spm.spatial.coreg.estimate.other = {{}};
    matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi'; % normalized mutual info
    matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
    matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.tol = ...
        [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
    matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];
    
    spm_jobman('run', matlabbatch);
    
    % Get coregistered header
    H_orig = spm_vol(input_T1);
    H_MNI = spm_vol(in_MNI_hdr);
    
    % Create a new volume header for output
    bb = [-128 -128 -128; 128 128 128]; % Target bounding box (MNI space, in mm) [minXYZ; maxXYZ]
    vox = [1 1 1]; % Voxel size
    dim = round((bb(2,:) - bb(1,:)) ./ vox); % Compute the dimensions explicitly (should be 256x256x256)    
    VO = struct();
    VO.fname = output_T1; 
    VO.dim = dim;
    VO.mat = diag([vox 1]);
    VO.mat(1:3, 4) = bb(1, :)' + vox(:) / 2;
    mni2orig = inv(H_MNI.mat) * VO.mat; % mni voxels to orig voxels
    VO.mat = H_orig.mat * mni2orig; % mni voxels to orig world xyz
    VO.dt = [spm_type('float32') 0];
    VO.pinfo = [1;0;0];

    % Create a new voxel grid for output and find its coordinates in original space
    [x, y, z] = ndgrid(1:dim(1), 1:dim(2), 1:dim(3));
    vox_orig = (mni2orig(1:3, 1:3) * [x(:) y(:) z(:)]' + mni2orig(1:3, 4))';
    
    % Interpolate input volume at native voxel coords (linear)
    interp_vals = spm_sample_vol(H_orig, vox_orig(:,1), vox_orig(:,2), vox_orig(:,3), 1); 
    Yout = reshape(interp_vals, dim);
    VO = spm_create_vol(VO);
    spm_write_vol(VO, Yout);

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