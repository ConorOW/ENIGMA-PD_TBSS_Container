#!/bin/bash

# I suggest running this with the screen command so you can throw it into the background and continue
# to use your terminal while it runs.

# Set a flag so the script exits on error and prints verbose output
set -ex

# SET A LOCATION FOR THE ERROR OUTPUT OF THIS FILE TO BE SENT TO
exec 2> /data/logs/script_04_qc_data-retrieval.log ;

# Create a new variable to clean up a little
tbss=/data/tbss ;

# Make a directory where we want out data to go
mkdir -p /data/USC_FINAL/FA
mkdir -p /data/USC_FINAL/RD
mkdir -p /data/USC_FINAL/AD
mkdir -p /data/USC_FINAL/MD

# Make a directory for our QC
mkdir -p /data/USC_FINAL/QC

# TBSS script applies the nonlinear transforms found in the previous stage to all subjects to bring them into standard space
for subj in $(cat /data/subjects.txt) ; do

    slices ${tbss}/FA/FA_individ/${subj}/FA/${subj}_masked_FA.nii.gz ${tbss}/FA/FA_individ/${subj}/stats/${subj}_masked_FAskel.nii.gz -L -a /data/USC_FINAL/QC/${subj}_FA_QC.png
    
done

# Now we want to copy all of our TBSS data into a central location
for subj in $(cat /data/subjects.txt) ; do

    # FA has slightly different format
    cp ${tbss}/FA/ENIGMA_ROI_part2/${subj}_ROIout_avg.csv /data/USC_FINAL/FA/${subj}_ROIout_avg_FA.csv ;

    # Now run for other DTI metrics
    for dti in MD RD AD ; do
    
        cp ${tbss}/${dti}/${dti}_individ/${dti}_ENIGMA_ROI_part2/${subj}_${dti}_ROIout_avg.csv /data/USC_FINAL/${dti}/${subj}_ROIout_avg_${dti}.csv ;
        
    done
    
done

# Now we want to change some permissions on that output
chmod -r 777 /data/USC_FINAL

