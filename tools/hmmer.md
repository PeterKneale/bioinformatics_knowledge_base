# HMMER

**Source:** [hmmer.org](http://hmmer.org/)  
**License:** BSD-3-Clause  
**Category:** Profile HMM search

## Purpose

Searches for sequence homologs using profile Hidden Markov Models. More sensitive than BLAST for detecting remote homology. Used for protein domain annotation (Pfam), gene family classification, and genome annotation. Implements the same statistical framework as Pfam and InterPro.

## Installation

```bash
conda install -c bioconda hmmer
# or
brew install hmmer
```

## Key Programs

| Program | Description |
|---------|-------------|
| `hmmbuild` | Build profile HMM from multiple alignment |
| `hmmsearch` | Search profile HMM against sequence database |
| `hmmscan` | Search sequence against profile HMM database |
| `hmmpress` | Prepare HMM database for hmmscan |
| `jackhmmer` | Iterative search (like PSI-BLAST) |
| `phmmer` | Single sequence vs database (like BLASTP) |
| `nhmmer` | Nucleotide HMM search |
| `hmmemit` | Generate sequences from HMM |

## Usage Examples

```bash
# Build HMM from a multiple sequence alignment
hmmbuild model.hmm alignment.sto

# Search HMM against a protein database
hmmsearch --tblout results.tbl -E 1e-5 --cpu 8 \
  model.hmm protein_database.fa

# Scan a protein against Pfam database
hmmpress Pfam-A.hmm
hmmscan --tblout domains.tbl -E 1e-5 --cpu 8 \
  Pfam-A.hmm query_protein.fa

# Iterative search (increasing sensitivity each round)
jackhmmer -N 3 --tblout results.tbl -E 1e-5 \
  query.fa protein_database.fa

# Single sequence search (like BLASTP but with HMM statistics)
phmmer --tblout results.tbl -E 1e-5 \
  query.fa protein_database.fa

# DNA-level search
nhmmer --tblout results.tbl -E 1e-5 \
  model.hmm genome.fa
```

## Produces

- `.hmm` — Profile HMM file
- `.tbl` — Per-target tabular results (`--tblout`)
- `.domtbl` — Per-domain tabular results (`--domtblout`)
- Alignment output (Stockholm format)

## Related Tools

- [blast](blast.md) — Faster but less sensitive sequence search
- [Pfam](https://www.ebi.ac.uk/interpro/) — Curated HMM database for protein domains
