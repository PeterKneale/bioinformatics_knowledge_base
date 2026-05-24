# BAM Format (Binary Alignment/Map)

**Extension:** `.bam`  
**Type:** Binary (BGZF-compressed)  
**Specification:** [SAM/BAM Format Specification](https://samtools.github.io/hts-specs/SAMv1.pdf)

## Purpose

Binary, compressed, and indexed representation of SAM alignment data. The standard working format for aligned sequencing reads in virtually all NGS analysis pipelines. Supports random access via index files, enabling fast retrieval of reads in any genomic region.

## Structure

BAM is a BGZF (Blocked GZip Format) compressed binary encoding of SAM. It contains the same information as SAM (header + alignments) but is:
- ~3-5× smaller than SAM
- Supports random access when indexed
- Required by most downstream tools

### BGZF Compression (Key Engineering Detail)

BGZF is a **block-based gzip variant** that enables random access within compressed data — something standard gzip cannot do. This is a critical data structure design for bioinformatics.

**How it works:**

```text
Standard gzip:  [========== one continuous stream ==========]
                 ↑ can only read from start (no random access)

BGZF:           [Block 1][Block 2][Block 3]...[Block N][EOF]
                 ↑ each block ≤ 64 KB compressed
                 ↑ independently decompressible
                 ↑ addressable by (block_offset, within_block_offset)
```

Each BGZF block:
- Is a valid gzip stream (so standard gzip tools can read the whole file)
- Contains at most 64 KB of compressed data (typically 16-64 KB)
- Stores uncompressed size in an extra field (BAM uses this for seeking)

**Virtual File Offset:** A 64-bit address encoding both the block's byte offset in the file (upper 48 bits) and the offset within the uncompressed block (lower 16 bits). This enables any position in the BAM to be addressed with a single 64-bit integer.

```text
Virtual offset = (block_start_offset << 16) | within_block_offset
                  [48 bits: cofpos]            [16 bits: uoffset]
```

**Why this matters:** The BAI index stores virtual file offsets, enabling O(1) seeking to any indexed position without decompressing intermediate blocks.

```bash
# bgzip is NOT regular gzip — it writes block-structured output
bgzip file.sam          # Creates file.sam.gz in BGZF format
# Standard gzip cannot be indexed; bgzip can
```

## Indexing

### BAI Index (`.bai`) — Binning Scheme

The BAI index uses a **hierarchical binning system** inspired by R-trees, enabling fast retrieval of reads overlapping any genomic interval.

**Binning scheme:**

```text
Level 0: 1 bin      covering the entire chromosome (up to 512 Mb)
Level 1: 8 bins     each covering 64 Mb
Level 2: 64 bins    each covering 8 Mb
Level 3: 512 bins   each covering 1 Mb
Level 4: 4096 bins  each covering 128 Kb
Level 5: 32768 bins each covering 16 Kb
```

A read at position `chr1:1,000,000-1,000,150` falls into bins at multiple levels. The index records which BGZF virtual file offsets contain reads for each bin.

**Query algorithm:**
1. Given a query interval [start, end], compute which bins at each level overlap it
2. For each overlapping bin, retrieve the list of BGZF block offsets
3. Seek to the earliest offset and scan reads until past the query region

**Time complexity:** O(log n) to find the relevant bins + O(k) to read k overlapping alignments.

```bash
# Create BAI index (requires coordinate-sorted BAM)
samtools index aligned.sorted.bam
# produces: aligned.sorted.bam.bai

# Alternative: explicit output name
samtools index aligned.sorted.bam aligned.sorted.bai
```

**Limitation:** BAI supports reference sequences up to 2^29 (512 Mb). For larger chromosomes, use CSI.

### CSI Index (`.csi`)

Coordinate-Sorted Index with **configurable bin sizes** (default minimum shift = 14, giving 16 Kb bins at the finest level). Removes the 512 Mb chromosome size limit.

```bash
# Create CSI index
samtools index -c aligned.sorted.bam
# produces: aligned.sorted.bam.csi

# Or specify minimum shift (smaller = finer bins = larger index)
samtools index -c -m 14 aligned.sorted.bam
```

### BAI vs CSI Comparison

| Property         | BAI                | CSI                       |
| ---------------- | ------------------ | ------------------------- |
| Max chrom size   | 512 Mb (2^29)     | 2^(15+min_shift × 5)     |
| Bin structure    | Fixed 6 levels     | Configurable depth        |
| File size        | Smaller            | Slightly larger           |
| Tool support     | Universal          | Most modern tools         |
| When to use      | Human, mouse, etc. | Wheat, axolotl, polyploid |

### Requirements for Indexing

1. BAM must be **coordinate-sorted** (`samtools sort`)
2. Index must be in same directory as BAM (or discoverable via path)
3. If BAM is modified, index must be regenerated
4. Index filename: `file.bam.bai` or `file.bai` (both searched)

## Sort Orders

| Sort       | Command                                        | Use Case                      |
| ---------- | ---------------------------------------------- | ----------------------------- |
| Coordinate | `samtools sort input.bam -o sorted.bam`        | Most tools, indexing, viewing |
| Name       | `samtools sort -n input.bam -o namesorted.bam` | htseq-count, some PE tools    |
| Unsorted   | Raw aligner output                             | Piping between tools          |

**Why coordinate sorting matters:** The binning index assumes records are sorted by position. Duplicate marking also requires coordinate order (to identify reads at identical positions). Name sorting is needed when tools must process both mates of a pair together.

## Binary Record Format

Each BAM alignment record is a binary struct:

```text
┌──────────────────────────────────────────────────────────┐
│ block_size (4 bytes) — total record length                │
├──────────────────────────────────────────────────────────┤
│ refID (4 bytes)     — reference sequence index            │
│ pos (4 bytes)       — 0-based leftmost coordinate         │
│ bin_mq_nl (4 bytes) — bin << 16 | MAPQ << 8 | name_len   │
│ flag_nc (4 bytes)   — FLAG << 16 | n_cigar_ops            │
│ l_seq (4 bytes)     — sequence length                     │
│ next_refID (4 bytes) — mate reference index               │
│ next_pos (4 bytes)  — mate 0-based position               │
│ tlen (4 bytes)      — template length                     │
├──────────────────────────────────────────────────────────┤
│ read_name (variable) — null-terminated string             │
│ cigar (variable)     — packed 4 bytes per CIGAR op        │
│ seq (variable)       — 4-bit encoded (2 bases per byte)   │
│ qual (variable)      — Phred qualities (1 byte per base)  │
│ aux (variable)       — optional TAG:TYPE:VALUE fields      │
└──────────────────────────────────────────────────────────┘
```

**Sequence encoding:** Bases are stored as 4-bit codes (A=1, C=2, G=4, T=8, N=15), packed 2 per byte. This halves storage vs ASCII.

**CIGAR packing:** Each operation is `(op_len << 4) | op_code` in a 32-bit integer. Operations: M=0, I=1, D=2, N=3, S=4, H=5, P=6, =7, X=8.

## Common Operations

```bash
# View BAM header
samtools view -H file.bam

# View reads in region (requires index)
samtools view file.bam chr1:1000000-2000000

# Count reads
samtools view -c file.bam

# Count reads in a region
samtools view -c file.bam chr1:1000000-2000000

# Convert BAM to SAM
samtools view -h file.bam > file.sam

# Convert BAM to CRAM (reference-based compression)
samtools view -C -T reference.fa file.bam > file.cram

# Extract unmapped reads
samtools view -b -f 4 file.bam > unmapped.bam

# Extract properly paired reads only
samtools view -b -f 2 file.bam > proper_pairs.bam

# Merge multiple BAMs
samtools merge merged.bam sample1.bam sample2.bam sample3.bam

# Subsample 10% of reads (useful for testing)
samtools view -bs 42.1 file.bam > subsampled.bam
```

## Tools That Create This Format

| Tool                                        | Context                               |
| ------------------------------------------- | ------------------------------------- |
| [samtools sort](../tools/samtools.md)       | Sorting SAM/BAM by coordinate or name |
| [samtools view](../tools/samtools.md)       | SAM → BAM conversion                  |
| [STAR](../tools/star.md)                    | Direct sorted BAM output              |
| [BWA](../tools/bwa.md) + samtools           | Piped alignment                       |
| [Bowtie2](../tools/bowtie2.md) + samtools   | Piped alignment                       |
| [HISAT2](../tools/hisat2.md) + samtools     | Piped alignment                       |
| [minimap2](../tools/minimap2.md) + samtools | Piped alignment                       |
| [Picard SortSam](../tools/picard.md)        | Sort/convert                          |
| [Picard MarkDuplicates](../tools/picard.md) | Deduplication                         |
| [GATK ApplyBQSR](../tools/gatk.md)          | Recalibrated BAM                      |

## Tools That Read This Format

| Tool                                       | Purpose                    |
| ------------------------------------------ | -------------------------- |
| [samtools](../tools/samtools.md)           | All BAM operations         |
| [Picard](../tools/picard.md)               | Metrics, duplicate marking |
| [GATK](../tools/gatk.md)                   | Variant calling            |
| [bcftools mpileup](../tools/bcftools.md)   | Variant calling            |
| [FreeBayes](../tools/freebayes.md)         | Variant calling            |
| [featureCounts](../tools/featurecounts.md) | Read quantification        |
| [HTSeq-count](../tools/htseq-count.md)     | Read quantification        |
| [deepTools](../tools/deeptools.md)         | Coverage, heatmaps         |
| [bedtools](../tools/bedtools.md)           | Coverage, intersections    |
| [FastQC](../tools/fastqc.md)               | QC from aligned reads      |
| [IGV](https://igv.org/)                    | Visualisation              |

## File Size Estimates

| Data Type            | Approximate BAM Size |
| -------------------- | -------------------- |
| 30× WGS (human)      | ~50-100 GB           |
| RNA-seq (50M reads)  | ~3-5 GB              |
| ChIP-seq (20M reads) | ~1-2 GB              |
| Exome (100× target)  | ~5-10 GB             |

## Performance Considerations

| Operation           | Indexed BAM            | Unindexed BAM              |
| ------------------- | ---------------------- | -------------------------- |
| Region query        | O(log n + k) — fast    | O(n) — must scan all reads |
| Count all reads     | O(n)                   | O(n)                       |
| Random access       | ✓ (via virtual offset) | ✗                          |
| Streaming           | ✓                      | ✓                          |
| Parallel by region  | ✓ (split by intervals) | ✗                          |

**Parallelisation pattern:** Because indexed BAMs support random access by region, many tools process chromosomes or intervals in parallel. This is how GATK's `-L` flag and scatter-gather workflows achieve parallelism.

## See Also

- [SAM](sam.md) — text version (human-readable)
- [CRAM](cram.md) — more compressed (reference-based)
- [FASTQ](fastq.md) — raw reads (pre-alignment)
- [Alignment process](../processes/alignment.md) — how BAM files are produced
