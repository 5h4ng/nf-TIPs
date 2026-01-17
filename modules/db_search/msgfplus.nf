process MSGFPlusSearch {
    publishDir "${params.sample.path}/DB_search_iProphet/MSGFPLUS", mode: 'copy'

    input:
    tuple path(mzml), path(search_db), val(params_file)

    output:
    path "*.mzid"

    script:
    def out_mzid = mzml.getBaseName() + '.mzid'
    // from pipelines_dbsearch.py lines 235-252
    def msgfplus_jar = "/opt/MSGFPlus/MSGFPlus.jar" // TODO: verify MSGFPlus.jar location inside container
    """
    java -Xmx8G -jar "${msgfplus_jar}" -d "${search_db}" -s "${mzml}" -o "${out_mzid}" -conf "${params_file}"
    """
}
