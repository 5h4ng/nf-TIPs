process NormalizeFasta {
    publishDir "${params.sample.path}/DB_search_iProphet/tmp_norm", mode: 'copy'

    input:
    path fasta
    val pe_tag
    val extra_tag

    output:
    path "PE${pe_tag}__${fasta.getName()}"

    script:
    // from fasta_utils.py lines51-97
    """
    #!/usr/bin/env python3
    import re

    with open("${fasta}", "r") as fh:
        fasta_str = fh.read()

    record_count = len(fasta_str.split(">")[1:])
    if len(fasta_str.split("\\n")) > record_count * 2 + 4:
        out_lines = []
        for record in fasta_str.split(">")[1:]:
            parts = record.strip().split("\\n")
            header = parts[0]
            seq = "".join(parts[1:])
            out_lines.append(f">{header}\\n{seq}\\n")
        fasta_str = "".join(out_lines)

    if "${pe_tag}":
        new_records = []
        for record in fasta_str.split(">")[1:]:
            header, seq = record.strip().split("\\n", 1)
            if "PE=" in header:
                header = re.sub(r"PE=(\\d)", f"PE=${pe_tag}", header)
            else:
                header = header + f" PE=${pe_tag}"
            seq = seq.replace("\\n", "")
            new_records.append(f">{header}\\n{seq}\\n")
        fasta_str = "".join(new_records)

    if "${extra_tag}":
        new_records = []
        for record in fasta_str.split(">")[1:]:
            header, seq = record.strip().split("\\n", 1)
            header = header + f" ${extra_tag}"
            seq = seq.replace("\\n", "")
            new_records.append(f">{header}\\n{seq}\\n")
        fasta_str = "".join(new_records)

    out_path = "PE${pe_tag}__${fasta.getName()}"
    with open(out_path, "w") as out:
        out.write(fasta_str)
    """
}
