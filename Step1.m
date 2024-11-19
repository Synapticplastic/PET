% MATLAB Script to Batch Import and Rename DICOM Files in the Same Directory

function inputs = Step1(inputs)

    % Ensure SPM12 is in your MATLAB path
    if isempty(which('spm'))
        error('SPM12 not found! Please add SPM12 to your MATLAB path.');
    end

    fn = {'PET', 'T1', 'FLAIR'};
    nifti_files = {''; ''; ''};

    % Get unique folders for imaging data    
    if nargin

        % Check for niftis
        nii_ext = cellfun(@(x) strsplit(inputs.(x), '.'), fn, 'un', 0);
        nii_ext = cellfun(@(x) strcmp(x{min(length(x), 2)}, 'nii'), nii_ext);

        % Get inputs
        paths = cellfun(@(x) inputs.(x), fn, 'un', 0);
        dirs = unique(paths(cellfun(@ischar, paths) & ~nii_ext), 'stable');        

        % Prepare niftis
        nifti_files(nii_ext) = paths(nii_ext);

        % Prepare output folder
        out = inputs.output_dir;

    % Default behavior - all dicoms in script folder
    else
        dirs = {fileparts(mfilename('fullpath'))};
        out = fileparts(mfilename('fullpath'));
        nii_ext = [0 0 0];
    end
    
    % Get current time
    timestamp = now;
    
    % Convert to nifti
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
        spm_dicom_convert(hdr, 'all', 'flat', 'nii', out);  % 'all' = convert all, 'flat' = single directory, 'nii' = save as NIfTI
        disp('DICOM to NIfTI conversion completed successfully.');        
    end    
    
    % Check and sort the NIfTI files created
    if ~all(nii_ext)
        new_nifti = dir(fullfile(out, '*.nii'));
        new_nifti = new_nifti(cell2mat({new_nifti.datenum}) >= timestamp);
        new_nifti = sortrows(struct2table(new_nifti), 'datenum');
        new_nifti = fullfile(out, new_nifti.name);
        if sum(~nii_ext) ~= length(new_nifti)
            error('Number of provided and number of converted NIfTI files do not add up to 3');
        end
        nifti_files(~nii_ext) = new_nifti;

        % Define the desired output filenames
        desired_names = {'PET.nii', 'T1.nii', 'FLAIR.nii'};
    
        % Rename the files in the same order as they appear
        for i = 1:length(nifti_files)
            old_name = nifti_files{i};
            new_name = fullfile(out, desired_names{i});
            movefile(old_name, new_name);
            disp(['Renamed ', old_name, ' to ', new_name]);
            inputs.(fn{i}) = new_name;
        end

        disp('All files renamed successfully as PET.nii, T1.nii, and FLAIR.nii.');
    end

end

% MATLAB Script to Open PET.nii using SPM12's Viewer before coregistering
function view_file(file_to_view)

    % Ensure SPM12 is in your MATLAB path
    if isempty(which('spm'))
        error('SPM12 not found! Please add SPM12 to your MATLAB path.');
    end

    % Specify the file name to view
    if ~nargin; file_to_view = 'PET.nii'; end  % Replace with your file name if needed

    % Check if the file exists
    if ~exist(file_to_view, 'file')
        error(['File not found: ', file_to_view]);
    end

    % Open the SPM12 Image Viewer
    disp(['Opening ', file_to_view, ' in SPM12 viewer...']);
    spm_image('Display', file_to_view);

    disp('Set AC and rotate PET image to good position!!.');

end