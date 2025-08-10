function view_PET_AI(params)

    % Initialize
    spm('defaults', 'fmri');
    spm_jobman('initcfg');
    def_min_Z = 3;

    % Get data
    if nargin % params provided
        T1 = params.original.T1;
        Z = fullfile(params.outdir, 'Z_AI_image.nii');
        if ~isfield(params.settings, 'thr')
            min_Z = def_min_Z;
        else
            min_Z = params.settings.thr;
        end
    else % params not provided = expect the script is in the outputs dir
        outdir = fileparts(mfilename('fullpath'));
        T1 = fullfile(outdir, 'original_T1.nii');
        Z = fullfile(outdir, 'Z_AI_image.nii');
        min_Z = def_min_Z;
    end
    if ~exist(T1, 'file') || ~exist(Z, 'file')
        error('Unable to locate required files')
    end    
    V_Z = spm_vol(Z);
    Z_data = spm_read_vols(V_Z);
    max_Z = max(Z_data(~isnan(Z_data)));

    % Show orthogonal views interactively
    close all
    spm_orthviews('Reset');
    spm_check_registration(T1);

    % Fiddle with orthviews' internal data to get masking working

    % 'AddTrueColourImage' does not support background transparency
    % so mapping T1w intensities to the colourmap of choice, breaking into
    % RGB colours and supplying one colour at a time with 'AddColouredImage' 
    % which allows blending / transparency but carries irrelevant colour bars

    % For that reason, having to also load 'AddTrueColourImage' with 0%
    % opacity just to have the correct colour bar -- however, both
    % 'AddTrueColourImage' with cmap and 'AddColouredImage' can not be overlaid
    % on the same volume simultaneously so also having to load the T1w volume x2

    global st;
    st.vols{2} = st.vols{1}; % unfortunately having to load data twice ...
    spm_orthviews('AddTrueColourImage', 1, V_Z.fname, turbo(256), 0, max_Z, 0); % first just to show colour bar correctly
    spm_orthviews('AddColouredImage', 2, V_Z.fname, [1, 0, 0]); % then to have correct blending / transparency
    mask = ~isnan(Z_data) & Z_data > min_Z;
    cmap = turbo(256);
    Z_RGB = cmap(uint16(uint8(Z_data / max_Z .* mask * 255)) + 1, :);
    Z_RGB(~mask(:), :) = 0;
    blob = st.vols{2}.blobs{1};
    for i = 1:3
        blob.vol = reshape(Z_RGB(:, i), size(Z_data));
        c = zeros(1, 3);
        c(i) = 1;
        blob.colour = c;
        blob.max = 1;
        blob.min = 0;
        st.vols{2}.blobs{i} = blob;
    end    
    spm_orthviews('Caption', 1, ['PET asymmetry Z>' num2str(min_Z) ' (right is right, left is left)']);
    spm_orthviews('Redraw');

end