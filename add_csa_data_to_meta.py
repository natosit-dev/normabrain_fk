import json
import argparse
from math import ceil, floor
from bidscoin import bcoin, bids, lsdirs
from pathlib import Path
from csa_header_scripts.return_csa_header_parse_by_my_self import return_csa

def add_csa_data_to_meta(bidspath: str):    
    t1b1fl_pattern = 'fmap/*TB1TFL*'
    vibemt_pattern = 'anat/*vibe*_MPM*'
    mp2rage_pattern = 'anat/*t1mp2r*'  
    bidsdir = Path(bidspath).resolve()
    subjects = lsdirs(bidsdir, 'sub-*')

    console = bcoin.setup_logging(bidsdir/'code'/'bidscoin'/'fixmeta.log')
    bidsmap = bids.BidsMap(Path('bidsmap.yaml'), bidsdir/'code'/'bidscoin', checks=(False, False, False))
    plugins  = bidsmap.plugins
    provdata = bids.bidsprov(bidsdir)

    for subject in subjects:
        sessions = lsdirs(subject, 'ses-*')
        
        for session in sessions:
            t1b1fl_targets = sorted([match for match in session.rglob(t1b1fl_pattern) if match.suffixes[0] in ('.tsv','.nii')])
            sourcedir = ''
            for target in t1b1fl_targets:
                for source, row in provdata.iterrows():
                    if isinstance(row['targets'], str) and target.name in row['targets']:
                        sourcedir = source
                datasource = bids.get_datasource(Path(sourcedir), plugins)
                jsonfile = target.with_suffix('').with_suffix('.json')
                jsondata = bids.poolmetadata(datasource, jsonfile, bids.Meta({}), ['.json'])
                csa_data, mrprotocol, cas = return_csa(sourcedir)
                jsondata['Target_FA_deg'] = float(csa_data['sWipMemBlock.adFree[0]'])
                with jsonfile.open('w') as jf:
                    json.dump(jsondata, jf, indent=4)

            vibemt_targets = sorted([match for match in session.rglob(vibemt_pattern) if match.suffixes[0] in ('.tsv','.nii')])
            for target in vibemt_targets:
                for source, row in provdata.iterrows():
                    if isinstance(row['targets'], str) and target.name in row['targets']:
                        sourcedir = source
                datasource = bids.get_datasource(Path(sourcedir), plugins)
                jsonfile = target.with_suffix('').with_suffix('.json')
                jsondata = bids.poolmetadata(datasource, jsonfile, bids.Meta({}), ['.json'])
                csa_data, mrprotocol, cas = return_csa(sourcedir)
                if isinstance(csa_data.get('sWipMemBlock.alFree[0]'), str):
                    jsondata['mt_state'] = int(csa_data['sWipMemBlock.alFree[0]'])
                else:
                    jsondata['mt_state'] = 0
                jsondata['sat_pulse_ms'] = float(csa_data['sWipMemBlock.adFree[2]'])
                jsondata['interdelay_ms'] = float(csa_data['sWipMemBlock.adFree[5]'])
                jsondata['ro_pulse_ms'] = float(csa_data['sWipMemBlock.alFree[7]']) / 1000
                jsondata['tr_ms'] = float(csa_data['alTR[0]']) / 1000
                jsondata['ro_pulse_ms'] = float(csa_data['sWipMemBlock.alFree[7]']) / 1000
                jsondata['ro_fa_deg'] = csa_data['adFlipAngleDegree[0]']
                if isinstance(csa_data.get('sWipMemBlock.alFree[8]'), str):
                    ro_pulse_shape = int(csa_data['sWipMemBlock.alFree[8]'])
                else:
                    ro_pulse_shape = 0 
                if ro_pulse_shape == 1:
                    jsondata['ro_pulse_shape'] = 'CSMT'
                elif ro_pulse_shape == 2:
                    jsondata['ro_pulse_shape'] = 'BP'
                else:
                    jsondata['ro_pulse_shape'] = 'Hann'
                jsondata['sat_pulse_fa_deg'] = float(csa_data['sWipMemBlock.adFree[0]'])
                jsondata['sat_pulse_offset_hz'] = float(csa_data['sWipMemBlock.adFree[1]'])
                if isinstance(csa_data.get('sWipMemBlock.alFree[1]'), str):
                    sat_pulse_shape = int(csa_data['sWipMemBlock.alFree[1]'])
                else:
                    sat_pulse_shape = 0
                if sat_pulse_shape == 1:
                    jsondata['sat_pulse_shape'] = 'GaussHann-Sine'
                elif sat_pulse_shape == 2:
                    jsondata['sat_pulse_shape'] = 'Gauss-Sine'
                else:
                    jsondata['sat_pulse_shape'] = 'Hann-Sine'
                with jsonfile.open('w') as jf:
                    json.dump(jsondata, jf, indent=4)
        
            mp2rage_targets = sorted([match for match in session.rglob(mp2rage_pattern) if match.suffixes[0] in ('.tsv','.nii')])
            for target in mp2rage_targets:
                for source, row in provdata.iterrows():
                    if isinstance(row['targets'], str) and target.name in row['targets']:
                        sourcedir = source
                datasource = bids.get_datasource(Path(sourcedir), plugins)

                jsonfile = target.with_suffix('').with_suffix('.json')
                jsondata = bids.poolmetadata(datasource, jsonfile, bids.Meta({}), ['.json'])
                csa_data, mrprotocol, cas = return_csa(sourcedir)
                jsondata['tr_ms'] = float(csa_data['alTR[0]']) / 1000
                if isinstance(csa_data.get('alTI[0]'), str):
                    jsondata['ti1_ms'] = float(csa_data['alTI[0]']) / 1000
                if isinstance(csa_data.get('alTI[1]'), str):
                    jsondata['ti2_ms'] = float(csa_data['alTI[1]']) / 1000
                jsondata['ro_fa1_deg'] = csa_data['adFlipAngleDegree[0]']
                jsondata['ro_fa2_deg'] = csa_data['adFlipAngleDegree[1]']
                if jsondata['PulseSequenceDetails'] == "%SiemensSeq%/tfl":
                    jsondata['n_after'] = int(csa_data['sKSpace.lPartitions']) / 2
                    jsondata['n_before'] = int(csa_data['sFastImaging.lTurboFactor']) - jsondata['n_after']
                elif jsondata['PulseSequenceDetails'] == "%CustomerSeq%/wip_csTFL_cstfl":
                    jsondata['n_after'] = floor(float(csa_data['sFastImaging.lTurboFactor']) / 2)
                    jsondata['n_before'] = ceil(float(csa_data['sFastImaging.lTurboFactor']) / 2)
                elif jsondata['PulseSequenceDetails'] == "%CustomerSeq%/cstfl_wip925b":
                    jsondata['n_after'] = floor(float(csa_data['sWipMemBlock.alFree[2]']) / 2)
                    jsondata['n_before'] = ceil(float(csa_data['sWipMemBlock.alFree[2]']) / 2)
                with jsonfile.open('w') as jf:
                    json.dump(jsondata, jf, indent=4)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=
        """
        Read CSA header data from DICOM source directories and add relevant fields to BIDS sidecar JSON files.
        Assumes BIDS structure was generated with bidscoin and that provenance data is available.
        """)
    parser.add_argument('bidspath', type=str, help="Path to the BIDS directory")
    args = parser.parse_args()
    add_csa_data_to_meta(args.bidspath)