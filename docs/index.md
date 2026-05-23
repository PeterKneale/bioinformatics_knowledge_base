# `Bioinformatics Knowledge Base`

A reference knowledge base covering CLI tools and file formats used in bioinformatics and next-generation sequencing analysis.

## Contents

### Processes

Reference pages for bioinformatics analysis workflows and processes, including sequencing, alignment, and downstream analysis.

| Process                               | Description                                                                                 |
| ------------------------------------- | ------------------------------------------------------------------------------------------- |
| [Sequencing](processes/sequencing.md) | Overview of the complete sequencing workflow from sample preparation to raw data generation |
| [Alignment](processes/alignment.md)   | Detailed workflow of mapping reads to reference genomes and post-alignment processing       |

### [CLI Tools](tools/INDEX.md)

Reference pages for bioinformatics command-line tools, including purpose, installation, usage examples, and cross-references.

| Category              | Tools                                                                                                                                               |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| QC & Preprocessing    | [FastQC](tools/fastqc.md), [MultiQC](tools/multiqc.md), [fastp](tools/fastp.md), [Trimmomatic](tools/trimmomatic.md), [Cutadapt](tools/cutadapt.md) |
| DNA Alignment         | [BWA](tools/bwa.md), [Bowtie2](tools/bowtie2.md), [minimap2](tools/minimap2.md)                                                                     |
| RNA-seq Alignment     | [STAR](tools/star.md), [HISAT2](tools/hisat2.md)                                                                                                    |
| Alignment Processing  | [samtools](tools/samtools.md), [Picard](tools/picard.md)                                                                                            |
| Variant Calling       | [GATK](tools/gatk.md), [bcftools](tools/bcftools.md), [FreeBayes](tools/freebayes.md)                                                               |
| VCF/Interval Tools    | [VCFtools](tools/vcftools.md), [tabix](tools/tabix.md), [bedtools](tools/bedtools.md)                                                               |
| Quantification        | [featureCounts](tools/featurecounts.md), [HTSeq-count](tools/htseq-count.md), [Kallisto](tools/kallisto.md), [Salmon](tools/salmon.md)              |
| Coverage & Viz        | [deepTools](tools/deeptools.md)                                                                                                                     |
| Sequence Search       | [BLAST](tools/blast.md), [HMMER](tools/hmmer.md)                                                                                                    |
| Multiple Alignment    | [MUSCLE](tools/muscle.md), [MAFFT](tools/mafft.md)                                                                                                  |
| Sequence Manipulation | [SeqKit](tools/seqkit.md)                                                                                                                           |
| Population Genetics   | [PLINK](tools/plink.md)                                                                                                                             |

### [File Formats](formats/INDEX.md)

Reference pages for bioinformatics file formats, including structure, indexing options, and which tools produce/consume them.

| Category        | Formats                                                                             |
| --------------- | ----------------------------------------------------------------------------------- |
| Sequences       | [FASTQ](formats/fastq.md), [FASTA](formats/fasta.md)                                |
| Alignments      | [SAM](formats/sam.md), [BAM](formats/bam.md), [CRAM](formats/cram.md)               |
| Variants        | [VCF](formats/vcf.md), [BCF](formats/bcf.md)                                        |
| Intervals       | [BED](formats/bed.md), [GFF/GTF](formats/gff-gtf.md), [BigBed](formats/bigbed.md)   |
| Signal/Coverage | [BigWig](formats/bigwig.md), [BedGraph](formats/bedgraph.md), [WIG](formats/wig.md) |


## Sources

- [HTSlib/samtools documentation](https://www.htslib.org/)
- [GATK Best Practices](https://gatk.broadinstitute.org/hc/en-us/sections/360007226651-Best-Practices-Workflows)
- [Bioconda package repository](https://bioconda.github.io/)
- [UCSC Genome Browser file formats](https://genome.ucsc.edu/FAQ/FAQformat.html)

## Download

- [Download as PDF](bioinformatics-knowledge-base.pdf)
