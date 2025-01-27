# ENIGMA-DTI Preprocessing & TBSS Container

## Introduction 
This document lays out the steps necessary to run a basic ENIGMA-DTI TBSS pipeline, running preprocessing, tensor fitting and tract-based spatial statistics. This is done using 4 shell scripts and a Singularity image. The final step will copy all of the TBSS metrics for each subject to a central folder `USC_FINAL` which can be shared with USC, along with the covariates file which you should fill out. This is not official ENIGMA- just my own project. Please contact me at my USC email if you want to run the pipeline so I can set up the Singularity image for you.

## Setup
Go into a location on your computer where you have all of the subject folders you want to analyze. It should look something like this:

```
cowenswalton:{folder} $ ls -1 * 
sub-P001
sub-P002
sub-P003

cowenswalton:{folder} $
```

If you change into one of these folders, it should look something like what we have below. What is important is that the image extensions are correct. So the diffusion image must end in `.nii.gz`, the diffusion direction and strength files must end in `.bvec` and `.bval` respectively, and the metadata for the diffusion image must be `.json`. So sub-P001 would look like:

```
cowenswalton:{folder} $ cd ./sub-P001
cowenswalton:{sub-P001} $ ls -1 *
dwi_image.nii.gz
dwi.json
dwi.bvec
dwi.bval

cowenswalton:{sub-P001} $
```

The next thing we need is a text file with a list of the subject folder names. This should look like this (make sure it has an empty line at the end):
```
cowenswalton:{sub-P001} $ cd ${folder}
cowenswalton:{folder} $ cat subjects.txt
sub-P001
sub-P002
sub-P003

cowenswalton:{folder} $
```

Once your image files are all set up, and you have a text file with a list of the names you want to use, we are ready to download the resources we need to run this ENIGMA-DTI Singularity image.

There are 8 things you must download to your main `folder` location:

1. [neuropipe_latest.sif](https://drive.google.com/file/d/1bqA77V_VR5h1gHZkcNEhP-P78nF4VHII/view?usp=share_link)
2. [enigmaDTI](https://git.ini.usc.edu/ehaddad/04_enigma-dti-tbss/-/tree/master/enigmaDTI)
3. [ROIextraction_info](https://git.ini.usc.edu/ehaddad/04_enigma-dti-tbss/-/tree/master/ROIextraction_info)
4. [covariates.csv](https://drive.google.com/file/d/1-caykSRDq1NHRLidc4VEJTE_hepIm7yp/view?usp=share_link)
5. [script_01_preproc.sh](https://github.com/ConorOW/ENIGMA-PD_TBSS_Container/blob/42a9efd90c8110e9b9541b053d31c53461015c06/script_01_preproc.sh)
6. [script_02_tbss.sh](https://github.com/ConorOW/ENIGMA-PD_TBSS_Container/blob/203f7d6e84581948f90c956551d31c31dc074619/script_02_tbss.sh)
7. [script_03_tbss.sh](https://github.com/ConorOW/ENIGMA-PD_TBSS_Container/blob/203f7d6e84581948f90c956551d31c31dc074619/script_03_tbss.sh)
8. [script_04_concat_linux.sh](https://github.com/ConorOW/ENIGMA-PD_TBSS_Container/blob/203f7d6e84581948f90c956551d31c31dc074619/script_04_qc_data-retrieval.sh)

## Script 1: Preprocessing Diffusion MRI Images
This script runs some basic preprocessing on the diffusion weighted images, including:
- MR Gibbs de-ringing
- Correcting for eddy current-induced distortions/movement correction
- EPI induced susceptibility artifact correction (*bias correction*). 

After preprocessing, the script fits a tensor model to the data. I suggest running this script after using the `screen` command, so you can throw it into the background and continue using your terminal [*using the ctrl + (A + D) command*]. This script might take 30-45 minutes per subject, so if that is going to be a prohibitively long time for your data, you might need to talk with Conor about tweaking the script to run on a SGE or job queuing system. It might also be a good idea to just included a few subjects in your `subjects.txt` file for the first run.

```
cowenswalton:{folder} $ ml load singularity
cowenswalton:{folder} $ which singularity
/usr/local/bin/singularity
cowenswalton:{folder} $ screen
cowenswalton:{folder} $ for subj in $(cat subjects.txt) ; do 
    singularity run \
    --cleanenv \
    --bind ${PWD}:/data \
    neuropipe_latest.sif /data/script_01_preproc.sh ${subj} ; 
done

cowenswalton:{folder} $ ctrl + (A + D) 
```

To check that this script has worked you can look at the log files in the `${folder}/logs` directory. You can also run the following command which might be easier:

```
cowenswalton:{folder} $ for subj in $(cat subjects.txt) ; do 
     ls -1 ${subj}/dtifit/dti_FA.nii.gz ; 
done
sub-101287/dtifit/dti_FA.nii.gz
sub-101288/dtifit/dti_FA.nii.gz
ls: cannot access sub-101289/dtifit/dti_FA.nii.gz: No such file or directory

cowenswalton:{folder} $
```

If any errors pop up like the above, you can copy those subject names to a new text file and re-run script 1, or troubleshoot in the logfiles.

## Script 2: TBSS - Erode FA images and alignment to ENIGMA DTI template
This script erodes our FA images slightly, then aligns them with the ENIGMA DTI template. Again, I suggest running this with the screen command.

```
cowenswalton:{folder} $ screen
cowenswalton:{folder} $ singularity run \
    --cleanenv \
    --bind ${PWD}:/data \
    neuropipe_latest.sif /data/script_02_tbss.sh ;
    
cowenswalton:{folder} $ ctrl + (A + D)
```

## Script 3: TBSS - Nonlinear transforms and TBSS
This script performs nonlinear transformations to get FA images into standard space. From there it performs TBSS, extracting average values for each JHU Atlas region-of-interest.

```
cowenswalton:{folder} $ screen
cowenswalton:{folder} $ singularity run \
    --cleanenv \
    --bind ${PWD}:/data \
    neuropipe_latest.sif /data/script_03_tbss.sh ;
    
cowenswalton:{folder} $ ctrl + (A + D)
```

## Script 4: QC and Data Retrieval
The final script in this pipeline creates a png of each subject FA skeleton, overlaid on top of the ENIGMA-DTI FA template. This, along with the calculated TBSS values for each subject, are then organized to a central location `USC_FINAL`, which can then be sent to USC for statistical analyses.

```
cowenswalton:{folder} $ singularity run \
    --cleanenv \
    --bind ${PWD}:/data \
    neuropipe_latest.sif /data/script_04_qc_data-retrieval.sh ;
```

## Conclusion
If this all ran successfully, you should have a folder called `USC_FINAL` which will have an `AD`, `FA`, `MD` and `RD` folder, containing the TBSS data for each subject. It will also have a folder called `QC` which has the FA skeleton pngs. Please also remember to either copy in your covariates file here, or send it along with this folder to USC.

If you have any issues, please [email Conor](conor.owens-walton@loni.usc.edu)
