function params = Step5(params)
    
    % Initialize SPM
    spm('defaults', 'PET');
    spm_jobman('initcfg');

    %% FORWARD DEFORMATION
    images = {params.resliced.PET, params.flipped.PET};
    flowfields = {params.flowfields.original, params.flowfields.flipped};
    matlabbatch = cell(2, 1);
    for i = 1:2
        matlabbatch{i}.spm.tools.dartel.crt_warped.flowfields = {flowfields{i}};
        matlabbatch{i}.spm.tools.dartel.crt_warped.images = {{images{i}}};
        matlabbatch{i}.spm.tools.dartel.crt_warped.jactransf = 0;
        matlabbatch{i}.spm.tools.dartel.crt_warped.K = 6;
        matlabbatch{i}.spm.tools.dartel.crt_warped.interp = 1;
    end
    spm_jobman('run', matlabbatch);
    
    %% INVERTED DEFORMATION    
    images = { ...
        strrep(params.original.PET, 'original', 'wresliced'), ...
        strrep(params.original.PET, 'original', 'wflipped') ...
    };
    flowfields = {params.flowfields.original, params.flowfields.original};
    matlabbatch = cell(2, 1);
    for i = 1:2
        matlabbatch{i}.spm.tools.dartel.crt_iwarped.flowfields = {flowfields{i}};
        matlabbatch{i}.spm.tools.dartel.crt_iwarped.images = {images{i}};
        matlabbatch{i}.spm.tools.dartel.crt_iwarped.K = 6;
        matlabbatch{i}.spm.tools.dartel.crt_iwarped.interp = 1;
    end
    spm_jobman('run', matlabbatch);    
        
    %% CALCULATE AI image using the two PET images

    % Prepare outputs
    nnT1 = 'resliced_T1'; nnflipPET = 'flipped_PET'; nnPET = 'resliced_PET';
    o = {['sww' nnflipPET], ['sww' nnPET], 'AIraw', 'product', 'sAI', 'Z_AI_image'};
    outputs = struct;
    for i = 1:length(o)
        outputs.(o{i}) = fullfile(params.outdir, [o{i} '.nii']);
    end
    outputs = renamefields(outputs, {['sww' nnflipPET], ['sww' nnPET]}, {'swwflipPET', 'swwPET'});

    % Smooth inputs
    sm_inputs{1} = ['ww' nnflipPET '_u_rc1' nnT1 '_Template.nii'];
    sm_inputs{2} = ['ww' nnPET '_u_rc1' nnT1 '_Template.nii'];
    sm_inputs = fullfile(params.outdir, sm_inputs);
    spm_smooth(sm_inputs{1}, outputs.swwflipPET, [8 8 8]);
    spm_smooth(sm_inputs{2}, outputs.swwPET, [8 8 8]);
    
    % Raw AI image
    spm_imcalc({outputs.swwflipPET, outputs.swwPET}, outputs.AIraw, '(i1 - i2) ./ max(i1, i2)');
    
    % Restrict to Gray matter    
    spm_imcalc({params.c1T1, outputs.AIraw}, outputs.product, 'i1 .* i2');

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
    V_Z.pinfo = [1; 0; 0];
    V_Z.dt = [spm_type('float32') 0];
    V_Z.fname = outputs.Z_AI_image; % Output filename
    
    % Write the Z-score image to disk
    spm_write_vol(V_Z, Z_data);

    % Read it again (otherwise there is some garbage generated)
    V_Z = spm_vol(V_Z.fname);
    
    % Generate report - this also saves niftis with individual clusters
    min_thr = generate_report(params, V_Z);

    % Generate burn-in image
    perform_burnin(params, V_Z);

    % Show outputs
    disp('Review the final results...');    
    spm('defaults', 'fmri');
    spm_jobman('initcfg');
    spm_orthviews('Reset');
    spm_check_registration(params.original.T1);

    % fiddle with orthviews' internal data to get masking working
    global st;
    st.vols{2} = st.vols{1};
    spm_orthviews('AddTrueColourImage', 1, V_Z.fname, turbo(256), 0, max(Z_data(~isnan(Z_data))), 0);
    spm_orthviews('AddColouredImage', 2, V_Z.fname, [1, 0, 0]);
    mask = ~isnan(Z_data) & Z_data > min_thr;
    data = Z_data / max(Z_data(~isnan(Z_data)));
    cmap = turbo(256);
    Z_RGB = cmap(uint16(uint8(data .* mask * 255)) + 1, :);
    Z_RGB(~mask(:), :) = 0;
    blob = st.vols{2}.blobs{1};
    for i = 1:3
        blob.vol = reshape(Z_RGB(:, i), size(data));
        c = zeros(1, 3);
        c(i) = 1;
        blob.colour = c;
        blob.max = 1;
        blob.min = 0;
        st.vols{2}.blobs{i} = blob;
    end    
    spm_orthviews('Caption', 1, 'See final results (right is right, left is left!)');
    spm_orthviews('Redraw');

end

function final_img = annotate_colourbar(imgs, cmap, clim, cbw)

    % set up
    fontsize = 10;
    label_padding = 5;  % space between labels and colour bar

    % generate tick labels
    max_label_img = render_text_image(sprintf('%.2f', clim(2)), fontsize);
    min_label_img = render_text_image(sprintf('%.2f', clim(1)), fontsize);

    % resize colour bar
    [H, ~, ~] = size(imgs);
    label_h = size(max_label_img, 1) + size(min_label_img, 1) + 2 * label_padding;
    cb_h = H - label_h;
    cmap_img = imresize(cmap, [cb_h 3], 'nearest');
    cbar_rgb = flip(repmat(permute(cmap_img, [1 3 2]), 1, cbw, 1), 1);

    % stack vertically: max label, colorbar, min label
    white = uint8(255);
    max_w = size(max_label_img, 2);
    min_w = size(min_label_img, 2);
    label_w = max([max_w, min_w, cbw]);
    
    % pad label images to match width
    max_label_img = pad_to_width(max_label_img, label_w);
    min_label_img = pad_to_width(min_label_img, label_w);
    cbar_rgb = uint8(255 * pad_to_width(cbar_rgb, label_w));
    
    % add vertical padding
    pad = white * ones(label_padding, label_w, 3, 'uint8');    
    cbar_block = cat(1, max_label_img, pad, cbar_rgb, pad, min_label_img);
    
    % append to main image
    final_img = uint8(255 * ones(H, size(imgs, 2) + size(cbar_block, 2), 3));
    final_img(:, 1:size(imgs,2), :) = uint8(imgs * 255);
    final_img(:, end-size(cbar_block,2)+1:end, :) = cbar_block;

end

function txt_img = render_text_image(txt, fontsize)

    % render text
    f = figure('Visible', 'off', 'Units', 'pixels', 'Color', 'white');
    ax = axes(f, 'Units', 'normalized', 'Position', [0 0 1 1]);
    text(0.5, 0.5, txt, 'FontSize', fontsize, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', ...
        'Color', 'black');
    axis off;
    frame = getframe(ax);
    img = frame.cdata;
    close(f);

    % crop white space
    gray = rgb2gray(img);
    mask = gray < 250;
    [r, c] = find(mask);
    if isempty(r)
        txt_img = img;
        return;
    end
    txt_img = img(min(r):max(r), min(c):max(c), :);

end

function out = pad_to_width(img, target_w)

    % pad image to match width
    w = size(img, 2);
    if w >= target_w
        out = img;
        return
    end
    pad_amt = target_w - w;
    left = floor(pad_amt / 2);
    right = pad_amt - left;
    out = padarray(img, [0 left], 255, 'pre');
    out = padarray(out, [0 right], 255, 'post');

end


function imgs = generate_report_images(t1_path, Z_data, cluster_mask)      

    % set up
    t1_hdr = spm_vol(t1_path);
    t1_vol = spm_read_vols(t1_hdr); 
    cmap = turbo(256);              % hard-coded for now
    crosshair_colour = [0 0 1];     % hard-coded for now
    gap = 10;                       % between-image gap, hard-coded for now
    cbw = 20;                       % colourbar width, hard-coded for now
    
    % prepare background T1-weighted image
    t1_vol(~isfinite(t1_vol)) = 0;
    low_thresh = prctile(t1_vol(:), 0.5);
    high_thresh = prctile(t1_vol(:), 99.5);    
    t1_vol(t1_vol < low_thresh) = low_thresh;
    t1_vol(t1_vol > high_thresh) = high_thresh;
    t1_vol = t1_vol - low_thresh;
    t1_vol = t1_vol / high_thresh;
    shape = size(t1_vol);

    % prepare thresholded cluster Z-data
    max_Z = max(Z_data(~isnan(Z_data)));
    Z_data(~isfinite(Z_data) | ~cluster_mask) = 0;
    Z_data = Z_data / max_Z;
    
    % create a blended 3D colour image
    Z_RGB = cmap(uint16(uint8(Z_data * 255)) + 1, :);
    Z_RGB = reshape(Z_RGB, [t1_hdr.dim 3]);
    RGB = repmat(t1_vol, [1,1,1,3]);
    mask_4D = repmat(cluster_mask, [1,1,1,3]);    
    RGB(mask_4D) = Z_RGB(mask_4D);

    % find focus
    foci = find(max(Z_data(:)) == Z_data);
    if length(foci) == 1  % single peak available
        focus_idx = foci;
    else                  % multiple peaks -> find closest to centre of mass        
        [zi, zj, zk] = ndgrid(1:shape(1), 1:shape(2), 1:shape(3));
        Z_vox = [zi(:) zj(:) zk(:)];
        Z_CoM = sum(Z_vox(cluster_mask(:), :) .* Z_data(cluster_mask)) / sum(Z_data(cluster_mask));
        [fi, fj, fk] = ind2sub(size(cluster_mask), foci);
        foci_vox = [fi(:) fj(:) fk(:)];
        [~, closest] = min(sum((foci_vox - Z_CoM) .^ 2, 2));
        focus_idx = foci(closest);
    end
    [fi, fj, fk] = ind2sub(size(Z_data), focus_idx);
    focus = [fi, fj, fk];

    % iterate through the views
    views = {'axial', 'coronal', 'sagittal'}; % for clarity     
    imgs = [];
    for v = 1:3
        view = views{v};
        switch lower(view)
            case 'axial'    % slice in XY, normal is Z
                img = squeeze(RGB(:, :, focus(3), :)); % [X, Y, RGB]
                img(focus(1), :, :) = repmat(crosshair_colour, [shape(2), 1]);
                img(:, focus(2), :) = repmat(crosshair_colour, [shape(1), 1]);
            case 'coronal'  % slice in XZ, normal is Y            
                img = squeeze(RGB(:, focus(2), :, :)); % [X, Z, RGB]
                img(focus(1), :, :) = repmat(crosshair_colour, [shape(1), 1]);
                img(:, focus(3), :) = repmat(crosshair_colour, [shape(3), 1]);
            case 'sagittal' % slice in YZ, normal is X
                img = squeeze(RGB(focus(1), :, :, :)); % [Y, Z, RGB]
                img(focus(2), :, :) = repmat(crosshair_colour, [shape(2), 1]);
                img(:, focus(3), :) = repmat(crosshair_colour, [shape(3), 1]);
                img = flip(img, 1);
        end
        img = flip(permute(img, [2 1 3]), 1);
        imgs(:, end + 1:end + size(img, 1), :) = img; % all dimensions should be same size due to reslicing
        imgs(:, end + 1:end + gap, :) = ones(size(imgs, 1), gap, 3);
    end

    % append a colour bar
    imgs = annotate_colourbar(imgs, cmap, [0 max_Z], cbw);

end

function nearest_index = find_nearest_valid_peak(peak_index, mask)
    
    if size(peak_index) == 1        
        [fi, fj, fk] = ind2sub(size(mask), peak_index);
        peak_index = [fi(:) fj(:) fk(:)];
    end
    [mi, mj, mk] = ind2sub(size(mask), find(mask));
    mask_indices = [mi(:) mj(:) mk(:)];
    [~, closest] = min(sum((peak_index - mask_indices) .^ 2, 2));
    nearest_index = mask_indices(closest, :);

end

function [label_map, exclude_labels] = read_xml_labels(path)

    % Exclusion keywords
    exclude_labels = [];
    exclude = {'Ventricle', 'White Matter', 'Lat Vent', 'CSF', ...
        'vessel', 'Brain Stem', 'Optic Chiasm'};

    % Read and parse the XML file
    xml = xmlread(path);
    
    % Get all region nodes    
    regions = xml.getElementsByTagName('label');
    
    n = regions.getLength;
    label_map = containers.Map('KeyType', 'int32', 'ValueType', 'char');
    
    for i = 0:n-1
        thisLabel = regions.item(i);
        children = thisLabel.getChildNodes();
        index_val = NaN;
        name_val = '';
        
        for j = 0:children.getLength-1
            node = children.item(j);
            if node.getNodeType() == node.ELEMENT_NODE
                switch char(node.getNodeName())
                    case 'index'
                        index_val = str2double(char(node.getTextContent()));                        
                    case 'name'
                        name_val = strtrim(char(node.getTextContent()));
                        words = split(name_val);
                        if length(words) >= 2 && strlength(words(2)) == 3
                            words(2) = [];
                        end
                        name_val = lower(strjoin(words, ' '));
                end
            end
        end

        if ~isnan(index_val)
            include = all(cellfun(@isempty, regexp(name_val, lower(exclude), 'once')));
            if include
                label_map(index_val) = name_val;
            else
                exclude_labels = [exclude_labels index_val];
            end        
        end
    end    
end

function generate_report_template(report, report_path)

    pad = 5;                        % padding pixels
    dim = 175;                      % image dimensions in pixels
    gap = 10;                       % gap between images in a panel in pixels
    cbw = 20;                       % legend width
    ipw = dim * 3 + gap * 3 + cbw;  % image panel width in pixels

    if ~exist(report_path, 'dir')
        mkdir(report_path)
    end

    % start XML report
    html_path = fullfile(report_path, 'report.html');
    fid = fopen(html_path, 'w');    
    fprintf(fid, [ ...
        '<!DOCTYPE html>\n<html>\n<head>\n<title>Asymmetry Index pipeline report</title><style>' ...
            'table { width: %dpx; border-collapse: collapse; table-layout: fixed; } ' ...
            'td { padding: %dpx; vertical-align: top; } '...
            'tr { page-break-inside: avoid; } ' ...
            'h1 { font-size: 16px; font-family: Aptos; color: #0F4761; } ' ...
            'h2 { font-size: 14px; font-family: Aptos; color: #0F4761; } ' ...
            'h3 { font-size: 12px; font-family: Aptos; font-style: italic; color: #0F4761; } ' ...
        '</style></head>\n<body><table>\n' ], dim * 3 + pad * 4, pad);

    % commence per-cluster reporting
    for r_idx = 1:length(report)

        % subtitle
        fprintf(fid, '<tr><td><h2>Cluster %d</h2></td></tr>', r_idx);

        % images
        fname = ['cluster_' num2str(r_idx) '.png'];
        impath = fullfile(report_path, fname);
        imwrite(report(r_idx).images, impath);
        fprintf(fid, '<tr><td><img src="%s" width="%d" height="%d"></td></tr>', fname, ipw, dim);

        % cluster report
        fprintf(fid, '<tr><td><p>');
        fprintf(fid, '<b>Cluster volume:</b> %.2f cl <br>', report(r_idx).volume / 1e4);
        fprintf(fid, '<b>Highest Z-score:</b> %.2f, <b>mean:</b> %.2f, <b>lowest:</b> %.2f<br>', report(r_idx).max, report(r_idx).mean, report(r_idx).min);
        fprintf(fid, '</p>');

        if isfield(report(r_idx), 'regions') && isfield(report(r_idx), 'peak')
            if length(report(r_idx).regions) == 1 && strcmp(report(r_idx).regions{1}, report(r_idx).peak)
                fprintf(fid, '<p>Cluster involves the %s only.</p>', report(r_idx).peak);
            else
                fprintf(fid, '<p>Cluster peaks in the %s and involves the following areas: %s.</p>', ...
                    report(r_idx).peak, strjoin(report(r_idx).regions, ', '));
            end
        end
        fprintf(fid, '</td></tr>');

    end

    % wrap up and open
    fprintf(fid, '</table></body>\n</html>');    
    fclose(fid);
    web(html_path, '-browser');

end

function min_thr = generate_report(params, V_Z)

    % prepare thresholds    
    if ~isfield(params.settings, 'thr')
        min_thr = 3;
    else
        min_thr = params.settings.thr;
    end

    if isfield(params.settings, 'report') && ~params.settings.report % on by default
        return
    end

    % prepare clustering settings
    conn = 26; % use 26-connectivity for clustering - hard-code for noow
    if ~isfield(params.settings, 'cluster_size') % minimum cluster size in mm³
        min_cluster_size = 100; 
    else
        min_cluster_size = params.settings.cluster_size;
    end

    % prepare data
    Z_data = spm_read_vols(V_Z);

    report_regions = isfield(params.settings, 'regions') && params.settings.regions; % off by default
    if report_regions
        labels_xml_path = fullfile(fileparts(which('spm')), 'tpm', 'labels_Neuromorphometrics.xml');
        [label_map, exclude_labels] = read_xml_labels(labels_xml_path);
        atlas_hdr = spm_vol(strrep(labels_xml_path, '.xml', '.nii'));
        atlas_vol = spm_read_vols(atlas_hdr);
        cutoff_percent = 5; % for each label, minimum % of total cluster volume for it to be reported
    end

    % work out min_cluster_size in voxels
    voxel_size = sqrt(sum(V_Z.mat(1:3, 1:3) .^ 2)); % Size along each axis (X, Y, Z)
    voxel_volume = prod(voxel_size);                % Voxel volume in mm³
    voxel_cluster_size = min_cluster_size / voxel_volume;

    % perform clustering    
    mask = (Z_data - min_thr) > 0;
    mask(isnan(mask)) = 0;
    [labels, nl] = bwlabeln(mask, conn);
    peak_id = labels(Z_data == max(Z_data(:)));

    % remove unwanted clusters
    large_clusters = arrayfun(@(l_idx) sum(labels(:) == l_idx) >= voxel_cluster_size, 1:nl);
    peak_cluster = (1:nl) == peak_id;
    invalid_cluster_idx = find(~large_clusters & ~peak_cluster);
    labels(ismember(labels, invalid_cluster_idx)) = 0;

    % map clusters based on size
    unique_labels = unique(labels(:))';
    label_sizes = arrayfun(@(l_idx) sum(labels(:) == l_idx), unique_labels);
    [~, cluster_sorting] = sort(label_sizes(unique_labels > 0), 'descend');
    [~, inverse_sorting] = sort(cluster_sorting);
    mapping = zeros(size(unique_labels));
    mapping(unique_labels(unique_labels > 0)) = inverse_sorting;
    labels(labels > 0) = mapping(labels(labels > 0)); % 1 = largest cluster, 2 = second largest, etc

    % iterate through clusters     
    report = struct;
    for l_idx = 1:max(labels(:))

        cluster_mask = labels == l_idx;
        cluster_vals = Z_data(cluster_mask);

        % Get the images and cluster mask
        report(l_idx).min = min(cluster_vals);
        report(l_idx).max = max(cluster_vals);
        report(l_idx).mean = mean(cluster_vals);
        report(l_idx).volume = sum(cluster_mask(:)) * voxel_volume;
        report(l_idx).images = generate_report_images(params.resliced.T1, Z_data, cluster_mask);

        % Produce t1-space image
        AS_hdr = V_Z;
        AS_hdr.fname = fullfile(params.outdir, ['cluster_' num2str(l_idx) '.nii']);
        spm_write_vol(AS_hdr, Z_data .* double(cluster_mask));

        if report_regions
    
            % Get it into template space
            matlabbatch = {};
            matlabbatch{1}.spm.tools.dartel.crt_warped.flowfields = {params.flowfields.original};
            matlabbatch{1}.spm.tools.dartel.crt_warped.images = {{AS_hdr.fname}};
            matlabbatch{1}.spm.tools.dartel.crt_warped.jactransf = 0;
            matlabbatch{1}.spm.tools.dartel.crt_warped.K = 6;
            matlabbatch{1}.spm.tools.dartel.crt_warped.interp = 1;
            spm_jobman('run', matlabbatch);
    
            % Read the volume and check which labels it contains
            template_space_cluster_path = fullfile(params.outdir, ['wcluster_' num2str(l_idx) '.nii']);
            TSCH = spm_vol(template_space_cluster_path);
            TSCV = spm_read_vols(TSCH);
            cluster_labels = atlas_vol(TSCV > 0);
            cluster_labels(ismember(cluster_labels, exclude_labels)) = 0;
            unique_labels = unique(cluster_labels);
            unique_counts = arrayfun(@(l) sum(cluster_labels(:) == l), unique_labels);
            unique_counts(unique_labels == 0) = [];
            unique_labels(unique_labels == 0) = [];
            unique_percents = unique_counts / sum(unique_counts) * 100;
            include_labels = unique_labels(unique_percents > cutoff_percent);
            report(l_idx).regions = arrayfun(@(l) label_map(l), include_labels, 'un', 0);
    
            % Also include the region with peak Z
            [~, max_Z] = max(TSCV(:));            
            focus_label = atlas_vol(max_Z);
            if any(focus_label == exclude_labels)
                ijk = find_nearest_valid_peak(max_Z, ~ismember(atlas_vol .* (TSCV > 0), [0 exclude_labels]));
                focus_idx = sub2ind(size(atlas_vol), ijk(1), ijk(2), ijk(3));
                focus_label = atlas_vol(sub2ind(size(atlas_vol), focus_idx));
            end
            report(l_idx).peak = label_map(focus_label);

        end
    end

    % generate report
    generate_report_template(report, fullfile(params.outdir, 'report'));

end

function perform_burnin(params, Z_hdr)
    
    if ~isfield(params.settings, 'burnin') || ~params.settings.burnin % off by default
        return
    end

    thresholds = [3, 4, 5]; % hard-code for now

    if length(thresholds) > 3 % in case custom options allowed later
        warning('Only the last three thresholds will be burned in')
    end

    % prepare data
    burnin_hdr = spm_vol(params.original.T1);
    burnin_vol = spm_read_vols(burnin_hdr);
    burnin_hdr.fname = [params.outdir filesep 'burnin.nii'];
    t1_vol = burnin_vol;
    resliced_hdr = spm_vol(params.resliced.T1);

    % reslice Z_data (currently on "MNI" voxel grid from step 2) back into the original T1 voxel grid    
    orig2mni = inv(resliced_hdr.mat) * burnin_hdr.mat; % since it's already aligned in world space
    dim = burnin_hdr.dim;
    [x, y, z] = ndgrid(1:dim(1), 1:dim(2), 1:dim(3)); % original grid voxel coordinates
    vox_orig = (orig2mni(1:3, 1:3) * [x(:) y(:) z(:)]' + orig2mni(1:3, 4))'; % original grid voxels coordinates in mni grid coordinate space
    interp_vals = spm_sample_vol(Z_hdr, vox_orig(:,1), vox_orig(:,2), vox_orig(:,3), 1); % Z_data values corresponding to the original grid
    Z_data_orig = reshape(interp_vals, dim);

    % burn in Z levels
    for t_idx = 1:length(thresholds)
        mask = Z_data_orig > thresholds(t_idx);
        switch t_idx - (length(thresholds) - 3)
            case 1
                burnin_vol(mask) = max(t1_vol(:)); % white burn-in
            case 2
                burnin_vol(mask) = min(t1_vol(:)); % black burn-in
            case 3
                % we want to find the mean grey and white matter intensities
                % and use the average of those for the burn-in
                t1_mni_hdr = spm_vol(params.resliced.T1);
                t1_mni_vol = spm_read_vols(t1_mni_hdr);
                gm_img = params.c1T1;
                gm_vol = spm_read_vols(spm_vol(gm_img));
                gm_int = sum(t1_mni_vol(gm_vol > 0) .* gm_vol(gm_vol > 0)) / sum(gm_vol(gm_vol > 0));
                wm_img = strrep(params.c1T1, 'c1resliced', 'c2resliced');
                wm_vol = spm_read_vols(spm_vol(wm_img));
                wm_int = sum(t1_mni_vol(wm_vol > 0) .* wm_vol(wm_vol > 0)) / sum(wm_vol(wm_vol > 0));
                grey_intensity = (gm_int + wm_int) / 2;
                burnin_vol(mask) = grey_intensity; % grey burn-in
        end
    end
    
    spm_write_vol(burnin_hdr, burnin_vol);

end