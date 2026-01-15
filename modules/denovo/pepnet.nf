process PepNetSearch {
    label 'gpu'
    publishDir "${params.sample.path}/Denovo/PepNet", mode: 'copy'
    
    input:
    path mgf
    
    output:
    path "*.result", emit: results
    
    script:
    // from pipelines_denovo.py lines 124-137 (PepNetEngine.run())
    def base = mgf.baseName
    """
    export CUDA_VISIBLE_DEVICES=${params.gpu.id}
    
    # PepNet requires custom Python script
    python ${params.denovo.pepnet.script} \\
        --input ${mgf} \\
        --model ${params.denovo.pepnet.model_h5} \\
        --output ${base}.result
    """
}

process PepNetParseAndFilter {
    publishDir "${params.sample.path}/Denovo/PepNet", mode: 'copy'
    
    input:
    path result_files
    
    output:
    path "pepnet.filtered.pkl", emit: filtered_pkl
    
    script:
    // from pipelines_denovo.py lines 139-162 (PepNetEngine.parse())
    // and lines 37-52 (DeNovoEngine.filter_subseq())
    """
    #!/usr/bin/env python3
    import sys
    import re
    import glob
    import pandas as pd
    
    sys.path.insert(0, '${projectDir}/bin')
    from sequence_filters import extract_confident_subsequences
    
    dfs = []
    for res_file in glob.glob("*.result"):
        df_single = pd.read_csv(res_file, sep="\\t")
        dfs.append(df_single)
    if not dfs:
        df = pd.DataFrame(columns=["Sequence", "ScoreList"])
    else:
        df = pd.concat(dfs, ignore_index=True)
        df = df.rename(columns={
            "DENOVO": "Sequence",
            "Positional Score": "Score"
        })
        df["Score"] = df["Score"].apply(
            lambda x: re.sub(r"[\\[\\]\\s]", "", str(x))
        )
        df["ScoreList"] = df["Score"].apply(
            lambda s: [float(v) for v in s.split(",") if v != ""]
        )
        df["Sequence"] = df["Sequence"].apply(lambda s: re.sub("[^A-Z]", "", s))
        df = df.dropna()
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
    df.to_pickle("pepnet.filtered.pkl")
    """
}
