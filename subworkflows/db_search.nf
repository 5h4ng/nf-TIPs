include { CometSearch } from '../modules/db_search/comet.nf'
include { MSFraggerSearch } from '../modules/db_search/msfragger.nf'
include { MSGFPlusSearch } from '../modules/db_search/msgfplus.nf'
include { ConvertMzidToPepxml } from '../modules/db_search/convert_mzid_to_pepxml.nf'

workflow DB_SEARCH {
    take:
    mzml_files
    search_dbs // tuple(value(engine), path(db_fasta))

    main:
    pepxml_ch = channel.empty()

    if (params.search_engines.comet.enable) {
        comet_db = search_dbs
            .filter { row -> row[0] == 'comet' }
            .map { row -> row[1] } 
        comet_inputs = mzml_files
            .combine(comet_db) // cartesian product
            .map { mzml, db ->
                tuple(mzml, db, params.search_engines.comet.params_file)
            }
        comet_pepxml = CometSearch(comet_inputs)
        pepxml_ch = pepxml_ch.mix(comet_pepxml)
    }

    if (params.search_engines.msfragger.enable) {
        fragger_db = search_dbs
            .filter { row -> row[0] == 'msfragger' }
            .map { row -> row[1] }
        fragger_inputs = mzml_files
            .combine(fragger_db)
            .map { mzml, db ->
                tuple(mzml, db, params.search_engines.msfragger.base_params)
            }
        fragger_pepxml = MSFraggerSearch(fragger_inputs)
        pepxml_ch = pepxml_ch.mix(fragger_pepxml)
    }

    if (params.search_engines.msgfplus.enable) {
        msgf_db = search_dbs
            .filter { row -> row[0] == 'msgfplus' }
            .map { row -> row[1] }
        msgf_inputs = mzml_files
            .combine(msgf_db)
            .map { mzml, db ->
                tuple(mzml, db, params.search_engines.msgfplus.params_file)
            }
        msgf_mzid = MSGFPlusSearch(msgf_inputs)
        msgf_pepxml = ConvertMzidToPepxml(msgf_mzid) // TODO: implement
        pepxml_ch = pepxml_ch.mix(msgf_pepxml)
    }

    emit:
    pepxml_ch
}
