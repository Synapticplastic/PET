# PET
Asymmetry Index pipeline for evaluation of epilepsy
v1.0.1 (October 24, 2024)

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

1. Download all scripts (Steps 1-5), ensure MATLAB and SPM12 is installed
2. Export PET, T1 MRI, FLAIR MRI scans of patients.
3. PET images will come as "PET" or "NACPET". Choose the "PET" one, as this is attenuation corrected.
4. Ideally the scans above are done within the same year, and are thinly sliced
   
5. Run Step 1.m   This will convert all the DICOM images to three key NIFTI files (.nii) and rename them.  View the files (PET, FLAIR, T1) to ensure the names correspond to the images. Depending on the order of the Dicoms, they may need to be manually renamed
6. The PET image will automatically display at the end up Step 1. Manually rotate the image and set the origin to the AC so it is approximately orthogonal. I will automate this in the future.
7. Run Step 2.m    This will rigidly coregister the PET and FLAIR images to the T1 image.  The checkreg tool will pop up at the end. Verify the images all align
8. Run Step 3.m   This will flip all the images Left to Right and save as flipX.nii.  Need to check the results to ensure they flipped correctly.
9. Run Step 4.m  This will automatically call step4_job.m (which should be sitting in your directory for a complex set of gray/white matter mapping and DARTEL template creation.  THIS STEP TAKES ABOUT 20-30 MINUTES OR SO on a laptop and will create many .nii files
10. Run Step 5.m   This will warp and process the results further to create a set of NIFTI overlays which can be manually mapped over your original T1 scan

INTERPRETING RESULTS:

1. Open wwT1_u_rc1T1_Template.nii using any viewer to view the T1 image. Alternatively can open the wwPet.nii file if the background is desired to be the PET scan.
2. "Add overlay", and add the Z3, Z4, and Z5.nii overlays to see the asymmetrical regions in order of strength of asymmetry. Set colors for a nice heatmap (will automate this later)
3. Z3,4,5 with "clustered" suffix can be used instead if only want to see big clusters of asymmetry



Reference: Aslam S, Damodaran N, Rajeshkannan R, Sarma M, Gopinath S, Pillai A. Asymmetry index in anatomically symmetrized FDG-PET for improved epileptogenic focus detection in pharmacoresistant epilepsy. J Neurosurg. 2022 Aug 5;138(3):828-836. doi: 10.3171/2022.6.JNS22717. PMID: 35932262
