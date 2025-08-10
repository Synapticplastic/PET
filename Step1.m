% MATLAB Script to Batch Import and Rename DICOM Files in the Same Directory

function params = Step1(params)

    fn = {'PET', 'T1', 'FLAIR'};

    % Check that correct inputs have been provided
    inputs = cellfun(@(fn) isfield(params.settings, fn), [{'input_dir'} fn]);
    msg = ['Provide either "inputs" OR all of the following: ' strjoin(fn, ', ')];
    if ~inputs(1) && sum(inputs(2:4)) < 3
        error(msg)
    elseif inputs(1) && any(inputs(2:4))
        error(msg)
    end
    
    % inputs provided as a single directory
    if inputs(1)

        % check if all inputs are niftis
        fdir = params.settings.input_dir;
        if ~isfolder(fdir)
            error('When providing "input_dir", the input must be a directory')
        end
        ext_chk = @(p, e) exist(fullfile(fdir, [p e]), 'file');
        nii_chk = @(p) ext_chk(p, '.nii') | ext_chk(p, '.nii.gz');
        available_nii = cellfun(nii_chk, fn); % have to be clearly named files

        % if not, convert dicoms to niftis then try to determine type
        pstrcmp = @(s, p) ~isempty(regexp(s, p, 'once'));
        if ~all(available_nii)
            dicoms = search_for_dicoms(params.settings.input_dir);
            i_meta = dcm2nii(dicoms, params.outdir);
            meta = i_meta([]);
            for m = 1:length(i_meta)
                md = lower(i_meta(m).Modality);
                sd = lower(i_meta(m).SeriesDescription);
                if strcmp(md, 'pt') || pstrcmp(sd, 'PET')
                    fn_id = find(strcmp(fn, 'PET'));
                elseif strcmp(md, 'mr') && ~pstrcmp(sd, 't1') && (pstrcmp(sd, 't2') || pstrcmp(sd, 'flair'))
                    fn_id = find(strcmp(fn, 'FLAIR'));
                elseif strcmp(md, 'mr') && pstrcmp(sd, 't1') && ~pstrcmp(sd, 't2')
                    fn_id = find(strcmp(fn, 'T1'));
                else
                    error(['Unable to identify DICOMs, ' ...
                        'try providing each modality/sequence explicitly'])
                end
                if available_nii(fn_id)
                    error(['NIFTI and DICOMs appear to be same modality/sequence, ' ...
                        'try providing each modality/sequence explicitly'])
                else
                    meta(fn_id) = i_meta(m);
                end
            end
        end

        % for those that were niftis, allocate path too
        for i = 1:3
            if available_nii(i)
                if ext_chk(fn{i}, '.nii')
                    meta(i).Path = fullfile(fdir, [fn{i} '.nii']);
                else
                    meta(i).Path = fullfile(fdir, [fn{i} '.nii.gz']);
                end
            end
        end

        % ensure enough files were collected
        no_path = arrayfun(@(i) isempty(meta(i).Path), 1:3);
        if any(no_path)
            error(['Failed to identify ' strjoin(fn(no_path), ', ') 'input(s)'])
        end

    % inputs provided as individual files / dicom folders
    else
        available_nii = [false, false, false];
        ext_chk = @(p, e) endsWith(p, e) & exist(p, 'file');
        nii_chk = @(p) ext_chk(p, '.nii') | ext_chk(p, '.nii.gz');
        meta = struct('Path', []);
        for i = 1:3
            input_path = params.settings.(fn{i});

            % if the path leads to a NIFTI, don't do anything else
            if nii_chk(input_path)
                available_nii(i) = true;
                if ~exist(input_path, 'file')
                    error(['Input for ' fn{i} ' does not exist'])
                end

            % otherwise, assume it's a directory with DICOMS for a single volume
            else
                if ~isfolder(input_path)
                    error(['When providing individual inputs, ' ...
                        'they must point to a NIFTI file or ' ...
                        'a directory of DICOMS, check ' fn{i}]);
                end
                dicoms = search_for_dicoms(input_path);
                i_meta = dcm2nii(dicoms, params.outdir);
                if length(i_meta) > 1
                    error(['More than one DICOM volume identified ' ...
                        'in the path for ' fn{i}]);
                end
            end

            % get metainfo
            if ~available_nii(i)
                if ~isempty(setxor(fieldnames(meta), fieldnames(i_meta)))
                    meta_temp = i_meta([]);
                    for j = 1:length(meta)
                        meta_temp(j).Path = meta(j).Path;
                    end
                    meta = meta_temp;
                end
                meta(i) = i_meta;
            else
                meta(i).Path = input_path;
            end
        end
    end

    % tidy up, ensure we are working with copies of the original
    for i = 1:length(fn)
        params.original.(fn{i}) = [params.outdir filesep 'original_' fn{i} '.nii'];
        if ~strcmp(meta(i).Path, params.original.(fn{i}))
            if endsWith(meta(i).Path, '.nii.gz') % spm dislikes .nii.gz
                gunzip(meta(i).Path, params.outdir);
                [~, nn, ~] = fileparts(meta(i).Path);
                extracted_path = [params.outdir filesep nn];
                if ~strcmp(extracted_path, params.original.(fn{i}))
                    movefile(extracted_path, params.original.(fn{i}))
                end
            else
                copyfile(meta(i).Path, params.original.(fn{i}));
            end
        end
    end

    params.meta = struct(...
        fn{1}, meta(1), ...
        fn{2}, meta(2), ...
        fn{3}, meta(3));
    
end

function dicoms = search_for_dicoms(path)

    dicoms = {};
    contents = dir(path);
    for i = 1:length(contents)
        if contents(i).isdir
            if any(strcmp(contents(i).name, {'.', '..'}))
                continue
            else
                path = fullfile(contents(i).folder, contents(i).name);
                dicoms = cat(2, dicoms, search_for_dicoms(path));
            end
        else
            if endsWith(contents(i).name, '.dcm')
                dicoms{end + 1} = fullfile(contents(i).folder, contents(i).name);
            end
        end
    end
end

function meta = dcm2nii(paths, outdir)

    disp('Converting DICOM files to NIfTI format...');
    spm('Defaults','fmri');
    hdr = spm_dicom_headers(paths); 
    out = spm_dicom_convert(hdr, 'all', 'flat', 'nii', outdir, true); 
    meta = struct;
    fields = {'StudyDate', 'SeriesDescription', 'Modality'};
    for i = 1:length(out.files)
        fname = out.files{i};
        fmeta = jsondecode(fileread(strrep(fname, '.nii', '.json')));
        for f = 1:length(fields)
            if isfield(fmeta.acqpar, fields{f})                
                if strcmp(fields{f}, 'StudyDate')
                    meta(i).StudyDate =  datetime(fmeta.acqpar.StudyDate, 'ConvertFrom', 'datenum');
                else
                    meta(i).(fields{f}) = fmeta.acqpar.(fields{f});
                end
            else
                meta(i).(fields{f}) = [];
            end
        end
        meta(i).Path = fname;
    end
    disp('DICOM to NIfTI conversion completed successfully.');   

end