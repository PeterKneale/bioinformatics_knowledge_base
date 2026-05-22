# HISAT2

**Source:** [daehwankimlab.github.io/hisat2](http://daehwankimlab.github.io/hisat2/)  
**License:** GPL-3.0  
**Category:** RNA-seq alignment

## Purpose

Graph-based splice-aware aligner for RNA-seq reads. Uses a graph FM index (GFM) that can incorporate known variants (SNPs) and splice sites into the index structure. Lower memory footprint than STAR while maintaining competitive speed and accuracy.

## Installation

```bash
conda install -c bioconda hisat2
```

## Key Commands

| Command | Description |
|---------|-------------|
| `hisat2-build` | Build genome index |
| `hisat2` | Align reads |
| `hisat2_extract_splice_sites.py` | Extract splice sites from GTF |
| `hisat2_extract_exons.py` | Extract exons from GTF |

## Usage Examples

```bash
# Extract splice sites and exons from annotation
hisat2_extract_splice_sites.py annotation.gtf > splice_sites.txt
hisat2_extract_exons.py annotation.gtf > exons.txt

# Build index with known splice sites
hisat2-build --ss splice_sites.txt --exon exons.txt \
  reference.fa hisat2_index

# Align paired-end RNA-seq reads
hisat2 -x hisat2_index \
  -1 reads_R1.fastq.gz -2 reads_R2.fastq.gz \
  --dta \
  --threads 8 | samtools sort -o aligned.sorted.bam

# Align with novel splice junction discovery
hisat2 -x hisat2_index \
  -1 reads_R1.fastq.gz -2 reads_R2.fastq.gz \
  --dta --novel-splicesite-outfile novel_splicesites.txt \
  --threads 8 | samtools sort -o aligned.sorted.bam

# Single-end alignment
hisat2 -x hisat2_index -U reads.fastq.gz \
  --threads 8 | samtools sort -o aligned.sorted.bam
```

## Produces

- SAM output to stdout (pipe to samtools for BAM)
- `.ht2` — Index files
- Splice junction files (novel junctions)

## Notes

- `--dta` (downstream transcriptome assembly) produces alignments better suited for StringTie
- Memory requirement: ~8GB for human genome (vs ~30GB for STAR)

## Related Tools

- [star](star.md) — Alternative RNA-seq aligner (faster, more memory)
- [featurecounts](featurecounts.md) — Read quantification
- [samtools](samtools.md) — Post-alignment processing
