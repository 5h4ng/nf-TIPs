process CometSearch {
    publishDir "${params.sample.path}/DB_search_iProphet/COMET", mode: 'copy'

    input:
    tuple path(mzml), path(search_db), val(params_file)

    output:
    path "*.pep.xml"

    script:
    // from pipelines_dbsearch.py lines 208-219
    """
    comet -P${params_file} -D${search_db} "${mzml}"
    """
}