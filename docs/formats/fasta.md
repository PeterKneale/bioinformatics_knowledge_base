# FASTA Format

**Extension:** `.fa`, `.fasta`, `.fna` (nucleotide), `.faa` (amino acid)  
**Type:** Text  
**Specification:** [Pearson & Lipman 1988](https://doi.org/10.1073/pnas.85.8.2444)

## Purpose

Simple text format for representing nucleotide or protein sequences. Used for reference genomes, transcriptomes, protein databases, and any sequence data where quality scores are not needed.

## Structure

```text
>SEQUENCE_ID optional description
SEQUENCE_DATA
SEQUENCE_DATA_CONTINUED
```

### Example

```text
>chr1 Homo sapiens chromosome 1
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNGATCACAGGTCTATCACCC
TGTAACTTAAACCCTTACTTAAGCTTAAAGAAAGGGCTTGCATTTACCCTTTTG
>chr2 Homo sapiens chromosome 2
NNNNNNNNNNNNNNNNNNNNNNNNACCCAAAGCTCAGCCTTGTTTCTTGTAACT
```

### Fields

| Component   | Description                                                           |
| ----------- | --------------------------------------------------------------------- |
| `>`         | Header line prefix                                                    |
| Sequence ID | First word after `>` (no spaces)                                      |
| Description | Remainder of header line (optional)                                   |
| Sequence    | One or more lines of sequence data (typically wrapped at 60-80 chars) |

## Indexing

### FASTA Index (`.fai`)

Created by `samtools faidx`, enables rapid random access to subsequences without reading entire file.

```bash
# Create index
samtools faidx reference.fa

# Extract region using index
samtools faidx reference.fa chr1:1000-2000
```

The `.fai` file is tab-delimited:

| Column | Content                   |
| ------ | ------------------------- |
| 1      | Sequence name             |
| 2      | Sequence length           |
| 3      | Byte offset of first base |
| 4      | Bases per line            |
| 5      | Bytes per line            |

### Sequence Dictionary (`.dict`)

Required by GATK/Picard. Created by `picard CreateSequenceDictionary` or `samtools dict`.

```bash
samtools dict reference.fa > reference.dict
picard CreateSequenceDictionary R=reference.fa O=reference.dict
```

### BLAST Database Index

For similarity searching:
```bash
makeblastdb -in sequences.fa -dbtype nucl -out mydb
```

Produces: `.nhr`, `.nin`, `.nsq` (nucleotide) or `.phr`, `.pin`, `.psq` (protein)

### BWA Index

For short-read alignment:
```bash
bwa index reference.fa
```

Produces: `.amb`, `.ann`, `.bwt`, `.pac`, `.sa`

## Tools That Create This Format

| Tool                                       | Context                      |
| ------------------------------------------ | ---------------------------- |
| Genome assemblies                          | Reference genomes            |
| [bcftools consensus](../tools/bcftools.md) | Consensus from VCF           |
| [bedtools getfasta](../tools/bedtools.md)  | Extracted regions            |
| [SeqKit](../tools/seqkit.md)               | Converted/filtered sequences |
| [samtools faidx](../tools/samtools.md)     | Extracted subsequences       |

## Tools That Read This Format

| Tool                             | Purpose                  |
| -------------------------------- | ------------------------ |
| [BWA](../tools/bwa.md)           | Reference for alignment  |
| [Bowtie2](../tools/bowtie2.md)   | Reference for alignment  |
| [STAR](../tools/star.md)         | Genome index building    |
| [BLAST](../tools/blast.md)       | Database/query sequences |
| [HMMER](../tools/hmmer.md)       | Sequence databases       |
| [MUSCLE](../tools/muscle.md)     | Multiple alignment input |
| [MAFFT](../tools/mafft.md)       | Multiple alignment input |
| [Kallisto](../tools/kallisto.md) | Transcriptome index      |
| [Salmon](../tools/salmon.md)     | Transcriptome index      |
| [samtools](../tools/samtools.md) | Reference for pileup     |
| [SeqKit](../tools/seqkit.md)     | Sequence manipulation    |

## See Also

- [FASTQ](fastq.md) — sequences with quality scores
- [SAM/BAM](bam.md) — aligned sequences reference this format
