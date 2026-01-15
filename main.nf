include { DENOVO } from './subworkflows/denovo'

workflow {
    mgf_files = Channel.fromPath("${params.sample.path}/mgf/*.mgf")
    DENOVO(mgf_files)
}
