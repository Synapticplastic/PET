% MATLAB Script to Batch Import and Rename DICOM Files in the Same Directory

function params = Step1(params)

    fn = {'PET', 'T1', 'FLAIR'};
    nifti_files = {''; ''; ''};

    % Check for niftis
    nii_ext = cellfun(@(x) strsplit(params.settings.(x), '.'), fn, 'un', 0);
    nii_ext = cellfun(@(x) any(strcmp(x(end - min(1, length(x) - 1): end), 'nii')), nii_ext);

    % Get input and their types
    paths = cellfun(@(x) params.settings.(x), fn, 'un', 0);
    dirs = unique(paths(cellfun(@ischar, paths) & ~nii_ext), 'stable');        

    % Prepare niftis
    nifti_files(nii_ext) = paths(nii_ext);     
    
    % Get current time
    timestamp = now;
    
    % Convert any directories (presumed to be DICOM) to nifti
    for d = 1:length(dirs)
    
        % Get a list of all DICOM files in the directory
        dicom_files = dir(fullfile(dirs{d}));  % Use '*.dcm' for DICOM files; modify if necessary

        % Check if DICOM files are found
        if isempty(dicom_files)
            error(['No DICOM files found in: ' dirs{d}]);
        end

        % Display the number of DICOM files found
        disp(['Found ', num2str(length(dicom_files)), ' DICOM files in: ' dirs{d}]);

        % Create a cell array of file names with full paths
        dicom_filepaths = fullfile(dirs{d}, {dicom_files.name});

        % Set up SPM12 defaults and read the DICOM headers
        spm('Defaults','fmri');
        hdr = spm_dicom_headers(dicom_filepaths);  % Read DICOM headers

        % Import DICOM files to NIfTI format
        disp('Converting DICOM files to NIfTI format...');
        spm_dicom_convert(hdr, 'all', 'flat', 'nii', params.outdir);  % 'all' = convert all, 'flat' = single directory, 'nii' = save as NIfTI
        disp('DICOM to NIfTI conversion completed successfully.');        

    end    
    
    % Check and sort the NIfTI files created
    if ~all(nii_ext)

        new_nifti = dir(fullfile(params.outdir, '*.nii'));
        new_nifti = new_nifti(cell2mat({new_nifti.datenum}) >= timestamp);
        new_nifti = sortrows(struct2table(new_nifti), 'datenum');
        if size(new_nifti, 1) == 1
            new_nifti = {fullfile(params.outdir, new_nifti.name)};
        else
            new_nifti = fullfile(params.outdir, new_nifti.name);
        end        
        if sum(~nii_ext) ~= length(new_nifti)
            error('Number of provided and number of converted NIfTI files do not add up to 3');
        end
        nifti_files(~nii_ext) = new_nifti;

        % Define the desired output filenames
        desired_names = cellfun(@(x) [x '.nii'], fn, 'un', 0);
    
        % Rename the files in the same order as they appear
        for i = 1:length(nifti_files)
            if nii_ext(i); continue; end % do not touch NIfTIs explicitly provided
            old_name = nifti_files{i};
            new_name = fullfile(params.outdir, desired_names{i});
            movefile(old_name, new_name);
            disp(['Renamed ', old_name, ' to ', new_name]);
            params.settings.(fn{i}) = new_name;
        end

        disp('All files renamed successfully as PET.nii, T1.nii, and FLAIR.nii.');

    end

    for i = 1:length(fn)
        params.original.(fn{i}) = [params.outdir filesep 'original_' fn{i} '.nii'];
        if ~strcmp(params.settings.(fn{i}), params.original.(fn{i}))
            if endsWith(params.settings.(fn{i}), '.nii.gz') % spm dislikes .nii.gz
                gunzip(params.settings.(fn{i}), params.outdir);
                [~, nn, ~] = fileparts(params.settings.(fn{i}));
                extracted_path = [params.outdir filesep nn];
                if ~strcmp(extracted_path, params.original.(fn{i}))
                    movefile(extracted_path, params.original.(fn{i}))
                end
            else
                copyfile(params.settings.(fn{i}), params.original.(fn{i}));
            end
        end
    end

end