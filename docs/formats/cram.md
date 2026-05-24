# CRAM Format

**Extension:** `.cram`  
**Type:** Binary (reference-based compression)  
**Specification:** [CRAM Format Specification v3.1](https://samtools.github.io/hts-specs/CRAMv3.pdf)

## Purpose

Highly compressed alignment format that uses **reference-based compression** to achieve 30-60% size reduction compared to BAM. Instead of storing full read sequences, CRAM stores only the differences (edits) from the reference genome, exploiting the fact that most aligned bases match the reference. Ideal for long-term archival and large-scale genomics projects where storage costs dominate.

## Compression Strategy

### Reference-Based Compression (Key Insight)

For a typical 30× WGS dataset aligned to a reference genome:
- ~99% of aligned bases match the reference
- Only mismatches, insertions, and soft-clipped bases need explicit storage
- Sequences can be reconstructed on-the-fly from: reference + position + edit operations

```text
BAM stores:   ACGTACGTACGTACGTACGT  (full sequence — 20 bytes)
CRAM stores:  pos=1000, CIGAR=20M, edits=[pos7:A→T]  (~5 bytes)
              + reference genome provides the rest
```

### Column-Oriented Storage

Unlike BAM (which stores all fields of a record together), CRAM uses **columnar storage** — grouping the same field across many records for better compression:

```text
BAM layout (row-oriented):
  [read1: name, flag, pos, cigar, seq, qual]
  [read2: name, flag, pos, cigar, seq, qual]
  ...

CRAM layout (column-oriented):
  Container:
    [all positions: 1000, 1001, 1005, ...]    ← delta-encoded, compresses well
    [all flags: 99, 147, 99, ...]              ← run-length encoded
    [all quality scores: IIII..., HHHH..., ...] ← separate codec
    [all edits: ...]                           ← sparse, compresses well
```

Each column can use the **optimal codec** for its data type:
- Positions → delta + variable-length integer encoding
- Quality scores → Huffman or rANS coding
- Sequence differences → sparse representation
- Read names → can be discarded if not needed

### Codec Options

| Codec          | Best For                    | Speed | Compression |
| -------------- | --------------------------- | ----- | ----------- |
| gzip           | General purpose             | Fast  | Good        |
| bzip2          | Sequences, quality scores   | Slow  | Better      |
| lzma           | Maximum compression         | Slowest | Best      |
| rANS (order-0) | Quality scores, flags      | Fast  | Good        |
| rANS (order-1) | Quality scores with context| Medium | Better     |

## Structure

### File Layout

```text
┌─────────────────────────────────────┐
│ File Header                          │  Magic number, version, reference info
├─────────────────────────────────────┤
│ Container 1                          │  Typically one per reference sequence
│   ├── Container Header               │  Reference, position range, record count
│   ├── Compression Header             │  Codec definitions for each data series
│   ├── Slice 1                        │  Subset of records (for parallelism)
│   │     ├── Slice Header             │
│   │     ├── Core Block (bitstream)   │  Flags, positions, CIGAR (compressed)
│   │     └── External Blocks          │  Qualities, names, tags (per-codec)
│   ├── Slice 2                        │
│   └── ...                            │
├─────────────────────────────────────┤
│ Container 2                          │
│   └── ...                            │
├─────────────────────────────────────┤
│ EOF Container (empty)                │  Signals clean file termination
└─────────────────────────────────────┘
```

### Key Design Decisions

| Decision                    | Rationale                                              |
| --------------------------- | ------------------------------------------------------ |
| Reference-based             | Most bases match reference — store diffs only           |
| Columnar                    | Same data type compresses better together               |
| Slicing                     | Enables parallel encode/decode                          |
| Multiple codecs             | Optimal compression per data series                     |
| Embedded reference checksums | Detect reference mismatch at read time                 |
| Optional quality omission   | Quality scores are often >50% of BAM size              |

## Indexing

### CRAI Index (`.crai`)

CRAM index file enables random access by genomic region. Similar concept to BAI but indexes containers/slices rather than BGZF blocks.

```bash
# Create CRAI index
samtools index aligned.cram
# produces: aligned.cram.crai
```

### Requirements

1. CRAM must be coordinate-sorted
2. Reference FASTA must be available (for reading/decoding)
3. Reference must match the one used during CRAM creation (checksums verified)

## Creating CRAM

```bash
# Convert BAM to CRAM
samtools view -C -T reference.fa sorted.bam -o aligned.cram

# Convert SAM to CRAM
samtools view -C -T reference.fa aligned.sam -o aligned.cram

# Sort and convert in one step
samtools sort --output-fmt cram --reference reference.fa input.sam -o sorted.cram

# Index the CRAM
samtools index aligned.cram

# Lossy compression (discard quality scores for massive savings)
samtools view -C -T reference.fa --output-fmt-option lossy_names=1 sorted.bam -o lossy.cram
```

## Reading CRAM

```bash
# View CRAM (requires reference)
samtools view -T reference.fa aligned.cram

# View specific region
samtools view -T reference.fa aligned.cram chr1:1000000-2000000

# Convert CRAM back to BAM
samtools view -b -T reference.fa aligned.cram -o converted.bam

# Use REF_PATH environment for reference cache (recommended for production)
export REF_PATH=/path/to/ref_cache/%2s/%2s/%s
samtools view aligned.cram chr1:1000-2000
```

## Reference Management

CRAM files **require the original reference** to decode sequences. Without it, reads cannot be reconstructed.

### Reference Cache

For production environments, set up a reference cache to avoid specifying `-T` every time:

```bash
# Set reference cache directory (MD5-based directory structure)
export REF_PATH="$HOME/.cache/hts-ref/%2s/%2s/%s"
export REF_CACHE="$HOME/.cache/hts-ref/%2s/%2s/%s"

# Populate cache from a FASTA (creates MD5-named sequence files)
seq_cache_populate.pl -root $HOME/.cache/hts-ref reference.fa

# Or specify per-command
samtools view -T reference.fa file.cram
```

### EBI Reference Server

For publicly deposited data, htslib can fetch reference sequences from EBI's CRAM reference server:

```bash
export REF_PATH="https://www.ebi.ac.uk/ena/cram/md5/%s"
# Now samtools can decode CRAMs without a local reference copy
```

## Compression Comparison

| Format | Relative Size   | Random Access   | Reference Needed | Quality Stored |
| ------ | --------------- | --------------- | ---------------- | -------------- |
| SAM    | 100% (baseline) | No              | No               | Yes            |
| BAM    | ~25-30%         | Yes (.bai/.csi) | No               | Yes            |
| CRAM   | ~15-20%         | Yes (.crai)     | Yes (for decode) | Yes            |
| CRAM (no qual) | ~5-8%  | Yes (.crai)     | Yes              | No (lossy)     |

### Where the Space Goes (Typical 30× WGS BAM)

| Component          | % of BAM | CRAM Approach                          |
| ------------------ | --------- | -------------------------------------- |
| Quality scores     | ~55%      | rANS encoding (or discard for archival)|
| Sequence bases     | ~25%      | Reference-based (store diffs only)     |
| Read names         | ~10%      | Can be discarded or compressed         |
| Aux tags           | ~5%       | Column-grouped compression             |
| Overhead           | ~5%       | Improved with columnar layout          |

## Tools That Create This Format

| Tool                                     | Context                   |
| ---------------------------------------- | ------------------------- |
| [samtools view -C](../tools/samtools.md) | BAM/SAM → CRAM conversion |
| [samtools sort](../tools/samtools.md)    | Direct CRAM output        |
| Illumina DRAGEN                          | Direct CRAM from aligner  |

## Tools That Read This Format

| Tool                             | Purpose                  |
| -------------------------------- | ------------------------ |
| [samtools](../tools/samtools.md) | All alignment operations |
| [GATK](../tools/gatk.md)         | Variant calling          |
| [Picard](../tools/picard.md)     | Metrics and validation   |
| [deepTools](../tools/deeptools.md) | Coverage, heatmaps     |
| [IGV](https://igv.org/)          | Visualisation            |

## When to Use CRAM

- **Long-term archival storage** — space savings significant at scale (e.g., UK Biobank stores ~500,000 WGS as CRAM)
- **Submitting to public repositories** — EBI/ENA prefers CRAM; NCBI SRA accepts it
- **When reference genome is stable** — GRCh38 is mature and widely available
- **Cost-sensitive storage** — at scale, 40% savings on petabytes is substantial

## When to Use BAM Instead

- **Active analysis** — avoid reference dependency during iterative workflows
- **Pipeline compatibility** — some older tools don't support CRAM
- **When reference may not be readily available** — e.g., custom/unpublished assemblies
- **Speed-critical workloads** — CRAM decode is slightly slower than BAM

## See Also

- [BAM](bam.md) — standard working format (faster, no reference needed)
- [SAM](sam.md) — human-readable text format
- [Alignment process](../processes/alignment.md) — how alignment files are produced
