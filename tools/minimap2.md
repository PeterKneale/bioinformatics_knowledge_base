# minimap2

**Source:** [github.com/lh3/minimap2](https://github.com/lh3/minimap2)  
**License:** MIT  
**Category:** Long-read alignment

## Purpose

Versatile aligner for long reads (PacBio, Oxford Nanopore), full-length cDNA, and genome assemblies. Handles reads from 1kb to 100Mb+. Also fast for short-read alignment. Successor to BWA-MEM for long sequences.

## Installation

```bash
conda install -c bioconda minimap2
# or
brew install minimap2
```

## Key Presets

| Preset | Use Case |
|--------|----------|
| `map-ont` | Oxford Nanopore genomic reads |
| `map-pb` | PacBio CLR genomic reads |
| `map-hifi` | PacBio HiFi/CCS reads |
| `splice` | Long-read RNA-seq (cDNA/direct RNA) |
| `asm5` | Assembly-to-assembly (divergence <5%) |
| `asm20` | Assembly-to-assembly (divergence <20%) |
| `sr` | Short reads (Illumina) |

## Usage Examples

```bash
# Align Oxford Nanopore reads
minimap2 -ax map-ont -t 8 reference.fa reads.fastq.gz | \
  samtools sort -o aligned.sorted.bam

# Align PacBio HiFi reads
minimap2 -ax map-hifi -t 8 reference.fa hifi_reads.fastq.gz | \
  samtools sort -o aligned.sorted.bam

# Align long-read RNA-seq (splice-aware)
minimap2 -ax splice -t 8 reference.fa cdna_reads.fastq.gz | \
  samtools sort -o aligned.sorted.bam

# Align long-read RNA-seq with annotation-guided splice
minimap2 -ax splice --junc-bed annotation.bed -t 8 \
  reference.fa cdna_reads.fastq.gz | samtools sort -o aligned.sorted.bam

# Assembly-to-reference alignment (PAF format)
minimap2 -cx asm5 reference.fa assembly.fa > alignment.paf

# Build an index for repeated use
minimap2 -d reference.mmi reference.fa
minimap2 -ax map-ont -t 8 reference.mmi reads.fastq.gz | \
  samtools sort -o aligned.sorted.bam
```

## Produces

- SAM output to stdout with `-a` flag (pipe to samtools)
- PAF (Pairwise Alignment Format) without `-a` flag
- `.mmi` — Prebuilt minimap2 index

## Related Tools

- [bwa](bwa.md) — Short-read alignment (Illumina)
- [samtools](samtools.md) — BAM processing downstream
