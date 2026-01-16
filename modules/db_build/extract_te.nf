process ExtractTEFromBlastDb {
    label 'blast'

    publishDir "${params.sample.path}/Denovo", mode: 'copy'

    input:
    path te_ids
    path te_db
    path blast_db_files
    path denovo_fasta

    output:
    path "TE_candidates_from_DB.fasta"

    script:
    // from pipelines_dbsearch.py lines126-153 (_build_te_candidates_via_blast)
    """
    if [ ! -s "${te_ids}" ]; then
        cp "${denovo_fasta}" TE_candidates_from_DB.fasta
        exit 0
    fi

    ls ${blast_db_files} > /dev/null
    blastdbcmd -db "${te_db}" -dbtype prot \
        -entry_batch "${te_ids}" -out "TE_candidates_from_DB.fasta" -outfmt %f
    """
}

process ExtractTEFromFasta {
    publishDir "${params.sample.path}/Denovo", mode: 'copy'

    input:
    path te_ids
    path te_db
    path denovo_fasta

    output:
    path "TE_candidates_from_DB.fasta"

    script:
    // from pipelines_dbsearch.py lines148-153 (_build_te_candidates_via_blast)
    // use pure python scripts instead of BioPython
    """
    #!/usr/bin/env python3
    import os

    # if no TE ids, return the denovo fasta
    if os.path.getsize("${te_ids}") == 0:
        with open("${denovo_fasta}", "r") as src, open("TE_candidates_from_DB.fasta", "w") as out:
            out.write(src.read())
        raise SystemExit(0)

    ids = set()
    with open("${te_ids}", "r") as fh:
        for line in fh:
            line = line.strip()
            if line:
                ids.add(line)

    out = open("TE_candidates_from_DB.fasta", "w")
    with open("${te_db}", "r") as fh:
        header = None
        seq_parts = []
        for line in fh:
            if line.startswith(">"):
                if header:
                    rec_id = header.split()[0]
                    if rec_id in ids:
                        out.write(f">{header}\\n{''.join(seq_parts)}\\n")
                header = line[1:].strip()
                seq_parts = []
            else:
                seq_parts.append(line.strip())
        if header:
            rec_id = header.split()[0]
            if rec_id in ids:
                out.write(f">{header}\\n{''.join(seq_parts)}\\n")
    out.close()
    """
}
