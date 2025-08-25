function params = PET_AI_Step4(params)    

    % Prepare
    spm('defaults', 'FMRI');

    disp('Creating Gray/White matter maps for the flipped orientation.');   
    PET_AI_segment(params.flipped.T1, params.flipped.FLAIR);
    disp('Finished creating Gray/White matter maps for the flipped orientation. Proceeding to template creation.');   

    pause(1)
    [~, nnT1, ~] = fileparts(params.MNI_aligned.T1);
    [~, nnflipT1, ~] = fileparts(params.flipped.T1);
    imgs = {['rc1' nnT1], ['rc1' nnflipT1], ['rc2' nnT1], ['rc2' nnflipT1]}';
    imgs = cellfun(@(x) [fullfile(params.outdir, x) '.nii,1'], imgs, 'un', 0);
    matlabbatch = {};
    matlabbatch{1}.spm.tools.dartel.warp.images = {imgs};
    matlabbatch{1}.spm.tools.dartel.warp.settings.template = 'Template';
    matlabbatch{1}.spm.tools.dartel.warp.settings.rform = 0;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(1).its = 3;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(1).rparam = [4 2 1e-06];
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(1).K = 0;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(1).slam = 16;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(2).its = 3;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(2).rparam = [2 1 1e-06];
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(2).K = 0;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(2).slam = 8;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(3).its = 3;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(3).rparam = [1 0.5 1e-06];
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(3).K = 1;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(3).slam = 4;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(4).its = 3;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(4).rparam = [0.5 0.25 1e-06];
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(4).K = 2;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(4).slam = 2;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(5).its = 3;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(5).rparam = [0.25 0.125 1e-06];
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(5).K = 4;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(5).slam = 1;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(6).its = 3;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(6).rparam = [0.25 0.125 1e-06];
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(6).K = 6;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(6).slam = 0.5;
    matlabbatch{1}.spm.tools.dartel.warp.settings.optim.lmreg = 0.01;
    matlabbatch{1}.spm.tools.dartel.warp.settings.optim.cyc = 3;
    matlabbatch{1}.spm.tools.dartel.warp.settings.optim.its = 3;
    
    spm_jobman('run', matlabbatch);
    
    disp('Finished Warping images using Templates.');    
    params.flowfields.original = fullfile(params.outdir, ['u_rc1' nnT1 '_Template.nii']); % flowfield for original T1
    params.flowfields.flipped = fullfile(params.outdir, ['u_rc1' nnflipT1 '_Template.nii']); % flowfield for flipped T1
    params.c1T1 = fullfile(params.outdir, ['c1' nnT1 '.nii']); % grey matter map in the original T1 image's space
    t_last = length(matlabbatch{1}.spm.tools.dartel.warp.settings.param);
    params.dartel_template = fullfile(params.outdir, sprintf('Template_%d.nii', t_last));

end
