process ConvertMzidToPepxml {
    publishDir "${params.sample.path}/DB_search_iProphet/MSGFPLUS", mode: 'copy'

    input:
    path mzid

    output:
    path "*.pep.xml"

    script:
    // TODO: implement idconvert
    """
    echo "placeholder for idconvert"
    """
}
