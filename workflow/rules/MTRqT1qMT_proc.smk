session_paths = []
for strength in FIELD_STRENGTHS:
    bids_path = data_path / strength / "rawdata" / "bids"
    subject_paths = [x for x in bids_path.glob('sub-*') if x.is_dir()]
    for subject in subject_paths:
        sessions = [x for x in subject.glob("ses-*") if x.is_dir()]
        session_paths = [*session_paths, *sessions]