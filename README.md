# PET
Asymmetry Index pipeline for evaluation of epilepsy
v2.0 (Feb 2025)

Custom scripts by Anton Fomenko MD FRCSC
Epilepsy Neurosurgery Fellow, University of Toronto


REQUIREMENTS:

1.MATLAB v2017 or higher

2.SPM12 toolbox https://www.fil.ion.ucl.ac.uk/spm/software/spm12/

3. Exported PET, T1 MRI, and FLAIR MRI sequences of the patient (in NIFTI or DICOM)

4. Scripts attached to this repository.

5. Optional but desirable: MRIcron viewer  https://www.nitrc.org/projects/mricron

5. Approximately 1 hour to run the full pipeline on a personal laptop. Dedicated desktop machines will perform faster

GUIDELINE FOR USE:

1. Download all scripts (Steps 1-5). The step4_job.m file needs to also be downloaded but not explicity run. Ensure MATLAB and SPM12 is installed
2. Export PET, T1 MRI, FLAIR MRI scans of patients. Ideally the scans are done within the same year, and are thinly sliced
3. PET images will come as "PET" or "NACPET". Choose the "PET" one, as this is attenuation corrected.
4. Make sure all scripts and .nii files are in the same folder. Find the TPM.nii file in your SPM folder (spm12\tpm\tpm.nii), and make a copy into this folder.
5. Run Step 1.m   This will convert all the DICOM images to three key NIFTI files (.nii) and rename them.
6. View the files (PET.nii, FLAIR.nii, T1.nii) to ensure the names correspond to the images. Depending on the order of the Dicoms, they may need to be manually renamed
7. Run Step 2.m    This will rigidly coregister the PET and FLAIR images to the T1 image.  The checkreg tool will pop up at the end. Verify the images all align
8. note: If the images have not correctly coregistered, usually the PET image needs to be manually rotated so it is approximately orthogonal and the origin set to roughly the AC using SPM's viewer. Then, re-run Step2. This rarely needs to be done, but fixes the issue.
9. Run Step 3.m   This will flip all the images Left to Right.  Need to check the results to ensure they flipped correctly.
10. Run Step 4.m  This will automatically call step4_job.m (which should be sitting in your directory for a complex set of gray/white matter mapping and DARTEL template creation.  THIS STEP TAKES ABOUT 20-30 MINUTES OR SO on a laptop and will create many .nii files
11. Run Step 5.m   This will warp and process the results further to create a set of NIFTI overlays which can be manually mapped over your original T1 scan. This will also overlay the results onto the T1 using a viewer

![image](https://github.com/user-attachments/assets/987a5f85-21a7-4577-90c3-9b2f703ef9be)

VIEWING RESULTS (results are automatically shown in Step 5.m above, but if you just want to view existing results separately do this step):

1. The viewer.m script will set the anatomical unflipped T1 wwT1_u_rc1T1_Template.nii as background..
2. The Z3, Z4, and Z5.nii overlays are simultaneously superimposed to see the asymmetrical regions in order of strength of asymmetry. 
3. Z3,4,5 with "clustered" suffix can be used instead if only want to see big clusters of asymmetry

EXPORTING RESULTS TO DICOM:

On MRICron: File> Save as NIFTI for both the background (T1.nii) and each overlay, one by one. Ensure overlays are grayscale.

Use SPM12 imgcalc function to fuse all three into one nifti file. Expression (i1=base MRI .nii, i2, i3, etc = are overlay .nii files)
Can choose black or white for your burn-in color:

(i1 .* ((i2<0.5) & (i3<0.5))) + (1 .* ((i2>0.5) | (i3>0.5)))                                         
BLACK burnin

(i1 .* ((i2 < 0.5) & (i3 < 0.5))) + (131 .* ((i2 > 0.5) | (i3 > 0.5)))                          
WHITE burnin

Open output in MRIcron to ensure Burned in is adequate of new nifti. 

4. To use in BrainLab/NeuroMate planning station must EXPORT burned-in .nii AS DICOM 
5. Use 3Dslicer --> Module> DICOM  --> EXPORT as DICOM series --> Populate tag fields.
6. You should now have a folder of DICOMs ready for use. Can put this on USB stick and use on planning software (Brainlab, Stealth, Neuromate)



Reference: Aslam S, Damodaran N, Rajeshkannan R, Sarma M, Gopinath S, Pillai A. Asymmetry index in anatomically symmetrized FDG-PET for improved epileptogenic focus detection in pharmacoresistant epilepsy. J Neurosurg. 2022 Aug 5;138(3):828-836. doi: 10.3171/2022.6.JNS22717. PMID: 35932262
