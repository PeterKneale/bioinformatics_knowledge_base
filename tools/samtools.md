# samtools

**Source:** [htslib.org](https://www.htslib.org/)  
**License:** MIT  
**Category:** Alignment processing

## Purpose

Swiss-army knife for manipulating alignments in SAM/BAM/CRAM format. Provides sorting, indexing, filtering, format conversion, statistics, depth calculation, duplicate marking, and merging of aligned sequencing reads.

## Installation

```bash
conda install -c bioconda samtools
# or
brew install samtools
```

## Key Commands

| Command | Description |
|---------|-------------|
| `view` | Convert between SAM/BAM/CRAM, filter by flag/region |
| `sort` | Sort alignments by coordinate or name |
| `index` | Create .bai/.csi index for coordinate-sorted BAM |
| `flagstat` | Quick alignment QC summary |
| `stats` | Comprehensive alignment statistics |
| `depth` | Per-base or per-region depth |
| `markdup` | Mark or remove PCR duplicates |
| `merge` | Merge multiple sorted BAM files |
| `mpileup` | Generate pileup for variant calling |
| `faidx` | Index and extract FASTA sequences |
| `fastq` | Convert BAM back to FASTQ |
| `idxstats` | Per-chromosome mapped/unmapped counts |

## Usage Examples

```bash
# Convert SAM to sorted BAM
samtools sort -o aligned.sorted.bam aligned.sam

# Index a sorted BAM file (produces .bai)
samtools index aligned.sorted.bam

# View reads in a specific region
samtools view -b aligned.sorted.bam chr1:1000000-2000000 > region.bam

# Quick alignment statistics
samtools flagstat aligned.sorted.bam

# Calculate per-base depth
samtools depth -a aligned.sorted.bam > depth.txt

# Filter for properly paired, mapped reads (exclude unmapped, secondary, supplementary)
samtools view -b -F 0x904 -f 0x2 input.bam > filtered.bam

# Mark PCR duplicates
samtools markdup input.sorted.bam output.markdup.bam

# Index a FASTA reference (produces .fai)
samtools faidx reference.fa

# Extract a region from reference
samtools faidx reference.fa chr1:1000-2000
```

## Produces

- `.bam` — Binary alignment format
- `.bai` / `.csi` — BAM index files
- `.cram` — Compressed reference-based alignment
- `.fai` — FASTA index

## Related Tools

- [bcftools](bcftools.md) — Variant calling from mpileup output
- [picard](picard.md) — Alternative duplicate marking
- [deeptools](deeptools.md) — Coverage visualisation from BAM
