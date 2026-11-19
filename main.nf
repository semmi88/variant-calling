#!/usr/bin/env nextflow

// Module INCLUDE statements
include { SAMTOOLS_INDEX } from './modules/samtools_index.nf'
include { GATK_HAPLOTYPECALLER } from './modules/gatk_haplotypecaller.nf'

/*
 * Pipeline parameters
 */
params {
    // Base location for inputs and outputs
    base_dir: String

    // Paths relative to base_dir (absolute paths / URIs are used as-is)
    bam_glob: String        = 'data/bam/*.bam'
    reference: String       = 'data/ref/ref.fasta'
    reference_index: String = 'data/ref/ref.fasta.fai'
    reference_dict: String  = 'data/ref/ref.dict'
    intervals: String       = 'data/ref/intervals.bed'
    output_suffix: String   = 'results'
}

workflow {

    main:
    def base = params.base_dir.replaceAll('/+$', '')
    def resolve = { p -> (p.startsWith('/') || p.contains('://')) ? p : "${base}/${p}" }

    reads_ch       = channel.fromPath(resolve.call(params.bam_glob), checkIfExists: true)
    ref_file       = file(resolve.call(params.reference),       checkIfExists: true)
    ref_index_file = file(resolve.call(params.reference_index), checkIfExists: true)
    ref_dict_file  = file(resolve.call(params.reference_dict),  checkIfExists: true)
    intervals_file = file(resolve.call(params.intervals),       checkIfExists: true)

    // Create index file for input BAM file
    SAMTOOLS_INDEX(reads_ch)

    // Call variants from the indexed BAM file
    GATK_HAPLOTYPECALLER(
        SAMTOOLS_INDEX.out,
        ref_file,
        ref_index_file,
        ref_dict_file,
        intervals_file
    )

    publish:
    indexed_bam = SAMTOOLS_INDEX.out
    vcf = GATK_HAPLOTYPECALLER.out.vcf
    vcf_idx = GATK_HAPLOTYPECALLER.out.idx
}

output {
    indexed_bam {
        path 'bam'
    }
    vcf {
        path 'vcf'
    }
    vcf_idx {
        path 'vcf'
    }
}