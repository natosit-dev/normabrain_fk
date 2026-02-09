import json
from pathlib import Path
from snakemake.script import snakemake

def create_json_for_mp2rage_proc(b1map_nifti: str, inv1_nifti: str, inv2_nifti: str, unit1_nifti: str, output_folder: str, echo_spacing: float, threads: int):
    # with open(metadata_json_path, "r") as f:
    #     metadata = json.load(f)
    
    #convert path strings to Path objects, used to grab metadata later
    b1map_nifti_path = Path(b1map_nifti)
    inv1_nifti_path = Path(inv1_nifti)
    inv2_nifti_path = Path(inv2_nifti)
    unit1_nifti_path = Path(unit1_nifti)
    output_path = Path(output_folder)

    #grab metadata
    #need with_suffix('') or else will return nii.json
    b1map_json_path = b1map_nifti_path.with_suffix('').with_suffix(".json") 
    with open(b1map_json_path, "r") as b1:
        b1map_meta = json.load(b1)

    inv1_json_path = inv1_nifti_path.with_suffix('').with_suffix(".json")
    with open(inv1_json_path, "r") as inv1:
        inv1_meta = json.load(inv1)

    mp2rage_proc_params = {
        #pipeline settings
        "verbose": True,
        "use_deprecated_normalization_from_12bits": False,
        "use_alternative_denoising_on_synthetic_maps": False,
        "do_ants_transform_B1_map_to_t1wUNI_space": True,
        "do_ants_smoothing_of_B1_map_in_t1wUNI_space": True,
        "do_ants_smoothing_using_median_filtering": False,
        "is_ants_smoothing_sigma_in_spacing_units": False,
        "do_restore_bijectivity_of_qT1_along_local_B1": True,
        "do_bound_B1_to_valid_interpolation_range": False,
        "do_round_on_export": True,
        "export_quantitative_instead_of_qualitative": False,
        "export_interpolation_hypersurface_data_n_plot": True,
        "show_interpolation_hypersurface_plot": False,

        #maps to compute
        "compute_t1wUNI_DEN": True,
        "compute_t1wUNI_B1Corrected": True,
        "compute_t1wUNI_B1Corrected_DEN": True,
        "compute_qT1": True,
        "compute_qR1": True,
        "compute_EDGE": False,
        "compute_EDGE_DEN": False,
        "compute_FLAWS": False,
        "compute_FLAWS_DEN": False,

        #paths to input files
        "path_INPUT_b1_faUnit": str(b1map_nifti_path),
        "path_INPUT_inversion_1_msUnit": str(inv1_nifti_path),
        "path_INPUT_inversion_2_msUnit": str(inv2_nifti_path),
        "path_INPUT_t1wUNI_dicomUnit": str(unit1_nifti_path),

        #paths to output files
        # what is relativeUnit vs dicomUnit?
        "path_OUTPUT_b1_processed_perthousand": str(Path(output_path, "b1_processed_relativeUnit_perThousand.nii.gz")),
        "path_OUTPUT_t1wUNI_DEN_dicomUnit": str(Path(output_path, "t1wUNI_DEN_dicomUnit.nii.gz")),
        "path_OUTPUT_t1wUNI_B1Corrected_dicomUnit": str(Path(output_path, "t1wUNI_B1Corrected_dicomUnit.nii.gz")),
        "path_OUTPUT_t1wUNI_B1Corrected_DEN_dicomUnit": str(Path(output_path, "t1wUNI_B1Corrected_DEN_dicomUnit.nii.gz")),
        "path_OUTPUT_qT1_msUnit": str(Path(output_path, "qT1_msUnit.nii.gz")),
        "path_OUTPUT_qR1_pksUnit": str(Path(output_path, "qR1_pksUnit.nii.gz")),
        "path_OUTPUT_EDGE_dicomUnit": str(Path(output_path, "EDGE_dicomUnit.nii.gz")),
        "path_OUTPUT_EDGE_DEN_dicomUnit": str(Path(output_path, "EDGE_DEN_dicomUnit.nii.gz")),
        "path_OUTPUT_FLAWS_dicomUnit": str(Path(output_path, "FLAWS_dicomUnit.nii.gz")),
        "path_OUTPUT_FLAWS_DEN_dicomUnit": str(Path(output_path, "FLAWS_DEN_dicomUnit.nii.gz")),
        "path_OUTPUT_global_mask": str(Path(output_path, "global_mask.nii.gz")),
        "path_OUTPUT_interpolation_hypersurface_no_ext": str(Path(output_path, "out_interpolant_hypersurface_plot")),

        #ANTS parameters
        "ants_interpolation_method_for_resampling": "BSpline[3]",
        "ants_smoothing_sigma": "3x1x1",

        #B1map parameters
        #v1ref no longer needs to be set manually, we will keep default values here for now
        "vref_b1_vUnit"                                 : 247.007827759,
        "vref_t1wUNI_vUnit"                             : 247.007827759,
        "target_b1_faUnit"                              : b1map_meta["target_fa_deg"] * 10,
        #noise_shift is the same as lambda, see MP2RAGE paper
        "noise_shift"                                   : 100.0,

        #MP2RAGE parameters
        #echo spacing needs to be read from PDF of scan protocol
        "t_echo_spacing_msUnit"                         : echo_spacing,
        "t_repeat_MP2RAGE_msUnit"                       : inv1_meta["tr_ms"],
        "t_inversion1_msUnit"                           : inv1_meta["ti1_ms"],
        "t_inversion2_msUnit"                           : inv1_meta["ti2_ms"],
        "fa_1_degUnit"                                  : inv1_meta["ro_fa1_deg"],
        "fa_2_degUnit"                                  : inv1_meta["ro_fa2_deg"],
        #inversion efficiency and M0 vary across the brain, set them to 1 for now
        "inversion_efficiency"                          : 1.0,
        "M0"                                            : 1.0,
        "n_before"                                      : inv1_meta["n_before"],
        "n_after"                                       : inv1_meta["n_after"],

        #parameters for synthetic EDGE images
        # "edge_t_echo_spacing_msUnit"                    : 2.5,
        # "edge_t_repeat_MP2RAGE_msUnit"                  : 8000.0,
        # "edge_t_inversion1_msUnit"                      : 820.0,
        # "edge_t_inversion2_msUnit"                      : 1320.0,
        # "edge_fa_1_degUnit"                             : 5.0,
        # "edge_fa_2_degUnit"                             : 5.0,
        # "edge_inversion_efficiency"                     : 1.0,
        # "edge_M0"                                       : 1.0,

        #parameters for synthetic FLAWS images
        # "flaws1_t_echo_spacing_msUnit"                  : 7.5,
        # "flaws1_t_repeat_MP2RAGE_msUnit"                : 8250.0,
        # "flaws1_t_inversion1_msUnit"                    : 900.0,
        # "flaws1_t_inversion2_msUnit"                    : 3700.0,
        # "flaws1_fa_1_degUnit"                           : 9.0,
        # "flaws1_fa_2_degUnit"                           : 5.0,
        # "flaws1_inversion_efficiency"                   : 1.0,
        # "flaws1_M0"                                     : 1.0,

        # "flaws2_t_echo_spacing_msUnit"                  : 3.1,
        # "flaws2_t_repeat_MP2RAGE_msUnit"                : 5000.0,
        # "flaws2_t_inversion1_msUnit"                    : 200.0,
        # "flaws2_t_inversion2_msUnit"                    : 1200.0,
        # "flaws2_fa_1_degUnit"                           : 5.0,
        # "flaws2_fa_2_degUnit"                           : 5.0,
        # "flaws2_inversion_efficiency"                   : 1.0,
        # "flaws2_M0"                                     : 1.0,

        #Ask Tim what "datatype" means here
        "datatype"                                      : 512,
        "n_threads"                                     : threads,



        # "edge_n_before"                                 : 64,
        # "edge_n_after"                                  : 128,

        # "flaws1_n_before"                               : 64,
        # "flaws1_n_after"                                : 128,

        # "flaws2_n_before"                               : 64,
        # "flaws2_n_after"                                : 128,

        # "array_b1_relativeUnit"                         : [191, 0.1, 2.0],
        # "array_qT1_msUnit"                              : [3996, 100.0, 4095.0]

    }

    output_json = str(Path(output_path, "mp2rage_proc_params.json"))
    with open(output_json, "w") as f:
        json.dump(mp2rage_proc_params, f)

create_json_for_mp2rage_proc(snakemake.input.b1map_nifti, snakemake.input.inv1_nifti, snakemake.input.inv2_nifti, snakemake.input.unit1_nifti, snakemake.output[0], snakemake.config["mp2rage_echo_spacing"], snakemake.threads)