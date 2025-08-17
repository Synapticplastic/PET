function params = PET_AI_Step3(params)

    %% TISSUE SEGMENTATION

    disp('Creating Gray/White matter maps for the original orientation.');   
    spm('defaults', 'FMRI');
    PET_AI_segment(params.resliced.T1, params.resliced.FLAIR);
    disp('Finished creating Gray/White matter maps for the original orientation. Now moving to MNI space and doing the flips.');   

    %% MNI-ALIGNED VOXEL GRID + FLIP
        
    % get a rigid transform to MNI space
    t1_world2mni = load(strrep(params.resliced.T1, '.nii', '_seg8.mat'), 'Affine').Affine; % non-rigid
    A = t1_world2mni(1:3,1:3);
    [U, ~, V] = svd(A);
    R = U * V'; 
    if det(R) < 0 % avoid flips
        U(:, 3) = -U(:, 3);
        R = U * V';
    end
    T = R * A \ t1_world2mni(1:3, 4); 
    t1_world2mni_rigid = eye(4);
    t1_world2mni_rigid(1:3, 1:3) = R; % rigid rotation
    t1_world2mni_rigid(1:3, 4)   = T; % rigid translation
    params.MNI_rigid = t1_world2mni_rigid;

    % rotate original voxels to MNI space, reslice, flip
    fn = {'PET', 'T1', 'FLAIR'};

    for i = 1:3        
        
        if strcmp(fn{i}, 'T1')
            base_img = params.original.T1;
        else
            base_img = params.hdr_reg.(fn{i});
        end
        params.MNI_aligned.(fn{i}) = strrep(params.original.(fn{i}), 'original', 'MNI_aligned');
        h = spm_vol(base_img);
        v = spm_read_vols(h);
        h.mat = t1_world2mni_rigid * h.mat;
        h.fname = params.MNI_aligned.(fn{i});
        spm_write_vol(h, v);
        PET_AI_reslice(params.MNI_aligned.(fn{i}), params.MNI_aligned.(fn{i}));

        params.flipped.(fn{i}) = strrep(params.original.(fn{i}), 'original', 'MNI_flipped');
        h = spm_vol(params.MNI_aligned.(fn{i}));
        v = flip(spm_read_vols(h), 1);
        h.fname = params.flipped.(fn{i});
        spm_write_vol(h, v);

        if ~isfield(params.settings, 'viz') || params.settings.viz
    
            % Run SPM12 Check Reg with the specified files
            disp('Loading SPM Check Reg for comparison...');
            close all
            spm_check_registration(params.MNI_aligned.(fn{i}), params.flipped.(fn{i}));
            spm_orthviews('Caption', 1, sprintf('Please confirm that the flip was applied\nalong the correct axis.'));
            spm_orthviews('Redraw');
            disp('Check Reg complete. Please confirm that the flip was applied along the correct axis.');
            disp('Viewer is open. Press any key in the command window to continue.');
            pause;  % Waits for any key press in the command window
            disp('Key pressed. Script resumed.');
            close all

        end
    end

    % update the tissue segmentation results
    for i = 1:2

        % first, reslice the c1 / c2 images accordingly
        map_prefix = ['c' num2str(i) 'resliced'];
        map = strrep(params.resliced.T1, 'resliced', map_prefix);
        MNI_map = strrep(map, 'resliced', 'MNI_aligned');
        h = spm_vol(map);
        v = spm_read_vols(h);
        h.mat = t1_world2mni_rigid * h.mat;
        h.fname = MNI_map;
        spm_write_vol(h, v);
        PET_AI_reslice(MNI_map, MNI_map);
        params.(['c' num2str(i) 'T1']) = MNI_map;

        % next, update and rename the template space ones
        template_map = strrep(map, map_prefix, ['r' map_prefix]);
        tmap = nifti(template_map); 
        tmap.mat0 = t1_world2mni_rigid * tmap.mat0; % spm uses qform for linking to original data (MNI_aligned in this case)
        create(tmap); 
        movefile(template_map, strrep(template_map, 'resliced', 'MNI_aligned'));
        
    end    

end