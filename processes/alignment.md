# Alignment Process

## Overview
The alignment process maps sequencing reads (typically in FASTQ format) to a reference genome or transcriptome. This is a critical step in most NGS analysis pipelines, enabling variant calling, quantification, and downstream analyses.

## Pre-alignment Steps
1. **Reference preparation**
   - Genome indexing using tools like BWA index or Bowtie2-build
   - Transcriptome indexing (for RNA-seq)
2. **Read preprocessing**
   - Quality filtering (FastQC, fastp)
   - Adapter trimming (Cutadapt)
   - Length filtering
3. **Quality control**
   - Read statistics (number, length distribution)
   - Quality score assessment

## Alignment Algorithms
### Short-read Aligners
| Tool                           | Algorithm                 | Best For                         |
| ------------------------------ | ------------------------- | -------------------------------- |
| [BWA](../tools/bwa.md)         | Burrows-Wheeler Transform | General short-read DNA alignment |
| [Bowtie2](../tools/bowtie2.md) | FM-index                  | Fast, memory-efficient alignment |
| [HISAT2](../tools/hisat2.md)   | Graph-based               | Splice-aware RNA-seq alignment   |
| [STAR](../tools/star.md)       | Split alignment           | Ultrafast splice-aware alignment |

### Long-read Aligners
| Tool                                      | Algorithm           | Best For                   |
| ----------------------------------------- | ------------------- | -------------------------- |
| [minimap2](../tools/minimap2.md)          | Pairwise alignment  | Long-read alignment        |
| [ngmlr](https://github.com/philres/ngmlr) | Long-read alignment | PacBio and Oxford Nanopore |

## Alignment Parameters
- **Mapping quality threshold** (MAPQ)
- **Maximum mismatches** allowed
- **Seed length** for alignment
- **Gap penalties** for indels
- **Splice site recognition** (for RNA-seq)

## Post-alignment Processing
1. **Sorting** (coordinate-sorted BAM)
2. **Indexing** (BAI or CSI index)
3. **Duplicate marking** (Picard MarkDuplicates)
4. **Quality filtering** (remove low MAPQ reads)
5. **Coverage calculation**

## Output Formats
- **BAM/CRAM** (aligned reads with alignment information)
- **BAI/CSI** (index files for random access)
- **Metrics files** (alignment statistics)
- **Unmapped reads** (FASTQ format)

## Tools Involved
- [BWA](../tools/bwa.md) - Standard DNA short-read alignment
- [Bowtie2](../tools/bowtie2.md) - Fast short-read alignment
- [STAR](../tools/star.md) - RNA-seq splice-aware alignment
- [HISAT2](../tools/hisat2.md) - Graph-based RNA-seq alignment
- [minimap2](../tools/minimap2.md) - Long-read alignment
- [samtools](../tools/samtools.md) - BAM manipulation and sorting
- [Picard](../tools/picard.md) - Duplicate marking and metrics