function inputs = Step5(inputs)
    
    % Prepare inputs
    images = {'coregistered_PET', 'flipped_coregistered_PET'};
    
    % Initialize SPM
    spm('defaults', 'PET');
    spm_jobman('initcfg');

    %%FORWARD DEFORMATION
    flowfields = {inputs.flowfields.original, inputs.flowfields.flipped};
    matlabbatch = cell(2, 1);
    for i = 1:2
        matlabbatch{i}.spm.tools.dartel.crt_warped.flowfields = {flowfields{i}};
        matlabbatch{i}.spm.tools.dartel.crt_warped.images = {{inputs.(images{i})}};
        matlabbatch{i}.spm.tools.dartel.crt_warped.jactransf = 0;
        matlabbatch{i}.spm.tools.dartel.crt_warped.K = 6;
        matlabbatch{i}.spm.tools.dartel.crt_warped.interp = 1;
    end
    spm_jobman('run', matlabbatch);
    
    %%INVERTED DEFORMATION
    [~, nn, ee] = cellfun(@(x) fileparts(inputs.(x)), images, 'un', 0);
    images = cellfun(@(n, e) fullfile(inputs.output_dir, ['w' n e]), nn, ee, 'un', 0);
    flowfields = {inputs.flowfields.original, inputs.flowfields.original};
    matlabbatch = cell(2, 1);
    for i = 1:2
        matlabbatch{i}.spm.tools.dartel.crt_iwarped.flowfields = {flowfields{i}};
        matlabbatch{i}.spm.tools.dartel.crt_iwarped.images = {images{i}};
        matlabbatch{i}.spm.tools.dartel.crt_iwarped.K = 6;
        matlabbatch{i}.spm.tools.dartel.crt_iwarped.interp = 1;
    end
    spm_jobman('run', matlabbatch);

    [~, nnT1, ~] = fileparts(inputs.T1);
    [~, nnflipcPET, ~] = fileparts(inputs.flipped_coregistered_PET);
    [~, nnPET, ~] = fileparts(inputs.coregistered_PET);
    o = {['sww' nnflipcPET], ['sww' nnPET], 'AIraw', 'product', 'sAI', 'Z_AI_image'};
    outputs = struct;
    for i = 1:length(o)
        outputs.(o{i}) = fullfile(inputs.output_dir, [o{i} '.nii']);
    end
    outputs = renamefields(outputs, {['sww' nnflipcPET], ['sww' nnPET]}, {'swwflipcPET', 'swwPET'});
    
    %%SMOOTH
    sm_inputs{1} = ['ww' nnflipcPET '_u_rc1' nnT1 '_Template.nii'];
    sm_inputs{2} = ['ww' nnPET '_u_rc1' nnT1 '_Template.nii'];
    sm_inputs = fullfile(inputs.output_dir, sm_inputs);
    spm_smooth(sm_inputs{1}, outputs.swwflipcPET, [8 8 8]);
    spm_smooth(sm_inputs{2}, outputs.swwPET, [8 8 8]);
    
    %% CALCULATE AI image using the two PET images
    
    spm_imcalc({outputs.swwflipcPET, outputs.swwPET}, outputs.AIraw, '(i1 - i2) ./ max(i1, i2)');
    
    % Restrict to Gray matter
    
    spm_imcalc({inputs.c1T1, outputs.AIraw}, outputs.product, 'i1 .* i2');
    
    % Smooth to 8 FWHM
    
    spm_smooth(outputs.product, outputs.sAI, [8 8 8]); % in mm
    
    % Specify the filename of your AI image
    AI_filename = outputs.sAI;
    
    % Load the image header and data
    V_AI = spm_vol(AI_filename);
    AI_data = spm_read_vols(V_AI);
    
    % Flatten the data to a vector
    AI_vector = AI_data(:);
    
    % Exclude zeros and NaNs
    valid_AI = AI_vector(~isnan(AI_vector) & AI_vector ~= 0);
    
    % Compute mean and standard deviation
    mean_AI = mean(valid_AI);
    std_AI = std(valid_AI);
    
    % Compute the Z-score
    Z_data = (AI_data - mean_AI) / std_AI;
    
    % Prepare the header for the Z-score image
    V_Z = V_AI;
    V_Z.fname = outputs.Z_AI_image; % Output filename
    
    % Write the Z-score image to disk
    spm_write_vol(V_Z, Z_data);
    
    % Settings for thresholding
    thresholds = [3, 4, 5];
    conn = 26; % use 26-connectivity for clustering
    if ~isfield(inputs, 'cluster_size') % minimum cluster size in mm³
        min_cluster_size = 100; 
    else
        min_cluster_size = inputs.cluster_size;
    end

    % work out min_cluster_size in voxels
    voxel_size = sqrt(sum(V_AI.mat(1:3,1:3).^2));  % Size along each axis (X, Y, Z)
    voxel_volume = prod(voxel_size);    % Voxel volume in mm³
    voxel_cluster_size = ceil(min_cluster_size / voxel_volume);

    % prepare burn-in image
    if isfield(inputs, 'burnin') && inputs.burnin
        burnin_hdr = spm_vol(inputs.T1);
        burnin_vol = spm_read_vols(burnin_hdr);
        t1_vol = burnin_vol;
        if length(thresholds) > 3
            warning('Only the last three thresholds will be burned in')
        end
        burnin_hdr.fname = [inputs.output_dir filesep 'burnin.nii'];
    end
    
    % Loop over thresholds
    for t_idx = 1:length(thresholds)

        %% create thresholded image

        Z_threshold = thresholds(t_idx);
        
        % Create a copy of the Z-score data
        Z_thresh_data = Z_data;
        
        % Apply threshold: set values <= threshold to NaN
        Z_thresh_data(Z_thresh_data <= Z_threshold) = NaN;
        
        % Subtract threshold to set minimum value at zero
        Z_thresh_data = Z_thresh_data - Z_threshold;
        
        % Rescale the data to enhance contrast
        max_value = nanmax(Z_thresh_data(:));
        if max_value > 0
            Z_thresh_data = Z_thresh_data / max_value;
        end
        
        % Prepare the header for the thresholded image
        V_Z_thresh = V_AI;
        V_Z_thresh.fname = fullfile(inputs.output_dir, sprintf('Z%d.nii', Z_threshold)); % Output filename
        
        % Write the thresholded image to disk
        spm_write_vol(V_Z_thresh, Z_thresh_data);

        %% Perform clustering
                
        % Create a binary mask of non-NaN and positive voxels
        mask = ~isnan(Z_thresh_data) & Z_thresh_data > 0;
        
        % Label connected clusters        
        CC = bwconncomp(mask, conn);
        
        % Get cluster sizes
        cluster_sizes = cellfun(@numel, CC.PixelIdxList);
        
        % Retain clusters larger than 100 mm^3
        large_clusters_idx = find(cluster_sizes >= voxel_cluster_size);
        
        % Initialize an empty image for the clusters
        clustered_Z_data = zeros(size(Z_thresh_data));
        
        % Include clusters larger than the threshold
        for i = 1:length(large_clusters_idx)
            z_idx = CC.PixelIdxList{large_clusters_idx(i)};
            clustered_Z_data(z_idx) = Z_thresh_data(z_idx);
        end
        
        % Find the peak AI value in the Z-score image
        [~, peak_index] = max(Z_thresh_data(:));
        
        % Check if the cluster containing the peak AI value is included
        peak_included = any(cellfun(@(c) ismember(peak_index, c), CC.PixelIdxList(large_clusters_idx)));
        
        if ~peak_included
            % Find which cluster contains the peak
            peak_cluster_idx = find(cellfun(@(c) ismember(peak_index, c), CC.PixelIdxList));
            
            % Include this cluster even if it's smaller than the threshold
            z_idx = CC.PixelIdxList{peak_cluster_idx};
            clustered_Z_data(z_idx) = Z_thresh_data(z_idx);
        end
        
        % Save the clustered image
        V_clustered = V_AI;
        V_clustered.fname = fullfile(inputs.output_dir, sprintf('Z%d_clustered.nii', Z_threshold)); % Output filename
        spm_write_vol(V_clustered, clustered_Z_data);

        % Add to the burn-in image
        if isfield(inputs, 'burnin') && inputs.burnin
            switch t_idx - (length(thresholds) - 3)
                case 1
                    burnin_vol(clustered_Z_data > 0) = max(burnin_vol(:)); % white burn-in
                case 2
                    burnin_vol(clustered_Z_data > 0) = min(burnin_vol(:)); % black burn-in
                case 3
                    gm_img = inputs.c1T1;
                    gm_vox = spm_read_vols(spm_vol(gm_img)) > 0;
                    gm_int = t1_vol(gm_vox);
                    wm_img = strrep(inputs.c1T1, 'c1original', 'c2original');
                    wm_vox = spm_read_vols(spm_vol(wm_img)) > 0;
                    wm_int = t1_vol(wm_vox);
                    grey_intensity = (median(gm_int(:)) + median(wm_int(:))) / 2;
                    burnin_vol(clustered_Z_data > 0) = grey_intensity; % grey burn-in
            end
        end

    end

    if isfield(inputs, 'burnin') && inputs.burnin
        spm_write_vol(burnin_hdr, burnin_vol);
    end    

    disp('Overlays finished')

    if ~isfield(inputs, 'viz') || inputs.viz
    
        disp('Now proceeding to open viewer...');
        
        % Initialize SPM
        spm('defaults', 'fmri');
        spm_jobman('initcfg');
        
        % Reset the orthviews
        spm_orthviews('Reset');
        
        % Define full paths to images
        imgs = struct;        
        imgs.overlay1 = 'Z3.nii';
        imgs.overlay2 = 'Z4.nii';
        imgs.overlay3 = 'Z5.nii';
        imgs = structfun(@(x) fullfile(inputs.output_dir, x), imgs, 'un', 0);
        imgs.base_image = inputs.T1;
        
        % Display the base image using spm_check_registration
        spm_check_registration(imgs.base_image);
        
        % Overlay Z3.nii in yellow
        spm_orthviews('AddColouredImage', 1, imgs.overlay1, [1, 1, 0]);
        
        % Overlay Z4.nii in blue
        spm_orthviews('AddColouredImage', 1, imgs.overlay2, [0, 0, 1]);
        
        % Overlay Z5.nii in red
        spm_orthviews('AddColouredImage', 1, imgs.overlay3, [1, 0, 0]);
        
        % Refresh the display
        spm_orthviews('Redraw');

    end    

end