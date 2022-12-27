#!/bin/bash

# Set a flag so the script exits on error and prints verbose output
set -ex

# SET A LOCATION FOR THE ERROR OUTPUT OF THIS FILE TO BE SENT TO
exec 2> /data/logs/script_02_tbss.log

#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~
#~%~%~%~%~%~%~%~%~%~%~%~% STEP 12 ~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%
#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~

# Create a new variable to clean up a little
base=/data ;

# Set a directory for our enigmaDTI data
enigmaDir=${base}/enigmaDTI

# Create a folder for our TBSS
tbss=${base}/tbss ; mkdir -p ${base}/tbss ;

# Change into the directory with our subject folders
cd ${base} ;

for subj in $(cat ${base}/subjects.txt) ; do

    # Set an input directory to work from
    inDir=${base}/${subj} ;

    # Copy over our diffusion metrics to a convenient location
    cp ${inDir}/dtifit/dti_FA.nii.gz ${tbss}/${subj}_FA.nii.gz ;

done ;

#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~
#~%~%~%~%~%~%~%~%~%~%~%~% STEP 13 ~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%
#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~

# Ensure we are in the correct folder
cd ${tbss} ;

# Next we erode our images
tbss_1_preproc *_FA.nii.gz ;

#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~
#~%~%~%~%~%~%~%~%~%~%~%~% STEP 14 ~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%
#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~

# Register subjects to the ENIGMA FA template
cd ${tbss} ;

# Ensure we are in the correct folder
tbss_2_reg -t ${enigmaDir}/ENIGMA_DTI_FA.nii.gz ;
