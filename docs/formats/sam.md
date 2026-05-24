# SAM Format (Sequence Alignment/Map)

**Extension:** `.sam`  
**Type:** Text (tab-delimited)  
**Specification:** [SAM/BAM Format Specification](https://samtools.github.io/hts-specs/SAMv1.pdf)

## Purpose

Tab-delimited text format for storing aligned sequencing reads against a reference. Human-readable counterpart to BAM. Contains alignment coordinates, mapping quality, CIGAR strings describing alignment operations, and optional tags for additional metadata. SAM is the lingua franca between aligners and downstream tools — every aligner emits SAM/BAM.

## Structure

### Header Section (lines starting with `@`)

```tsv
@HD	VN:1.6	SO:coordinate
@SQ	SN:chr1	LN:248956422
@SQ	SN:chr2	LN:242193529
@RG	ID:sample1	SM:sample1	PL:ILLUMINA	LB:lib1
@PG	ID:bwa	PN:bwa	VN:0.7.17	CL:bwa mem -t 8 ref.fa r1.fq r2.fq
```

| Tag   | Description                       | Key Fields                                       |
| ----- | --------------------------------- | ------------------------------------------------ |
| `@HD` | Header line (version, sort order) | `VN` (version), `SO` (sort order)                |
| `@SQ` | Reference sequence dictionary     | `SN` (name), `LN` (length) — one per chromosome |
| `@RG` | Read group                        | `ID`, `SM` (sample), `PL` (platform), `LB` (library) |
| `@PG` | Program record                    | `ID`, `PN` (name), `VN` (version), `CL` (command line) |

**`@RG` is critical:** GATK and most variant callers require every read to belong to a read group. The `SM` field determines which sample each read belongs to. Multiple libraries/runs for the same sample share the same `SM` value.

### Alignment Section

Each line represents one read alignment with **11 mandatory fields** followed by optional TAG fields:

| Col | Field | Type   | Description                             |
| --- | ----- | ------ | --------------------------------------- |
| 1   | QNAME | String | Read name (query template name)         |
| 2   | FLAG  | Int    | Bitwise flag (see below)                |
| 3   | RNAME | String | Reference sequence name (chromosome)    |
| 4   | POS   | Int    | 1-based leftmost mapping position       |
| 5   | MAPQ  | Int    | Mapping quality (0-255)                 |
| 6   | CIGAR | String | Alignment operations (see below)        |
| 7   | RNEXT | String | Mate reference name (`=` if same, `*` if unavailable) |
| 8   | PNEXT | Int    | Mate position (0 if unavailable)        |
| 9   | TLEN  | Int    | Template length (insert size, signed)   |
| 10  | SEQ   | String | Read sequence (`*` if not stored)       |
| 11  | QUAL  | String | Base quality (Phred+33, `*` if unavailable) |

### Example

```tsv
@HD	VN:1.6	SO:coordinate
@SQ	SN:chr1	LN:248956422
read001	99	chr1	10000	60	76M	=	10200	276	ACGTACGT...	IIIIIII...	NM:i:0	MD:Z:76	RG:Z:sample1
read001	147	chr1	10200	60	76M	=	10000	-276	TGCATGCA...	IIIIIII...	NM:i:1	MD:Z:50A25	RG:Z:sample1
```

The two lines above are a **properly paired** read pair — same QNAME, complementary FLAGs (99 = first/forward/paired, 147 = second/reverse/paired), and opposite TLEN signs.

## FLAG Field (Bitwise)

The FLAG is an unsigned 16-bit integer where each bit encodes a property. Multiple properties combine via bitwise OR.

| Bit    | Hex    | Dec  | Meaning                           | Set when...                           |
| ------ | ------ | ---- | --------------------------------- | ------------------------------------- |
| 0x1    | 0x1    | 1    | Read is paired                    | Paired-end sequencing                 |
| 0x2    | 0x2    | 2    | Read mapped in proper pair        | Both mates align with expected insert |
| 0x4    | 0x4    | 4    | Read unmapped                     | No valid alignment found              |
| 0x8    | 0x8    | 8    | Mate unmapped                     | Mate has no valid alignment           |
| 0x10   | 0x10   | 16   | Read on reverse strand            | Aligned to reverse complement         |
| 0x20   | 0x20   | 32   | Mate on reverse strand            | Mate aligned to reverse complement    |
| 0x40   | 0x40   | 64   | First in pair (R1)                | Read 1 of the pair                    |
| 0x80   | 0x80   | 128  | Second in pair (R2)               | Read 2 of the pair                    |
| 0x100  | 0x100  | 256  | Secondary alignment               | Not the primary (best) alignment      |
| 0x200  | 0x200  | 512  | Failed quality checks             | Vendor quality filter failed          |
| 0x400  | 0x400  | 1024 | PCR or optical duplicate          | Marked by MarkDuplicates/markdup      |
| 0x800  | 0x800  | 2048 | Supplementary alignment           | Part of a chimeric alignment          |

### Common FLAG Values

| FLAG | Binary         | Meaning                                               |
| ---- | -------------- | ----------------------------------------------------- |
| 77   | 0000 0100 1101 | R1, paired, both unmapped                             |
| 83   | 0000 0101 0011 | R1, properly paired, mapped reverse                   |
| 99   | 0000 0110 0011 | R1, properly paired, mate reverse                     |
| 141  | 0000 1000 1101 | R2, paired, both unmapped                             |
| 147  | 0000 1001 0011 | R2, properly paired, mapped reverse                   |
| 163  | 0000 1010 0011 | R2, properly paired, mate reverse                     |
| 2048 | 1000 0000 0000 | Supplementary alignment (chimeric/split read)          |

### Filtering by FLAG

```bash
# -f: INCLUDE reads with ALL these bits set
# -F: EXCLUDE reads with ANY of these bits set

# Properly paired reads only (require bit 0x2)
samtools view -f 2 input.bam

# Exclude unmapped + secondary + duplicate + supplementary
samtools view -F 0xF04 input.bam
# 0xF04 = 0x4 + 0x100 + 0x400 + 0x800 = 4 + 256 + 1024 + 2048 = 3844

# Only R1 reads (for strand-specific counting)
samtools view -f 0x40 input.bam

# Only uniquely mapped (exclude MAPQ 0) and non-duplicate
samtools view -F 0x400 -q 1 input.bam

# Explain a FLAG value (use samtools flags utility)
samtools flags 99
# 0x63  99  PAIRED,PROPER_PAIR,MREVERSE,READ1
```

**Online tool:** [Picard Explain Flags](https://broadinstitute.github.io/picard/explain-flags.html) — interactive FLAG decoder.

## CIGAR String

The CIGAR (Compact Idiosyncratic Gapped Alignment Report) string is a run-length encoding of alignment operations:

| Op  | Consumes Query | Consumes Reference | Description                               |
| --- | -------------- | ------------------ | ----------------------------------------- |
| `M` | Yes            | Yes                | Alignment match (match OR mismatch)       |
| `I` | Yes            | No                 | Insertion to reference                    |
| `D` | No             | Yes                | Deletion from reference                   |
| `N` | No             | Yes                | Skipped region (intron in RNA-seq)        |
| `S` | Yes            | No                 | Soft clip (bases present in SEQ but not aligned) |
| `H` | No             | No                 | Hard clip (bases not in SEQ)              |
| `=` | Yes            | Yes                | Sequence match (exact)                    |
| `X` | Yes            | Yes                | Sequence mismatch                         |
| `P` | No             | No                 | Padding (for multiple alignment)          |

### CIGAR Arithmetic

```text
CIGAR: 30M2I50M3D20M48S
       ──── ── ──── ── ──── ────
       30bp  2bp 50bp    20bp 48bp   ← query (SEQ) bases consumed: 30+2+50+20+48 = 150
       30bp      50bp 3bp 20bp       ← reference bases consumed: 30+50+3+20 = 103
                                      ← alignment length on reference = 103
```

**Calculating reference span:** Sum of all operations that consume reference (M, D, N, =, X).

**RNA-seq intron:** `75M50000N75M` — 75 bases aligned, 50kb intron skip, 75 bases aligned. The `N` operation is what makes RNA-seq aligners "splice-aware."

### Examples

| CIGAR         | Meaning                                              |
| ------------- | ---------------------------------------------------- |
| `150M`        | Perfect 150bp alignment                              |
| `100M50S`     | 100bp aligned, 50bp soft-clipped at 3' end          |
| `30S120M`     | 30bp soft-clipped at 5' end, 120bp aligned          |
| `75M1I74M`    | 1bp insertion at position 75                         |
| `50M2D100M`   | 2bp deletion at position 50                          |
| `75M5000N75M` | Exon-intron-exon (RNA-seq splice junction)           |
| `50M1X99M`    | Explicit mismatch at position 50 (if = and X used)  |

## MAPQ (Mapping Quality)

MAPQ encodes the probability the reported alignment position is wrong:

$$\text{MAPQ} = -10 \log_{10}(P[\text{position is wrong}])$$

| MAPQ | P(wrong) | Meaning                                             |
| ---- | --------- | --------------------------------------------------- |
| 0    | 1.0       | Aligns equally well to multiple locations           |
| 1    | ~0.8      | Slightly better than random                         |
| 10   | 0.1       | 90% confidence                                      |
| 20   | 0.01      | 99% confidence — common filtering threshold         |
| 30   | 0.001     | High confidence                                     |
| 42   | ~0.00006  | BWA-MEM cap for unique alignments                   |
| 60   | 10⁻⁶      | BWA maximum (effectively unique)                    |
| 255  | N/A       | STAR uses 255 for uniquely mapped reads             |

**MAPQ = 0 does NOT mean unmapped.** It means the read mapped, but equally well to multiple places (multimapper). Unmapped reads have FLAG bit 0x4 set.

## TLEN (Template Length / Insert Size)

TLEN represents the inferred size of the original DNA fragment:

```text
Reference:  ────────────────────────────────────────────────
Read 1:     ████████████████→              (POS = 1000, len = 150)
Read 2:              ←████████████████     (POS = 1200, len = 150)
            |←────── TLEN = 350 ──────→|
```

- Positive for the leftmost read, negative for the rightmost
- Includes the reads themselves: `TLEN = rightmost_end - leftmost_start`
- Typical range for Illumina: 200-600 bp

## Optional Tags

Tags follow the 11 mandatory fields as `TAG:TYPE:VALUE` triples:

| Tag    | Type | Description                           | Set By           |
| ------ | ---- | ------------------------------------- | ---------------- |
| `NM:i` | int  | Edit distance to reference            | Aligner          |
| `MD:Z` | str  | Mismatching positions/bases           | Aligner          |
| `AS:i` | int  | Alignment score                       | Aligner          |
| `XS:i` | int  | Suboptimal alignment score            | BWA/Bowtie2      |
| `RG:Z` | str  | Read group                            | Aligner (`-R`)   |
| `NH:i` | int  | Number of reported alignments         | STAR/HISAT2      |
| `HI:i` | int  | Hit index (which of NH alignments)    | STAR/HISAT2      |
| `SA:Z` | str  | Supplementary alignment info (chimeric) | Aligner        |
| `MC:Z` | str  | CIGAR of mate                         | samtools fixmate |
| `MQ:i` | int  | Mapping quality of mate               | Aligner          |

### Tag Types

| Code | Type                 | Example         |
| ---- | -------------------- | --------------- |
| `i`  | Signed integer       | `NM:i:3`        |
| `f`  | Float                | `AS:f:98.5`     |
| `Z`  | String               | `RG:Z:sample1`  |
| `H`  | Hex string           | `BC:H:ACGT`     |
| `A`  | Character            | `XS:A:+`        |
| `B`  | Array (int or float) | `BQ:B:i,0,1,2`  |

## Indexing

SAM files are **not indexed** — convert to BAM for indexed access:

```bash
# Direct conversion + sort + index pipeline
samtools view -bS file.sam | samtools sort -o sorted.bam
samtools index sorted.bam

# Or one-liner from aligner
bwa mem ref.fa r1.fq r2.fq | samtools sort -o sorted.bam && samtools index sorted.bam
```

## Coordinate System

SAM uses **1-based, inclusive** coordinates for POS:
- POS = 1 means the first base of the reference
- This differs from BAM internal representation (0-based)
- Matches VCF and GFF/GTF coordinate system

## Tools That Create This Format

| Tool                                  | Context                  |
| ------------------------------------- | ------------------------ |
| [BWA](../tools/bwa.md)                | Default alignment output |
| [Bowtie2](../tools/bowtie2.md)        | Default alignment output |
| [HISAT2](../tools/hisat2.md)          | Default alignment output |
| [minimap2](../tools/minimap2.md)      | With `-a` flag           |
| [samtools view](../tools/samtools.md) | BAM → SAM conversion     |

## Tools That Read This Format

| Tool                                       | Purpose                       |
| ------------------------------------------ | ----------------------------- |
| [samtools](../tools/samtools.md)           | Convert to BAM, filter, stats |
| [Picard](../tools/picard.md)               | Validation, metrics           |
| [featureCounts](../tools/featurecounts.md) | Read counting                 |
| [HTSeq-count](../tools/htseq-count.md)     | Read counting                 |

## Notes

- SAM is inefficient for storage — always convert to BAM or CRAM for archival and analysis
- Useful for debugging (human-readable) and piping between tools
- Most aligners emit SAM to stdout; pipe directly to `samtools sort` to avoid writing SAM to disk:
  ```bash
  bwa mem ref.fa r1.fq r2.fq | samtools sort -o sorted.bam
  ```

## See Also

- [BAM](bam.md) — binary, compressed, indexed version
- [CRAM](cram.md) — reference-based compressed version
- [Alignment process](../processes/alignment.md) — how SAM/BAM files are produced
