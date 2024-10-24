   

%%FORWARD DEFORMATION


% Initialize SPM
spm('defaults', 'PET');
spm_jobman('initcfg');

% Define flowfield and images
flowfield = {'u_rc1T1_Template.nii'};
images = {
    {
        'PET.nii'
    }
};



% Create batch job
matlabbatch = [];
matlabbatch{1}.spm.tools.dartel.crt_warped.flowfields = flowfield;
matlabbatch{1}.spm.tools.dartel.crt_warped.images = images;
matlabbatch{1}.spm.tools.dartel.crt_warped.jactransf = 0;
matlabbatch{1}.spm.tools.dartel.crt_warped.K = 6;
matlabbatch{1}.spm.tools.dartel.crt_warped.interp = 1;

% Run job
spm_jobman('run', matlabbatch);





% Define flowfield and images
flowfield = {'u_rc1flipT1_Template.nii'};
images = {
    {
        'flipcPET.nii'
    }
};

% Create batch job
matlabbatch = [];
matlabbatch{1}.spm.tools.dartel.crt_warped.flowfields = flowfield;
matlabbatch{1}.spm.tools.dartel.crt_warped.images = images;
matlabbatch{1}.spm.tools.dartel.crt_warped.jactransf = 0;
matlabbatch{1}.spm.tools.dartel.crt_warped.K = 6;
matlabbatch{1}.spm.tools.dartel.crt_warped.interp = 1;

% Run job
spm_jobman('run', matlabbatch);





% Define flowfield and images
flowfield = {'u_rc1T1_Template.nii'};
images = {
    {
        'T1.nii'
    }
};

% Create batch job
matlabbatch = [];
matlabbatch{1}.spm.tools.dartel.crt_warped.flowfields = flowfield;
matlabbatch{1}.spm.tools.dartel.crt_warped.images = images;
matlabbatch{1}.spm.tools.dartel.crt_warped.jactransf = 0;
matlabbatch{1}.spm.tools.dartel.crt_warped.K = 6;
matlabbatch{1}.spm.tools.dartel.crt_warped.interp = 1;

% Run job
spm_jobman('run', matlabbatch);






%%INVERTED DEFORMATION

% Define flowfield and images
flowfield = {'u_rc1T1_Template.nii'};
images = {
    
        'wPET.nii'
    
};

% Create batch job
matlabbatch = [];
matlabbatch{1}.spm.tools.dartel.crt_iwarped.flowfields = flowfield;
matlabbatch{1}.spm.tools.dartel.crt_iwarped.images = images;
matlabbatch{1}.spm.tools.dartel.crt_iwarped.K = 6;
matlabbatch{1}.spm.tools.dartel.crt_iwarped.interp = 1;

% Run job
spm_jobman('run', matlabbatch);



%%INVERTED DEFORMATION 2
% Define flowfield and images
flowfield = {'u_rc1T1_Template.nii'};
images = {
    
        'wflipcPET.nii'
    
};

% Create batch job
matlabbatch = [];
matlabbatch{1}.spm.tools.dartel.crt_iwarped.flowfields = flowfield;
matlabbatch{1}.spm.tools.dartel.crt_iwarped.images = images;
matlabbatch{1}.spm.tools.dartel.crt_iwarped.K = 6;
matlabbatch{1}.spm.tools.dartel.crt_iwarped.interp = 1;

% Run job
spm_jobman('run', matlabbatch);




%%INVERTED DEFORMATION 3 (T1)

% Define flowfield and images
flowfield = {'u_rc1T1_Template.nii'};
images = {
    
        'wT1.nii'
    
};

% Create batch job
matlabbatch = [];
matlabbatch{1}.spm.tools.dartel.crt_iwarped.flowfields = flowfield;
matlabbatch{1}.spm.tools.dartel.crt_iwarped.images = images;
matlabbatch{1}.spm.tools.dartel.crt_iwarped.K = 6;
matlabbatch{1}.spm.tools.dartel.crt_iwarped.interp = 1;

% Run job
spm_jobman('run', matlabbatch);


%%
%SMOOTH



spm_smooth('wwflipcPET_u_rc1T1_Template.nii', 'swwflipcPET.nii', [8 8 8]);
spm_smooth('wwPET_u_rc1T1_Template.nii', 'swwPET.nii', [8 8 8]);

%% CALCULATE AI image using the two PET images

spm_imcalc({'swwflipcPET.nii', 'swwPET.nii'}, 'AIraw.nii', '(i1 - i2) ./ max(i1, i2)');

%% REstrict to Gray matter

spm_imcalc({'AIraw.nii', 'c1T1.nii'}, 'product.nii', 'i1 .* i2');

%Smooth to 8 FWHM

spm_smooth('product.nii', 'sAI.nii', [8 8 8]);

% Specify the filename of your AI image
AI_filename = 'sAI.nii'; % Replace with your actual filename

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
V_Z.fname = 'Z_AI_image.nii'; % Output filename

% Write the Z-score image to disk
spm_write_vol(V_Z, Z_data);

% Thresholds to apply
thresholds = [3, 4, 5];

% Loop over thresholds
for idx = 1:length(thresholds)
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
    V_Z_thresh.fname = sprintf('Z%d.nii', Z_threshold); % Output filename
    
    % Write the thresholded image to disk
    spm_write_vol(V_Z_thresh, Z_thresh_data);
end


% Specify the filename of your thresholded Z-score image
Z_filename = 'Z3.nii'; % Replace with your actual filename

% Load the image header and data
V_Z = spm_vol(Z_filename);
Z_data = spm_read_vols(V_Z);

% Create a binary mask of non-NaN and positive voxels
mask = ~isnan(Z_data) & Z_data > 0;

% Label connected clusters using 26-connectivity
conn = 26;
CC = bwconncomp(mask, conn);

% Get cluster sizes
cluster_sizes = cellfun(@numel, CC.PixelIdxList);

% Retain clusters larger than 100 voxels
min_cluster_size = 100;
large_clusters_idx = find(cluster_sizes >= min_cluster_size);

% Initialize an empty image for the clusters
clustered_Z_data = zeros(size(Z_data));

% Include clusters larger than 100 voxels
for i = 1:length(large_clusters_idx)
    idx = CC.PixelIdxList{large_clusters_idx(i)};
    clustered_Z_data(idx) = Z_data(idx);
end

% Find the peak AI value in the Z-score image
[peak_value, peak_index] = max(Z_data(:));

% Check if the cluster containing the peak AI value is included
peak_included = any(cellfun(@(c) ismember(peak_index, c), CC.PixelIdxList(large_clusters_idx)));

if ~peak_included
    % Find which cluster contains the peak
    peak_cluster_idx = find(cellfun(@(c) ismember(peak_index, c), CC.PixelIdxList));
    
    % Include this cluster even if it's smaller than 100 voxels
    idx = CC.PixelIdxList{peak_cluster_idx};
    clustered_Z_data(idx) = Z_data(idx);
end

% Save the clustered image
V_clustered = V_Z;
V_clustered.fname = 'Z3_clustered.nii'; % Output filename
spm_write_vol(V_clustered, clustered_Z_data);


% Specify the filename of your thresholded Z-score image
Z_filename = 'Z4.nii'; % Replace with your actual filename

% Load the image header and data
V_Z = spm_vol(Z_filename);
Z_data = spm_read_vols(V_Z);

% Create a binary mask of non-NaN and positive voxels
mask = ~isnan(Z_data) & Z_data > 0;

% Label connected clusters using 26-connectivity
conn = 26;
CC = bwconncomp(mask, conn);

% Get cluster sizes
cluster_sizes = cellfun(@numel, CC.PixelIdxList);

% Retain clusters larger than 100 voxels
min_cluster_size = 100;
large_clusters_idx = find(cluster_sizes >= min_cluster_size);

% Initialize an empty image for the clusters
clustered_Z_data = zeros(size(Z_data));

% Include clusters larger than 100 voxels
for i = 1:length(large_clusters_idx)
    idx = CC.PixelIdxList{large_clusters_idx(i)};
    clustered_Z_data(idx) = Z_data(idx);
end

% Find the peak AI value in the Z-score image
[peak_value, peak_index] = max(Z_data(:));

% Check if the cluster containing the peak AI value is included
peak_included = any(cellfun(@(c) ismember(peak_index, c), CC.PixelIdxList(large_clusters_idx)));

if ~peak_included
    % Find which cluster contains the peak
    peak_cluster_idx = find(cellfun(@(c) ismember(peak_index, c), CC.PixelIdxList));
    
    % Include this cluster even if it's smaller than 100 voxels
    idx = CC.PixelIdxList{peak_cluster_idx};
    clustered_Z_data(idx) = Z_data(idx);
end

% Save the clustered image
V_clustered = V_Z;
V_clustered.fname = 'Z4_clustered.nii'; % Output filename
spm_write_vol(V_clustered, clustered_Z_data);


% Specify the filename of your thresholded Z-score image
Z_filename = 'Z5.nii'; % Replace with your actual filename

% Load the image header and data
V_Z = spm_vol(Z_filename);
Z_data = spm_read_vols(V_Z);

% Create a binary mask of non-NaN and positive voxels
mask = ~isnan(Z_data) & Z_data > 0;

% Label connected clusters using 26-connectivity
conn = 26;
CC = bwconncomp(mask, conn);

% Get cluster sizes
cluster_sizes = cellfun(@numel, CC.PixelIdxList);

% Retain clusters larger than 100 voxels
min_cluster_size = 100;
large_clusters_idx = find(cluster_sizes >= min_cluster_size);

% Initialize an empty image for the clusters
clustered_Z_data = zeros(size(Z_data));

% Include clusters larger than 100 voxels
for i = 1:length(large_clusters_idx)
    idx = CC.PixelIdxList{large_clusters_idx(i)};
    clustered_Z_data(idx) = Z_data(idx);
end

% Find the peak AI value in the Z-score image
[peak_value, peak_index] = max(Z_data(:));

% Check if the cluster containing the peak AI value is included
peak_included = any(cellfun(@(c) ismember(peak_index, c), CC.PixelIdxList(large_clusters_idx)));

if ~peak_included
    % Find which cluster contains the peak
    peak_cluster_idx = find(cellfun(@(c) ismember(peak_index, c), CC.PixelIdxList));
    
    % Include this cluster even if it's smaller than 100 voxels
    idx = CC.PixelIdxList{peak_cluster_idx};
    clustered_Z_data(idx) = Z_data(idx);
end

% Save the clustered image
V_clustered = V_Z;
V_clustered.fname = 'Z5_clustered.nii'; % Output filename
spm_write_vol(V_clustered, clustered_Z_data);

disp('Overlays finished, now proceeding to open viewer...');

% Initialize SPM
spm('defaults', 'fmri');
spm_jobman('initcfg');

% Reset the orthviews
spm_orthviews('Reset');

% Define full paths to images
base_image = 'wwT1_u_rc1T1_Template.nii';
overlay1 = 'Z3.nii';
overlay2 = 'Z4.nii';
overlay3 = 'Z5.nii';

% Display the base image using spm_check_registration
spm_check_registration(base_image);

% Overlay Z3.nii in yellow
spm_orthviews('AddColouredImage', 1, overlay1, [1, 1, 0]);

% Overlay Z4.nii in blue
spm_orthviews('AddColouredImage', 1, overlay2, [0, 0, 1]);

% Overlay Z5.nii in red
spm_orthviews('AddColouredImage', 1, overlay3, [1, 0, 0]);

% Refresh the display
spm_orthviews('Redraw');




