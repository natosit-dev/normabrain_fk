input=../data/derivatives/3T/MPM/sub-rfl260123normanoel/ses-1/preproc/sub-rfl260123normanoel_ses-1_acq-vibeMTmt0_mt-off_part-phase_echos4d_riciancorr.nii
output=../data/derivatives/3T/QSM/sub-rfl260123normanoel/ses-1/anat/tmp_phase.nii.gz

vols="$(mrinfo -size $input | awk '{{print $4}}')"
for vol in $(seq 1 $vols); do
    i=$((${vol}-1))
    echo $i
    mrconvert $input -coord 3 $i -axes 0,1,2 $output -force
done
