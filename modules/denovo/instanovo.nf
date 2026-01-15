process InstaNovoSearch {
    label 'gpu'
    publishDir "${params.sample.path}/Denovo/InstaNovo", mode: 'copy'
    
    input:
    path mgf_files  // all mgf files
    
    output:
    path "InstaNovo.result", emit: results
    
    script:
    // from pipelines_denovo.py lines 180-197 (InstaNovoEngine.run())
    """
    export CUDA_VISIBLE_DEVICES=${params.gpu.id}
    
    python -m ${params.denovo.instanovo.module_call} \\
        data_path=*.mgf \\
        model_path=${params.denovo.instanovo.model_ckpt} \\
        output_path=InstaNovo.result \\
        denovo=True
    """
}

process InstaNovoParseAndFilter {
    publishDir "${params.sample.path}/Denovo/InstaNovo", mode: 'copy'
    
    input:
    path result_csv
    
    output:
    path "instanovo.filtered.pkl", emit: filtered_pkl
    
    script:
    // from pipelines_denovo.py lines 199-216 (InstaNovoEngine.parse())
    // and lines 37-52 (DeNovoEngine.filter_subseq())
    """
    #!/usr/bin/env python3
    import sys
    import re
    import numpy as np
    import pandas as pd
    
    sys.path.insert(0, '${projectDir}/bin')
    from sequence_filters import extract_confident_subsequences
    
    df = pd.read_csv('${result_csv}')
    df = df.rename(columns={
        'preds': 'Sequence',
        'token_log_probs': 'RawScores'
    })
    
    def to_probs(x):
        x = x.strip()[1:-1]
        return [float(np.exp(float(v))) for v in x.split(",")]
    
    df["ScoreList"] = df["RawScores"].apply(to_probs)
    df["Sequence"] = df["Sequence"].apply(lambda s: re.sub("[^A-Z]", "", s))
    df = df[["Sequence", "ScoreList"]]
    
    df["Filtered_Subsequences"] = df.apply(
        lambda row: extract_confident_subsequences(
            row["Sequence"], row["ScoreList"],
            min_score=${params.denovo.min_score},
            min_length=${params.denovo.min_length}
        ),
        axis=1
    )
    df = df[df["Filtered_Subsequences"].str.len() > 0]
    df.to_pickle("instanovo.filtered.pkl")
    """
}
