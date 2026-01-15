include { CasanovoSearch; CasanovoParseAndFilter } from '../modules/denovo/casanovo'
include { PepNetSearch; PepNetParseAndFilter } from '../modules/denovo/pepnet'
include { InstaNovoSearch; InstaNovoParseAndFilter } from '../modules/denovo/instanovo'
include { MergeDenovoResults } from '../modules/denovo/merge_denovo'

workflow DENOVO {
    take:
    mgf_files
    
    main:
    def engines = params.denovo.engines
    filtered_pkls = Channel.empty()
    
    if (engines.contains('casanovo')) {
        casanovo_mztabs = CasanovoSearch(mgf_files)
        casanovo_pkl = CasanovoParseAndFilter(casanovo_mztabs.collect())
        filtered_pkls = filtered_pkls.mix(casanovo_pkl)
    }
    
    if (engines.contains('pepnet')) {
        pepnet_results = PepNetSearch(mgf_files)
        pepnet_pkl = PepNetParseAndFilter(pepnet_results.collect())
        filtered_pkls = filtered_pkls.mix(pepnet_pkl)
    }
    
    if (engines.contains('instanovo')) {
        instanovo_result = InstaNovoSearch(mgf_files.collect())
        instanovo_pkl = InstaNovoParseAndFilter(instanovo_result)
        filtered_pkls = filtered_pkls.mix(instanovo_pkl)
    }
    
    merged_fasta = MergeDenovoResults(filtered_pkls.collect())
    
    emit:
    merged_fasta
}
