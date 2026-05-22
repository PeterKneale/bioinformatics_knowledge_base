# STAR (Spliced Transcripts Alignment to a Reference)

**Source:** [github.com/alexdobin/STAR](https://github.com/alexdobin/STAR)  
**License:** MIT  
**Category:** RNA-seq alignment

## Purpose

Ultrafast RNA-seq aligner that handles spliced alignments across exon-exon junctions. Designed for mapping RNA-seq reads to a reference genome while discovering novel splice junctions. Also supports gene quantification (--quantMode) and chimeric alignment detection for fusion gene discovery.

## Installation

```bash
conda install -c bioconda star
```

## Key Operations

| Mode                       | Description                                   |
| -------------------------- | --------------------------------------------- |
| `--runMode genomeGenerate` | Build genome index with annotation            |
| `--runMode alignReads`     | Align RNA-seq reads (default)                 |
| `--quantMode GeneCounts`   | Quantify gene expression during alignment     |
| `--chimSegmentMin`         | Enable chimeric/fusion detection              |
| `--twopassMode Basic`      | Two-pass mapping for novel junction discovery |

## Usage Examples

```bash
# Generate genome index (requires ~30GB RAM for human)
STAR --runMode genomeGenerate \
  --genomeDir star_index/ \
  --genomeFastaFiles reference.fa \
  --sjdbGTFfile annotation.gtf \
  --runThreadN 8

# Basic paired-end alignment
STAR --runMode alignReads \
  --genomeDir star_index/ \
  --readFilesIn reads_R1.fastq.gz reads_R2.fastq.gz \
  --readFilesCommand zcat \
  --outSAMtype BAM SortedByCoordinate \
  --runThreadN 8 \
  --outFileNamePrefix sample1_

# Alignment with gene quantification
STAR --genomeDir star_index/ \
  --readFilesIn reads_R1.fastq.gz reads_R2.fastq.gz \
  --readFilesCommand zcat \
  --outSAMtype BAM SortedByCoordinate \
  --quantMode GeneCounts \
  --runThreadN 8

# Two-pass mode for sensitive novel junction detection
STAR --genomeDir star_index/ \
  --readFilesIn reads_R1.fastq.gz reads_R2.fastq.gz \
  --readFilesCommand zcat \
  --outSAMtype BAM SortedByCoordinate \
  --twopassMode Basic \
  --runThreadN 8
```

## Produces

- `Aligned.sortedByCoord.out.bam` — Sorted BAM alignment
- `SJ.out.tab` — Splice junctions
- `ReadsPerGene.out.tab` — Gene counts (with --quantMode)
- `Log.final.out` — Alignment summary statistics
- `Chimeric.out.junction` — Fusion/chimeric reads

## Related Tools

- [hisat2](hisat2.md) — Alternative splice-aware aligner (lower memory)
- [featurecounts](featurecounts.md) — Count reads per gene from BAM
- [samtools](samtools.md) — BAM indexing and manipulation
- [kallisto](kallisto.md) — Alignment-free transcript quantification
