# FreeBayes

**Source:** [github.com/freebayes/freebayes](https://github.com/freebayes/freebayes)  
**License:** MIT  
**Category:** Variant calling

## Purpose

Bayesian haplotype-based variant caller for SNPs, indels, MNPs, and complex events. Simpler to use than GATK — requires no base quality recalibration and handles polyploid samples. Particularly suited for smaller projects, non-model organisms, and pooled sequencing experiments.

## Installation

```bash
conda install -c bioconda freebayes
```

## Key Features

- Haplotype-based calling (evaluates nearby variants together)
- No BQSR required
- Supports polyploid and pooled samples
- Can call variants from multiple BAMs simultaneously
- Population-aware priors

## Usage Examples

```bash
# Basic variant calling (diploid)
freebayes -f reference.fa aligned.sorted.bam > variants.vcf

# With quality and depth thresholds
freebayes -f reference.fa \
  --min-mapping-quality 20 \
  --min-base-quality 20 \
  --min-alternate-count 3 \
  aligned.sorted.bam > variants.vcf

# Call variants from multiple samples simultaneously
freebayes -f reference.fa \
  sample1.bam sample2.bam sample3.bam > cohort.vcf

# Restrict to specific region
freebayes -f reference.fa -r chr1:1000000-2000000 \
  aligned.sorted.bam > region_variants.vcf

# Polyploid calling (e.g., tetraploid)
freebayes -f reference.fa --ploidy 4 \
  aligned.sorted.bam > variants.vcf

# Pooled sequencing (20 individuals in one pool)
freebayes -f reference.fa --pooled-discrete --ploidy 40 \
  pool.bam > variants.vcf

# Parallel execution with freebayes-parallel
freebayes-parallel <(fasta_generate_regions.py reference.fa.fai 100000) 8 \
  -f reference.fa aligned.sorted.bam > variants.vcf
```

## Produces

- `.vcf` — Variant calls (pipe through bgzip + tabix for indexing)

## Related Tools

- [gatk](gatk.md) — More complex pipeline, gold-standard for clinical
- [bcftools](bcftools.md) — Alternative caller + downstream filtering
- [vcftools](vcftools.md) — VCF post-processing and population stats
