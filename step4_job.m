%-----------------------------------------------------------------------
% Job saved on 11-Oct-2024 09:29:27 by cfg_util (rev $Rev: 7345 $)
% spm SPM - SPM12 (7771)
% cfg_basicio BasicIO - Unknown
% dtijobs DTI tools - Unknown
% impexp_NiftiMrStruct NiftiMrStruct - Unknown
%-----------------------------------------------------------------------
matlabbatch{1}.spm.spatial.preproc.channel.vols = {
                                                   'C:\Users\Anton Fomenko\Desktop\TESTBATCHPET\DICOM\T1.nii,1'
                                                   'C:\Users\Anton Fomenko\Desktop\TESTBATCHPET\DICOM\cFLAIR.nii,1'
                                                   };
matlabbatch{1}.spm.spatial.preproc.channel.biasreg = 0.001;
matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 60;
matlabbatch{1}.spm.spatial.preproc.channel.write = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(1).tpm = {'C:\Users\Anton Fomenko\Documents\MATLAB\spm12\spm12\tpm\TPM.nii,1'};
matlabbatch{1}.spm.spatial.preproc.tissue(1).ngaus = 1;
matlabbatch{1}.spm.spatial.preproc.tissue(1).native = [1 1];
matlabbatch{1}.spm.spatial.preproc.tissue(1).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(2).tpm = {'C:\Users\Anton Fomenko\Documents\MATLAB\spm12\spm12\tpm\TPM.nii,2'};
matlabbatch{1}.spm.spatial.preproc.tissue(2).ngaus = 1;
matlabbatch{1}.spm.spatial.preproc.tissue(2).native = [1 1];
matlabbatch{1}.spm.spatial.preproc.tissue(2).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(3).tpm = {'C:\Users\Anton Fomenko\Documents\MATLAB\spm12\spm12\tpm\TPM.nii,3'};
matlabbatch{1}.spm.spatial.preproc.tissue(3).ngaus = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(3).native = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(3).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(4).tpm = {'C:\Users\Anton Fomenko\Documents\MATLAB\spm12\spm12\tpm\TPM.nii,4'};
matlabbatch{1}.spm.spatial.preproc.tissue(4).ngaus = 3;
matlabbatch{1}.spm.spatial.preproc.tissue(4).native = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(4).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(5).tpm = {'C:\Users\Anton Fomenko\Documents\MATLAB\spm12\spm12\tpm\TPM.nii,5'};
matlabbatch{1}.spm.spatial.preproc.tissue(5).ngaus = 4;
matlabbatch{1}.spm.spatial.preproc.tissue(5).native = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(5).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(6).tpm = {'C:\Users\Anton Fomenko\Documents\MATLAB\spm12\spm12\tpm\TPM.nii,6'};
matlabbatch{1}.spm.spatial.preproc.tissue(6).ngaus = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(6).native = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(6).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1;
matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1;
matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';
matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0;
matlabbatch{1}.spm.spatial.preproc.warp.samp = 3;
matlabbatch{1}.spm.spatial.preproc.warp.write = [0 0];
matlabbatch{1}.spm.spatial.preproc.warp.vox = NaN;
matlabbatch{1}.spm.spatial.preproc.warp.bb = [NaN NaN NaN
                                              NaN NaN NaN];
matlabbatch{2}.spm.spatial.preproc.channel.vols = {
                                                   'C:\Users\Anton Fomenko\Desktop\TESTBATCHPET\DICOM\flipT1.nii,1'
                                                   'C:\Users\Anton Fomenko\Desktop\TESTBATCHPET\DICOM\flipFLAIR.nii,1'
                                                   };
matlabbatch{2}.spm.spatial.preproc.channel.biasreg = 0.001;
matlabbatch{2}.spm.spatial.preproc.channel.biasfwhm = 60;
matlabbatch{2}.spm.spatial.preproc.channel.write = [0 0];
matlabbatch{2}.spm.spatial.preproc.tissue(1).tpm = {'C:\Users\Anton Fomenko\Documents\MATLAB\spm12\spm12\tpm\TPM.nii,1'};
matlabbatch{2}.spm.spatial.preproc.tissue(1).ngaus = 1;
matlabbatch{2}.spm.spatial.preproc.tissue(1).native = [1 1];
matlabbatch{2}.spm.spatial.preproc.tissue(1).warped = [0 0];
matlabbatch{2}.spm.spatial.preproc.tissue(2).tpm = {'C:\Users\Anton Fomenko\Documents\MATLAB\spm12\spm12\tpm\TPM.nii,2'};
matlabbatch{2}.spm.spatial.preproc.tissue(2).ngaus = 1;
matlabbatch{2}.spm.spatial.preproc.tissue(2).native = [1 1];
matlabbatch{2}.spm.spatial.preproc.tissue(2).warped = [0 0];
matlabbatch{2}.spm.spatial.preproc.tissue(3).tpm = {'C:\Users\Anton Fomenko\Documents\MATLAB\spm12\spm12\tpm\TPM.nii,3'};
matlabbatch{2}.spm.spatial.preproc.tissue(3).ngaus = 2;
matlabbatch{2}.spm.spatial.preproc.tissue(3).native = [0 0];
matlabbatch{2}.spm.spatial.preproc.tissue(3).warped = [0 0];
matlabbatch{2}.spm.spatial.preproc.tissue(4).tpm = {'C:\Users\Anton Fomenko\Documents\MATLAB\spm12\spm12\tpm\TPM.nii,4'};
matlabbatch{2}.spm.spatial.preproc.tissue(4).ngaus = 3;
matlabbatch{2}.spm.spatial.preproc.tissue(4).native = [0 0];
matlabbatch{2}.spm.spatial.preproc.tissue(4).warped = [0 0];
matlabbatch{2}.spm.spatial.preproc.tissue(5).tpm = {'C:\Users\Anton Fomenko\Documents\MATLAB\spm12\spm12\tpm\TPM.nii,5'};
matlabbatch{2}.spm.spatial.preproc.tissue(5).ngaus = 4;
matlabbatch{2}.spm.spatial.preproc.tissue(5).native = [0 0];
matlabbatch{2}.spm.spatial.preproc.tissue(5).warped = [0 0];
matlabbatch{2}.spm.spatial.preproc.tissue(6).tpm = {'C:\Users\Anton Fomenko\Documents\MATLAB\spm12\spm12\tpm\TPM.nii,6'};
matlabbatch{2}.spm.spatial.preproc.tissue(6).ngaus = 2;
matlabbatch{2}.spm.spatial.preproc.tissue(6).native = [0 0];
matlabbatch{2}.spm.spatial.preproc.tissue(6).warped = [0 0];
matlabbatch{2}.spm.spatial.preproc.warp.mrf = 1;
matlabbatch{2}.spm.spatial.preproc.warp.cleanup = 1;
matlabbatch{2}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
matlabbatch{2}.spm.spatial.preproc.warp.affreg = 'mni';
matlabbatch{2}.spm.spatial.preproc.warp.fwhm = 0;
matlabbatch{2}.spm.spatial.preproc.warp.samp = 3;
matlabbatch{2}.spm.spatial.preproc.warp.write = [0 0];
matlabbatch{2}.spm.spatial.preproc.warp.vox = NaN;
matlabbatch{2}.spm.spatial.preproc.warp.bb = [NaN NaN NaN
                                              NaN NaN NaN];
matlabbatch{3}.spm.tools.dartel.warp.images = {
                                               {
                                               'C:\Users\Anton Fomenko\Desktop\TESTBATCHPET\DICOM\rc1T1.nii,1'
                                               'C:\Users\Anton Fomenko\Desktop\TESTBATCHPET\DICOM\rc1flipT1.nii,1'
                                               'C:\Users\Anton Fomenko\Desktop\TESTBATCHPET\DICOM\rc2T1.nii,1'
                                               'C:\Users\Anton Fomenko\Desktop\TESTBATCHPET\DICOM\rc2flipT1.nii,1'
                                               }
                                               }';
matlabbatch{3}.spm.tools.dartel.warp.settings.template = 'Template';
matlabbatch{3}.spm.tools.dartel.warp.settings.rform = 0;
matlabbatch{3}.spm.tools.dartel.warp.settings.param(1).its = 3;
matlabbatch{3}.spm.tools.dartel.warp.settings.param(1).rparam = [4 2 1e-06];
matlabbatch{3}.spm.tools.dartel.warp.settings.param(1).K = 0;
matlabbatch{3}.spm.tools.dartel.warp.settings.param(1).slam = 16;
matlabbatch{3}.spm.tools.dartel.warp.settings.param(2).its = 3;
matlabbatch{3}.spm.tools.dartel.warp.settings.param(2).rparam = [2 1 1e-06];
matlabbatch{3}.spm.tools.dartel.warp.settings.param(2).K = 0;
matlabbatch{3}.spm.tools.dartel.warp.settings.param(2).slam = 8;
matlabbatch{3}.spm.tools.dartel.warp.settings.param(3).its = 3;
matlabbatch{3}.spm.tools.dartel.warp.settings.param(3).rparam = [1 0.5 1e-06];
matlabbatch{3}.spm.tools.dartel.warp.settings.param(3).K = 1;
matlabbatch{3}.spm.tools.dartel.warp.settings.param(3).slam = 4;
matlabbatch{3}.spm.tools.dartel.warp.settings.param(4).its = 3;
matlabbatch{3}.spm.tools.dartel.warp.settings.param(4).rparam = [0.5 0.25 1e-06];
matlabbatch{3}.spm.tools.dartel.warp.settings.param(4).K = 2;
matlabbatch{3}.spm.tools.dartel.warp.settings.param(4).slam = 2;
matlabbatch{3}.spm.tools.dartel.warp.settings.param(5).its = 3;
matlabbatch{3}.spm.tools.dartel.warp.settings.param(5).rparam = [0.25 0.125 1e-06];
matlabbatch{3}.spm.tools.dartel.warp.settings.param(5).K = 4;
matlabbatch{3}.spm.tools.dartel.warp.settings.param(5).slam = 1;
matlabbatch{3}.spm.tools.dartel.warp.settings.param(6).its = 3;
matlabbatch{3}.spm.tools.dartel.warp.settings.param(6).rparam = [0.25 0.125 1e-06];
matlabbatch{3}.spm.tools.dartel.warp.settings.param(6).K = 6;
matlabbatch{3}.spm.tools.dartel.warp.settings.param(6).slam = 0.5;
matlabbatch{3}.spm.tools.dartel.warp.settings.optim.lmreg = 0.01;
matlabbatch{3}.spm.tools.dartel.warp.settings.optim.cyc = 3;
matlabbatch{3}.spm.tools.dartel.warp.settings.optim.its = 3;
