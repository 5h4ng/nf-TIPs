process MSFraggerSearch {
    publishDir "${params.sample.path}/DB_search_iProphet/MSFRAGGER", mode: 'copy'

    input:
    tuple path(mzml), path(search_db), val(base_params)

    output:
    path "*.pepXML"

    script:
    // from pipelines_dbsearch.py lines 221-233
    def fragger_jar = "/opt/MSFragger/MSFragger.jar" // TODO: verify MSFragger.jar location inside container
    """
    java -Xmx32G -jar "${fragger_jar}" "${base_params}" "${mzml}" --database "${search_db}"
    """
}
