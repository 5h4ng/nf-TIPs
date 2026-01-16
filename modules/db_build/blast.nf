process BlastTE {
    label 'blast'

    input:
    path query_fasta
    path blast_db
    path blast_db_files

    output:
    path "${query_fasta.getName()}.txt"

    script:
    // from fasta_utils.py lines142-173 (blastp_short_parallel)
    """
    ls ${blast_db_files} > /dev/null
    blastp -task blastp-short \
        -query ${query_fasta} \
        -db ${blast_db} \
        -out ${query_fasta.getName()}.txt \
        -outfmt "6 qaccver saccver pident length mismatch gapopen qstart qend sstart send evalue bitscore qseq sseq" \
        -evalue 20000 -num_threads ${params.database_build.te_selection.threads_per_chunk} 
    """
}