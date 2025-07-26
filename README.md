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
  "output_dir": "path\to\output_dir"
}
```

These are the required inputs that should always be present. In addition, the following are optional (contain within the same curly brackets):

```
  "centre_of_mass": 1,
  "viz": 1,
  "cluster_size": 100,
  "burnin": 0
```

- `centre_of_mass` lets registration initialise from the centres of mass of both images. This helps when e.g. PET is wildly out of alignment, and so it is strongly recommended by default (unless all images are pre-registered). Valid values: 0 (off) or 1 (on).
- `viz` provides interactive quality control of the relevant steps - it is recommended to inspect the interim and final outputs to ensure correct results. Valid values: 0 (off) or 1 (on).
- `cluster_size`: threshold for cluster size in mm<sup>3</sup>. Clusters smaller that this threshold will get discarded, unless they contain Z peak which will always be preserved.
- `burnin`: whether output burn-in image is produced. This will modify the original T1-weighted image such that Z>3 clusters are shown as white, Z>4 clusters are shown as black, Z>5 clusters are shown as grey. The file is saved as 'burnin.nii'. Valid values: 0 (off) or 1 (on).

Any of these optional flags can be omitted, in which case they will default to the values shown above.

### VIEWING RESULTS 

![image](https://github.com/user-attachments/assets/987a5f85-21a7-4577-90c3-9b2f703ef9be)

Results are automatically shown at the end, but if you just want to view existing results separately do this step:

1. The viewer.m script will set the anatomical unflipped T1 as background..
2. The Z3, Z4, and Z5.nii overlays are simultaneously superimposed to see the asymmetrical regions in order of strength of asymmetry. 
3. Z3,4,5 with "clustered" suffix can be used instead if only want to see big clusters of asymmetry

**NOTE! The viewer will demonstrate results in "anatomical" orientation (right is right, left is left). The cluster image files, however, will stay aligned with the original T1w image file.**


### EXPORTING RESULTS TO DICOM:

Open output in MRIcron to ensure Burned in is adequate of new nifti. 

1. To use in BrainLab/NeuroMate planning station must EXPORT burned-in .nii AS DICOM 
2. Use 3Dslicer --> Module> DICOM  --> EXPORT as DICOM series --> Populate tag fields.
3. You should now have a folder of DICOMs ready for use. Can put this on USB stick and use on planning software (Brainlab, Stealth, Neuromate). It must be noted that any such use is purely experimental.


> Reference: Aslam S, Damodaran N, Rajeshkannan R, Sarma M, Gopinath S, Pillai A. Asymmetry index in anatomically symmetrized FDG-PET for improved epileptogenic focus detection in pharmacoresistant epilepsy. J Neurosurg. 2022 Aug 5;138(3):828-836. doi: 10.3171/2022.6.JNS22717. PMID: 35932262
