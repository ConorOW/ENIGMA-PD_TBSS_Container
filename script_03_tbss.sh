#!/bin/bash

# EXIT ON ERROR
set -x

# SET A LOCATION FOR THE ERROR OUTPUT OF THIS FILE TO BE SENT TO
exec 2> /data/logs/script_03_tbss.log ;

# Set a directory for our enigmaDTI data
enigmaDir=/data/enigmaDTI ;

# Set a directory with our executables
executables=/data/ROIextraction_info ;

# Create a new variable to clean up a little
tbss=/data/tbss ;

#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~
#~%~%~%~%~%~%~%~%~%~%~%~% STEP 15 ~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%
#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~

# TBSS script applies the nonlinear transforms found in the previous stage to all subjects to bring them into standard space
cd ${tbss} ;

# Applies the nonlinear transforms to all subjects to bring them into standard space
tbss_3_postreg -S ;

#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~
#~%~%~%~%~%~%~%~%~%~%~%~% STEP 16 ~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%
#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~

# Change back to our base
cd /data/

# Copy our FA values to subj specific folders
for subj in $(cat /data/subjects.txt) ; do

    mkdir -p ${tbss}/FA/FA_individ/${subj}/stats ;
    mkdir -p ${tbss}/FA/FA_individ/${subj}/FA ;

    # Copy the images into each individuals folder
    cp ${tbss}/FA/${subj}_*.nii.gz ${tbss}/FA/FA_individ/${subj}/FA ;

done ;

# Move/Copy our FA values and rename them
for subj in $(cat /data/subjects.txt) ; do

    # Masking to the ENIGMA-DTI FA template
    fslmaths \
    ${tbss}/FA/FA_individ/${subj}/FA/${subj}_*FA_to_target.nii.gz \
    -mas ${enigmaDir}/ENIGMA_DTI_FA_mask.nii.gz \
    ${tbss}/FA/FA_individ/${subj}/FA/${subj}_masked_FA.nii.gz ;

#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~
#~%~%~%~%~%~%~%~%~%~%~%~% STEP 17 ~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%
#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~

# Skeletonize images by projecting the ENIGMA skeleton onto them

    # Skeletonize our images to create distance maps
    tbss_skeleton \
    -i ${tbss}/FA/FA_individ/${subj}/FA/${subj}_masked_FA.nii.gz \
    -p 0.049 ${enigmaDir}/ENIGMA_DTI_FA_skeleton_mask_dst.nii.gz \
    ${FSLDIR}/data/standard/LowerCingulum_1mm.nii.gz \
    ${tbss}/FA/FA_individ/${subj}/FA/${subj}_masked_FA.nii.gz \
    ${tbss}/FA/FA_individ/${subj}/stats/${subj}_masked_FAskel.nii.gz \
   -s ${enigmaDir}/ENIGMA_DTI_FA_skeleton_mask.nii.gz ;

done ;

#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~
#~%~%~%~%~%~%~%~%~%~%~%~% STEP 18 ~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%
#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~

## part 1 - loop through all subjects to create a subject ROI file

# Make an output directory for all files pt1
mkdir -p ${tbss}/FA/ENIGMA_ROI_part1 ;
dirO1=${tbss}/FA/ENIGMA_ROI_part1 ;

# make an output directory for all files pt2
mkdir -p ${tbss}/FA/ENIGMA_ROI_part2 ;
dirO2=${tbss}/FA/ENIGMA_ROI_part2 ;

# Make sure we are in the right place
cd ${tbss} ;

# Extract the TBSS stats for each ROI for each subject
for subj in $(cat /data/subjects.txt) ; do

    # Create skeleton images
    ${executables}/singleSubjROI_exe \
    ${executables}/ENIGMA_look_up_table.txt \
    ${executables}/mean_FA_skeleton.nii.gz \
    ${executables}/JHU-WhiteMatter-labels-1mm.nii.gz \
    ${dirO1}/${subj}_ROIout \
    ${tbss}/FA/FA_individ/${subj}/stats/${subj}_masked_FAskel.nii.gz ;

## part 2 - loop through all subjects to create ROI file
## removing ROIs not of interest and averaging others

    ${executables}/averageSubjectTracts_exe ${dirO1}/${subj}_ROIout.csv ${dirO2}/${subj}_ROIout_avg.csv ;

# can create subject list here for part 3!
    echo ${subj},${dirO2}/${subj}_ROIout_avg.csv >> ${tbss}/FA/subjectList.csv

done

#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~
#~%~%~%~%~%~%~%~%~%~%~%~% STEP 19 ~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%
#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~

# Go over each subject and extract the values at each ROI
for subj in $(cat /data/subjects.txt) ; do

    # Set an input directory to get data from
    inDir=/data/${subj} ;

    # Copy over our diffusion metrics to a convenient location
    cp ${inDir}/dtifit/dti_RD.nii.gz ${tbss}/${subj}_RD.nii.gz ;
    cp ${inDir}/dtifit/dti_MD.nii.gz ${tbss}/${subj}_MD.nii.gz ;
    cp ${inDir}/dtifit/dti_L1.nii.gz ${tbss}/${subj}_AD.nii.gz ;

    # First copy over our MD, RD and AD values and rename them
    for DIFF in MD AD RD ; do
        mkdir -p ${tbss}/${DIFF}/origdata/ ;
        mkdir -p ${tbss}/${DIFF}/${DIFF}_individ/${subj}/${DIFF}/ ;
        mkdir -p ${tbss}/${DIFF}/${DIFF}_individ/${subj}/stats/ ;

        # Mask our MD/AD/RD images
        fslmaths \
        ${tbss}/${subj}_${DIFF}.nii.gz \
        -mas ${tbss}/FA/${subj}_FA_FA_mask.nii.gz \
        ${tbss}/${DIFF}/${DIFF}_individ/${subj}/${DIFF}/${subj}_${DIFF} ;

        # Move the images
        immv ${tbss}/${subj}_${DIFF}.nii.gz ${tbss}/${DIFF}/origdata/ ;

        # Apply warp to our image
        applywarp \
        -i ${tbss}/${DIFF}/${DIFF}_individ/${subj}/${DIFF}/${subj}_${DIFF} \
        -o ${tbss}/${DIFF}/${DIFF}_individ/${subj}/${DIFF}/${subj}_${DIFF}_to_target \
        -r /opt/fsl-5.0.11/data/standard/FMRIB58_FA_1mm \
        -w ${tbss}/FA/${subj}_FA_FA_to_target_warp.nii.gz ;

        # Mask our images
        fslmaths \
        ${tbss}/${DIFF}/${DIFF}_individ/${subj}/${DIFF}/${subj}_${DIFF}_to_target \
        -mas ${enigmaDir}/ENIGMA_DTI_FA_mask.nii.gz \
        ${tbss}/${DIFF}/${DIFF}_individ/${subj}/${DIFF}/${subj}_masked_${DIFF}.nii.gz	;

        # Skeletonizes our images
        tbss_skeleton \
        -i ${tbss}/FA/FA_individ/${subj}/FA/${subj}_masked_FA.nii.gz \
        -p 0.049 \
        ${enigmaDir}/ENIGMA_DTI_FA_skeleton_mask_dst.nii.gz \
        /opt/fsl-5.0.11/data/standard/LowerCingulum_1mm.nii.gz \
        ${tbss}/FA/FA_individ/${subj}/FA/${subj}_masked_FA.nii.gz \
        ${tbss}/${DIFF}/${DIFF}_individ/${subj}/stats/${subj}_masked_${DIFF}skel \
        -a ${tbss}/${DIFF}/${DIFF}_individ/${subj}/${DIFF}/${subj}_masked_${DIFF}.nii.gz \
        -s ${enigmaDir}/ENIGMA_DTI_FA_skeleton_mask.nii.gz ;

    done
done

#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~
#~%~%~%~%~%~%~%~%~%~%~%~% STEP 21 ~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%
#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~

# Move into the folder with our data
cd ${tbss} ;

for DIFF in MD AD RD ; do

    # Create some folders for our ROI output
    mkdir -p ${tbss}/${DIFF}/${DIFF}_individ/${DIFF}_ENIGMA_ROI_part1 ;
    mkdir -p ${tbss}/${DIFF}/${DIFF}_individ/${DIFF}_ENIGMA_ROI_part2 ;

    # Create some variables for those locations
    export dirO1=${tbss}/${DIFF}/${DIFF}_individ/${DIFF}_ENIGMA_ROI_part1 ;
    export dirO2=${tbss}/${DIFF}/${DIFF}_individ/${DIFF}_ENIGMA_ROI_part2 ;

    # Go over each subject and extract the values at each ROI
    for subj in $(cat /data/subjects.txt) ; do

        # Create skeleton images
        ${executables}/singleSubjROI_exe \
        ${executables}/ENIGMA_look_up_table.txt \
        ${executables}/mean_FA_skeleton.nii.gz \
        ${executables}/JHU-WhiteMatter-labels-1mm.nii.gz \
        ${dirO1}/${subj}_${DIFF}_ROIout \
        ${tbss}/${DIFF}/${DIFF}_individ/${subj}/stats/${subj}_masked_${DIFF}skel.nii.gz ;

        # Create average ROI values
        ${executables}/averageSubjectTracts_exe \
        ${dirO1}/${subj}_${DIFF}_ROIout.csv \
        ${dirO2}/${subj}_${DIFF}_ROIout_avg.csv ;

        echo ${subj},${dirO2}/${subj}_${DIFF}_ROIout_avg.csv >> ${tbss}/${DIFF}/${DIFF}_individ/subjectList_${DIFF}.csv ;

    done

done