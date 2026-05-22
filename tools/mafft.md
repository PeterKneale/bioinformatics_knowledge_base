# MAFFT

**Source:** [mafft.cbrc.jp](https://mafft.cbrc.jp/alignment/software/)  
**License:** BSD-3-Clause  
**Category:** Multiple sequence alignment

## Purpose

Multiple sequence alignment program with multiple algorithms for different dataset sizes and accuracy requirements. Particularly effective for large-scale alignments (thousands of sequences) and offers iterative refinement for improved accuracy. Widely used for phylogenomics and comparative genomics.

## Installation

```bash
conda install -c bioconda mafft
# or
brew install mafft
```

## Algorithm Strategies

| Strategy | Speed | Accuracy | Use Case |
|----------|-------|----------|----------|
| `--auto` | Varies | Best auto-selected | Default recommendation |
| `FFT-NS-2` | Fast | Good | Large datasets (>2000 seq) |
| `L-INS-i` | Slow | Highest | Small datasets, one alignable domain |
| `G-INS-i` | Slow | High | Global homology |
| `E-INS-i` | Slow | High | Multiple conserved domains with gaps |

## Usage Examples

```bash
# Automatic strategy selection (recommended)
mafft --auto sequences.fa > aligned.fa

# Most accurate (for <200 sequences with single domain)
mafft --localpair --maxiterate 1000 sequences.fa > aligned.fa
# equivalent to: linsi sequences.fa > aligned.fa

# Fast for large datasets
mafft --retree 2 sequences.fa > aligned.fa
# equivalent to: mafft sequences.fa > aligned.fa

# Global alignment with iterative refinement
mafft --globalpair --maxiterate 1000 sequences.fa > aligned.fa
# equivalent to: ginsi sequences.fa > aligned.fa

# Add new sequences to existing alignment (without re-aligning)
mafft --add new_sequences.fa --keeplength existing_alignment.fa > updated.fa

# Thread-parallel execution
mafft --auto --thread 8 sequences.fa > aligned.fa

# Output in Clustal format
mafft --auto --clustalout sequences.fa > aligned.aln

# Nucleotide alignment adjusting for coding sequences
mafft --auto --nuc sequences.fa > aligned.fa
```

## Produces

- Aligned FASTA (default to stdout)
- Clustal format (`--clustalout`)

## Related Tools

- [muscle](muscle.md) — Alternative MSA tool
- [hmmer](hmmer.md) — Build HMMs from alignments
