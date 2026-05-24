# STAR (Spliced Transcripts Alignment to a Reference)

**Source:** [github.com/alexdobin/STAR](https://github.com/alexdobin/STAR)  
**License:** MIT  
**Category:** RNA-seq alignment

## Purpose

Ultrafast RNA-seq aligner that handles spliced alignments across exon-exon junctions. Designed for mapping RNA-seq reads to a reference genome while discovering novel splice junctions. Also supports gene quantification (`--quantMode`), chimeric alignment detection for fusion gene discovery, and WASP filtering for allele-specific expression. The default aligner for most RNA-seq pipelines when memory is not a constraint.

## Installation

```bash
conda install -c bioconda star
```

## Algorithm

### Seed Finding (Maximal Mappable Prefix)

STAR uses a **suffix array** (SA) based approach to find seeds:

```text
Read:    ACGTACGT|NNNNNNNN|ACGTACGT     (spans a splice junction)
         ^^^^^^^^           ^^^^^^^^
         Seed 1             Seed 2

1. Find the Maximal Mappable Prefix (MMP) — longest prefix that aligns to genome
2. If MMP < full read → unmapped suffix is a new seed candidate
3. Repeat until all seeds found or read exhausted
4. Seeds on different chromosomes/strands → cluster and score
```

This approach naturally discovers splice junctions: when a read spans an intron, the first half maps to one exon and the second half maps to the next exon.

### Stitching and Scoring

After seed finding, STAR stitches seeds into full alignments:

1. **Cluster** seeds by proximity in genome space
2. **Score** combinations considering:
   - Number of mismatches
   - Splice junction signals (GT-AG canonical = bonus)
   - Gap penalty for introns
   - Concordance with known annotations
3. **Report** the best-scoring alignment(s)

### Two-Pass Mode

```text
Pass 1:  Align all reads → discover novel splice junctions
Pass 2:  Re-build genome index including novel junctions → re-align all reads

Result:  More sensitive detection of rare/novel splice events
         ~1% more reads mapped at junctions
```

## Key Operations

| Mode                        | Description                                   |
| --------------------------- | --------------------------------------------- |
| `--runMode genomeGenerate`  | Build genome index with annotation            |
| `--runMode alignReads`      | Align RNA-seq reads (default)                 |
| `--quantMode GeneCounts`    | Quantify gene expression during alignment     |
| `--quantMode TranscriptomeSAM` | Output transcriptome-aligned BAM (for RSEM)|
| `--chimSegmentMin`          | Enable chimeric/fusion detection              |
| `--twopassMode Basic`       | Two-pass mapping for novel junction discovery |

## Key Options

### Genome Generation

| Option                    | Description                                       | Recommendation          |
| ------------------------- | ------------------------------------------------- | ----------------------- |
| `--genomeDir`             | Output directory for index                        | Required                |
| `--genomeFastaFiles`      | Reference FASTA file(s)                           | Required                |
| `--sjdbGTFfile`           | GTF annotation (highly recommended)               | Always provide          |
| `--sjdbOverhang`          | ReadLength - 1 (for splice junction DB)           | 100 for most cases      |
| `--runThreadN`            | Number of threads                                 | 8-16                    |
| `--genomeSAindexNbases`   | SA index granularity (reduce for small genomes)   | 14 (default), lower for small |

### Alignment

| Option                     | Description                                   | Default     |
| -------------------------- | --------------------------------------------- | ----------- |
| `--genomeDir`              | Path to genome index                          | Required    |
| `--readFilesIn`            | Input FASTQ file(s) (R1 R2 for PE)           | Required    |
| `--readFilesCommand`       | Decompression command (zcat for .gz)          | —           |
| `--outSAMtype`             | Output format: BAM SortedByCoordinate         | SAM         |
| `--outSAMattributes`       | SAM tags to include                           | Standard    |
| `--runThreadN`             | Number of threads                             | 1           |
| `--outFileNamePrefix`      | Output file prefix                            | ./          |
| `--twopassMode`            | Basic = 2-pass within single STAR run         | None        |
| `--quantMode`              | GeneCounts and/or TranscriptomeSAM            | —           |
| `--chimSegmentMin`         | Min segment length for chimeric detection     | 0 (disabled)|
| `--outFilterMultimapNmax`  | Max number of multi-map loci                  | 10          |
| `--outFilterMismatchNmax`  | Max mismatches per pair                       | 10          |
| `--alignIntronMin`         | Minimum intron size                           | 21          |
| `--alignIntronMax`         | Maximum intron size                           | 0 (from GTF)|
| `--alignSJoverhangMin`     | Min overhang for unannotated junctions        | 8           |
| `--alignSJDBoverhangMin`   | Min overhang for annotated junctions          | 1           |
| `--outSAMstrandField`      | Add XS strand tag (for Cufflinks)             | None        |
| `--waspOutputMode`         | WASP allele-specific filtering                | None        |

### Recommended SAM Attributes

```bash
--outSAMattributes NH HI AS NM MD nM jM jI XS
```

| Tag  | Meaning                                    |
| ---- | ------------------------------------------ |
| NH   | Number of hits (multi-mapping)             |
| HI   | Hit index (which alignment is this)        |
| AS   | Alignment score                            |
| NM   | Edit distance                              |
| MD   | Mismatch detail string                     |
| nM   | Number of mismatches per mate              |
| jM   | Junction type per splice (annotated/novel) |
| jI   | Intron coordinates                         |
| XS   | Strand of splice junction (for Cufflinks)  |

## Usage Examples

```bash
# Generate genome index (requires ~30GB RAM for human)
STAR --runMode genomeGenerate \
  --genomeDir star_index/ \
  --genomeFastaFiles reference.fa \
  --sjdbGTFfile annotation.gtf \
  --sjdbOverhang 100 \
  --runThreadN 8

# Basic paired-end alignment (sorted BAM output)
STAR --runMode alignReads \
  --genomeDir star_index/ \
  --readFilesIn reads_R1.fastq.gz reads_R2.fastq.gz \
  --readFilesCommand zcat \
  --outSAMtype BAM SortedByCoordinate \
  --outSAMattributes NH HI AS NM MD \
  --runThreadN 8 \
  --outFileNamePrefix sample1_

# Alignment with gene quantification (replaces featureCounts for simple cases)
STAR --genomeDir star_index/ \
  --readFilesIn reads_R1.fastq.gz reads_R2.fastq.gz \
  --readFilesCommand zcat \
  --outSAMtype BAM SortedByCoordinate \
  --quantMode GeneCounts \
  --runThreadN 8 \
  --outFileNamePrefix sample1_

# Two-pass mode (better novel junction sensitivity)
STAR --genomeDir star_index/ \
  --readFilesIn reads_R1.fastq.gz reads_R2.fastq.gz \
  --readFilesCommand zcat \
  --outSAMtype BAM SortedByCoordinate \
  --twopassMode Basic \
  --runThreadN 8 \
  --outFileNamePrefix sample1_

# Fusion gene detection (for STAR-Fusion downstream)
STAR --genomeDir star_index/ \
  --readFilesIn reads_R1.fastq.gz reads_R2.fastq.gz \
  --readFilesCommand zcat \
  --outSAMtype BAM SortedByCoordinate \
  --chimSegmentMin 12 \
  --chimJunctionOverhangMin 8 \
  --chimOutType Junctions WithinBAM SoftClip \
  --chimOutJunctionFormat 1 \
  --runThreadN 8 \
  --outFileNamePrefix fusion_

# Output transcriptome-aligned BAM (for RSEM quantification)
STAR --genomeDir star_index/ \
  --readFilesIn reads_R1.fastq.gz reads_R2.fastq.gz \
  --readFilesCommand zcat \
  --outSAMtype BAM SortedByCoordinate \
  --quantMode TranscriptomeSAM \
  --runThreadN 8

# ENCODE recommended settings (strict but reproducible)
STAR --genomeDir star_index/ \
  --readFilesIn reads_R1.fastq.gz reads_R2.fastq.gz \
  --readFilesCommand zcat \
  --outSAMtype BAM SortedByCoordinate \
  --outSAMattributes NH HI AS NM MD nM jM jI XS \
  --twopassMode Basic \
  --outFilterMultimapNmax 20 \
  --alignSJoverhangMin 8 \
  --alignSJDBoverhangMin 1 \
  --outFilterMismatchNmax 999 \
  --outFilterMismatchNoverReadLmax 0.04 \
  --alignIntronMin 20 \
  --alignIntronMax 1000000 \
  --alignMatesGapMax 1000000 \
  --runThreadN 8
```

### Small Genome Index

For small genomes (bacteria, viruses), reduce SA index size:

```bash
# Compute: min(14, floor(log2(GenomeLength)/2 - 1))
# E.g., 5Mb genome: floor(log2(5000000)/2 - 1) = floor(11.1) = 11

STAR --runMode genomeGenerate \
  --genomeDir small_genome_index/ \
  --genomeFastaFiles small_genome.fa \
  --genomeSAindexNbases 11 \
  --runThreadN 4
```

## Output Files

| File                                    | Description                                        |
| --------------------------------------- | -------------------------------------------------- |
| `Aligned.sortedByCoord.out.bam`         | Coordinate-sorted BAM alignment                    |
| `Aligned.toTranscriptome.out.bam`       | Transcriptome BAM (with --quantMode TranscriptomeSAM) |
| `SJ.out.tab`                            | Splice junctions discovered                        |
| `ReadsPerGene.out.tab`                  | Gene counts (with --quantMode GeneCounts)          |
| `Log.final.out`                         | Alignment summary statistics                       |
| `Log.out`                               | Detailed run log                                   |
| `Log.progress.out`                      | Runtime progress                                   |
| `Chimeric.out.junction`                 | Chimeric/fusion reads                              |
| `_STARgenome/`                          | 2-pass genome (if twopassMode)                     |

### SJ.out.tab (Splice Junctions)

```tsv
chr1  15038  15796  2  2  1  0  1  45
```

| Column | Description                                          |
| ------ | ---------------------------------------------------- |
| 1      | Chromosome                                           |
| 2      | Intron start (1-based)                               |
| 3      | Intron end (1-based)                                 |
| 4      | Strand: 0=undefined, 1=+, 2=-                       |
| 5      | Intron motif: 0=non-canonical, 1=GT/AG, 2=CT/AC, 3=GC/AG, 4=CT/GC, 5=AT/AC, 6=GT/AT |
| 6      | Annotated: 0=novel, 1=annotated                      |
| 7      | Unique mapping reads crossing junction               |
| 8      | Multi-mapping reads crossing junction                |
| 9      | Maximum overhang                                     |

### ReadsPerGene.out.tab (Gene Counts)

```tsv
N_unmapped      234567  234567  234567
N_multimapping  1234567 1234567 1234567
N_noFeature     2345678 4567890 3456789
N_ambiguous     123456  234567  345678
ENSG00000223972 0       0       0
ENSG00000227232 523     0       523
```

**Columns 2/3/4** correspond to unstranded / sense / antisense counting. Choose the column matching your library:

| Library Protocol   | Use Column |
| ------------------ | ---------- |
| Unstranded         | 2          |
| Stranded (sense)   | 3          |
| dUTP (antisense)   | 4          |

### Log.final.out (Key Metrics)

```text
                          Number of input reads |   20000000
              Uniquely mapped reads number |    17500000
                   Uniquely mapped reads % |    87.50%
        Number of reads mapped to multiple loci |    1500000
             % of reads mapped to multiple loci |    7.50%
                          % of reads unmapped |    5.00%
              Number of splices: Total |    12000000
                    Number of splices: Annotated |    11000000
                        Mismatch rate per base |    0.30%
```

**Healthy values (human RNA-seq):**
- Uniquely mapped: >70% (typically 80-90%)
- Multi-mapped: 5-15% (higher with pseudogenes)
- Unmapped: <10%
- Mismatch rate: <1%

## Resource Requirements

| Operation         | Memory     | Time (human, 50M PE reads) | Disk            |
| ----------------- | ---------- | -------------------------- | --------------- |
| Genome generation | ~32 GB     | 30-60 minutes              | ~27 GB index    |
| Alignment         | ~30 GB     | 10-20 minutes              | BAM output      |
| 2-pass mode       | ~30 GB     | 20-40 minutes              | Same + temp     |

**Memory is the critical constraint.** STAR loads the entire genome index into shared memory. For machines with <32GB RAM, use HISAT2 instead.

### Shared Memory (Multiple Samples)

```bash
# Load genome into shared memory once (stays resident)
STAR --genomeDir star_index/ --genomeLoad LoadAndKeep ...

# Subsequent samples reuse shared memory (instant startup)
STAR --genomeDir star_index/ --genomeLoad LoadAndKeep ...

# Remove from shared memory when done
STAR --genomeDir star_index/ --genomeLoad Remove
```

## STAR vs Other RNA-seq Aligners

| Feature                  | STAR           | HISAT2         | Salmon/Kallisto    |
| ------------------------ | -------------- | -------------- | ------------------ |
| Type                     | Genome aligner | Genome aligner | Pseudo-aligner     |
| Memory (human)           | ~30 GB         | ~8 GB          | ~5 GB              |
| Speed (50M PE reads)     | ~15 min        | ~25 min        | ~5 min             |
| Novel junction detection | Excellent      | Good           | No (transcript-based) |
| Built-in quantification  | Yes (GeneCounts)| No            | Yes (primary output)|
| Fusion detection         | Yes            | No             | No                 |
| BAM output               | Yes            | Yes            | Optional           |
| Best for                 | General RNA-seq| Low-memory     | Quick quantification|

## Related Tools

| Tool                               | Relationship                               |
| ---------------------------------- | ------------------------------------------ |
| [HISAT2](hisat2.md)               | Alternative aligner (lower memory)         |
| [featureCounts](featurecounts.md) | Read quantification from STAR BAM output   |
| [samtools](samtools.md)            | BAM indexing (needed after STAR output)    |
| [Salmon](salmon.md)               | Alignment-free quantification alternative  |
| [Kallisto](kallisto.md)            | Alignment-free quantification alternative  |
| [MultiQC](multiqc.md)             | Aggregates STAR Log.final.out statistics   |
| STAR-Fusion                        | Fusion detection from chimeric output      |
| RSEM                               | Transcript quantification from TranscriptomeSAM |
