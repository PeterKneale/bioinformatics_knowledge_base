# GATK (Genome Analysis Toolkit)

**Source:** [gatk.broadinstitute.org](https://gatk.broadinstitute.org/)  
**License:** BSD-3-Clause  
**Category:** Variant calling

## Purpose

Industry-standard toolkit for variant discovery in high-throughput sequencing data. Implements the Broad Institute's Best Practices pipelines for germline and somatic variant calling. Includes tools for base quality recalibration, variant calling (HaplotypeCaller, Mutect2), variant filtering (VQSR), and genotype refinement.

## Installation

```bash
conda install -c bioconda gatk4
```

## Key Tools

| Tool                  | Description                             |
| --------------------- | --------------------------------------- |
| `HaplotypeCaller`     | Germline SNP/indel calling (per-sample) |
| `GenotypeGVCFs`       | Joint genotyping from gVCFs             |
| `Mutect2`             | Somatic variant calling (tumor/normal)  |
| `BaseRecalibrator`    | Model base quality errors               |
| `ApplyBQSR`           | Apply recalibrated quality scores       |
| `VariantFiltration`   | Hard-filter variants by expression      |
| `VariantRecalibrator` | Train VQSR model for filtering          |
| `ApplyVQSR`           | Apply VQSR filtering                    |
| `CombineGVCFs`        | Merge per-sample gVCFs                  |
| `SelectVariants`      | Subset variants by type/criteria        |
| `MarkDuplicatesSpark` | Spark-enabled duplicate marking         |

## Usage Examples

```bash
# Base Quality Score Recalibration (BQSR)
gatk BaseRecalibrator \
  -I aligned.markdup.bam \
  -R reference.fa \
  --known-sites dbsnp.vcf.gz \
  --known-sites known_indels.vcf.gz \
  -O recal_table.txt

gatk ApplyBQSR \
  -I aligned.markdup.bam \
  -R reference.fa \
  --bqsr-recal-file recal_table.txt \
  -O recalibrated.bam

# Germline variant calling (per-sample gVCF mode)
gatk HaplotypeCaller \
  -I recalibrated.bam \
  -R reference.fa \
  -ERC GVCF \
  -O sample.g.vcf.gz

# Joint genotyping across samples
gatk CombineGVCFs \
  -R reference.fa \
  -V sample1.g.vcf.gz -V sample2.g.vcf.gz -V sample3.g.vcf.gz \
  -O combined.g.vcf.gz

gatk GenotypeGVCFs \
  -R reference.fa \
  -V combined.g.vcf.gz \
  -O genotyped.vcf.gz

# Hard filtering (small cohorts)
gatk VariantFiltration \
  -R reference.fa \
  -V genotyped.vcf.gz \
  --filter-expression "QD < 2.0" --filter-name "LowQD" \
  --filter-expression "FS > 60.0" --filter-name "StrandBias" \
  -O filtered.vcf.gz

# Somatic variant calling (tumor-normal pair)
gatk Mutect2 \
  -I tumor.bam -I normal.bam \
  -normal normal_sample_name \
  -R reference.fa \
  --germline-resource af-only-gnomad.vcf.gz \
  -O somatic.vcf.gz
```

## Produces

- `.vcf.gz` / `.g.vcf.gz` — Variant calls (gVCF for per-sample)
- Recalibration tables
- Filtered VCF files

## Prerequisites

- Coordinate-sorted, duplicate-marked BAM with read groups
- Indexed reference FASTA (`.fai` + `.dict`)
- Known variant sites (dbSNP, known indels) for BQSR

## Related Tools

- [bcftools](bcftools.md) — Lighter-weight variant calling alternative
- [freebayes](freebayes.md) — Bayesian variant caller (no BQSR needed)
- [picard](picard.md) — Duplicate marking, metrics (used upstream)
- [samtools](samtools.md) — BAM preprocessing
