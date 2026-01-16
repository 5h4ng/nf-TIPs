process MergeFastas {
    publishDir "${params.sample.path}/DB_search_iProphet/${engine.toUpperCase()}", mode: 'copy'

    input:
    path human_fasta
    path te_fasta
    path cont_fasta
    each engine

    output:
    tuple val(engine), path("${engine.toUpperCase()}_DBsearch.fasta")

    script:
    // from pipelines_dbsearch.py lines45-51 (_write_concat)
    """
    cat ${human_fasta} ${te_fasta} ${cont_fasta} > ${engine.toUpperCase()}_DBsearch.fasta
    """
}
