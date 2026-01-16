process GenerateDecoy {
    publishDir "${params.sample.path}/DB_search_iProphet/${engine.toUpperCase()}", mode: 'copy'

    input:
    tuple val(engine), path(db_fasta)

    output:
    tuple val(engine), path("${db_fasta.getName()}")

    script:
    // from pipelines_dbsearch.py lines63-69 and fasta_utils.py lines131-140
    """
    #!/usr/bin/env python3
    import os

    def generate_decoy(input_fasta: str, out_fasta: str):
        with open(out_fasta, "w") as out_handle:
            with open(input_fasta, "r") as fh:
                header = None
                seq_parts = []
                for line in fh:
                    if line.startswith(">"):
                        if header:
                            seq = "".join(seq_parts)
                            decoy_seq = seq[::-1]
                            out_handle.write(f">rev_{header}\\n{decoy_seq}\\n")
                        header = line[1:].strip()
                        seq_parts = []
                    else:
                        seq_parts.append(line.strip())
                if header:
                    seq = "".join(seq_parts)
                    decoy_seq = seq[::-1]
                    out_handle.write(f">rev_{header}\\n{decoy_seq}\\n")

    decoy_path = "${db_fasta}.decoy.tmp.fasta"
    generate_decoy("${db_fasta}", decoy_path)
    with open("${db_fasta}", "a") as oh, open(decoy_path, "r") as ih:
        oh.write(ih.read())
    os.remove(decoy_path)
    """
}
