# VCF Format (Variant Call Format)

**Extension:** `.vcf`, `.vcf.gz`  
**Type:** Text (tab-delimited), often bgzip-compressed  
**Specification:** [VCF 4.3 Specification](https://samtools.github.io/hts-specs/VCFv4.3.pdf)

## Purpose

Standard format for representing genomic variants (SNPs, indels, structural variants) discovered by variant calling. Contains variant positions, reference/alternate alleles, quality scores, filter status, and per-sample genotype information. VCF is the primary output of variant calling pipelines and the input to annotation, filtering, and population genetics tools.

## Structure

### Header (lines starting with `##`)

The header is **structured metadata** — not just comments. It defines the schema for INFO and FORMAT fields (analogous to a database schema).

```tsv
##fileformat=VCFv4.3
##FILTER=<ID=PASS,Description="All filters passed">
##FILTER=<ID=LowQual,Description="Low quality variant">
##INFO=<ID=DP,Number=1,Type=Integer,Description="Total Depth">
##INFO=<ID=AF,Number=A,Type=Float,Description="Allele Frequency">
##INFO=<ID=AC,Number=A,Type=Integer,Description="Allele Count">
##INFO=<ID=AN,Number=1,Type=Integer,Description="Total Alleles">
##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Read Depth">
##FORMAT=<ID=GQ,Number=1,Type=Integer,Description="Genotype Quality">
##FORMAT=<ID=AD,Number=R,Type=Integer,Description="Allelic Depths (ref,alt)">
##FORMAT=<ID=PL,Number=G,Type=Integer,Description="Phred-scaled Genotype Likelihoods">
##contig=<ID=chr1,length=248956422>
##reference=file:///path/to/reference.fa
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	SAMPLE1	SAMPLE2
```

### Header Meta-Information Types

| Directive   | Purpose                              | Number Field Values           |
| ----------- | ------------------------------------ | ----------------------------- |
| `##INFO`    | Defines a field in the INFO column   | `0` (flag), `1`, `A` (per-alt), `R` (per-allele), `G` (per-genotype), `.` (variable) |
| `##FORMAT`  | Defines a per-sample field           | Same as INFO                  |
| `##FILTER`  | Defines a filter status              | —                             |
| `##contig`  | Reference sequence metadata          | —                             |
| `##ALT`     | Defines symbolic ALT alleles         | —                             |

### Data Columns

| Col | Field   | Description                               |
| --- | ------- | ----------------------------------------- |
| 1   | CHROM   | Chromosome                                |
| 2   | POS     | 1-based position of the first base of REF |
| 3   | ID      | Variant identifier (rsID or `.`)          |
| 4   | REF     | Reference allele (must match reference genome) |
| 5   | ALT     | Alternate allele(s), comma-separated      |
| 6   | QUAL    | Phred-scaled probability variant is wrong |
| 7   | FILTER  | Filter status (`PASS` or filter name(s))  |
| 8   | INFO    | Semicolon-separated key=value annotations |
| 9   | FORMAT  | Colon-separated genotype field keys       |
| 10+ | SAMPLES | Per-sample genotype data (colon-separated)|

### Example

```tsv
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	SAMPLE1
chr1	10177	rs367896724	A	AC	100	PASS	DP=50;AF=0.45;AC=1;AN=2	GT:DP:GQ:AD	0/1:48:99:26,22
chr1	10235	.	T	TA	50	PASS	DP=30;AF=0.20	GT:DP:GQ:AD	0/0:28:85:28,0
chr1	10352	rs145072688	T	TA	200	PASS	DP=100;AF=0.60	GT:DP:GQ:AD	1/1:95:99:2,93
```

## Variant Representation

### SNPs (Single Nucleotide Polymorphisms)

```tsv
chr1	1000	.	A	G	100	PASS	.	GT	0/1
```
Position 1000: reference is `A`, variant is `G`.

### Insertions

```tsv
chr1	1000	.	A	ACGT	100	PASS	.	GT	0/1
```
After position 1000, `CGT` is inserted. REF includes the anchor base.

### Deletions

```tsv
chr1	1000	.	ACGT	A	100	PASS	.	GT	0/1
```
Bases `CGT` at positions 1001-1003 are deleted. REF includes them, ALT is just the anchor.

### Multi-Allelic Sites

```tsv
chr1	1000	.	A	G,T	100	PASS	AC=5,3;AF=0.25,0.15	GT	1/2
```
Two alternative alleles at the same position. Allele indexing: 0=REF(A), 1=G, 2=T.

## Genotype Field

### GT (Genotype)

| Value | Meaning                        | Ploidy |
| ----- | ------------------------------ | ------ |
| `0/0` | Homozygous reference           | Diploid, unphased |
| `0/1` | Heterozygous                   | Diploid, unphased |
| `1/1` | Homozygous alternate           | Diploid, unphased |
| `1/2` | Heterozygous (two alt alleles) | Diploid, unphased |
| `./.` | Missing genotype               | Unknown |
| `0|1` | Phased heterozygous (ref first)| Diploid, phased |
| `1|0` | Phased heterozygous (alt first)| Diploid, phased |
| `0`   | Haploid reference              | Haploid (e.g., chrX male) |

**Phasing:** `/` = unphased (alleles on either chromosome), `|` = phased (left = maternal/paternal haplotype 1).

### Key FORMAT Fields

| Field  | Type     | Description                                                     |
| ------ | -------- | --------------------------------------------------------------- |
| `GT`   | String   | Genotype (always first if present)                              |
| `DP`   | Integer  | Read depth at this site for this sample                         |
| `GQ`   | Integer  | Genotype quality (Phred-scaled confidence in GT call)           |
| `AD`   | Int[]    | Allelic depths: reads supporting ref, alt1, alt2...             |
| `PL`   | Int[]    | Phred-scaled genotype likelihoods (0/0, 0/1, 1/1 for biallelic)|
| `GL`   | Float[]  | Log10-scaled genotype likelihoods (older format)                |

### PL Field (Genotype Likelihoods)

`PL` encodes the Phred-scaled likelihood of each possible genotype, ordered by the genotype index formula:

For alleles 0..n, genotype (a,b) where a ≤ b has index: `b*(b+1)/2 + a`

**Biallelic example:** `PL:0,30,200` means:
- P(0/0) = 10^(-0/10) = 1.0 (most likely)
- P(0/1) = 10^(-30/10) = 0.001
- P(1/1) = 10^(-200/10) ≈ 0 

The called genotype is the one with PL = 0 (lowest). GQ = second lowest PL value.

## INFO Field

Site-level annotations (apply to the variant, not per-sample):

| Field   | Number | Meaning                                              |
| ------- | ------ | ---------------------------------------------------- |
| `DP`    | 1      | Total depth across all samples                       |
| `AF`    | A      | Allele frequency (one per ALT allele)                |
| `AC`    | A      | Allele count in genotypes (per ALT)                  |
| `AN`    | 1      | Total number of alleles (2 × n_samples for diploid)  |
| `MQ`    | 1      | RMS mapping quality of reads supporting the variant  |
| `QD`    | 1      | QUAL / DP — quality normalized by depth (GATK)       |
| `FS`    | 1      | Fisher strand bias (Phred-scaled)                    |
| `SOR`   | 1      | Strand odds ratio (better than FS for high depth)    |
| `MQRankSum` | 1  | Mapping quality rank sum test (ref vs alt reads)     |
| `ReadPosRankSum` | 1 | Read position rank sum (variant near read ends?) |

### GATK Hard Filter Thresholds (Common Defaults)

| Filter           | SNPs        | Indels      | Rationale                     |
| ---------------- | ----------- | ----------- | ----------------------------- |
| QD               | < 2.0       | < 2.0       | Low quality relative to depth |
| FS               | > 60.0      | > 200.0     | Strand bias                   |
| MQ               | < 40.0      | —           | Low mapping quality           |
| MQRankSum        | < -12.5     | —           | Alt reads have worse MAPQ     |
| ReadPosRankSum   | < -8.0      | < -20.0     | Variant at read ends (error)  |
| SOR              | > 3.0       | > 10.0      | Strand odds ratio             |

## Variant Normalization

The same biological variant can be represented multiple ways in VCF. **Normalization** ensures a canonical representation:

```text
Unnormalized:   chr1  1001  ACGT  ACCC    (right-aligned insertion)
Normalized:     chr1  1001  G     C       (left-aligned, minimal representation)

Unnormalized:   chr1  1000  AACAC  AAC   (ambiguous deletion)
Normalized:     chr1  1001  AC     A     (left-aligned, trimmed)
```

**Rules:**
1. **Left-align** — shift indels left until they can't move further
2. **Trim** — remove common prefix/suffix between REF and ALT
3. **Keep anchor base** — indels must have at least one REF base

```bash
# Normalize a VCF
bcftools norm -f reference.fa -m -both input.vcf.gz -Oz -o normalized.vcf.gz

# -m -both: split multi-allelic sites into biallelic records
# -f ref.fa: left-align and trim using reference
```

**Why normalization matters:** Without it, the same variant called by different tools (GATK, FreeBayes, bcftools) will appear at different positions, making merging and comparison impossible.

## Indexing

### TBI Index (`.tbi`)

Standard tabix index for compressed VCF:

```bash
# Compress with bgzip (NOT gzip — must be block-compressed)
bgzip variants.vcf        # → variants.vcf.gz

# Index with tabix
tabix -p vcf variants.vcf.gz   # → variants.vcf.gz.tbi

# Query a region
tabix variants.vcf.gz chr1:1000000-2000000

# Query specific variant
tabix variants.vcf.gz chr1:10177-10177
```

### CSI Index (`.csi`)

For genomes with chromosomes >512Mb:

```bash
# Create CSI index
bcftools index variants.vcf.gz          # → .csi (default in bcftools)
tabix --csi variants.vcf.gz             # → .csi with tabix

# Or explicitly
bcftools index --csi variants.vcf.gz
bcftools index --tbi variants.vcf.gz    # force .tbi
```

### Index Comparison

| Index | Extension | Max Chrom Size | Tool                        |
| ----- | --------- | -------------- | --------------------------- |
| TBI   | `.tbi`    | 512 Mb         | tabix                       |
| CSI   | `.csi`    | Unlimited      | bcftools index, tabix --csi |

## gVCF (Genomic VCF)

Extended VCF that includes **non-variant (reference) blocks** — encoding confidence that a region is homozygous-reference. Required for GATK's joint genotyping workflow.

```tsv
chr1	10000	.	A	<NON_REF>	.	.	END=10100	GT:DP:GQ	0/0:30:90
chr1	10177	rs367896724	A	AC,<NON_REF>	100	.	DP=50	GT:DP:GQ	0/1:48:99
```

**Design rationale:** Regular VCF only records variant sites — so absence of a record is ambiguous (was it reference, or was there no data?). gVCF makes this explicit: non-variant blocks confirm "we had coverage here and it was reference."

## Common Operations

```bash
# View header
bcftools view -h variants.vcf.gz

# Count variants
bcftools view -H variants.vcf.gz | wc -l

# Extract specific samples
bcftools view -s SAMPLE1,SAMPLE2 variants.vcf.gz -Oz -o subset.vcf.gz

# Filter by quality
bcftools filter -i 'QUAL>=30 && INFO/DP>=10' variants.vcf.gz

# Extract genotypes as table
bcftools query -f '%CHROM\t%POS\t%REF\t%ALT\t[%GT\t]\n' variants.vcf.gz

# Statistics summary
bcftools stats variants.vcf.gz > stats.txt

# Compare two callsets (concordance)
bcftools isec -p comparison_dir callset1.vcf.gz callset2.vcf.gz
```

## Tools That Create This Format

| Tool                                         | Context                  |
| -------------------------------------------- | ------------------------ |
| [GATK HaplotypeCaller](../tools/gatk.md)     | Germline variant calling |
| [GATK Mutect2](../tools/gatk.md)             | Somatic variant calling  |
| [bcftools call](../tools/bcftools.md)        | Variant calling          |
| [FreeBayes](../tools/freebayes.md)           | Bayesian variant calling |
| [bcftools filter/view](../tools/bcftools.md) | Filtered variants        |

## Tools That Read This Format

| Tool                             | Purpose                          |
| -------------------------------- | -------------------------------- |
| [bcftools](../tools/bcftools.md) | Filter, query, annotate, merge   |
| [GATK](../tools/gatk.md)         | Joint genotyping, filtering      |
| [VCFtools](../tools/vcftools.md) | Population statistics, filtering |
| [tabix](../tools/tabix.md)       | Region queries                   |
| [PLINK](../tools/plink.md)       | GWAS import                      |
| [bedtools](../tools/bedtools.md) | Interval operations              |
| [IGV](https://igv.org/)          | Visualisation                    |

## See Also

- [BCF](bcf.md) — binary VCF (faster I/O)
- [BAM](bam.md) — aligned reads (upstream of VCF)
- [BED](bed.md) — genomic intervals
