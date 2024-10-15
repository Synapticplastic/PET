% MATLAB Script to Batch Import and Rename DICOM Files in the Same Directory

% Ensure SPM12 is in your MATLAB path
if isempty(which('spm'))
    error('SPM12 not found! Please add SPM12 to your MATLAB path.');
end

% Get the directory where this script is located
current_dir = fileparts(mfilename('fullpath'));

% Get a list of all DICOM files in the same directory
dicom_files = dir(fullfile(current_dir));  % Use '*.dcm' for DICOM files; modify if necessary

% Check if DICOM files are found
if isempty(dicom_files)
    error('No DICOM files found in the current directory!');
end

% Display the number of DICOM files found
disp(['Found ', num2str(length(dicom_files)), ' DICOM files in the directory.']);

% Create a cell array of file names with full paths
dicom_filepaths = fullfile(current_dir, {dicom_files.name});

% Set up SPM12 defaults and read the DICOM headers
spm('Defaults','fmri');
hdr = spm_dicom_headers(dicom_filepaths);  % Read DICOM headers

% Import DICOM files to NIfTI format
disp('Converting DICOM files to NIfTI format...');
spm_dicom_convert(hdr, 'all', 'flat', 'nii');  % 'all' = convert all, 'flat' = single directory, 'nii' = save as NIfTI
disp('DICOM to NIfTI conversion completed successfully.');

% Get a list of the newly created NIfTI files in the current directory
nifti_files = dir(fullfile(current_dir, '*.nii'));

% Check if three NIfTI files are present
if length(nifti_files) ~= 3
    error('Expected 3 NIfTI files, but found %d. Please check the conversion step.', length(nifti_files));
end

% Sort the NIfTI files by their order in the directory listing
nifti_files = sortrows(struct2table(nifti_files), 'datenum');
nifti_filepaths = fullfile(current_dir, nifti_files.name);  % Extract full paths

% Define the desired output filenames
desired_names = {'PET.nii', 'T1.nii', 'FLAIR.nii'};

% Rename the files in the same order as they appear
for i = 1:length(nifti_filepaths)
    old_name = nifti_filepaths{i};
    new_name = fullfile(current_dir, desired_names{i});
    movefile(old_name, new_name);
    disp(['Renamed ', old_name, ' to ', new_name]);
end

disp('All files renamed successfully as PET.nii, T1.nii, and FLAIR.nii.');




% MATLAB Script to Open PET.nii using SPM12's Viewer before coregistering

% Ensure SPM12 is in your MATLAB path
if isempty(which('spm'))
    error('SPM12 not found! Please add SPM12 to your MATLAB path.');
end

% Specify the file name to view
file_to_view = 'PET.nii';  % Replace with your file name if needed

% Check if the file exists
if ~exist(file_to_view, 'file')
    error(['File not found: ', file_to_view]);
end

% Open the SPM12 Image Viewer
disp(['Opening ', file_to_view, ' in SPM12 viewer...']);
spm_image('Display', file_to_view);

disp('Set AC and rotate PET image to good position!!.');
