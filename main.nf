include { DENOVO } from './subworkflows/denovo'
include { DB_BUILD } from './subworkflows/db_build'
include { DB_SEARCH } from './subworkflows/db_search'

workflow {
    // TODO: use msconvert to automatically convert mzml to mgf in the future
    mgf_files = channel.fromPath("${params.sample.path}/mgf/*.mgf") 
    mzml_files = channel.fromPath("${params.sample.path}/mzML/*.mzML")

    denovo_fasta = DENOVO(mgf_files)
    search_dbs = DB_BUILD(denovo_fasta)
    DB_SEARCH(mzml_files, search_dbs)
}
