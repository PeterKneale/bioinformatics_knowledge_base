# Kallisto

**Source:** [pachterlab.github.io/kallisto](https://pachterlab.github.io/kallisto/)  
**License:** BSD-2-Clause  
**Category:** Transcript quantification

## Purpose

Near-optimal RNA-seq quantification using pseudoalignment. Quantifies transcript-level abundances directly from FASTQ reads without full alignment to a genome. Extremely fast (minutes for a typical RNA-seq sample) and accurate for differential expression and isoform-level analysis.

## Installation

```bash
conda install -c bioconda kallisto
```

## Key Commands

| Command  | Description                      |
| -------- | -------------------------------- |
| `index`  | Build transcriptome index        |
| `quant`  | Quantify transcript abundances   |
| `bus`    | Generate BUS files (single-cell) |
| `pseudo` | Pseudoalignment output           |

## Usage Examples

```bash
# Build index from transcriptome FASTA
kallisto index -i transcriptome.idx transcriptome.fa

# Quantify paired-end RNA-seq
kallisto quant -i transcriptome.idx \
  -o kallisto_output/ \
  -t 8 \
  reads_R1.fastq.gz reads_R2.fastq.gz

# Quantify with bootstraps (for sleuth uncertainty estimates)
kallisto quant -i transcriptome.idx \
  -o kallisto_output/ \
  -b 100 \
  -t 8 \
  reads_R1.fastq.gz reads_R2.fastq.gz

# Single-end mode (must specify fragment length and SD)
kallisto quant -i transcriptome.idx \
  -o kallisto_output/ \
  --single -l 200 -s 20 \
  -t 8 \
  reads.fastq.gz
```

## Produces

- `abundance.tsv` — Per-transcript TPM and estimated counts
- `abundance.h5` — HDF5 format (includes bootstrap data)
- `run_info.json` — Run metadata

## Output Format (abundance.tsv)

```tsv
target_id       length  eff_length  est_counts  tpm
ENST00000456328 1657    1458        100.5       12.34
ENST00000450305 632     433         50.2        6.78
```

## Notes

- Works at **transcript** level (not gene level) — summarise to gene with tximport (R) or tximeta
- No genome alignment needed — only requires a transcriptome FASTA
- Bootstraps enable uncertainty quantification (used by sleuth)

## Related Tools

- [salmon](salmon.md) — Alternative pseudoalignment quantifier
- [star](star.md) — Genome-level alignment + quantification
- [featurecounts](featurecounts.md) — Gene-level counting from BAM
