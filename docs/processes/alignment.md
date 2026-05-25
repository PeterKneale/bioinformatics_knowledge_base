# Alignment Process

## Overview

Alignment (or mapping) is the process of determining where each sequencing read originated in a reference genome. Given millions of short strings (reads, ~100-300 characters from a 4-letter alphabet) and one very long string (the reference genome, ~3 billion characters for human), find the best-matching position for each read — allowing for mismatches, insertions, and deletions.

This is fundamentally a **string matching** problem, but at a scale where naive algorithms (O(n×m) per read) are computationally infeasible. Modern aligners solve this using **index data structures** that enable sublinear-time lookups.

## The Computational Problem

```text
Input:   50,000,000 reads × 150 bp each  (FASTQ)
         +  1 reference genome, ~3 Gb     (FASTA, indexed)

Output:  Position, strand, and edit operations for each read  (SAM/BAM)

Scale:   ~7.5 Gb of query sequence against ~3 Gb of reference
         Must complete in hours, not days
```

### Why Not Use grep/suffix arrays directly?

| Approach           | Time per read | Total (50M reads) | Practical? |
| ------------------ | ------------- | ------------------ | ---------- |
| Naive O(nm)        | ~450 ms       | ~260 days          | No         |
| Suffix array       | ~1 μs exact   | ~50 s (exact only) | No inexact |
| BWT + FM-index     | ~10 μs        | ~500 s             | Yes        |
| Hash table (k-mer) | ~5 μs         | ~250 s             | Yes        |

The key insight: pre-build an index of the reference genome once, then query it millions of times with different reads.

## Indexing Algorithms

### Burrows-Wheeler Transform (BWT) — BWA, Bowtie2

The BWT is a reversible text transformation that groups similar characters together, enabling compression and fast pattern matching via the FM-index.

**How it works:**

1. Generate all rotations of the reference string (conceptually)
2. Sort rotations lexicographically
3. The last column is the BWT
4. Build auxiliary data structures (occurrence table, suffix array samples) for O(m) pattern search where m = query length

**Properties:**

- Space: ~1 byte per reference base (compressed) — human genome index ≈ 3-5 GB
- Query time: O(m) for exact match of length-m pattern
- Inexact search: backtracking with bounded mismatches

```bash
# Build BWT index for BWA (one-time, ~1 hour for human genome)
bwa index reference.fa
# Produces: reference.fa.{amb,ann,bwt,pac,sa}  (~6 GB total)
```

### Graph-Based Index — HISAT2

HISAT2 uses a **graph FM-index (GFM)** — an FM-index built over a graph that incorporates known variants and splice sites, rather than a single linear reference.

- Handles known SNPs without penalty
- Splice-site aware (for RNA-seq) without full transcript indexing
- Memory: ~8 GB for human genome + SNPs + splice sites

```bash
# Build HISAT2 index (includes splice sites and SNPs)
hisat2-build --ss splice_sites.txt --exon exons.txt \
  reference.fa genome_index
```

### Suffix Array + Hash Table — STAR

STAR uses a **suffix array** of the reference genome stored in RAM, combined with a hash table for fast seed lookup. It is optimised for splice-aware RNA-seq alignment.

- Memory: ~30 GB for human genome (trades memory for speed)
- Speed: Fastest RNA-seq aligner (processes ~100M reads/hour)
- Can discover novel splice junctions

```bash
# Build STAR genome index (requires ~30 GB RAM)
STAR --runMode genomeGenerate \
  --genomeDir star_index/ \
  --genomeFastaFiles reference.fa \
  --sjdbGTFfile annotations.gtf \
  --sjdbOverhang 149 \
  --runThreadN 8
```

### Minimizer/k-mer Hashing — minimap2

minimap2 uses **minimizers** — a subset of k-mers (hash-selected) that serve as sparse seeds for chaining alignments. Designed for long reads and high error rates.

- Index: ~6 GB for human (just minimizer hash table)
- Handles reads with 5-15% error rate (long-read sequencing)
- Chains seeds with dynamic programming, then refines with banded Smith-Waterman

```bash
# Index once (fast — minutes not hours)
minimap2 -d reference.mmi reference.fa

# Align (preset for PacBio HiFi)
minimap2 -a -x map-hifi reference.mmi reads.fastq.gz | samtools sort -o aligned.bam
```

## The Seed-and-Extend Paradigm

All modern aligners use a two-phase strategy:

```text
Phase 1: SEED — Find exact-match anchors between read and reference
  └─ Use index to locate short exact matches (seeds) in O(k) time
  └─ Multiple seeds per read provide candidate mapping positions

Phase 2: EXTEND — Full alignment around seeds
  └─ Smith-Waterman or Needleman-Wunsch dynamic programming
  └─ Score: matches (+1), mismatches (-4 typical), gaps (-6 open, -1 extend)
  └─ Select best-scoring alignment
```

**Why seeds work:** Even with errors, a 150bp read at 1% error rate will have long exact-matching substrings. If you require seeds of length 20, the probability of no exact seed in 150bp at 1% error is negligibly small.

## Alignment Parameters

### Mapping Quality (MAPQ)

MAPQ is the aligner's estimate of the probability the reported position is wrong:

$$\text{MAPQ} = -10 \log_{10}(P[\text{mapping position is wrong}])$$

| MAPQ | P(wrong) | Interpretation                                |
| ---- | --------- | --------------------------------------------- |
| 0    | 1.0       | Equally good alignments elsewhere (multimapper) |
| 3    | 0.5       | Coin flip — unreliable                         |
| 10   | 0.1       | 90% confident                                  |
| 20   | 0.01      | 99% confident                                  |
| 30   | 0.001     | High confidence                                |
| 40   | 0.0001    | Very high confidence                           |
| 60   | 10⁻⁶      | Maximum reported by BWA                        |

**How it's computed:** The aligner considers the alignment score of the best hit vs the second-best hit. If they're similar, MAPQ is low (the read could belong to either location).

### Scoring Parameters

| Parameter      | BWA Default | Effect                                       |
| -------------- | ----------- | -------------------------------------------- |
| Match score    | +1          | Reward for matching base                     |
| Mismatch       | -4          | Penalty for substitution                     |
| Gap open       | -6          | Cost to start an insertion/deletion          |
| Gap extend     | -1          | Cost for each additional base in a gap       |
| Clip penalty   | 5           | Cost for soft-clipping read ends             |

These parameters encode a **probabilistic model** of sequencing errors: mismatches are more likely than indels, and multi-base indels should be penalised less per base than single-base indels (hence open+extend model).

## Choosing an Aligner

| Scenario                         | Tool                                | Reason                                    |
| -------------------------------- | ----------------------------------- | ----------------------------------------- |
| WGS/WES Illumina (DNA)          | [BWA-MEM](../tools/bwa.md)          | Gold standard; GATK best practices        |
| RNA-seq (splice-aware)           | [STAR](../tools/star.md)            | Fastest; discovers novel junctions        |
| RNA-seq (low memory)             | [HISAT2](../tools/hisat2.md)        | 8 GB RAM vs 30 GB for STAR                |
| ChIP-seq / ATAC-seq             | [Bowtie2](../tools/bowtie2.md)      | Fast; good for shorter fragments          |
| PacBio HiFi / CLR               | [minimap2](../tools/minimap2.md)    | Designed for long-read error profiles     |
| Oxford Nanopore                  | [minimap2](../tools/minimap2.md)    | Handles high error + ultra-long reads     |
| Large structural variants        | [minimap2](../tools/minimap2.md)    | Chains split alignments                   |

## The Standard Alignment Pipeline

### Step 1: Reference Preparation (One-Time)

```bash
# Download reference genome
wget https://ftp.ensembl.org/pub/release-112/fasta/homo_sapiens/dna/\
Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz
gunzip Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz

# Index reference for FASTA random access
samtools faidx reference.fa           # → reference.fa.fai

# Create sequence dictionary (required by GATK/Picard)
picard CreateSequenceDictionary R=reference.fa O=reference.dict

# Build aligner-specific index
bwa index reference.fa                # BWA (takes ~1hr for human)
# OR
STAR --runMode genomeGenerate ...      # STAR (RNA-seq)
# OR  
hisat2-build reference.fa ht2_index   # HISAT2
```

### Step 2: Align Reads

```bash
# BWA-MEM for Illumina WGS/WES (streams directly to sorted BAM)
bwa mem -t 16 \
  -R '@RG\tID:sample1\tSM:sample1\tPL:ILLUMINA\tLB:lib1\tPU:unit1' \
  reference.fa \
  clean_R1.fastq.gz clean_R2.fastq.gz | \
  samtools sort -@ 4 -o aligned.sorted.bam -

# STAR for RNA-seq
STAR --runThreadN 16 \
  --genomeDir star_index/ \
  --readFilesIn clean_R1.fastq.gz clean_R2.fastq.gz \
  --readFilesCommand zcat \
  --outSAMtype BAM SortedByCoordinate \
  --outFileNamePrefix sample_ \
  --twopassMode Basic \
  --quantMode GeneCounts
```

**Read Groups (`-R` flag):** Required metadata that identifies the sample, library, platform, and sequencing unit. GATK refuses to run without read groups. Format: `@RG\tID:{id}\tSM:{sample}\tPL:{platform}\tLB:{library}\tPU:{unit}`

### Step 3: Index the BAM

```bash
# Create .bai index (required for random access by all downstream tools)
samtools index aligned.sorted.bam
# Produces: aligned.sorted.bam.bai
```

### Step 4: Mark Duplicates

PCR duplicates are identified as reads mapping to the exact same position with the same orientation. They arise from amplification of the same original DNA molecule.

```bash
# Picard MarkDuplicates (standard in GATK pipelines)
picard MarkDuplicates \
  I=aligned.sorted.bam \
  O=aligned.markdup.bam \
  M=dup_metrics.txt \
  CREATE_INDEX=true

# Alternative: samtools markdup (faster, same result)
samtools markdup aligned.sorted.bam aligned.markdup.bam
samtools index aligned.markdup.bam
```

**Algorithm:** Sort by position → compare 5' mapping coordinates + orientation → mark later-sequenced copies as duplicates (FLAG bit 0x400). Optical duplicates (same flow cell tile) are distinguished from PCR duplicates.

### Step 5: Alignment QC

```bash
# Quick stats
samtools flagstat aligned.markdup.bam

# Detailed stats
samtools stats aligned.markdup.bam > alignment_stats.txt

# Per-chromosome read counts
samtools idxstats aligned.markdup.bam

# Insert size and alignment metrics
picard CollectInsertSizeMetrics \
  I=aligned.markdup.bam O=insert_metrics.txt H=insert_hist.pdf

picard CollectAlignmentSummaryMetrics \
  I=aligned.markdup.bam R=reference.fa O=align_metrics.txt
```

## Post-Alignment Processing

### Quality Filtering

```bash
# Remove unmapped, secondary, supplementary, duplicate, and low-MAPQ reads
samtools view -b -F 0xF04 -q 20 aligned.markdup.bam > filtered.bam
# Flags: 0xF04 = unmapped(4) + secondary(256) + duplicate(1024) + supplementary(2048)

# For RNA-seq, also remove reads with too many mismatches
# (STAR uses NH:i tag for multimappers)
samtools view -b -q 255 star_output.bam > uniquely_mapped.bam
```

### SAM FLAG Field (Bitwise)

The FLAG field is a bitwise OR of:

| Bit    | Hex    | Meaning                           |
| ------ | ------ | --------------------------------- |
| 0x1    | 1      | Read is paired                    |
| 0x2    | 2      | Read mapped in proper pair        |
| 0x4    | 4      | Read unmapped                     |
| 0x8    | 8      | Mate unmapped                     |
| 0x10   | 16     | Read on reverse strand            |
| 0x20   | 32     | Mate on reverse strand            |
| 0x40   | 64     | First in pair (R1)                |
| 0x80   | 128    | Second in pair (R2)               |
| 0x100  | 256    | Secondary alignment               |
| 0x200  | 512    | Failed quality checks             |
| 0x400  | 1024   | PCR or optical duplicate          |
| 0x800  | 2048   | Supplementary alignment           |

**Useful filters:**

```bash
# Only properly paired reads
samtools view -f 0x2 input.bam

# Exclude unmapped + duplicates + secondary
samtools view -F 0x504 input.bam

# Only first-in-pair reads (for strand-specific RNA-seq counting)
samtools view -f 0x40 input.bam
```

### CIGAR String

The CIGAR (Compact Idiosyncratic Gapped Alignment Report) string encodes the alignment structure:

| Op | Meaning            | Consumes Reference | Consumes Read |
| -- | ------------------ | ------------------ | ------------- |
| M  | Match/mismatch     | Yes                | Yes           |
| I  | Insertion to ref   | No                 | Yes           |
| D  | Deletion from ref  | Yes                | No            |
| N  | Skipped region     | Yes                | No            |
| S  | Soft clip          | No                 | Yes           |
| H  | Hard clip          | No                 | No            |
| =  | Sequence match     | Yes                | Yes           |
| X  | Sequence mismatch  | Yes                | Yes           |

**Example:** `50M2I30M3D20M48S` = 50 aligned bases, 2bp insertion, 30 aligned, 3bp deletion, 20 aligned, 48 soft-clipped.

**RNA-seq specificity:** The `N` operation represents intron-spanning (splice junction). `30M5000N120M` = 30bp exon, 5kb intron, 120bp exon.

## Splice-Aware Alignment (RNA-seq)

RNA-seq reads may span exon-exon junctions. Standard DNA aligners cannot handle this — they would fail to align reads crossing introns (gaps of 10bp to 1Mb).

**STAR's two-pass approach:**

1. **Pass 1:** Align reads with default splice junction database (from GTF annotation)
2. **Discover novel junctions** from chimeric alignments in pass 1
3. **Pass 2:** Re-align all reads using both annotated + novel junctions

```text
Genomic DNA:  EXON1────INTRON (50kb)────EXON2
RNA read:     [EXON1|EXON2]  (spans junction)
CIGAR:        75M50000N75M   (75bp match, 50kb skip, 75bp match)
```

## Output Format

Alignment produces [SAM/BAM](../formats/bam.md) files. Key fields per alignment record:

```
QNAME  FLAG  RNAME  POS  MAPQ  CIGAR  RNEXT  PNEXT  TLEN  SEQ  QUAL  [TAGS]
read1  99    chr1   1000 60    150M   =      1200   350   ACGT... IIII... NM:i:1
```

See [SAM format](../formats/sam.md) and [BAM format](../formats/bam.md) for full specification.

## Tools Involved

| Tool                                   | Role                                            |
| -------------------------------------- | ----------------------------------------------- |
| [BWA](../tools/bwa.md)                 | BWT-based short-read DNA alignment              |
| [Bowtie2](../tools/bowtie2.md)         | FM-index short-read alignment (ChIP/ATAC)       |
| [STAR](../tools/star.md)               | Suffix array RNA-seq splice-aware alignment     |
| [HISAT2](../tools/hisat2.md)           | Graph FM-index RNA-seq alignment                |
| [minimap2](../tools/minimap2.md)       | Minimizer-based long-read alignment             |
| [samtools](../tools/samtools.md)       | BAM sorting, indexing, filtering, statistics    |
| [Picard](../tools/picard.md)           | Duplicate marking, metrics, read groups         |

## Key Concepts for Computer Scientists

| Concept              | CS Analogy / Detail                                                                      |
| -------------------- | ---------------------------------------------------------------------------------------- |
| BWT / FM-index       | A compressed suffix array; enables O(m) pattern matching in space proportional to text   |
| Seed-and-extend      | Like a B-tree lookup (seed) followed by sequential scan (extend) in a database           |
| MAPQ                 | Posterior probability of error; analogous to a confidence interval on a prediction       |
| CIGAR string         | A run-length encoded diff; similar to edit script in `diff` output                       |
| BAI index            | A binning scheme (R-tree-like) for genomic intervals enabling random access O(log n)     |
| Splice-aware         | The aligner models a grammar where reads can skip non-adjacent regions (introns)         |
| Read groups          | Metadata provenance; tracks which batch/instrument produced each read                    |
| Soft clipping        | Partial alignment — analogous to prefix/suffix trimming in string matching               |