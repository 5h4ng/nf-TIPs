process FilterBlastResults {
    label 'blast'

    publishDir "${params.sample.path}/Denovo/TE_blast_work", mode: 'copy'

    input:
    path blast_results

    output:
    path "merged_blastp_filter.txt"

    script:
    // from fasta_utils.py lines192-203 (blastp_short_parallel)
    // qstart==1, gapopen==0, pident>=75
    """
    mkdir -p blast_results
    cp ${blast_results} blast_results/
    cat blast_results/*.txt > merged_blastp.txt
    awk '\$7 == 1 && \$6 == 0 && \$3 >= 75' merged_blastp.txt > merged_blastp_filter.txt
    """
}

process FilterILEquivalence {

    publishDir "${params.sample.path}/Denovo/TE_blast_work", mode: 'copy'

    input:
    path filtered_blast

    output:
    path "te_ids.txt"

    script:
    // from fasta_utils.py lines 207-230 (load_and_filter_blastp_results)
    // TODO: check 'df["q_length"] = df["qaccver"].str.len()'
    """
    #!/usr/bin/env python3
    import csv

    cols = [
        "qaccver", "saccver", "pident", "length", "mismatch", "gapopen",
        "qstart", "qend", "sstart", "send", "evalue", "bitscore",
        "qseq", "sseq"
    ]

    te_ids = set()
    with open("${filtered_blast}", "r") as fh:
        reader = csv.DictReader(fh, fieldnames=cols, delimiter="\\t")
        for row in reader:
            qaccver = row["qaccver"]
            qseq = row["qseq"]
            sseq = row["sseq"]
            gapopen = int(row["gapopen"])
            length = int(row["length"])

            q_length = len(qseq) # It seems original code is wrong, if qaccver != qseq
            if length != q_length:
                continue
            if len(qseq) != len(sseq):
                continue
            if gapopen != 0:
                continue

            qseq_i2l = qseq.replace("I", "L")
            sseq_i2l = sseq.replace("I", "L")
            if qseq_i2l != sseq_i2l:
                continue

            te_ids.add(row["saccver"])

    with open("te_ids.txt", "w") as out:
        for te_id in sorted(te_ids):
            out.write(f"{te_id}\\n")
    """
}
