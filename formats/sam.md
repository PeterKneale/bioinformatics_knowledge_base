# SAM Format (Sequence Alignment/Map)

**Extension:** `.sam`  
**Type:** Text (tab-delimited)  
**Specification:** [SAM/BAM Format Specification](https://samtools.github.io/hts-specs/SAMv1.pdf)

## Purpose

Tab-delimited text format for storing aligned sequencing reads against a reference. Human-readable counterpart to BAM. Contains alignment coordinates, mapping quality, CIGAR strings describing alignment operations, and optional tags for additional metadata.

## Structure

### Header Section (lines starting with `@`)

```
@HD     VN:1.6  SO:coordinate
@SQ     SN:chr1 LN:248956422
@SQ     SN:chr2 LN:242193529
@RG     ID:sample1      SM:sample1      PL:ILLUMINA     LB:lib1
@PG     ID:bwa  PN:bwa  VN:0.7.17       CL:bwa mem -t 8 ref.fa r1.fq r2.fq
```

| Tag | Description |
|-----|-------------|
| `@HD` | Header line (version, sort order) |
| `@SQ` | Reference sequence dictionary |
| `@RG` | Read group |
| `@PG` | Program used |

### Alignment Section

Each line represents one read alignment with 11 mandatory fields:

| Col | Field | Description |
|-----|-------|-------------|
| 1 | QNAME | Read name |
| 2 | FLAG | Bitwise flag (see BAM flags) |
| 3 | RNAME | Reference sequence name |
| 4 | POS | 1-based leftmost mapping position |
| 5 | MAPQ | Mapping quality (Phred-scaled) |
| 6 | CIGAR | Alignment operations |
| 7 | RNEXT | Mate reference name (`=` if same) |
| 8 | PNEXT | Mate position |
| 9 | TLEN | Template length (insert size) |
| 10 | SEQ | Read sequence |
| 11 | QUAL | Base quality (Phred+33) |

### Example

```
@HD	VN:1.6	SO:coordinate
@SQ	SN:chr1	LN:248956422
read001	99	chr1	10000	60	76M	=	10200	276	ACGTACGT...	IIIIIII...	NM:i:0	MD:Z:76
read001	147	chr1	10200	60	76M	=	10000	-276	TGCATGCA...	IIIIIII...	NM:i:1	MD:Z:50A25
```

## CIGAR String

| Op | Description |
|----|-------------|
| `M` | Alignment match (or mismatch) |
| `I` | Insertion to reference |
| `D` | Deletion from reference |
| `N` | Skipped region (intron in RNA-seq) |
| `S` | Soft clipping (present in SEQ) |
| `H` | Hard clipping (not in SEQ) |
| `=` | Sequence match |
| `X` | Sequence mismatch |

Example: `50M2I24M` = 50 matches, 2bp insertion, 24 matches

## Indexing

SAM files are not indexed. Convert to BAM for indexed access:

```bash
samtools view -bS file.sam | samtools sort -o sorted.bam
samtools index sorted.bam
```

## Tools That Create This Format

| Tool | Context |
|------|---------|
| [BWA](../tools/bwa.md) | Default alignment output |
| [Bowtie2](../tools/bowtie2.md) | Default alignment output |
| [HISAT2](../tools/hisat2.md) | Default alignment output |
| [minimap2](../tools/minimap2.md) | With `-a` flag |
| [samtools view](../tools/samtools.md) | BAM → SAM conversion |

## Tools That Read This Format

| Tool | Purpose |
|------|---------|
| [samtools](../tools/samtools.md) | Convert to BAM, filter, stats |
| [Picard](../tools/picard.md) | Validation, metrics |
| [featureCounts](../tools/featurecounts.md) | Read counting |
| [HTSeq-count](../tools/htseq-count.md) | Read counting |

## Notes

- SAM is inefficient for storage — always convert to BAM or CRAM for archival
- Useful for debugging and piping between tools
- Some tools output SAM to stdout for piping: `bwa mem ref.fa r1.fq r2.fq | samtools sort -o sorted.bam`

## See Also

- [BAM](bam.md) — binary, compressed, indexed version
- [CRAM](cram.md) — reference-based compressed version
