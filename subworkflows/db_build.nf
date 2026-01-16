include { BlastTE } from '../modules/db_build/blast'
include { FilterBlastResults; FilterILEquivalence } from '../modules/db_build/filter_blast'
include { ExtractTEFromBlastDb; ExtractTEFromFasta } from '../modules/db_build/extract_te'
include { NormalizeFasta as NormalizeHumanFasta } from '../modules/db_build/normalize_fasta'
include { NormalizeFasta as NormalizeContamFasta } from '../modules/db_build/normalize_fasta'
include { NormalizeFasta as NormalizeTeFasta } from '../modules/db_build/normalize_fasta'
include { MergeFastas } from '../modules/db_build/merge_fastas'
include { GenerateDecoy } from '../modules/db_build/generate_decoy'

workflow DB_BUILD {
    take:
    denovo_fasta

    main:
    // chunks handling. split and save as files
    fasta_chunks = denovo_fasta
        .splitFasta(by: params.database_build.te_selection.chunks, file: true) // rename 'chunks' to 'chunk_size' ??
        //.view { file -> "[DB_BUILD] BLAST chunk: ${file.getName()}" }
    blast_db_base = file(params.database_build.te_db_fasta)
    blast_db_files = channel.fromPath("${params.database_build.te_db_fasta}.*").collect()

    // Blast each chunk against TE database
    blast_results = BlastTE(fasta_chunks, blast_db_base, blast_db_files)

    filtered_blast = FilterBlastResults(blast_results.collect())

    te_ids = FilterILEquivalence(filtered_blast)

    // check if TE database is a blast database from pipelines_dbsearch.py lines 126-132
    def is_blast_db = file("${params.database_build.te_db_fasta}.pal").exists() ||
        file("${params.database_build.te_db_fasta}.pin").exists() ||
        file("${params.database_build.te_db_fasta}.00.pin").exists()

    te_fasta = is_blast_db \
        ? ExtractTEFromBlastDb(te_ids, blast_db_base, blast_db_files, denovo_fasta)  // blastdbcmd 
        : ExtractTEFromFasta(te_ids, params.database_build.te_db_fasta, denovo_fasta) // python scripts

    human_norm = NormalizeHumanFasta(params.database_build.human_fasta, '0', 'SRC=HUMAN')
    cont_norm = NormalizeContamFasta(params.database_build.contaminants_fasta, '0', 'SRC=CONTAM')
    te_norm = NormalizeTeFasta(te_fasta, '1', 'SRC=TE')

    engines = channel.of('comet', 'msfragger', 'msgfplus')
        .filter { x -> params.search_engines[x].enable }
        //.view { eng -> "[DB_BUILD] engine enabled: ${eng}" }

    merged_dbs = MergeFastas(human_norm, te_norm, cont_norm, engines)
        //.view { merged -> "[DB_BUILD] merged db: ${merged}" }
    search_dbs = params.database_build.add_decoy \
        ? GenerateDecoy(merged_dbs) \
        : merged_dbs

    emit:
    search_dbs
}