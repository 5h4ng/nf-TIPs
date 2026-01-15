process CasanovoSearch {
    label 'gpu'
    publishDir "${params.sample.path}/Denovo/Casanovo", mode: 'copy'
    
    input:
    path mgf
    
    output:
    path "*.mztab", emit: results
    
    script:
    def base = mgf.baseName
    """
    export CUDA_VISIBLE_DEVICES=${params.gpu.id}

    casanovo sequence ${mgf} \\
        -m ${params.denovo.casanovo.model_ckpt} \\
        -o ${base}.mztab \\
        --config ${params.denovo.casanovo.config_yaml}
    """
}

process CasanovoParseAndFilter {
    publishDir "${params.sample.path}/Denovo/Casanovo", mode: 'copy'
    
    input:
    path mztab_files
    
    output:
    path "casanovo.filtered.pkl", emit: filtered_pkl
    
    script:
    // from pipelines_denovo.py lines 85-106 (CasanovoEngine.parse())
    // and lines 37-52 (DeNovoEngine.filter_subseq())
    // uses bin/sequence_filters.py extract_confident_subsequences()
    """
    #!/usr/bin/env python3
    import sys
    import os
    import re
    import glob
    import pandas as pd
    from io import StringIO
    
    sys.path.insert(0, '${projectDir}/bin')
    from sequence_filters import extract_confident_subsequences
    
    all_rows = []
    for path in glob.glob("*.mztab*"):
        with open(path, "r") as fh:
            lines = [ln for ln in fh if not ln.startswith("MTD")]
        df_single = pd.read_csv(StringIO("".join(lines)), sep="\\t")
        all_rows.append(df_single)
    if not all_rows:
        df = pd.DataFrame(columns=["Sequence", "ScoreList"])
    else:
        df = pd.concat(all_rows, ignore_index=True)
        df = df.rename(columns={
            "sequence": "Sequence",
            "opt_ms_run[1]_aa_scores": "Score"
        })
        df["Sequence"] = df["Sequence"].apply(lambda s: re.sub("[^A-Z]", "", s))
        df["ScoreList"] = df["Score"].apply(
            lambda x: list(map(float, str(x).split(",")))
        )
    
    df["Filtered_Subsequences"] = df.apply(
        lambda row: extract_confident_subsequences(
            row["Sequence"], row["ScoreList"],
            min_score=${params.denovo.min_score},
            min_length=${params.denovo.min_length}
        ),
        axis=1
    )
    df = df[df["Filtered_Subsequences"].str.len() > 0]
    df.to_pickle("casanovo.filtered.pkl")
    """
}