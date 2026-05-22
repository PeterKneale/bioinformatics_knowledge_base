# BLAST (Basic Local Alignment Search Tool)

**Source:** [blast.ncbi.nlm.nih.gov](https://blast.ncbi.nlm.nih.gov/)  
**License:** Public Domain  
**Category:** Sequence similarity search

## Purpose

Finds regions of local similarity between nucleotide or protein sequences. Compares query sequences against a database to identify homologs, annotate unknown sequences, and discover evolutionary relationships. The most widely used bioinformatics tool for sequence similarity searching.

## Installation

```bash
conda install -c bioconda blast
# or
brew install blast
```

## Programs

| Program       | Query → Database                              |
| ------------- | --------------------------------------------- |
| `blastn`      | Nucleotide → Nucleotide                       |
| `blastp`      | Protein → Protein                             |
| `blastx`      | Translated nucleotide → Protein               |
| `tblastn`     | Protein → Translated nucleotide               |
| `tblastx`     | Translated nucleotide → Translated nucleotide |
| `makeblastdb` | Create BLAST database                         |

## Usage Examples

```bash
# Create a BLAST database from FASTA
makeblastdb -in sequences.fa -dbtype nucl -out my_db
makeblastdb -in proteins.fa -dbtype prot -out prot_db

# Nucleotide BLAST
blastn -query query.fa -db my_db -out results.txt \
  -evalue 1e-5 -outfmt 6

# Protein BLAST
blastp -query query_protein.fa -db prot_db -out results.txt \
  -evalue 1e-5 -outfmt 6 -num_threads 8

# Translated search (DNA query vs protein DB)
blastx -query contigs.fa -db nr -out results.txt \
  -evalue 1e-5 -outfmt 6 -num_threads 8

# Tabular output format (outfmt 6)
blastn -query query.fa -db nt -outfmt 6 -out results.tsv

# Custom output columns
blastn -query query.fa -db my_db \
  -outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore"

# Remote BLAST against NCBI (no local DB needed)
blastn -query query.fa -db nt -remote -out results.txt
```

## Output Format 6 Columns

```
qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore
```

## Produces

- Text/tabular alignment results
- BLAST database files (`.nhr`, `.nin`, `.nsq` for nucleotide; `.phr`, `.pin`, `.psq` for protein)

## Related Tools

- [hmmer](hmmer.md) — Profile HMM search (more sensitive for remote homology)
- [diamond](https://github.com/bbuchfink/diamond) — Faster protein alignment alternative
