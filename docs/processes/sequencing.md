# Sequencing Process

## Overview
The sequencing process refers to the workflow of preparing and analyzing DNA or RNA samples for high-throughput sequencing technologies. This encompasses sample preparation, library construction, sequencing, and initial data processing.

## Sample Preparation
- **DNA/RNA extraction** from biological samples (cells, tissues, blood)
- **Quality control** of extracted nucleic acids (concentration, integrity)
- **Fragmentation** of DNA/RNA to appropriate sizes for sequencing
- **Adapter ligation** for library construction
- **PCR amplification** (if needed) to generate sufficient material

## Library Construction
- **End repair** and A-tailing of DNA fragments
- **Adapter addition** for sequencing platform compatibility
- **Size selection** using gel electrophoresis or bead-based methods
- **Indexing** (barcoding) for multiplexing samples
- **Quality control** of library constructs

## Sequencing Technologies
| Technology                  | Read Length | Platform       | Use Case                              |
| --------------------------- | ----------- | -------------- | ------------------------------------- |
| Illumina (NextSeq, NovaSeq) | 50-300bp    | Short-read     | WGS, WES, RNA-seq                     |
| PacBio SMRT                 | 1-20kb      | Long-read      | De novo assembly, structural variants |
| Oxford Nanopore             | 100bp-100kb | Long-read      | Real-time, portable, long reads       |
| 454                         | 100-1000bp  | Pyrosequencing | Targeted sequencing                   |

## Quality Control Steps
- **Base calling** from raw instrument output
- **Quality filtering** of reads (Phred scores)
- **Adapter trimming**
- **Length filtering**
- **Duplicate removal** (if applicable)

## Data Output
- **Raw reads** in FASTQ format
- **Quality metrics** (FastQC reports)
- **Index files** for multiplexed samples
- **Sample metadata** (library prep details, sequencing parameters)

## Tools Involved
- [FastQC](../tools/fastqc.md) - Quality assessment
- [fastp](../tools/fastp.md) - Preprocessing and trimming
- [Cutadapt](../tools/cutadapt.md) - Adapter removal
- [MultiQC](../tools/multiqc.md) - Aggregate reports