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

## Indexing

### BAI Index (`.bai`)

The standard BAM index. Required for random access (viewing specific regions, variant calling, coverage).

```bash
# Create BAI index (requires coordinate-sorted BAM)
samtools index aligned.sorted.bam
# produces: aligned.sorted.bam.bai

# Alternative: explicit output name
samtools index aligned.sorted.bam aligned.sorted.bai
```

**Limitation:** BAI supports reference sequences up to 2^29 (512 Mb). For larger chromosomes, use CSI.

### CSI Index (`.csi`)

Coordinate-Sorted Index with configurable bin sizes. Required for references with chromosomes >512Mb.

```bash
# Create CSI index
samtools index -c aligned.sorted.bam
# produces: aligned.sorted.bam.csi

# Or specify minimum shift
samtools index -c -m 14 aligned.sorted.bam
```

### Requirements for Indexing

1. BAM must be **coordinate-sorted** (`samtools sort`)
2. Index must be in same directory as BAM (or discoverable)
3. If BAM is modified, index must be regenerated

## Sort Orders

| Sort       | Command                                        | Use Case                      |
| ---------- | ---------------------------------------------- | ----------------------------- |
| Coordinate | `samtools sort input.bam -o sorted.bam`        | Most tools, indexing, viewing |
| Name       | `samtools sort -n input.bam -o namesorted.bam` | htseq-count, some PE tools    |

## Common Operations

```bash
# View BAM header
samtools view -H file.bam

# View reads in region (requires index)
samtools view file.bam chr1:1000000-2000000

# Count reads
samtools view -c file.bam

# Convert BAM to SAM
samtools view -h file.bam > file.sam

# Convert BAM to CRAM
samtools view -C -T reference.fa file.bam > file.cram
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

## See Also

- [SAM](sam.md) — text version (human-readable)
- [CRAM](cram.md) — more compressed (reference-based)
- [FASTQ](fastq.md) — raw reads (pre-alignment)
