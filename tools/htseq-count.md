# HTSeq-count

**Source:** [htseq.readthedocs.io](https://htseq.readthedocs.io/)  
**License:** GPL-3.0  
**Category:** Read quantification

## Purpose

Python-based tool for counting reads mapped to genomic features. Assigns aligned reads from a BAM file to features in a GFF/GTF annotation. Simpler and more conservative than featureCounts — stricter overlap-handling defaults make it suitable when precise counting is preferred over speed.

## Installation

```bash
conda install -c bioconda htseq
# or
pip install HTSeq
```

## Key Options

| Option        | Description                                                          |
| ------------- | -------------------------------------------------------------------- |
| `-f`          | Input format (bam/sam)                                               |
| `-r`          | Sort order (pos/name)                                                |
| `-s`          | Strandedness (yes/no/reverse)                                        |
| `-t`          | Feature type (default: exon)                                         |
| `-i`          | ID attribute (default: gene_id)                                      |
| `--mode`      | Overlap resolution (union/intersection-strict/intersection-nonempty) |
| `--nonunique` | How to handle multi-mappers (none/all/fraction/random)               |

## Usage Examples

```bash
# Basic gene counting (name-sorted BAM, unstranded)
htseq-count -f bam -r name -s no \
  aligned.sorted_by_name.bam annotation.gtf > counts.txt

# Position-sorted BAM (requires more memory)
htseq-count -f bam -r pos -s no \
  aligned.sorted.bam annotation.gtf > counts.txt

# Reverse-stranded RNA-seq (dUTP protocol)
htseq-count -f bam -r pos -s reverse \
  aligned.sorted.bam annotation.gtf > counts.txt

# Strict intersection mode
htseq-count -f bam -r pos -s no --mode intersection-strict \
  aligned.sorted.bam annotation.gtf > counts.txt
```

## Produces

- Tab-delimited count file (gene_id \t count), one gene per line
- Summary lines at end: `__no_feature`, `__ambiguous`, `__too_low_aQual`, `__not_aligned`, `__alignment_not_unique`

## Output Format

```
GENE1   523
GENE2   102
__no_feature    14523
__ambiguous     2341
__alignment_not_unique  8921
```

## Related Tools

- [featurecounts](featurecounts.md) — Faster alternative (C-based, multi-threaded)
- [star](star.md) — Alignment with built-in gene counts
- [salmon](salmon.md) — Alignment-free quantification
