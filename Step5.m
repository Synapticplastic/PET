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

    nnT1 = 'resliced_T1'; nnflipPET = 'flipped_PET'; nnPET = 'resliced_PET';
    o = {['sww' nnflipPET], ['sww' nnPET], 'AIraw', 'product', 'sAI', 'Z_AI_image'};
    outputs = struct;
    for i = 1:length(o)
        outputs.(o{i}) = fullfile(params.outdir, [o{i} '.nii']);
    end
    outputs = renamefields(outputs, {['sww' nnflipPET], ['sww' nnPET]}, {'swwflipPET', 'swwPET'});
    
    %% CHECK OUTPUTS ONE MORE TIME
    sm_inputs{1} = ['ww' nnflipPET '_u_rc1' nnT1 '_Template.nii'];
    sm_inputs{2} = ['ww' nnPET '_u_rc1' nnT1 '_Template.nii'];
    sm_inputs = fullfile(params.outdir, sm_inputs);

    if ~isfield(params.settings, 'viz') || params.settings.viz
    
        % Run SPM12 Check Reg with the specified files
        disp('Loading SPM Check Reg for comparison...');
        spm_check_registration(sm_inputs{1}, sm_inputs{2});
        disp('Please confirm that the final PET images are mirrored along the correct axis.');
        disp('Viewer is open. Press any key in the command window to continue.');
        pause;  % Waits for any key press in the command window
        disp('Key pressed. Script resumed.');

    end    

    %% SMOOTH
    spm_smooth(sm_inputs{1}, outputs.swwflipPET, [8 8 8]);
    spm_smooth(sm_inputs{2}, outputs.swwPET, [8 8 8]);
    
    %% CALCULATE AI image using the two PET images
    
    spm_imcalc({outputs.swwflipPET, outputs.swwPET}, outputs.AIraw, '(i1 - i2) ./ max(i1, i2)');
    
    % Restrict to Gray matter
    
    spm_imcalc({params.W, outputs.AIraw}, outputs.product, 'i1 .* i2');

    %{
    % Reslice back to the original voxel grid
    
    P = char(params.original.T1, outputs.product);
    flags = struct( ...
        'interp', 1, ...       % 1 = trilinear interpolation
        'wrap', [0 0 0], ...
        'mask', 0, ...
        'which', 1, ...        % 1 = reslice only the second image (src)
        'mean', 0); 

    spm_reslice(P, flags);

    % Smooth to 8 FWHM
    
    spm_smooth(fullfile(params.outdir, 'rproduct.nii'), outputs.sAI, [8 8 8]); % in mm
    %}
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
    V_Z = rmfield(V_AI, 'pinfo');
    V_Z.dt = [16 0];
    V_Z.fname = outputs.Z_AI_image; % Output filename
    
    % Write the Z-score image to disk
    spm_write_vol(V_Z, Z_data);
    
    % prepare thresholds
    thresholds = [3, 4, 5]; % hard-code for now
    min_thr = thresholds(1);    

    %% Perform clustering & generate report
    if ~isfield(params.settings, 'report') || params.settings.report

        % prepare the report
        report = struct;

        % prepare clustering settings
        conn = 26; % use 26-connectivity for clustering - hard-code for noow
        if ~isfield(params.settings, 'cluster_size') % minimum cluster size in mm³
            min_cluster_size = 100; 
        else
            min_cluster_size = params.settings.cluster_size;
        end
    
        % work out min_cluster_size in voxels
        voxel_size = sqrt(sum(V_AI.mat(1:3,1:3).^2));  % Size along each axis (X, Y, Z)
        voxel_volume = prod(voxel_size);    % Voxel volume in mm³
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
        [~, cluster_sorting] = sort(arrayfun(@(l_idx) sum(labels(:) == l_idx), 1:max(labels(:))), 'descend');
        labels(labels > 0) = cluster_sorting(labels(labels > 0)); % 1 = largest cluster, 2 = second largest, etc

        % prepare MNI-related stuff
        %templ_hdr = spm_vol(strrep(params.original.PET, 'original', 'wresliced'));
        [label_map, exclude_labels] = read_xml_labels(fullfile(fileparts(which('spm')), 'tpm', 'labels_Neuromorphometrics.xml'));
        atlas_hdr = spm_vol(fullfile(fileparts(which('spm')), 'tpm', 'labels_Neuromorphometrics.nii'));
        atlas_vol = spm_read_vols(atlas_hdr);
        cutoff_percent = 5; % minimum percent of total cluster volume in template space to be reported - hard coded for now
        %FFH = spm_vol(params.flowfields.original);
        %FF = double(permute(squeeze(niftiread(params.flowfields.original)), [2,1,3,4])); % permute for interp3
        %inv_FFM = inv(FFH.mat);
        %aff2FF = inv_FFM * V_Z.mat;
        %inv_aff = inv(V_Z.mat);

        %shape = templ_hdr.dim;
        %shape = V_Z.dim;
        %[xg, yg, zg] = ndgrid(1:shape(1), 1:shape(2), 1:shape(3));
        %voxgrid = [xg(:), yg(:), zg(:)];        
        
        % iterate through clusters        
        for l_idx = 1:nl

            cluster_mask = labels == l_idx;
            cluster_vals = Z_data(cluster_mask);

            % Get the images and cluster mask
            report(l_idx).minimum = min(cluster_vals);
            report(l_idx).maximum = max(cluster_vals);
            report(l_idx).mean = mean(cluster_vals);
            report(l_idx).volume = sum(cluster_mask(:)) * voxel_volume;
            report(l_idx).images = generate_report_images(params.original.T1, Z_data, cluster_mask);

            %{
            % Cluster voxel cds -> world -> FF voxel cds
            p_vox = (aff2FF(1:3, 1:3) * Z_vox' + aff2FF(1:3, 4))'; 
            
            % Interpolate deformation at those voxel locations
            dx = interp3(FF(:,:,:,1), p_vox(:, 1), p_vox(:, 2), p_vox(:, 3), 'linear', 0);
            dy = interp3(FF(:,:,:,2), p_vox(:, 1), p_vox(:, 2), p_vox(:, 3), 'linear', 0);
            dz = interp3(FF(:,:,:,3), p_vox(:, 1), p_vox(:, 2), p_vox(:, 3), 'linear', 0);
            
            % Add displacement to get template-space world coordinates
            p_wld = (V_Z.mat(1:3, 1:3) * Z_vox' + V_Z.mat(1:3, 4))';
            p_template = p_wld + [dx(:) dy(:) dz(:)];

            % Optional - produce template-space image
            AS_hdr = V_Z;
            AS_hdr.fname = fullfile(params.outdir, ['cluster_' num2str(l_idx) '_template.nii']);
            %p_vox_t = (inv_FFM(1:3, 1:3) * p_template' + inv_FFM(1:3, 4))';
            p_vox_t = (inv_aff(1:3, 1:3) * p_template' + inv_aff(1:3, 4))';            
            F = scatteredInterpolant(p_vox_t(:,1), p_vox_t(:,2), p_vox_t(:,3), cluster_vals, 'linear', 'none');
            resampled = reshape(F(voxgrid(:, 1), voxgrid(:, 2), voxgrid(:, 3)), shape);
            spm_write_vol(AS_hdr, resampled);
            %}

            % Produce t1-space image
            AS_hdr = V_Z;
            AS_hdr.fname = fullfile(params.outdir, ['cluster_' num2str(l_idx) '.nii']);
            spm_write_vol(AS_hdr, Z_data .* double(cluster_mask));

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

        % generate report
        report_path = fullfile(params.outdir, 'report');
        if ~exist(report_path, 'dir')
            mkdir(report_path)
        end
        generate_report_template(report, min_thr, max(Z_data), report_path);

    end

    %% Generate burn-in image
    if isfield(params.settings, 'burnin') && params.settings.burnin
        if length(thresholds) > 3
            warning('Only the last three thresholds will be burned in')
        end
        burnin_hdr = spm_vol(params.original.T1);
        burnin_vol = spm_read_vols(burnin_hdr);        
        burnin_hdr.fname = [params.outdir filesep 'burnin.nii'];
        t1_vol = burnin_vol;
        for t_idx = 1:length(thresholds)
            mask = Z_data > thresholds(t_idx);
            switch t_idx - (length(thresholds) - 3)
                case 1
                    burnin_vol(mask) = max(burnin_vol(:)); % white burn-in
                case 2
                    burnin_vol(mask) = min(burnin_vol(:)); % black burn-in
                case 3
                    gm_img = params.c1T1;
                    gm_vox = spm_read_vols(spm_vol(gm_img)) > 0;
                    gm_int = t1_vol(gm_vox);
                    wm_img = strrep(params.c1T1, 'c1original', 'c2original');
                    wm_vox = spm_read_vols(spm_vol(wm_img)) > 0;
                    wm_int = t1_vol(wm_vox);
                    grey_intensity = (median(gm_int(:)) + median(wm_int(:))) / 2;
                    burnin_vol(mask) = grey_intensity; % grey burn-in
            end
        end
        spm_write_vol(burnin_hdr, burnin_vol);
    end

    %fullfile(params.outdir, sprintf('Z%d.nii', Z_threshold)); % Output filename
    %V_clustered.fname = fullfile(params.output_dir, sprintf('Z%d_clustered.nii', Z_threshold)); % Output filename
    
    disp('Overlays finished')

    if ~isfield(params.settings, 'viz') || params.settings.viz
    
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
        imgs = structfun(@(x) fullfile(params.outdir, x), imgs, 'un', 0);
        imgs.base_image = params.original.T1;
        
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

function [report, Z_vox] = generate_report_images(t1_path, overlay, mask)
    
    % careful here! spm affines are translated to map to the voxel space origin of (1,1,1)

    t1_hdr = spm_vol(t1_path);
    t1_vol = spm_read_vols(t1_hdr); 
    affine = t1_hdr.mat;
    cmap = turbo(256);              % hard-coded for now
    crosshair_colour = [0 0 1];     % hard-coded for now
    
    t1_vol(~isfinite(t1_vol)) = 0;
    t1_vol = t1_vol - min(t1_vol(:));
    t1_vol = t1_vol / max(t1_vol(:));
    [I, J, K] = ind2sub(t1_hdr.dim, 1:numel(t1_vol));
    t1_vox = [I(:) J(:) K(:)];
    cds = (affine(1:3, 1:3) * t1_vox' + affine(1:3, 4))';
    t1_CoM = sum(cds .* t1_vol(:)) / sum(t1_vol(:));
        
    overlay(~isfinite(overlay) | ~mask) = 0;
    overlay = overlay / max(overlay(:));
    overlay_RGB = cmap(discretize(overlay * 256 + 1, 1:257), :);
    overlay_RGB = reshape(overlay_RGB, [t1_hdr.dim 3]);  
    [I, J, K] = ind2sub(size(mask), find(mask)); 
    Z_vox = [I(:) J(:) K(:)];
    
    fov_mm = [300 300 300]; % field of view in mm, hard-coded for now
    resolution = 1.; % hard-coded for now
    [xi, yi, zi] = meshgrid(...
        0 : resolution : fov_mm(1) , ...
        0 : resolution : fov_mm(2) , ...
        0 : resolution : fov_mm(3));
    
    inv_affine = inv(affine);
    gc = [xi(:) yi(:) zi(:)] - (fov_mm + resolution) / 2 - t1_CoM;
    gv = (inv_affine(1:3, 1:3) * gc' + inv_affine(1:3, 4))';
    
    blended_RGB = repmat(t1_vol, [1,1,1,3]);
    mask_4D = repmat(mask, [1,1,1,3]);
    blended_RGB(mask_4D) = overlay_RGB(mask_4D);
    blended_RGB_matlab = permute(blended_RGB, [2, 1, 3, 4]);
    
    shape = size(xi);
    R = reshape(interp3(blended_RGB_matlab(:, :, :, 1), gv(:, 1), gv(:, 2), gv(:, 3)), shape);
    G = reshape(interp3(blended_RGB_matlab(:, :, :, 2), gv(:, 1), gv(:, 2), gv(:, 3)), shape); 
    B = reshape(interp3(blended_RGB_matlab(:, :, :, 3), gv(:, 1), gv(:, 2), gv(:, 3)), shape); 
    RGB = cat(4, R, G, B);      

    % find focus
    foci = find(max(overlay(:)) == overlay);

    % single peak available
    if length(foci) == 1 
        focus_idx = foci;

    % multiple peaks -> find closest to centre of mass
    else        
        Z_CoM = sum(Z_vox .* overlay(mask)) / sum(overlay(mask));        
        [fi, fj, fk] = ind2sub(size(mask), foci);
        foci_vox = [fi(:) fj(:) fk(:)];
        [~, closest] = min(sum((foci_vox - Z_CoM) .^ 2, 2));
        focus_idx = foci(closest);
    end

    [fx, fy, fz] = ind2sub(size(overlay), focus_idx);
    focus = (affine(1:3, 1:3) * [fx fy fz]' + affine(1:3, 4))' + (fov_mm + 1) / 2;
    focus = min(max(round(focus([2, 1, 3])), [1, 1, 1]), shape);

    views = {'axial', 'coronal', 'sagittal'};
    report = struct();
    for v = 1:3
        view = views{v};
        report(v).name = view;
        switch lower(view)
            case 'axial'    % slice in XY, normal is Z
                img = squeeze(RGB(:, :, focus(3), :)); % [X, Y, RGB]
                img(focus(1), :, :) = repmat(crosshair_colour, [shape(2), 1]);
                img(:, focus(2), :) = repmat(crosshair_colour, [shape(1), 1]);
                img = flip(img);
            case 'coronal'  % slice in XZ, normal is Y            
                img = squeeze(RGB(:, focus(2), :, :)); % [X, Z, RGB]
                img(focus(1), :, :) = repmat(crosshair_colour, [shape(1), 1]);
                img(:, focus(3), :) = repmat(crosshair_colour, [shape(3), 1]);
                img = flip(permute(img, [2 1 3]));
            case 'sagittal' % slice in YZ, normal is X
                img = squeeze(RGB(focus(1), :, :, :)); % [Y, Z, RGB]
                img(focus(2), :, :) = repmat(crosshair_colour, [shape(2), 1]);
                img(:, focus(3), :) = repmat(crosshair_colour, [shape(3), 1]);            
                img = flip(permute(img, [2 1 3]));
            otherwise
                error('view must be ''axial'', ''coronal'', or ''sagittal''');
        end        
        report(v).img = img;
    end

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


function generate_report_template(report, min_thr, max_Z, report_path)

    pad = 5;        % image padding pixels
    dim = 150;      % image dimensions in pixels

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

        fprintf(fid, '<tr><td colspan="3"><h2>Cluster %d</h2></td></tr>', r_idx);

        % embed the images
        fprintf(fid, '<tr>');
        for i = 1:3

            impath = fullfile(report_path, [num2str(r_idx) '_' report(r_idx).images(i).name '.png']);
            imwrite(report(r_idx).images(i).img, impath);
            fprintf(fid, '<td><img src="%s" width="%d" height="%d"></td>', [num2str(r_idx) '_' report(r_idx).images(i).name '.png'], dim, dim);

        end
        fprintf(fid, '</tr><tr><td colspan="3"><p>');
        fprintf(fid, '<b>Cluster volume:</b> %.2f cl <br>', report(r_idx).volume / 1e4);
        fprintf(fid, '<b>Mean Z-score:</b> %.2f (<b>range:</b> %.2f to %.2f)<br>', report(r_idx).mean, report(r_idx).minimum, report(r_idx).maximum);
        fprintf(fid, '</p><p>');

        if length(report(r_idx).regions) == 1 && strcmp(report(r_idx).regions{1}, report(r_idx).peak)
            fprintf(fid, 'Cluster involves the %s only.', report(r_idx).peak);
        else
            fprintf(fid, 'Cluster peaks in the %s and involves the following areas: %s. ', ...
                report(r_idx).peak, strjoin(report(r_idx).regions, ', '));
        end
        fprintf(fid, '</p></td></tr>')

    end

    fprintf(fid, '</table></body>\n</html>');    
    fclose(fid);
    web(html_path, '-browser');

end