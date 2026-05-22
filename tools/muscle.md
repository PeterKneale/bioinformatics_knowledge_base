# MUSCLE

**Source:** [drive5.com/muscle](https://www.drive5.com/muscle/)  
**License:** Public Domain  
**Category:** Multiple sequence alignment

## Purpose

Fast and accurate multiple sequence alignment program. Aligns protein or nucleotide sequences to identify conserved regions, build phylogenetic trees, and prepare alignments for downstream analysis (e.g., HMM building, evolutionary analysis). MUSCLE v5 uses ensemble methods for improved accuracy.

## Installation

```bash
conda install -c bioconda muscle
```

## Usage Examples

```bash
# Basic multiple sequence alignment
muscle -align sequences.fa -output aligned.fa

# MUSCLE v3 syntax (still common)
muscle -in sequences.fa -out aligned.fa

# Output in Clustal format
muscle -align sequences.fa -output aligned.aln -clustalw

# Protein alignment (auto-detected)
muscle -align proteins.fa -output aligned_proteins.fa

# Super5 algorithm for large datasets (>500 sequences)
muscle -super5 large_dataset.fa -output aligned.fa

# Refine an existing alignment
muscle -refine aligned.fa -output refined.fa
```

## Produces

- Aligned FASTA (default)
- Clustal format (`.aln`)
- Stockholm format
- PHYLIP format

## Notes

- Auto-detects protein vs nucleotide input
- For very large alignments (>10,000 sequences), use `-super5` mode
- Commonly used to prepare input for `hmmbuild` or phylogenetic tools

## Related Tools

- [mafft](mafft.md) — Alternative aligner (often preferred for large datasets)
- [hmmer](hmmer.md) — Build HMMs from MUSCLE alignments
- [clustalw](https://www.genome.jp/tools-bin/clustalw) — Classic MSA tool
