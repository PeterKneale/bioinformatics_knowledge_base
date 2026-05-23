# GFF/GTF Format (General Feature Format / Gene Transfer Format)

**Extension:** `.gff`, `.gff3`, `.gtf`  
**Type:** Text (tab-delimited)  
**Specification:** [GFF3 Spec](https://github.com/The-Sequence-Ontology/Specifications/blob/master/gff3.md) | [GTF/GFF2.5](https://genome.ucsc.edu/FAQ/FAQformat.html#format4)

## Purpose

Describes genomic features (genes, transcripts, exons, CDS) with hierarchical relationships. Used for genome annotation. GTF is a strict subset of GFF used primarily by Ensembl and many RNA-seq tools.

## Structure (GFF3)

Nine tab-delimited columns:

| Col | Field      | Description                             |
| --- | ---------- | --------------------------------------- |
| 1   | seqid      | Chromosome/scaffold                     |
| 2   | source     | Annotation source (e.g., "ensembl")     |
| 3   | type       | Feature type (gene, mRNA, exon, CDS)    |
| 4   | start      | Start position (1-based, inclusive)     |
| 5   | end        | End position (1-based, inclusive)       |
| 6   | score      | Score (or `.`)                          |
| 7   | strand     | `+`, `-`, or `.`                        |
| 8   | phase      | Reading frame for CDS (0, 1, 2, or `.`) |
| 9   | attributes | Semicolon-separated key=value pairs     |

### GFF3 Example

```tsv
chr1	ensembl	gene	11869	14409	.	+	.	ID=ENSG00000223972;Name=DDX11L1;biotype=transcribed_unprocessed_pseudogene
chr1	ensembl	mRNA	11869	14409	.	+	.	ID=ENST00000456328;Parent=ENSG00000223972;Name=DDX11L1-201
chr1	ensembl	exon	11869	12227	.	+	.	Parent=ENST00000456328
chr1	ensembl	exon	12613	12721	.	+	.	Parent=ENST00000456328
chr1	ensembl	exon	13221	14409	.	+	.	Parent=ENST00000456328
```

### GTF Example

```tsv
chr1	ensembl	gene	11869	14409	.	+	.	gene_id "ENSG00000223972"; gene_name "DDX11L1";
chr1	ensembl	transcript	11869	14409	.	+	.	gene_id "ENSG00000223972"; transcript_id "ENST00000456328";
chr1	ensembl	exon	11869	12227	.	+	.	gene_id "ENSG00000223972"; transcript_id "ENST00000456328"; exon_number "1";
chr1	ensembl	exon	12613	12721	.	+	.	gene_id "ENSG00000223972"; transcript_id "ENST00000456328"; exon_number "2";
chr1	ensembl	exon	13221	14409	.	+	.	gene_id "ENSG00000223972"; transcript_id "ENST00000456328"; exon_number "3";
```

## GFF3 vs GTF Differences

| Feature       | GFF3                     | GTF (GFF2.5)                            |
| ------------- | ------------------------ | --------------------------------------- |
| Hierarchy     | Explicit `ID`/`Parent`   | Implicit via `gene_id`/`transcript_id`  |
| Attributes    | `key=value`              | `key "value";`                          |
| Multi-value   | `Parent=id1,id2`         | Not supported                           |
| Directives    | `##gff-version 3`, `###` | None                                    |
| Feature types | Ontology-based (SO)      | Fixed set (gene, transcript, exon, CDS) |

## Indexing

### Tabix Index

```bash
# Sort, compress, and index GFF3
sort -k1,1 -k4,4n annotation.gff3 | bgzip > annotation.gff3.gz
tabix -p gff annotation.gff3.gz

# Query region
tabix annotation.gff3.gz chr1:11000-15000
```

## Coordinate System

GFF/GTF uses **1-based, inclusive** coordinates (same as VCF, different from BED).

| Format  | chr1, first 100 bases |
| ------- | --------------------- |
| GFF/GTF | `chr1 ... 1 ... 100`  |
| BED     | `chr1 0 100`          |

## Tools That Create This Format

| Tool                                         | Context                         |
| -------------------------------------------- | ------------------------------- |
| Genome annotation databases                  | Ensembl, GENCODE, RefSeq, UCSC  |
| Gene prediction tools                        | Augustus, GeneMark              |
| [HISAT2 extract scripts](../tools/hisat2.md) | Splice site extraction from GTF |

## Tools That Read This Format

| Tool                                       | Purpose                              |
| ------------------------------------------ | ------------------------------------ |
| [STAR](../tools/star.md)                   | Splice junction annotation for index |
| [HISAT2](../tools/hisat2.md)               | Splice site extraction               |
| [featureCounts](../tools/featurecounts.md) | Gene/exon counting                   |
| [HTSeq-count](../tools/htseq-count.md)     | Gene counting                        |
| [bedtools](../tools/bedtools.md)           | Interval operations                  |
| [tabix](../tools/tabix.md)                 | Region queries                       |
| [Kallisto](../tools/kallisto.md)           | Genome-BAM output                    |

## Common Operations

```bash
# Extract gene names from GTF
awk '$3 == "gene"' annotation.gtf | grep -o 'gene_name "[^"]*"' | sort -u

# Convert GTF to BED (genes)
awk '$3 == "gene" {print $1"\t"$4-1"\t"$5"\t"$10"\t.\t"$7}' annotation.gtf | tr -d '";' > genes.bed

# Count features by type
awk '{print $3}' annotation.gtf | sort | uniq -c | sort -rn
```

## See Also

- [BED](bed.md) — simpler interval format
- [FASTA](fasta.md) — sequence data referenced by GFF
