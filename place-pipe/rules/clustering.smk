# =================================================================================================
#     Cluster Query Sequences
# =================================================================================================

rule cluster_swarm:
    input:
        get_sample_fasta
    output:
        fasta       = "{outdir}/clustered/{sample}/sequences.fa",
        otu_table   = "{outdir}/clustered/{sample}/otu_table.tsv"
    params:
        differences = config["params"]["swarm"]["differences"],
        fastidious  = (" --fastidious" if config["params"]["swarm"]["fastidious"] else ""),
        extra       = config["params"]["swarm"]["extra"]
    threads:
        get_highest_override( "swarm", "threads" )
    log:
        "{outdir}/logs/swarm/{sample}.log"
    conda:
        "../envs/swarm.yaml"
    script:
        "swarm --seeds {output.fasta}"
        " --statistics-file {output.otu_table}"
        " --differences {params.differences}"
        " --append-abundance 1"
        " --log {log}"
        "{params.fastidious}"
        " {input}"

rule cluster_dada2:
    input:
        get_sample_fastq
    output:
        fasta       = "{outdir}/clustered/{sample}/sequences.fa",
        otu_table   = "{outdir}/clustered/{sample}/otu_table.tsv"
    # params:
    #     differences = config["params"]["swarm"]["differences"],
    #     fastidious  = (" --fastidious" if config["params"]["swarm"]["fastidious"] else ""),
    #     extra       = config["params"]["swarm"]["extra"]
    log:
        "{outdir}/logs/dada2/{sample}.log"
    conda:
        "../envs/dada2.yaml"
    script:
        "../scripts/dada2.R"
