# samtools

**Source:** [htslib.org](https://www.htslib.org/)  
**License:** MIT  
**Category:** Alignment processing

## Purpose

Swiss-army knife for manipulating alignments in SAM/BAM/CRAM format. Provides sorting, indexing, filtering, format conversion, statistics, depth calculation, duplicate marking, and merging of aligned sequencing reads. Part of the HTSlib ecosystem (alongside bcftools and tabix). The most frequently-used tool in any NGS pipeline — virtually every analysis involves samtools at multiple stages.

## Installation

```bash
conda install -c bioconda samtools
# or
brew install samtools
```

## Key Commands

| Command      | Description                                         | Typical Pipeline Stage     |
| ------------ | --------------------------------------------------- | -------------------------- |
| `view`       | Convert between SAM/BAM/CRAM, filter by flag/region | Conversion, filtering      |
| `sort`       | Sort alignments by coordinate or read name          | Post-alignment             |
| `index`      | Create .bai/.csi index for coordinate-sorted BAM    | After sorting              |
| `flagstat`   | Quick alignment QC summary                          | QC                         |
| `stats`      | Comprehensive alignment statistics                  | QC                         |
| `idxstats`   | Per-chromosome mapped/unmapped counts               | QC                         |
| `depth`      | Per-base or per-region depth                        | Coverage analysis          |
| `coverage`   | Per-chromosome coverage summary                     | Coverage analysis          |
| `markdup`    | Mark or remove PCR duplicates                       | Pre-variant calling        |
| `merge`      | Merge multiple sorted BAM files                     | Combining runs/lanes       |
| `mpileup`    | Generate pileup for variant calling                 | Variant calling            |
| `faidx`      | Index and extract FASTA sequences                   | Reference management       |
| `fqidx`      | Index and extract FASTQ sequences                   | FASTQ management           |
| `fastq`      | Convert BAM back to FASTQ                           | Re-processing              |
| `collate`    | Group reads by name (without full sort)             | Before fastq extraction    |
| `fixmate`    | Fill in mate coordinates and flags                  | Before markdup             |
| `addreplacerg`| Add or replace read group tags                     | Read group management      |
| `split`      | Split BAM by read group                             | Demultiplexing             |
| `cat`        | Concatenate BAMs (same header)                      | Combining files            |
| `calmd`      | Fill in MD and NM tags                              | Post-processing            |
| `ampliconclip`| Clip primer sequences from amplicon data           | Amplicon workflows         |

## Core Workflow

```text
Aligner (SAM) → sort → index → [markdup] → [filter] → downstream
                  │        │         │           │
              samtools  samtools  samtools   samtools view
               sort     index    markdup     -F/-f flags
```

### The Essential Pipeline

```bash
# Complete post-alignment processing (most common pattern)
samtools sort -@ 8 -o sorted.bam aligned.sam
samtools index sorted.bam

# With duplicate marking (recommended before variant calling)
samtools fixmate -m -@ 8 namesorted.bam fixmate.bam
samtools sort -@ 8 -o sorted.bam fixmate.bam
samtools markdup -@ 8 sorted.bam marked.bam
samtools index marked.bam
```

## samtools view (Conversion & Filtering)

The most versatile subcommand. Handles format conversion and complex read filtering.

### Format Conversion

```bash
# SAM → BAM
samtools view -bS aligned.sam -o aligned.bam

# BAM → CRAM (requires reference)
samtools view -C -T reference.fa aligned.bam -o aligned.cram

# CRAM → BAM
samtools view -b -T reference.fa aligned.cram -o aligned.bam

# BAM → SAM (for inspection)
samtools view -h aligned.bam | head -50
```

### FLAG-Based Filtering

Flags are a bitfield. Use `-f` (require bits set) and `-F` (require bits unset):

```bash
# Keep only properly paired, mapped reads
# Exclude: unmapped (4), mate unmapped (8), secondary (256), 
#          supplementary (2048), duplicate (1024), failed QC (512)
samtools view -b -f 2 -F 0xF0C input.bam -o filtered.bam

# Keep only mapped reads (exclude unmapped)
samtools view -b -F 4 input.bam -o mapped.bam

# Extract only read 1 of pairs
samtools view -b -f 64 input.bam -o read1_only.bam

# Extract only read 2 of pairs
samtools view -b -f 128 input.bam -o read2_only.bam

# Get unmapped reads (for contamination analysis)
samtools view -b -f 4 input.bam -o unmapped.bam

# Get supplementary alignments (chimeric reads)
samtools view -b -f 2048 input.bam -o supplementary.bam
```

### Common FLAG Filter Recipes

| Purpose                                    | Flags                    | Command                      |
| ------------------------------------------ | ------------------------ | ---------------------------- |
| Properly paired, primary, no dups          | `-f 2 -F 0xF0C`         | Standard variant calling     |
| All mapped reads                           | `-F 4`                   | Basic filtering              |
| Primary alignments only                    | `-F 0x900`              | Exclude secondary+supplementary |
| Unique alignments (MAPQ>0)                 | `-F 4 -q 1`             | Remove multi-mappers         |
| High-confidence unique                     | `-f 2 -F 0xF0C -q 20`   | Strict filtering             |

### Region Extraction

```bash
# Extract reads in a specific region (requires index)
samtools view -b input.bam chr1:1000000-2000000 -o region.bam

# Multiple regions
samtools view -b input.bam chr1:1000-2000 chr2:3000-4000 -o regions.bam

# Regions from BED file
samtools view -b -L targets.bed input.bam -o on_target.bam

# Count reads in region (don't output)
samtools view -c input.bam chr1:1000000-2000000
```

### Other view Options

| Option      | Description                                    |
| ----------- | ---------------------------------------------- |
| `-b`        | Output BAM                                     |
| `-C`        | Output CRAM                                    |
| `-h`        | Include header in output                       |
| `-H`        | Output only header                             |
| `-c`        | Count reads (no output)                        |
| `-f INT`    | Require all FLAG bits set                      |
| `-F INT`    | Require all FLAG bits unset                    |
| `-G INT`    | Exclude reads with any FLAG bits set           |
| `-q INT`    | Minimum mapping quality                        |
| `-L FILE`   | Only output reads overlapping BED regions      |
| `-T FILE`   | Reference (for CRAM)                           |
| `-@ INT`    | Additional threads for compression/decompression|
| `-o FILE`   | Output filename                                |
| `-e EXPR`   | Filter expression (samtools 1.12+)             |

### Filter Expressions (samtools 1.12+)

```bash
# Advanced filtering with expressions
samtools view -e 'mapq >= 30 && [NM] <= 3' input.bam -o filtered.bam

# Filter by read group
samtools view -e 'rg == "sample1"' input.bam -o sample1.bam

# Filter by tag value
samtools view -e '[AS] > 100' input.bam -o high_score.bam

# Combine conditions
samtools view -e 'mapq >= 20 && !flag.dup && !flag.secondary' input.bam
```

## samtools sort

```bash
# Coordinate sort (default, required for indexing and most tools)
samtools sort -@ 8 -o sorted.bam input.bam

# Name sort (required for fixmate, some tools like HTSeq)
samtools sort -n -@ 8 -o namesorted.bam input.bam

# Sort with memory limit per thread
samtools sort -@ 8 -m 2G -o sorted.bam input.bam

# Output CRAM directly
samtools sort -@ 8 --output-fmt cram --reference ref.fa -o sorted.cram input.bam

# Sort directly from aligner pipe (avoids intermediate SAM)
bwa mem -t 8 ref.fa reads_R1.fq reads_R2.fq | samtools sort -@ 4 -o sorted.bam
```

| Option   | Description                                     |
| -------- | ----------------------------------------------- |
| `-o`     | Output file                                     |
| `-n`     | Sort by read name                               |
| `-t TAG` | Sort by auxiliary tag value                     |
| `-@`     | Additional threads                              |
| `-m`     | Memory per thread (default 768M)                |
| `-T`     | Temporary file prefix                           |
| `-l`     | Compression level (0-9)                         |

## samtools index

```bash
# Create .bai index (requires coordinate-sorted BAM)
samtools index aligned.sorted.bam

# Create .csi index (for large chromosomes >512Mb, or CRAM)
samtools index -c aligned.sorted.bam

# Multi-threaded indexing (samtools 1.16+)
samtools index -@ 8 aligned.sorted.bam
```

**Critical requirement:** The input BAM **must** be coordinate-sorted. Indexing a name-sorted or unsorted BAM will fail or produce a corrupt index.

## samtools flagstat

Quick alignment summary — first QC check after alignment:

```bash
samtools flagstat aligned.sorted.bam
```

Output:

```text
20000000 + 0 in total (QC-passed reads + QC-failed reads)
200000 + 0 secondary
100000 + 0 supplementary
500000 + 0 duplicates
19500000 + 0 mapped (97.50% : N/A)
19700000 + 0 paired in sequencing
9850000 + 0 read1
9850000 + 0 read2
18800000 + 0 properly paired (95.43% : N/A)
19200000 + 0 with itself and mate mapped
300000 + 0 singletons (1.52% : N/A)
200000 + 0 with mate mapped to a different chr
50000 + 0 with mate mapped to a different chr (mapQ>=5)
```

**Key metrics:**
- `mapped %`: >95% expected for well-prepared DNA WGS
- `properly paired %`: >90% expected. Low = library/alignment issues
- `singletons %`: Should be low (<5%). High = fragmented library
- `duplicates`: Only meaningful after markdup has been run

## samtools stats

Comprehensive statistics (much more detail than flagstat):

```bash
# Full statistics
samtools stats aligned.sorted.bam > stats.txt

# Stats for a specific region
samtools stats aligned.sorted.bam chr1:1000000-2000000 > region_stats.txt

# Plot statistics (produces PDF/PNG)
plot-bamstats -p plots/ stats.txt
```

Key sections in output:

| Section   | Contents                                           |
| --------- | -------------------------------------------------- |
| `SN`      | Summary numbers (total reads, mapped, duplicates)  |
| `FFQ`/`LFQ` | First/last fragment quality per cycle           |
| `GCF`/`GCL` | GC content of first/last fragment               |
| `IS`      | Insert size distribution                           |
| `RL`      | Read length distribution                           |
| `IC`      | Coverage distribution                              |
| `COV`     | Coverage histogram                                 |

## samtools depth

```bash
# Per-base depth (all positions, including zero-coverage)
samtools depth -a aligned.sorted.bam > depth.txt

# Depth for specific regions
samtools depth -b targets.bed aligned.sorted.bam > target_depth.txt

# Mean depth (pipe to awk)
samtools depth -a aligned.sorted.bam | awk '{sum+=$3} END {print sum/NR}'

# Depth with quality filters
samtools depth -Q 20 -q 30 aligned.sorted.bam > hq_depth.txt
```

| Option | Description                              |
| ------ | ---------------------------------------- |
| `-a`   | Output all positions (including 0 depth) |
| `-b`   | BED file of regions                      |
| `-q`   | Minimum base quality                     |
| `-Q`   | Minimum mapping quality                  |
| `-d`   | Maximum depth to report (default 8000)   |
| `-J`   | Include deletions (D) in depth           |

## samtools markdup

Lightweight duplicate marking (alternative to Picard MarkDuplicates):

```bash
# Required pipeline: fixmate (name-sorted) → sort → markdup
samtools sort -n -@ 8 input.bam | \
  samtools fixmate -m -@ 8 - - | \
  samtools sort -@ 8 - | \
  samtools markdup -@ 8 - marked.bam

# With statistics
samtools markdup -s -@ 8 sorted.bam marked.bam 2> markdup_stats.txt

# Remove duplicates instead of just marking
samtools markdup -r -@ 8 sorted.bam deduped.bam
```

**Important:** `fixmate -m` adds mate score tags (ms) required by markdup to choose which duplicate to keep. The pipeline **must** be: name-sort → fixmate → coordinate-sort → markdup.

## samtools faidx (FASTA Index)

```bash
# Index a FASTA (creates .fai)
samtools faidx reference.fa

# Extract a region
samtools faidx reference.fa chr1:1000-2000

# Extract multiple regions
samtools faidx reference.fa chr1:1000-2000 chr2:3000-4000

# Extract entire chromosome
samtools faidx reference.fa chr1 > chr1.fa
```

The `.fai` index is a simple 5-column text file:

```text
chr1  248956422  52  80  81
chr2  242193529  253404903  80  81
```

Columns: name, length, offset (bytes to first base), bases per line, bytes per line.

## samtools fastq (BAM → FASTQ)

```bash
# Extract paired FASTQ from BAM
samtools fastq -@ 8 \
  -1 reads_R1.fastq.gz \
  -2 reads_R2.fastq.gz \
  -0 /dev/null \
  -s /dev/null \
  input.bam

# Collate first (groups read pairs without full name-sort — faster)
samtools collate -u -O input.bam | \
  samtools fastq -@ 8 -1 R1.fq.gz -2 R2.fq.gz -0 /dev/null -s /dev/null -
```

## samtools mpileup

Generate pileup format for variant calling:

```bash
# Basic pileup
samtools mpileup -f reference.fa aligned.sorted.bam > pileup.txt

# With base quality and mapping quality filters
samtools mpileup -f reference.fa -Q 20 -q 30 aligned.sorted.bam

# For bcftools variant calling (pipe directly)
samtools mpileup -f reference.fa aligned.sorted.bam | bcftools call -mv -Oz -o variants.vcf.gz

# Modern alternative (bcftools mpileup replaces samtools mpileup)
bcftools mpileup -f reference.fa aligned.sorted.bam | bcftools call -mv -Oz -o variants.vcf.gz
```

## Performance Tips

### Threading

Most samtools commands support `-@ N` for additional threads:

```bash
# Threading applies to BAM compression/decompression
samtools view -@ 8 -b input.sam -o output.bam
samtools sort -@ 8 -o sorted.bam input.bam
samtools index -@ 8 sorted.bam
samtools merge -@ 8 merged.bam sample1.bam sample2.bam
```

**Note:** `-@ N` specifies **additional** threads (total = N+1). For I/O-bound operations, 4-8 threads is usually sufficient.

### Piping (Avoid Intermediate Files)

```bash
# Align, sort, index in one pipeline
bwa mem -t 8 ref.fa R1.fq R2.fq | \
  samtools sort -@ 4 -o sorted.bam -

samtools index sorted.bam

# Full pipeline: align → fixmate → sort → markdup → index
bwa mem -t 8 ref.fa R1.fq R2.fq | \
  samtools fixmate -m -@ 4 - - | \
  samtools sort -@ 4 - | \
  samtools markdup -@ 4 - marked.bam

samtools index marked.bam
```

### Memory Management

```bash
# Limit memory per thread during sort (prevents OOM on large files)
samtools sort -@ 8 -m 2G -o sorted.bam input.bam
# Total memory ≈ 8 threads × 2GB = 16GB

# Use temp directory on fast storage
samtools sort -@ 8 -T /scratch/tmp/sort input.bam -o sorted.bam
```

## Common Patterns

```bash
# Count mapped reads
samtools view -c -F 4 input.bam

# Count reads in region
samtools view -c input.bam chr1:1000000-2000000

# Get all read groups
samtools view -H input.bam | grep '@RG'

# Check if BAM is sorted
samtools view -H input.bam | grep '@HD' | grep 'SO:'

# Quick coverage estimate (idxstats → mapped reads / genome size)
samtools idxstats input.bam | awk '{mapped+=$3; total+=$2} END {print mapped*150/total "x"}'

# Extract reads for a specific gene (from BED)
echo -e "chr1\t1000\t2000" | samtools view -b -L /dev/stdin input.bam > gene.bam

# Downsample to 10% of reads
samtools view -b -s 0.1 input.bam -o downsampled.bam
```

## Produces

| Output       | Extension     | Description                       |
| ------------ | ------------- | --------------------------------- |
| BAM          | `.bam`        | Binary alignment                  |
| BAM index    | `.bai`/`.csi` | Random access index               |
| CRAM         | `.cram`       | Reference-compressed alignment    |
| CRAM index   | `.crai`       | CRAM random access index          |
| FASTA index  | `.fai`        | FASTA random access index         |
| Pileup       | text          | Per-position read summaries       |
| Statistics   | text          | Alignment metrics                 |

## Related Tools

| Tool                           | Relationship                                |
| ------------------------------ | ------------------------------------------- |
| [bcftools](bcftools.md)        | Variant calling from pileup output          |
| [Picard](picard.md)            | Alternative duplicate marking, metrics      |
| [deepTools](deeptools.md)      | Coverage visualisation from BAM             |
| [tabix](tabix.md)              | Part of same HTSlib ecosystem               |
| [htslib](https://www.htslib.org/) | Underlying C library for BAM/CRAM/VCF   |
