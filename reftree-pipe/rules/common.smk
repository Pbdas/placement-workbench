# =================================================================================================
#     Dependencies
# =================================================================================================

sys.path.insert(0, '../../common')

import pandas as pd
import os
from util import extension, fail

# Ensure min Snakemake version
snakemake.utils.min_version("5.7")

# =================================================================================================
#     Pipeline Configuration
# =================================================================================================

# Load the config. If --directory was provided, this is also loaded from there.
# This is useful to have runs that have different settings, but generally re-use the main setup.
configfile: "config.yaml"
# snakemake.utils.validate(config, schema="../schemas/config.schema.yaml")

# =================================================================================================
#     Read Samples Table
# =================================================================================================

# Read samples and units table
samples = pd.read_table(config["data"]["samples"], dtype=str).set_index(["sample"], drop=False)
# samples.index = samples.index.set_levels([i.astype(str) for i in samples.index.levels])  # enforce str in index
# snakemake.utils.validate(samples, schema="../schemas/samples.schema.yaml")

# Transform for ease of use
sample_names=list(set(samples.index.get_level_values("sample")))

# Wildcard constraints: only allow sample names from the table to be used
wildcard_constraints:
    sample="|".join(sample_names)

# output prefix
outdir=config["settings"]["outdir"].rstrip("/")

# =================================================================================================
#     Other global settings
# =================================================================================================
use_phat = bool(config["settings"]["use_phat"])

# =================================================================================================
#     Pipeline User Output
# =================================================================================================

# Some helpful messages
logger.info("===========================================================================")
logger.info("    reftree-pipe")
logger.info("")
logger.info("    Snakefile:          " + (workflow.snakefile))
logger.info("    Base directory:     " + (workflow.basedir))
logger.info("    Working directory:  " + os.getcwd())
logger.info("    Config files:       " + (", ".join(workflow.configfiles)))
logger.info("    Sample count:       " + str(len(sample_names)))
logger.info("===========================================================================")
logger.info("")

# =================================================================================================
#     Common File Access Functions
# =================================================================================================

def get_fasta( wildcards, called_from_phat=False ):
    """Get fasta file of given sample."""

    # short-circuit if phat is being used, and the calling site is not phat itself
    if use_phat and not called_from_phat:
        return "{}/result/{}/phat/ref_candidates.fa".format( wildcards.outdir, wildcards.sample )

    # otherwise, return as usual, depending on csv or not:

    # differentiate: if the samples.tsv contains the path to a .csv file, then the fasta must be under
    # 'downloads'. If not, then take the path as-is, expecting a fasta file
    path = samples.loc[wildcards.sample, "input_file"]
    if( extension( path ) == ".csv" ):
        path = "{}/result/{}/download/seqs.fa".format( wildcards.outdir, wildcards.sample )
    return path

def get_taxonomy_file( wildcards ):
    """Get taxonomy file associated with given sample."""

    path = samples.loc[wildcards.sample, "input_file"]
    
    # we assume that if there is a taxonomy file, it exists alongside the sample fasta/csv file
    tax_file = "{}/{}.tsv".format( dirname(path), filename(path) )
    expect_file_exists( tax_file )

    return tax_file

def get_accessions( wildcards ):
    """Get accessions file of given sample."""

    path = samples.loc[wildcards.sample, "input_file"]
    if( extension( path ) != ".csv" ):
        # brief check, as this should not happen: samples that were specified via fasta file
        # should have the alignment rule as the top-level of the dependency graph
        fail("Somehow 'get_accessions' was called with a non-csv file? path: '{}'".format(path))
    return path

def relative_input_path( wildcards, input, output ):
    """Returns the relative path to the input file, from the directory of the output file/directory"""
    return os.path.relpath( str(input), os.path.dirname( str(output) ) )

# =================================================================================================
#     Config Related Functions
# =================================================================================================

def get_highest_override( tool, key ):
    """From the config, get the value labeled with "key", unless the "tool" overrides that value,
    in which case fetch the override"""

    if not tool in config["params"]:
        fail("invalid key for 'config['params']': '{}'".format( tool ))

    if key in config["params"][tool]:
        return config["params"][tool][key]
    else:
        return config["params"][key]
