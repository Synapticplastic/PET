% Script to Reslice and Flip NIfTI Image Left-to-Right
% This script handles complex affine transformations by first reslicing the NIfTI file

function params = Step3(params)

    fn = {'PET', 'T1', 'FLAIR'};

    % Generate Left-Right flipped images
    for i = 1:3    
        
        params.flipped.(fn{i}) = strrep(params.original.(fn{i}), 'original', 'flipped');
        unflipped_hdr = spm_vol(params.resliced.(fn{i}));
        unflipped_vol = spm_read_vols(unflipped_hdr);
        flipped_hdr = unflipped_hdr;
        flipped_hdr.fname = params.flipped.(fn{i});
        spm_write_vol(flipped_hdr, flip(unflipped_vol, 1));
        
        % MATLAB Script to Use SPM12's Check Reg to Compare X.nii and flipX.nii
        if ~exist(params.flipped.(fn{i}), 'file')
            error(['File not found: ', params.flipped.(fn{i})]);
        end
    
        if ~isfield(params.settings, 'viz') || params.settings.viz
    
            % Run SPM12 Check Reg with the specified files
            disp('Loading SPM Check Reg for comparison...');
            spm_check_registration(params.resliced.(fn{i}), params.flipped.(fn{i}));
            disp('Check Reg complete. Please confirm that the flip was applied along the correct axis.');
            disp('Viewer is open. Press any key in the command window to continue.');
            pause;  % Waits for any key press in the command window
            disp('Key pressed. Script resumed.');

        end
    end

end