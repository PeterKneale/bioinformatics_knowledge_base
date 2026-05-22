# Bioinformatics CLI Tools Index

A reference collection of command-line tools used in bioinformatics analysis pipelines.

## Quality Control & Preprocessing

| Tool                          | Purpose                                    |
| ----------------------------- | ------------------------------------------ |
| [FastQC](fastqc.md)           | Sequencing read quality assessment         |
| [MultiQC](multiqc.md)         | Aggregate QC reports from multiple tools   |
| [fastp](fastp.md)             | All-in-one FASTQ preprocessing (trim + QC) |
| [Trimmomatic](trimmomatic.md) | Flexible Illumina read trimming            |
| [Cutadapt](cutadapt.md)       | Adapter and primer removal                 |

## Alignment — DNA

| Tool                    | Purpose                                               |
| ----------------------- | ----------------------------------------------------- |
| [BWA](bwa.md)           | Short-read alignment (Illumina WGS/WES standard)      |
| [Bowtie2](bowtie2.md)   | Short-read alignment (ChIP-seq, general purpose)      |
| [minimap2](minimap2.md) | Long-read alignment (PacBio, Nanopore) and assemblies |

## Alignment — RNA-seq

| Tool                | Purpose                                         |
| ------------------- | ----------------------------------------------- |
| [STAR](star.md)     | Ultrafast splice-aware RNA-seq aligner          |
| [HISAT2](hisat2.md) | Graph-based splice-aware aligner (lower memory) |

## Alignment Processing

| Tool                    | Purpose                                                 |
| ----------------------- | ------------------------------------------------------- |
| [samtools](samtools.md) | SAM/BAM/CRAM manipulation, sorting, indexing, filtering |
| [Picard](picard.md)     | Duplicate marking, BAM metrics, format validation       |

## Variant Calling & Manipulation

| Tool                      | Purpose                                            |
| ------------------------- | -------------------------------------------------- |
| [GATK](gatk.md)           | Industry-standard germline/somatic variant calling |
| [bcftools](bcftools.md)   | Variant calling and VCF/BCF manipulation           |
| [FreeBayes](freebayes.md) | Bayesian haplotype-based variant caller            |
| [VCFtools](vcftools.md)   | VCF filtering and population genetics statistics   |
| [tabix](tabix.md)         | Indexing and querying tab-delimited genomic files  |

## Quantification — RNA-seq

| Tool                              | Purpose                                       |
| --------------------------------- | --------------------------------------------- |
| [featureCounts](featurecounts.md) | Fast read counting for genomic features       |
| [HTSeq-count](htseq-count.md)     | Python-based read counting                    |
| [Kallisto](kallisto.md)           | Pseudoalignment transcript quantification     |
| [Salmon](salmon.md)               | Selective-alignment transcript quantification |

## Coverage & Visualisation

| Tool                      | Purpose                                                  |
| ------------------------- | -------------------------------------------------------- |
| [deepTools](deeptools.md) | Normalized BigWig tracks, heatmaps, QC plots             |
| [bedtools](bedtools.md)   | Genomic interval arithmetic (intersect, merge, coverage) |

## Sequence Search & Alignment

| Tool                | Purpose                                                  |
| ------------------- | -------------------------------------------------------- |
| [BLAST](blast.md)   | Local similarity search (nucleotide and protein)         |
| [HMMER](hmmer.md)   | Profile HMM search (remote homology, domain annotation)  |
| [MUSCLE](muscle.md) | Multiple sequence alignment                              |
| [MAFFT](mafft.md)   | Multiple sequence alignment (scalable to large datasets) |

## Sequence Manipulation

| Tool                | Purpose                                            |
| ------------------- | -------------------------------------------------- |
| [SeqKit](seqkit.md) | FASTA/FASTQ toolkit (stats, grep, filter, convert) |

## Population Genetics / GWAS

| Tool                    | Purpose                                                |
| ----------------------- | ------------------------------------------------------ |
| [PLINK](plink.md)       | Genotype QC, association testing, population structure |
| [VCFtools](vcftools.md) | FST, LD, allele frequency, missingness                 |
