# PET
Asymmetry Index pipeline for evaluation of epilepsy
v2.0 (Feb 2025)

Custom scripts by Anton Fomenko MD FRCSC
Epilepsy Neurosurgery Fellow, University of Toronto

Branch: Dmitri Šastin
Epilepsy Neurosurgery Fellow, University of Toronto

### REQUIREMENTS:

1. MATLAB v2017 or higher

2. SPM12 toolbox https://www.fil.ion.ucl.ac.uk/spm/software/spm12/

3. Exported PET, T1 MRI, and FLAIR MRI sequences of the patient (in NIFTI or DICOM)

4. Scripts attached to this repository.

5. Optional but desirable: MRIcron viewer  https://www.nitrc.org/projects/mricron

6. Approximately 1 hour to run the full pipeline on a personal laptop. Dedicated desktop machines will perform faster


### GUIDELINE FOR USE:

1. Download the repository. Ensure MATLAB and SPM12 is installed.

2. Export PET, T1 MRI, FLAIR MRI scans of patients. Ideally the scans are done within the same year, and are thinly sliced. 

3. Consider cropping the images to contain brain only if excessive neck is present.

4. PET images will come as "PET" or "NACPET". Choose the "PET" one, as this is attenuation corrected.

5. Note this branch is only tested with NIFTI files (DICOM may or may not run). The advantage is that the correct modalities are manually labelled.

6. Create an inputs JSON as demonstrated below. **This file is mandatory.**

7. Run asymmetry_index_wrapper.m and with a string containing the path to your JSON as input.

8. In case any individual step needs to be re-run, the output folder will contain mat-files with inputs into every step which can be re-used.


### CREATING INPUTS JSON:

Create a text file and enter the following (could be later renamed to .json):

```
{
  "PET": "path\to\PET\nifti\or\NIFTI_or_DCM_dir",
  "T1": "path\to\T1\nifti\or\NIFTI_or_DCM_dir",
  "FLAIR": "path\to\FLAIR\nifti\or\NIFTI_or_DCM_dir",
  "output_dir": "path\to\output_dir",
  "centre_of_mass": 1,
  "viz": 1
}
```

The first four are full paths to the respective files / output folder. The `centre_of_mass` flag lets registration initialise from the centres of mass of both images. This helps when e.g. PET is wildly out of alignment, and so it is strongly recommended by default (unless all images are pre-registered). The `viz` flag provides interactive quality control of the relevant steps - it is recommended to inspect the interim and final outputs to ensure correct results. Disabling the last two flags is possible by changing "1" to "0".

![image](https://github.com/user-attachments/assets/987a5f85-21a7-4577-90c3-9b2f703ef9be)


### VIEWING RESULTS 

Results are automatically shown at the end, but if you just want to view existing results separately do this step:

1. The viewer.m script will set the anatomical unflipped T1 as background..
2. The Z3, Z4, and Z5.nii overlays are simultaneously superimposed to see the asymmetrical regions in order of strength of asymmetry. 
3. Z3,4,5 with "clustered" suffix can be used instead if only want to see big clusters of asymmetry

**NOTE! The viewer will demonstrate results in "anatomical" orientation (right is right, left is left). The cluster image files, however, will stay aligned with the original T1w image file.**


### EXPORTING RESULTS TO DICOM:

On MRICron: File> Save as NIFTI for both the background (T1.nii) and each overlay, one by one. Ensure overlays are grayscale.

Use SPM12 imgcalc function to fuse all three into one nifti file. Expression (i1=base MRI .nii, i2, i3, etc = are overlay .nii files)
Can choose black or white for your burn-in color:

BLACK burn-in: `(i1 .* ((i2<0.5) & (i3<0.5))) + (1 .* ((i2>0.5) | (i3>0.5)))` 

WHITE burn-in: `(i1 .* ((i2 < 0.5) & (i3 < 0.5))) + (131 .* ((i2 > 0.5) | (i3 > 0.5)))`

Open output in MRIcron to ensure Burned in is adequate of new nifti. 

1. To use in BrainLab/NeuroMate planning station must EXPORT burned-in .nii AS DICOM 
2. Use 3Dslicer --> Module> DICOM  --> EXPORT as DICOM series --> Populate tag fields.
3. You should now have a folder of DICOMs ready for use. Can put this on USB stick and use on planning software (Brainlab, Stealth, Neuromate)


> Reference: Aslam S, Damodaran N, Rajeshkannan R, Sarma M, Gopinath S, Pillai A. Asymmetry index in anatomically symmetrized FDG-PET for improved epileptogenic focus detection in pharmacoresistant epilepsy. J Neurosurg. 2022 Aug 5;138(3):828-836. doi: 10.3171/2022.6.JNS22717. PMID: 35932262
