# VCFtools

**Purpose:** Program for working with VCF files. Provides methods for filtering, comparing, summarizing, converting, and computing population genetics statistics from variant data.

**Source:** [vcftools.github.io](https://vcftools.github.io/)  
**Citation:** Danecek P. et al. (2011) *Bioinformatics* 27:2156-2158

## Installation

```bash
conda install -c bioconda vcftools
```

## Usage Examples

```bash
# Basic statistics
vcftools --gzvcf variants.vcf.gz

# Filter by quality and depth
vcftools --gzvcf variants.vcf.gz --minQ 30 --min-meanDP 10 --recode --out filtered

# Keep specific samples
vcftools --gzvcf variants.vcf.gz --keep samples.txt --recode --out subset

# Remove specific samples
vcftools --gzvcf variants.vcf.gz --remove remove_list.txt --recode --out subset

# Filter by region
vcftools --gzvcf variants.vcf.gz --chr chr1 --from-bp 1000000 --to-bp 2000000 --recode --out region

# Keep only biallelic SNPs
vcftools --gzvcf variants.vcf.gz --min-alleles 2 --max-alleles 2 --remove-indels --recode --out snps

# Minor allele frequency filter
vcftools --gzvcf variants.vcf.gz --maf 0.05 --recode --out maf_filtered

# Calculate allele frequencies
vcftools --gzvcf variants.vcf.gz --freq --out allele_freq

# Calculate missingness per individual
vcftools --gzvcf variants.vcf.gz --missing-indv --out missing

# Calculate missingness per site
vcftools --gzvcf variants.vcf.gz --missing-site --out site_missing

# Hardy-Weinberg p-values
vcftools --gzvcf variants.vcf.gz --hardy --out hwe

# Linkage disequilibrium (r²)
vcftools --gzvcf variants.vcf.gz --geno-r2 --ld-window-bp 50000 --out ld

# FST between populations
vcftools --gzvcf variants.vcf.gz --weir-fst-pop pop1.txt --weir-fst-pop pop2.txt --out fst

# Nucleotide diversity (π) in windows
vcftools --gzvcf variants.vcf.gz --window-pi 10000 --out pi

# Convert to PLINK format
vcftools --gzvcf variants.vcf.gz --plink --out plink_data

# Site depth statistics
vcftools --gzvcf variants.vcf.gz --site-mean-depth --out depth
```

## Key Options

| Option | Description |
|--------|-------------|
| `--vcf FILE` | Input VCF |
| `--gzvcf FILE` | Input bgzipped VCF |
| `--recode` | Output filtered VCF |
| `--out PREFIX` | Output file prefix |
| `--chr` | Restrict to chromosome |
| `--minQ` | Minimum quality |
| `--min-meanDP` | Minimum mean depth |
| `--maf` | Minimum minor allele frequency |
| `--max-missing` | Max missingness (0-1) |
| `--keep FILE` | Keep samples in file |
| `--remove FILE` | Remove samples in file |
| `--remove-indels` | Keep only SNPs |

## Formats Consumed/Produced

| Format | Description |
|--------|-------------|
| [VCF](../formats/vcf.md) | Input/output variants |
| PLINK (`.ped`/`.map`) | Converted genotype data |
| Tab-delimited | Statistics outputs |

## See Also

- [bcftools](bcftools.md) — faster alternative for filtering/manipulation
- [PLINK](plink.md) — population genetics / GWAS
- [VCF format](../formats/vcf.md)
