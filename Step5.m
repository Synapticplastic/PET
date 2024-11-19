function inputs = Step5(inputs)
    
    % Prepare inputs
    images = {'PET', 'flipcPET', 'T1'};
    if ~nargin
        current_dir = fileparts(mfilename('fullpath'));
        inputs.output_dir = current_dir;
        for i = 1:2
            if i == 2; prefix = 'w'; else; prefix = ''; end
            for j = 1:3
                inputs.(images{j}) = fullfile(current_dir, [prefix images{j} '.nii']);
            end
        end
        inputs.flowfields.original = fullfile(current_dir, 'u_rc1T1_Template.nii');
        inputs.flowfields.flipped = fullfile(current_dir, 'u_rc1flipT1_Template.nii');
    end

    % Initialize SPM
    spm('defaults', 'PET');
    spm_jobman('initcfg');

    ffo = inputs.flowfields.original;
    fff = inputs.flowfields.flipped; 
    flowfields = {ffo, fff, ffo};

    %%FORWARD DEFORMATION
    matlabbatch = cell(3, 1);
    for i = 1:3    
        matlabbatch{i}.spm.tools.dartel.crt_warped.flowfields = {flowfields{i}};
        matlabbatch{i}.spm.tools.dartel.crt_warped.images = {{inputs.(images{i})}};
        matlabbatch{i}.spm.tools.dartel.crt_warped.jactransf = 0;
        matlabbatch{i}.spm.tools.dartel.crt_warped.K = 6;
        matlabbatch{i}.spm.tools.dartel.crt_warped.interp = 1;        
    end
    spm_jobman('run', matlabbatch);
    
    %%INVERTED DEFORMATION
    images = cellfun(@(x) fullfile(inputs.output_dir, ['w' x '.nii']), images, 'un', 0);
    flowfields{2} = ffo;
    matlabbatch = cell(3, 1);
    for i = 1:3
        matlabbatch{i}.spm.tools.dartel.crt_iwarped.flowfields = {flowfields{i}};
        matlabbatch{i}.spm.tools.dartel.crt_iwarped.images = {images{i}};
        matlabbatch{i}.spm.tools.dartel.crt_iwarped.K = 6;
        matlabbatch{i}.spm.tools.dartel.crt_iwarped.interp = 1;        
    end
    spm_jobman('run', matlabbatch);

    o = {'swwflipcPET', 'swwPET', 'AIraw', 'product', 'sAI', 'Z_AI_image'};
    outputs = struct;
    for i = 1:length(o)
        outputs.(o{i}) = fullfile(inputs.output_dir, [o{i} '.nii']);
    end
    
    %%SMOOTH
    sm_inputs = fullfile(inputs.output_dir, {'wwflipcPET_u_rc1T1_Template.nii', 'wwPET_u_rc1T1_Template.nii'});
    spm_smooth(sm_inputs{1}, outputs.swwflipcPET, [8 8 8]);
    spm_smooth(sm_inputs{2}, outputs.swwPET, [8 8 8]);
    
    %% CALCULATE AI image using the two PET images
    
    spm_imcalc({outputs.swwflipcPET, outputs.swwPET}, outputs.AIraw, '(i1 - i2) ./ max(i1, i2)');
    
    %% REstrict to Gray matter
    
    spm_imcalc({outputs.AIraw, inputs.c1T1}, outputs.product, 'i1 .* i2');
    
    %Smooth to 8 FWHM
    
    spm_smooth(outputs.product, outputs.sAI, [8 8 8]);
    
    % Specify the filename of your AI image
    AI_filename = outputs.sAI; % Replace with your actual filename
    
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
    
    % Thresholds to apply
    thresholds = [3, 4, 5];
    
    % Loop over thresholds
    for idx = 1:length(thresholds)

        %% create thresholded image

        Z_threshold = thresholds(idx);
        
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
        
        % Label connected clusters using 26-connectivity
        conn = 26;
        CC = bwconncomp(mask, conn);
        
        % Get cluster sizes
        cluster_sizes = cellfun(@numel, CC.PixelIdxList);
        
        % Retain clusters larger than 100 voxels
        min_cluster_size = 100;
        large_clusters_idx = find(cluster_sizes >= min_cluster_size);
        
        % Initialize an empty image for the clusters
        clustered_Z_data = zeros(size(Z_thresh_data));
        
        % Include clusters larger than 100 voxels
        for i = 1:length(large_clusters_idx)
            idx = CC.PixelIdxList{large_clusters_idx(i)};
            clustered_Z_data(idx) = Z_thresh_data(idx);
        end
        
        % Find the peak AI value in the Z-score image
        [~, peak_index] = max(Z_thresh_data(:));
        
        % Check if the cluster containing the peak AI value is included
        peak_included = any(cellfun(@(c) ismember(peak_index, c), CC.PixelIdxList(large_clusters_idx)));
        
        if ~peak_included
            % Find which cluster contains the peak
            peak_cluster_idx = find(cellfun(@(c) ismember(peak_index, c), CC.PixelIdxList));
            
            % Include this cluster even if it's smaller than 100 voxels
            idx = CC.PixelIdxList{peak_cluster_idx};
            clustered_Z_data(idx) = Z_thresh_data(idx);
        end
        
        % Save the clustered image
        V_clustered = V_AI;
        V_clustered.fname = fullfile(inputs.output_dir, sprintf('Z%d_clustered.nii', Z_threshold)); % Output filename
        spm_write_vol(V_clustered, clustered_Z_data);
    end

    disp('Overlays finished')

    % inputs.viz = 1;
    if inputs.viz
    
        disp('Now proceeding to open viewer...');
        
        % Initialize SPM
        spm('defaults', 'fmri');
        spm_jobman('initcfg');
        
        % Reset the orthviews
        spm_orthviews('Reset');
        
        % Define full paths to images
        imgs = struct;
        imgs.base_image = 'wwT1_u_rc1T1_Template.nii';
        imgs.overlay1 = 'Z3.nii';
        imgs.overlay2 = 'Z4.nii';
        imgs.overlay3 = 'Z5.nii';
        imgs = structfun(@(x) fullfile(inputs.output_dir, x), imgs, 'un', 0);
        
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