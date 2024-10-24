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
