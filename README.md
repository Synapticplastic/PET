# PET
Asymmetry Index pipeline for evaluation of epilepsy
v2.0 (Feb 2025)

Custom scripts by Anton Fomenko MD FRCSC
Epilepsy Neurosurgery Fellow, University of Toronto

Branch: Dmitri Šastin
Epilepsy Neurosurgery Fellow, University of Toronto

Acknowledgments:
Thank you to Dr Lydia Falsitta for her contribution to the report structure.

### REQUIREMENTS:

1. MATLAB v2017 or higher

2. SPM12 toolbox https://www.fil.ion.ucl.ac.uk/spm/software/spm12/

3. Exported PET, T1 MRI, and FLAIR MRI sequences of the patient (in NIFTI or DICOM)

4. Scripts attached to this repository.

5. Optional but desirable: MRIcron viewer  https://www.nitrc.org/projects/mricron

6. Approximately 1 hour to run the full pipeline on a personal laptop. Dedicated desktop machines will perform faster


### GUIDELINE FOR USE:

1. Download the repository. Ensure MATLAB and SPM12 are installed, and SPM and the repository are on your MATLAB path.

2. Export PET, T1 MRI, FLAIR MRI scans of patients. Ideally the scans are done within the same year, and are thinly sliced. 

3. PET images will come as "PET" or "NACPET". Choose the "PET" one, as this is attenuation corrected.

4. Create an inputs JSON as demonstrated [below](#creating-inputs-json) (an example is also available in this repository). **This file is mandatory.**

5. Run `run_PET_AI('string\to\inputs.json')`.

6. If an individual step needs to be re-run (e.g., experimenting with Z-score and/or cluster volume thresholds):
    - The output folder will contain `params_step_*.mat` files with inputs for every step. 
    - Load this file, optionally change the contents of the thus loaded `params` structure (most likely in `params.settings`).
    - Type `PET_AI_Step5(params)` (replace 5 as needed).

7. If registration continues to fail, consider cropping the images to contain brain only if excessive neck is present (may help registration), followed by manual alignment of the images using external software (FLAIR and PET to T1 - do not modify T1 itself!).

### CREATING INPUTS JSON:

Create a text file (could be later renamed to `*.json`) and enter **EITHER**:

```
{
  "input_dir": "path\to\NIFTI_or_DCM_dir",
  "output_dir": "path\to\output_dir"
}
```

**OR**:

```
{
  "PET": "path\to\PET\NIFTI_or_DCM_dir",
  "T1": "path\to\T1\NIFTI_or_DCM_dir",
  "FLAIR": "path\to\FLAIR\NIFTI_or_DCM_dir",
  "output_dir": "path\to\output_dir"
}
```

These are the required inputs that must always be present. If `input_dir` is provided:
 
 - It can have files in a single folder or in nested subfolders.
 - It can contain NIFTI, DICOM, or a mixture of the two - as long as in the end there are just three volumes (T1, FLAIR, PET). 
 - NIFTI files **MUST** be named `T1.nii`, `FLAIR.nii`, `PET.nii` (could also be `.nii.gz`).
 - DICOM volumes **MUST** contain "t1", "t2", "pet" in their sequence names (lower or upper case).

In addition, the following are optional (contain within the same curly brackets):

```
  "centre_of_mass": 1,
  "thr": 3,
  "cluster_size": 0.1,
  "report": 1,
  "blanks": 1,
  "regions": 0, 
  "burnin": 0,
  "viz": 1
```

- `centre_of_mass` lets registration initialise from the centres of mass of both images. This helps when e.g. PET is wildly out of alignment, and so it is strongly recommended by default (unless all images are pre-registered). Valid values: 0&nbsp;/&nbsp;1.
- `viz` provides interactive quality control of the relevant steps - it is recommended to inspect the interim and final outputs to ensure the correctness of results. Valid values: 0&nbsp;/&nbsp;1.
- `thr` is the minimum Z-score for the PET asymmetry to be demonstrated on outputs. Default may sometimes be too conservative; setting to 3.5&nbsp;&#8209;&nbsp;4.0 can yield less noisy results (but start with a lower threshold first to avoid discarding useful data). Valid values: any non-negative number.
- `cluster_size`: threshold for cluster size in ml. Clusters smaller that this threshold will get discarded, unless they contain Z peak which will always be preserved. Default is likely too conservative, consider setting to 0.5&nbsp;&#8209;&nbsp;1.0. Valid values: any non-negative number; 0 will disable this thresholding.
- `report`: produce a report which will contain per-cluster images and data. Valid values: 0&nbsp;/&nbsp;1.
- `blanks`: given `report` is on, will append empty fields that can be populated with clinical data. Valid values: 0&nbsp;/&nbsp;1.
- `regions`: given `report` is on, will attempt an automated anatomical description of every cluster. Experimental feature, always double-check! Valid values: 0&nbsp;/&nbsp;1.
- `burnin`: whether output burn-in image is produced. For a Z-score threshold value of t (`thr` above), this will modify the original T1-weighted image such that clusters with Z-score between t and t&nbsp;+&nbsp;1 are shown as white, between t&nbsp;+&nbsp;1 and t&nbsp;+&nbsp;2 are black, and &#8805;&nbsp;t&nbsp;+&nbsp;2 are grey. The file is saved as `burnin.nii`. Valid values: 0&nbsp;/&nbsp;1.

Any of these optional flags can be omitted, in which case they will default to the values shown above.
All of these flags are present in `example_inputs.json` provided with the code; this can be copied for each set of data and modified accordingly.

### VIEWING RESULTS 

![image](https://github.com/user-attachments/assets/80220561-9b7b-4101-8085-ee257329989a)

Results are automatically shown at the end, but to view them separately, `PET_AI_viewer.m` should be used:

1. One option is to type `PET_AI_viewer(params)` where `params` is loaded in advance from the output folder's `params_step_5.mat` file. 
2. The other option is to copy the viewer file into the output folder, navigate there in Matlab, and type `PET_AI_viewer()`.

**NOTE! The viewer will demonstrate results in "anatomical" orientation (right is right, left is left). The actual image files (e.g., `MNI_cluster_1.nii` etc) will preserve the original T1w laterality but not orientation (i.e., they will be rotated). Only the burn-in output ([below](#exporting-results-to-dicom)) remains aligned with the original T1w image file.**

### EDITING THE REPORT

Report is produced as HTML and image files, stored in the `report` folder of the output directory. This is more flexible than generating a Microsoft Word document with Matlab directly. The HTML file can be subsequently opened with Microsoft Word, edited as needed (e.g., populating with clinical data), and stored as a document file or exported as a PDF. Note that thus produced `*.doc(x)` file will not have the images embedded (just linked) - so once the report is finished, it is recommended to save the final version in PDF format.

### EXPORTING RESULTS TO DICOM:

Preview `burnin.nii` (e.g., in MRIcron) to ensure it is adequate. If this was to be used in BrainLab / NeuroMate, it must be exported as DICOM:

1. Open 3D Slicer and launch Module > DICOM.
2. Under "Loaded Data" panel, right-click and select "Create new subject" (optionally, rename).
3. Right-click on the new subject and select "Create child study" (optionally, rename).
4. Drag `burnin.nii` from your file explorer to the panel and move it to sit under the new study.
5. Right-click on burnin and select "Export to DICOM...".
6. In the "DICOM Export" window that appears, relevant tags need to be populated (e.g., PatientBirthDate, PatientID, PatientName, StudyDate) and export type selected as "Scalar Volume".
7. You should now have a folder of DICOMs ready for use. Can put this on USB stick and use on planning software (Brainlab, Stealth, Neuromate). **It must be noted that any such use is purely experimental.**


> Reference: Aslam S, Damodaran N, Rajeshkannan R, Sarma M, Gopinath S, Pillai A. Asymmetry index in anatomically symmetrized FDG-PET for improved epileptogenic focus detection in pharmacoresistant epilepsy. J Neurosurg. 2022 Aug 5;138(3):828-836. doi: 10.3171/2022.6.JNS22717. PMID: 35932262
