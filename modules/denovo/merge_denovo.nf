process MergeDenovoResults {
    publishDir "${params.sample.path}/Denovo", mode: 'copy'
    
    input:
    path filtered_pkls
    
    output:
    path "${params.sample.name}.denovo.fasta", emit: merged_fasta
    
    script:
    // from pipelines_denovo.py lines 220-243 (write_denovo_merged_fasta)
    """
    #!/usr/bin/env python3
    import glob
    import pandas as pd
    
    peptides = set()
    for pkl_path in glob.glob("*.pkl"):
        df = pd.read_pickle(pkl_path)
        if df is None or len(df) == 0:
            continue
        for _, row in df.iterrows():
            for pep in row["Filtered_Subsequences"]:
                peptides.add(pep)
    
    with open("${params.sample.name}.denovo.fasta", "w") as fh:
        for pep in sorted(peptides):
            fh.write(f">{pep}\\n{pep}\\n")
    
    print(f"[write_denovo_merged_fasta] wrote ${params.sample.name}.denovo.fasta with {len(peptides)} peptides")
    """
}
