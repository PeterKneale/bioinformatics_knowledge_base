# CRAM Format

**Extension:** `.cram`  
**Type:** Binary (reference-based compression)  
**Specification:** [CRAM Format Specification](https://samtools.github.io/hts-specs/CRAMv3.pdf)

## Purpose

Highly compressed alignment format that uses reference-based compression to achieve 30-60% size reduction compared to BAM. Stores only the differences between reads and the reference genome, making it ideal for long-term archival of sequencing data.

## Structure

CRAM encodes alignment data by:
1. Storing differences from reference rather than full sequences
2. Using columnar storage (fields compressed separately)
3. Supporting multiple codecs (gzip, bzip2, lzma, rans)
4. Embedding reference sequence checksums for integrity

## Indexing

### CRAI Index (`.crai`)

CRAM index file enables random access by genomic region.

```bash
# Create CRAI index
samtools index aligned.cram
# produces: aligned.cram.crai
```

### Requirements

1. CRAM must be coordinate-sorted
2. Reference FASTA must be available (for reading)
3. Reference must match the one used during CRAM creation

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
```

## Reading CRAM

```bash
# View CRAM (requires reference)
samtools view -T reference.fa aligned.cram

# View specific region
samtools view -T reference.fa aligned.cram chr1:1000000-2000000

# Convert CRAM back to BAM
samtools view -b -T reference.fa aligned.cram -o converted.bam

# Use REF_PATH environment for reference cache
export REF_PATH=/path/to/ref_cache/%2s/%2s/%s
samtools view aligned.cram chr1:1000-2000
```

## Reference Management

CRAM files require the original reference to decode. Set up reference paths:

```bash
# Set reference cache directory
export REF_PATH="$HOME/.cache/hts-ref/%2s/%2s/%s"
export REF_CACHE="$HOME/.cache/hts-ref/%2s/%2s/%s"

# Or specify per-command
samtools view -T reference.fa file.cram
```

## Compression Comparison

| Format | Relative Size | Random Access | Reference Needed |
|--------|--------------|---------------|------------------|
| SAM | 100% (baseline) | No | No |
| BAM | ~25-30% | Yes (.bai/.csi) | No |
| CRAM | ~15-20% | Yes (.crai) | Yes (for decode) |

## Tools That Create This Format

| Tool | Context |
|------|---------|
| [samtools view -C](../tools/samtools.md) | BAM/SAM → CRAM conversion |
| [samtools sort](../tools/samtools.md) | Direct CRAM output |

## Tools That Read This Format

| Tool | Purpose |
|------|---------|
| [samtools](../tools/samtools.md) | All alignment operations |
| [GATK](../tools/gatk.md) | Variant calling |
| [Picard](../tools/picard.md) | Metrics and validation |
| [IGV](https://igv.org/) | Visualisation |

## When to Use CRAM

- Long-term archival storage (space savings significant at scale)
- Submitting to public repositories (EBI/ENA prefers CRAM)
- When reference genome is stable and available

## When to Use BAM Instead

- Active analysis (avoid reference dependency)
- Pipelines where reference may not be readily available
- When compatibility with older tools is needed

## See Also

- [BAM](bam.md) — standard working format
- [SAM](sam.md) — human-readable text format
