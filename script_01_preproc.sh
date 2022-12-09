#!/bin/bash

# Set a flag so the script exits on error
set -x

# Set the first argument of the script call as the subject ID
subj=${1}

# Make a log directory
mkdir -p /data/logs/ ;

# Send error to a text file
exec 2> /data/logs/script_01_${subj}.log

# Set a subject-specific input directory to work from
inDir=/data/${subj} ;

# Create some folders we need for output
mkdir -p ${inDir}/dtifit ;
mkdir -p ${inDir}/eddy ;

# Get some key variables
bvec=`ls -1 ${inDir}/*.bvec`
bval=`ls -1 ${inDir}/*.bval`
dwi_image=`ls -1 ${inDir}/*dwi.nii.gz`
dwi_json=`ls -1 ${inDir}/*dwi.json`
phaseDir=`jq .PhaseEncodingDirection ${inDir}/*dwi.json` ;
totalReadout=`jq .TotalReadoutTime ${inDir}/*dwi.json` ;

#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~
#~%~%~%~%~%~%~%~%~%~%~%~% STEP 01 ~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%
#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~

# Create an index file for EDDY
# Extract the number of volumes from the raw dwi file

fslinfo ${inDir}/*dwi.nii.gz | grep "dim4" | awk 'NR == 1' | awk '{print $2}' >> ${inDir}/eddy/dim4.txt ;

#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~
#~%~%~%~%~%~%~%~%~%~%~%~% STEP 02 ~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%
#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~

# This command reads the number of vols we have and creates a new
# file with a 1 for each volume, tab-delimited. Used for EDDY later.
vols=`cat ${inDir}/eddy/dim4.txt` ;
indx="" ;
for ((i=1; i<=${vols} ; i+=1)) ; do
  indx="${indx} 1" ;
done ;
echo ${indx} >> ${inDir}/eddy/index.txt ;

#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~
#~%~%~%~%~%~%~%~%~%~%~%~% STEP 03 ~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%
#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~

# Now we get acquisition parameters file for EDDY corrections
# Assign the PhaseEncodingDirection value to PE then populate an acqparams file based on that result
# If we have the dicoms: phaseDir=`jq .PhaseEncodingDirection ${base}/${subj}/dwi.json`

# Now we can echo our data to our acqparams file
if [ ${phaseDir} = '"j-"'  ] ; then
  echo "0 -1 0 ${totalReadout}" > ${inDir}/eddy/acqparams.txt ;

elif [ ${phaseDir} = '"j"'  ] ; then
  echo "0 1 0 ${totalReadout}" > ${inDir}/eddy/acqparams.txt ;

elif [ ${phaseDir} = '"i-"'  ] ; then
  echo "-1 0 0 ${totalReadout}" > ${inDir}/eddy/acqparams.txt ;

elif [ ${phaseDir} = '"i"'  ] ; then
  echo "1 0 0 ${totalReadout}" > ${inDir}/eddy/acqparams.txt ;
fi

#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~
#~%~%~%~%~%~%~%~%~%~%~%~% STEP 04 ~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%
#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~

# Image denoising MP-PCA denoising
# dwidenoise -force \
# ${inDir}/*dwi.nii.gz \
# ${inDir}/eddy/dwi_proc.nii.gz ;

#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~
#~%~%~%~%~%~%~%~%~%~%~%~% STEP 05 ~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%
#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~

# Gibbs de-ringing
mrdegibbs -force \
${dwi_image} \
${inDir}/eddy/dwi_proc.nii.gz ;

#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~
#~%~%~%~%~%~%~%~%~%~%~%~% STEP 06 ~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%
#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~

# Extract a bzero volume and a mask
dwiextract \
-fslgrad ${bvec} ${bval} \
${inDir}/eddy/dwi_proc.nii.gz - -bzero | \
mrmath - mean ${inDir}/eddy/b0.nii.gz -axis 3 ;

bet ${inDir}/eddy/b0.nii.gz ${inDir}/eddy/b0_brain -m -f 0.3 ;

#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~
#~%~%~%~%~%~%~%~%~%~%~%~% STEP 07 ~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%
#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~

# Run FSL Eddy
eddy_openmp \
--imain=${inDir}/eddy/dwi_proc.nii.gz \
--mask=${inDir}/eddy/b0_brain_mask.nii.gz \
--acqp=${inDir}/eddy/acqparams.txt \
--index=${inDir}/eddy/index.txt \
--bvecs=${bvec} \
--bvals=${bval} \
--flm=quadratic \
--out=${inDir}/eddy/eddy_corrected ;

#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~
#~%~%~%~%~%~%~%~%~%~%~%~% STEP 08 ~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%
#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~

## DWI bias correction
dwibiascorrect fsl \
${inDir}/eddy/eddy_corrected.nii.gz \
${inDir}/eddy/eddy_bias_corrected.nii.gz \
-mask ${inDir}/eddy/b0_brain_mask.nii.gz \
-fslgrad ${inDir}/eddy/eddy_corrected.eddy_rotated_bvecs ${bval} ;

#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~
#~%~%~%~%~%~%~%~%~%~%~%~% STEP 09 ~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%
#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~

# Extract a bzero volume from the eddy corrected image
dwiextract \
-fslgrad ${inDir}/eddy/eddy_corrected.eddy_rotated_bvecs ${bval} \
${inDir}/eddy/eddy_bias_corrected.nii.gz - -bzero | \
mrmath - mean ${inDir}/eddy/eddy_bias_corrected_b0.nii.gz -axis 3 ;

# Extract a bzero volume mask
bet \
${inDir}/eddy/eddy_bias_corrected_b0.nii.gz \
${inDir}/eddy/eddy_bias_corrected_b0_brain -m -f 0.3 ;

#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~
#~%~%~%~%~%~%~%~%~%~%~%~% STEP 10 ~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%
#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~

# DTIFIT
dtifit \
-k ${inDir}/eddy/eddy_bias_corrected.nii.gz \
-m ${inDir}/eddy/eddy_bias_corrected_b0_brain_mask.nii.gz \
-r ${inDir}/eddy/eddy_corrected.eddy_rotated_bvecs \
-b ${bval} \
--wls \
-o ${inDir}/dtifit/dti ;

# Create our radial diffusivity map
fslmaths \
${inDir}/dtifit/dti_L2.nii.gz -add \
${inDir}/dtifit/dti_L3.nii.gz -div 2 \
${inDir}/dtifit/dti_RD.nii.gz ;

#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~
#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~
#~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~
