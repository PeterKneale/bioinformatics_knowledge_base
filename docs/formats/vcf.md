# VCF Format (Variant Call Format)

**Extension:** `.vcf`, `.vcf.gz`  
**Type:** Text (tab-delimited), often bgzip-compressed  
**Specification:** [VCF 4.3 Specification](https://samtools.github.io/hts-specs/VCFv4.3.pdf)

## Purpose

Standard format for representing genomic variants (SNPs, indels, structural variants) discovered by variant calling. Contains variant positions, reference/alternate alleles, quality scores, filter status, and per-sample genotype information.

## Structure

### Header (lines starting with `##`)

```tsv
##fileformat=VCFv4.3
##FILTER=<ID=PASS,Description="All filters passed">
##INFO=<ID=DP,Number=1,Type=Integer,Description="Total Depth">
##INFO=<ID=AF,Number=A,Type=Float,Description="Allele Frequency">
##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Read Depth">
##FORMAT=<ID=GQ,Number=1,Type=Integer,Description="Genotype Quality">
##contig=<ID=chr1,length=248956422>
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	SAMPLE1	SAMPLE2
```

### Data Columns

| Col | Field   | Description                               |
| --- | ------- | ----------------------------------------- |
| 1   | CHROM   | Chromosome                                |
| 2   | POS     | 1-based position                          |
| 3   | ID      | Variant identifier (rsID or `.`)          |
| 4   | REF     | Reference allele                          |
| 5   | ALT     | Alternate allele(s), comma-separated      |
| 6   | QUAL    | Phred-scaled variant quality              |
| 7   | FILTER  | Filter status (`PASS` or filter name)     |
| 8   | INFO    | Semicolon-separated key=value annotations |
| 9   | FORMAT  | Colon-separated genotype field keys       |
| 10+ | SAMPLES | Per-sample genotype data                  |

### Example

```tsv
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	SAMPLE1
chr1	10177	rs367896724	A	AC	100	PASS	DP=50;AF=0.45	GT:DP:GQ	0/1:48:99
chr1	10235	.	T	TA	50	PASS	DP=30;AF=0.20	GT:DP:GQ	0/0:28:85
chr1	10352	rs145072688	T	TA	200	PASS	DP=100;AF=0.60	GT:DP:GQ	1/1:95:99
```

## Genotype Field

| Value | Meaning                        |
| ----- | ------------------------------ |
| `0/0` | Homozygous reference           |
| `0/1` | Heterozygous                   |
| `1/1` | Homozygous alternate           |
| `1/2` | Heterozygous (two alt alleles) |
| `./.` | Missing genotype               |
| `0    | 1`                             | Phased heterozygous |

## Indexing

### TBI Index (`.tbi`)

Standard tabix index for compressed VCF:

```bash
# Compress with bgzip
bgzip variants.vcf        # → variants.vcf.gz

# Index with tabix
tabix -p vcf variants.vcf.gz   # → variants.vcf.gz.tbi

# Query a region
tabix variants.vcf.gz chr1:1000000-2000000
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

Extended VCF that includes non-variant (reference) blocks. Used in GATK joint genotyping workflows.

```tsv
chr1	10000	.	A	<NON_REF>	.	.	END=10100	GT:DP:GQ	0/0:30:90
chr1	10177	rs367896724	A	AC,<NON_REF>	100	.	DP=50	GT:DP:GQ	0/1:48:99
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
