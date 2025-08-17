    function PET_AI_reslice(input_path, output_path)
        
    % Load original header
    H_orig = spm_vol(input_path);

    % Create a new volume header for output
    bb = [-128 -128 -128; 128 128 128]; % Target bounding box (new space, in mm) [minXYZ; maxXYZ]
    vox = [1 1 1]; % Voxel size
    dim = round((bb(2,:) - bb(1,:)) ./ vox); % Compute the dimensions explicitly (should be 256x256x256)    
    VO = struct();
    VO.fname = output_path;
    VO.dim = dim;
    VO.mat = diag([vox 1]);
    VO.mat(1:3, 4) = bb(1, :)' + vox(:) / 2;
    VO.dt = [spm_type('float32') 0];
    VO.pinfo = [1;0;0];

    % Create a new voxel grid for output and find its coordinates in original space
    [x, y, z] = ndgrid(1:dim(1), 1:dim(2), 1:dim(3));
    tx = inv(H_orig.mat) * VO.mat;
    vox_orig = (tx(1:3, 1:3) * [x(:) y(:) z(:)]' + tx(1:3, 4))';
    
    % Interpolate input volume at native voxel coords (linear)
    interp_vals = spm_sample_vol(H_orig, vox_orig(:,1), vox_orig(:,2), vox_orig(:,3), 1);
    Yout = reshape(interp_vals, dim);
    spm_write_vol(VO, Yout);

end