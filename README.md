# ENIGMA-DTI Preprocessing & TBSS Container

## Introduction 
This document lays out the steps necessary to run a basic ENIGMA-DTI TBSS pipeline, which runs preprocessing, tensor fitting and tract-based spatial statistics, using 4 shell scripts and a Singularity image. The final step will copy all of the TBSS metrics for each subject to a central folder “USC_FINAL” which can be shared with USC.

## Setup
Go into a location on your computer where you have all of the subject folders you want to analyze. It should look something like this:

```
cowenswalton:{folder} $ ls -1 * 
    sub-P001
    sub-P002
    sub-P003
```

If you change into one of these folders, it should look something like what we have below. What is important is that the image extensions are correct. So the diffusion image must end in `.nii.gz`, the diffusion direction and strength files must end in `.bvec` and `.bval` respectively, and the metadata for the diffusion image must be `.json`. So sub-P001 would look like:

```
cowenswalton:{folder} $ cd ./sub-P001
cowenswalton:{sub-P001} $ ls -1 *
    dwi_image.nii.gz
    dwi.json
    dwi.bvec
    dwi.bval
```

The next thing we need is a text file with a list of the subject folder names. This should look like this (make sure it has an empty line at the end):
```
cowenswalton:{folder} $ cat subjects.txt
    sub-P001
    sub-P002
    sub-P003
 
```

Once your image files are all set up, and you have a text file with a list of the names you want to use, we are ready to download the resources we need to run this ENIGMA-DTI Singularity image.

There are 8 things you must download to your main `folder` location:

1. neuropipe_latest.sif
2. enigmaDTI
3. ROIextraction_info
4. covariates.csv (*please fill in with subject information*)
5. [script_01_preproc.sh](https://drive.google.com/file/d/10wHjxNcqyQ1pCNvBNSQUD7mFSboKve0s/view?usp=share_link)
6. [script_02_tbss.sh](https://drive.google.com/file/d/10vXTtjxh97ve3HTJokIVdd-C4z1hWhEd/view?usp=share_link)
7. [script_03_tbss.sh](https://drive.google.com/file/d/10rnrpS8UhzvdWui5_0vNJ8NY6-BvQ-pe/view?usp=share_link)
8. [script_04_concat_linux.sh](https://drive.google.com/file/d/10nf3xS0X_QDi6emjX2AQ3YcSnAff4rZr/view?usp=share_link)

## Script 1: Preprocessing Diffusion MRI Images
This script runs some basic preprocessing on the diffusion weighted images, including:
    - MR Gibbs de-ringing
    - Correcting for eddy current-induced distortions/movement correction
    - EPI induced susceptibility artifact correction (*bias correction*). 

After this the script fits a tensor model to the preprocessed data. I suggest running this script after using the screen command, so you can throw it into the background and continue using your terminal [*using the ctrl + (A + D) command*].

```
cowenswalton:{folder} $ screen
cowenswalton:{folder} $ for subj in $(cat subjects.txt) ; 
do 
    singularity run \
    --cleanenv \
    --bind ${PWD}/input:/data \
    neuropipe_latest.sif ./script_01_preproc.sh ${subj} ; 
done
cowenswalton:{folder} $ ctrl + (A + D) 
```

## Script 2: TBSS - Erode FA images and alignment to ENIGMA DTI template
This script erodes our FA images slightly, then aligns them with the ENIGMA DTI template. Again, I suggest running this with the screen command.

```
cowenswalton:{folder} $ screen
cowenswalton:{folder} $ singularity run \
    --cleanenv \
    --bind ${PWD}:/data \
    neuropipe_latest.sif ./script_02_tbss.sh ;
cowenswalton:{folder} $ ctrl + (A + D)
```

## Script 3: TBSS - Nonlinear transforms and TBSS
This script performs nonlinear transformations to get FA images into standard space. From there it performs TBSS, extracting average values for each JHU Atlas region-of-interest.

```
cowenswalton:{folder} $ screen
cowenswalton:{folder} $ singularity run \
    --cleanenv \
    --bind ${PWD}:/data \
    neuropipe_latest.sif ./script_03_tbss.sh ;
cowenswalton:{folder} $ ctrl + (A + D)
```

## Script 4: QC and Data Retrieval
The final script in this pipeline creates a png of each subject FA skeleton, overlaid on top of the ENIGMA-DTI FA template. This, along with the calculated TBSS values for each subject, are then organized to a central location `USC_FINAL`, which can then be sent to USC for statistical analyses.

```
cowenswalton:{folder} $ singularity run \
    --cleanenv \
    --bind ${PWD}:/data \
    neuropipe_latest.sif ./script_04_qc_data-retrieval.sh ;
```

## Conclusion
If this all ran successfully, you should have a folder called `USC_FINAL` which will have an `AD`, `FA`, `MD` and `RD` folder, containing the TBSS data for each subject. It will also have a folder called `QC` which has the FA skeleton pngs. If there were any issues along the way, look in the `/folder/logs` file for clues.