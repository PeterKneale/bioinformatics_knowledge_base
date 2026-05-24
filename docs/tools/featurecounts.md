# featureCounts

**Source:** [subread.sourceforge.net](https://subread.sourceforge.net/) (part of Subread package)  
**License:** GPL-3.0  
**Category:** Read quantification

## Purpose

Ultrafast general-purpose read counting tool. Assigns aligned reads (from BAM) to genomic features (genes, exons) defined in a GTF/GFF annotation. Primary use is generating gene-level count matrices for RNA-seq differential expression analysis. Processes ~10M reads/minute — substantially faster than HTSeq-count.

## Installation

```bash
conda install -c bioconda subread
```

## How It Works

featureCounts assigns reads to features using a two-step process:

1. **Feature loading** — Parse GTF/GFF annotation, build interval index of features (exons by default)
2. **Read assignment** — For each read, determine which feature(s) it overlaps and assign accordingly

### Assignment Algorithm

```text
Read:        ────────────────────────────
Gene A:  ══════════                              (exon 1)
Gene B:                    ══════════════════     (exon 1)

Default mode (-O not set): 
  Read overlaps Gene A AND Gene B → AMBIGUOUS (not counted)

With -O (allow overlap):
  Read counted for BOTH Gene A and Gene B → +1 each

With --fracOverlap 0.5:
  Read must overlap ≥50% of its length with a feature
```

### Assignment Categories

Every read is placed into exactly one category:

| Category         | Meaning                                           | Counted? |
| ---------------- | ------------------------------------------------- | -------- |
| Assigned         | Uniquely assigned to one feature                  | Yes      |
| Unassigned_Ambiguity | Overlaps multiple features (and -O not set)   | No       |
| Unassigned_MultiMapping | Multi-mapped read (MAPQ=0, NH>1)           | No       |
| Unassigned_NoFeatures | No overlap with any feature                  | No       |
| Unassigned_Unmapped | Read is unmapped (FLAG 0x4)                    | No       |
| Unassigned_Secondary | Secondary alignment (FLAG 0x100)              | No       |
| Unassigned_Duplicate | Flagged as duplicate (FLAG 0x400)             | No       |
| Unassigned_MappingQuality | Below -Q threshold                      | No       |
| Unassigned_FragmentLength | Outside expected fragment length          | No       |
| Unassigned_Chimera | Mates on different chromosomes                 | No       |

## Key Options

| Option             | Description                                                   | Default    |
| ------------------ | ------------------------------------------------------------- | ---------- |
| `-a`               | Annotation file (GTF/GFF)                                     | Required   |
| `-o`               | Output count file                                             | Required   |
| `-F`               | Annotation format: GTF, GFF, SAF                              | GTF        |
| `-t`               | Feature type to count (3rd column of GTF)                     | exon       |
| `-g`               | Attribute for grouping features into meta-features            | gene_id    |
| `-p`               | Input is paired-end                                           | —          |
| `--countReadPairs` | Count fragments (read pairs) not individual reads             | —          |
| `-s`               | Strandedness: 0=unstranded, 1=stranded, 2=reverse stranded   | 0          |
| `-T`               | Number of threads                                             | 1          |
| `-M`               | Count multi-mapping reads                                     | Off        |
| `-O`               | Allow reads to be assigned to multiple features               | Off        |
| `--fraction`       | Assign fractional counts (1/n) to multi-mappers or overlaps   | Off        |
| `-Q`               | Minimum mapping quality                                       | 0          |
| `--minOverlap`     | Minimum overlap bases required                                | 1          |
| `--fracOverlap`    | Minimum fraction of read overlapping feature                  | 0          |
| `--largestOverlap` | Assign to feature with largest overlap (resolve ambiguity)    | Off        |
| `-B`               | Require both ends mapped (PE only)                            | Off        |
| `-C`               | Don't count pairs with mates on different chromosomes         | Off        |
| `--primary`        | Count primary alignments only                                 | Off        |

## Usage Examples

```bash
# Basic gene-level counting (unstranded, paired-end)
featureCounts -a annotation.gtf \
  -o counts.txt \
  -p --countReadPairs \
  -T 8 \
  aligned.sorted.bam

# Multiple BAMs simultaneously (produces count matrix)
featureCounts -a annotation.gtf \
  -o count_matrix.txt \
  -p --countReadPairs \
  -T 8 \
  sample1.bam sample2.bam sample3.bam

# Stranded RNA-seq (dUTP protocol = reverse stranded)
featureCounts -a annotation.gtf \
  -o counts.txt \
  -p --countReadPairs \
  -s 2 \
  -T 8 \
  aligned.sorted.bam

# Count at exon level (one row per exon)
featureCounts -a annotation.gtf \
  -o exon_counts.txt \
  -t exon -g exon_id \
  -f \
  -T 8 \
  aligned.sorted.bam

# Allow multi-mappers with fractional assignment
featureCounts -a annotation.gtf \
  -o counts.txt \
  -M --fraction \
  -T 8 \
  aligned.sorted.bam

# Using SAF format (simple custom annotation)
featureCounts -a custom_regions.saf \
  -F SAF \
  -o counts.txt \
  aligned.sorted.bam

# Strict mode: require 50% overlap, both mates mapped
featureCounts -a annotation.gtf \
  -o counts.txt \
  -p --countReadPairs \
  -B -C \
  --fracOverlap 0.5 \
  -T 8 \
  aligned.sorted.bam
```

## Strandedness

Choosing the correct `-s` value is critical. Wrong strandedness = wrong counts (potentially zero):

| Protocol / Kit                    | `-s` Value | Logic                                      |
| --------------------------------- | ---------- | ------------------------------------------ |
| Unstranded (old Illumina TruSeq) | 0          | Count reads on either strand               |
| dUTP (Illumina Stranded mRNA)    | 2          | Read 1 maps to reverse strand of gene      |
| Ligation (Illumina Stranded Total RNA) | 2   | Same as dUTP                               |
| Direct RNA (Nanopore)            | 1          | Reads map to same strand as gene           |
| SMART-Seq2                       | 0          | Unstranded                                 |

**How to check:** Run with `-s 0`, `-s 1`, and `-s 2` on a small BAM. The correct setting gives the most assigned reads. Or check the `.summary` file:

```bash
# Quick strandedness check
for s in 0 1 2; do
  featureCounts -a annotation.gtf -o /dev/null -s $s sample.bam 2>&1 | \
    grep "Successfully assigned"
done
```

## SAF Format (Simple Annotation Format)

Alternative to GTF for custom regions. Tab-delimited with 5 columns:

```tsv
GeneID	Chr	Start	End	Strand
gene1	chr1	1000	2000	+
gene2	chr1	3000	4000	-
peak_1	chr2	5000	6000	.
```

Useful for counting reads in custom regions (peaks, windows, promoters) without needing a full GTF.

## Output Format

### Main Count File

```tsv
# Program:featureCounts v2.0.6; Command:"featureCounts -a annotation.gtf ..."
Geneid	Chr	Start	End	Strand	Length	sample1.bam	sample2.bam
ENSG00000223972	chr1	11869	14409	+	1735	0	0
ENSG00000227232	chr1	14404	29570	-	6882	523	487
ENSG00000278267	chr1	17369	17436	-	68	15	12
```

| Column      | Description                                              |
| ----------- | -------------------------------------------------------- |
| Geneid      | Feature identifier (from `-g` attribute)                 |
| Chr         | Chromosome(s) — semicolon-separated if multiple exons    |
| Start       | Start position(s) of exons                               |
| End         | End position(s) of exons                                 |
| Strand      | Strand(s)                                                |
| Length       | Total exon length (sum of all exons, not genomic span)   |
| sample.bam  | Raw count for that sample                                |

### Summary File (`.summary`)

```tsv
Status                         sample1.bam   sample2.bam
Assigned                       15234567      14987234
Unassigned_Unmapped            234567        245678
Unassigned_Read_Type           0             0
Unassigned_Singleton           123456        134567
Unassigned_MappingQuality      0             0
Unassigned_Chimera             12345         13456
Unassigned_FragmentLength      0             0
Unassigned_Duplicate           0             0
Unassigned_MultiMapping        1234567       1345678
Unassigned_Secondary           0             0
Unassigned_NonSplit            0             0
Unassigned_NoFeatures          2345678       2456789
Unassigned_Overlapping_Length  0             0
Unassigned_Ambiguity           345678        356789
```

**Diagnostic value:** If `Unassigned_NoFeatures` is very high, check annotation compatibility (chromosome naming, GTF version). If `Unassigned_Ambiguity` is high, consider `--largestOverlap` or `-O`.

## Performance

| Metric           | Value                                     |
| ---------------- | ----------------------------------------- |
| Speed            | ~10M read pairs/minute (8 threads)        |
| Memory           | ~1-2GB (annotation in memory)             |
| vs HTSeq-count   | 10-50× faster                             |
| Parallelism      | Scales well to 16 threads                 |
| Input requirement| Sorted or unsorted BAM (sorted preferred) |

## Common Issues

| Problem                              | Symptom                          | Solution                                |
| ------------------------------------ | -------------------------------- | --------------------------------------- |
| Wrong strandedness                   | Very low assigned reads           | Try all three `-s` values               |
| Chromosome name mismatch             | 0 assigned reads                  | Check `chr1` vs `1` naming consistency  |
| GTF from different assembly          | Low assigned reads                | Match GTF version to reference genome   |
| Not counting fragments               | Double counts for PE data         | Add `--countReadPairs`                  |
| Multi-mappers silently excluded      | Lower counts than expected        | Add `-M` if appropriate                 |

## Related Tools

| Tool                             | Relationship                                      |
| -------------------------------- | ------------------------------------------------- |
| [HTSeq-count](htseq-count.md)   | Alternative counter (slower, Python-based)        |
| [STAR](star.md)                  | Aligner with built-in counting (--quantMode)      |
| [Salmon](salmon.md)             | Alignment-free quantification (transcript-level)  |
| [Kallisto](kallisto.md)          | Alignment-free quantification (transcript-level)  |
| [MultiQC](multiqc.md)           | Aggregates featureCounts summary statistics       |
