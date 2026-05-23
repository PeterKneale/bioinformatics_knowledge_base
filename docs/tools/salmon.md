# Salmon

**Source:** [combine-lab.github.io/salmon](https://combine-lab.github.io/salmon/)  
**License:** GPL-3.0  
**Category:** Transcript quantification

## Purpose

Fast transcript-level quantification from RNA-seq reads using selective alignment (quasi-mapping) or alignment-based mode. Accounts for GC bias, sequence-specific bias, and positional bias to produce accurate abundance estimates. Provides both transcript-level and gene-level quantification.

## Installation

```bash
conda install -c bioconda salmon
```

## Key Commands

| Command | Description                           |
| ------- | ------------------------------------- |
| `index` | Build transcriptome index             |
| `quant` | Quantify abundances from FASTQ or BAM |

## Usage Examples

```bash
# Build index (with decoy sequences from genome for improved accuracy)
grep "^>" reference.fa | cut -d " " -f 1 | tr -d ">" > decoys.txt
cat transcriptome.fa reference.fa > gentrome.fa
salmon index -t gentrome.fa -d decoys.txt -i salmon_index -p 8

# Simple index (transcriptome only)
salmon index -t transcriptome.fa -i salmon_index -p 8

# Quantify paired-end reads (quasi-mapping mode)
salmon quant -i salmon_index \
  -l A \
  -1 reads_R1.fastq.gz -2 reads_R2.fastq.gz \
  -o salmon_output/ \
  -p 8 --validateMappings

# Quantify with bias correction
salmon quant -i salmon_index \
  -l A \
  -1 reads_R1.fastq.gz -2 reads_R2.fastq.gz \
  -o salmon_output/ \
  -p 8 --validateMappings \
  --seqBias --gcBias

# Quantify from existing BAM (alignment-based mode)
salmon quant -t transcriptome.fa \
  -l A \
  -a aligned_to_transcriptome.bam \
  -o salmon_output/

# Single-end quantification
salmon quant -i salmon_index \
  -l A -r reads.fastq.gz \
  -o salmon_output/ -p 8
```

## Library Type (`-l`)

| Code  | Description                       |
| ----- | --------------------------------- |
| `A`   | Automatic detection (recommended) |
| `ISR` | Inward, stranded, read 1 reverse  |
| `ISF` | Inward, stranded, read 1 forward  |
| `IU`  | Inward, unstranded                |

## Produces

- `quant.sf` — Per-transcript quantification (TPM + counts)
- `quant.genes.sf` — Gene-level quantification (with `--geneMap`)
- `aux_info/` — Auxiliary data (bias models, fragment length dist)
- `cmd_info.json` — Command metadata

## Output Format (quant.sf)

```tsv
Name            Length  EffectiveLength TPM     NumReads
ENST00000456328 1657    1458.000        12.34   100.500
ENST00000450305 632     433.000         6.78    50.200
```

## Related Tools

- [kallisto](kallisto.md) — Alternative pseudoalignment quantifier
- [star](star.md) — Genome alignment (upstream of alignment-based mode)
- [featurecounts](featurecounts.md) — Gene-level counting from genome BAM
