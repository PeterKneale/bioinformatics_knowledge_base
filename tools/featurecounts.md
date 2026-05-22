# featureCounts

**Source:** [subread.sourceforge.net](https://subread.sourceforge.net/) (part of Subread package)  
**License:** GPL-3.0  
**Category:** Read quantification

## Purpose

Ultrafast general-purpose read counting tool. Assigns aligned reads (from BAM) to genomic features (genes, exons) defined in a GTF/GFF annotation. Primary use is generating gene-level count matrices for RNA-seq differential expression analysis.

## Installation

```bash
conda install -c bioconda subread
```

## Key Options

| Option | Description |
|--------|-------------|
| `-a` | Annotation file (GTF/GFF) |
| `-o` | Output count file |
| `-t` | Feature type (default: exon) |
| `-g` | Attribute for grouping (default: gene_id) |
| `-p` | Paired-end mode (count fragments not reads) |
| `--countReadPairs` | Count read pairs (PE) |
| `-s` | Strandedness (0=unstranded, 1=stranded, 2=reversely stranded) |
| `-T` | Number of threads |
| `-M` | Count multi-mapping reads |
| `-O` | Allow multi-overlap |

## Usage Examples

```bash
# Basic gene-level counting (unstranded, paired-end)
featureCounts -a annotation.gtf \
  -o counts.txt \
  -p --countReadPairs \
  -T 8 \
  aligned.sorted.bam

# Multiple BAMs (produces count matrix)
featureCounts -a annotation.gtf \
  -o count_matrix.txt \
  -p --countReadPairs \
  -T 8 \
  sample1.bam sample2.bam sample3.bam

# Stranded RNA-seq (e.g., dUTP protocol = reverse stranded)
featureCounts -a annotation.gtf \
  -o counts.txt \
  -p --countReadPairs \
  -s 2 \
  -T 8 \
  aligned.sorted.bam

# Count at exon level
featureCounts -a annotation.gtf \
  -o exon_counts.txt \
  -t exon -g exon_id \
  -T 8 \
  aligned.sorted.bam

# Allow multi-mappers (e.g., for TE analysis)
featureCounts -a annotation.gtf \
  -o counts.txt \
  -M --fraction \
  -T 8 \
  aligned.sorted.bam
```

## Produces

- Tab-delimited count file (gene × sample matrix)
- `.summary` — Assignment statistics per BAM

## Output Format

```
Geneid  Chr  Start  End  Strand  Length  sample1.bam  sample2.bam
GENE1   chr1 1000   2000 +       1000    523          487
GENE2   chr1 3000   4000 -       1000    102          98
```

## Related Tools

- [htseq-count](htseq-count.md) — Alternative read counter (Python, slower)
- [star](star.md) — Alignment with built-in quantification (--quantMode)
- [salmon](salmon.md) — Alignment-free quantification
- [kallisto](kallisto.md) — Alignment-free quantification
