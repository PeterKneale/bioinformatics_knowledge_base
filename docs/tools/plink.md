# PLINK

**Purpose:** Whole-genome association analysis toolkit. Handles genotype data management, quality control, population stratification, and genome-wide association testing (GWAS).

**Source:** [cog-genomics.org/plink](https://www.cog-genomics.org/plink/)  
**Citation:** Chang C.C. et al. (2015) *GigaScience* 4:7 (PLINK 1.9)

## Versions

| Version   | Notes                                           |
| --------- | ----------------------------------------------- |
| PLINK 1.9 | Stable, widely used                             |
| PLINK 2.0 | Faster, better file formats, VCF native support |

## Installation

```bash
conda install -c bioconda plink
conda install -c bioconda plink2  # for PLINK 2.0
```

## Usage Examples

```bash
# Import VCF
plink --vcf variants.vcf.gz --make-bed --out dataset

# Basic QC filtering
plink --bfile dataset \
    --maf 0.01 \
    --geno 0.05 \
    --mind 0.1 \
    --hwe 1e-6 \
    --make-bed --out qc_dataset

# LD pruning
plink --bfile qc_dataset --indep-pairwise 50 5 0.2 --out ld_prune
plink --bfile qc_dataset --extract ld_prune.prune.in --make-bed --out pruned

# PCA (population structure)
plink --bfile pruned --pca 10 --out pca_results

# Association testing (case/control)
plink --bfile qc_dataset --assoc --out assoc_results

# Logistic regression with covariates
plink --bfile qc_dataset --logistic --covar covariates.txt --out logistic_results

# IBD/relatedness
plink --bfile pruned --genome --out ibd

# Sex check
plink --bfile dataset --check-sex --out sex_check

# Merge datasets
plink --bfile dataset1 --bmerge dataset2 --make-bed --out merged

# Extract specific SNPs
plink --bfile dataset --extract snp_list.txt --make-bed --out subset

# Frequency report
plink --bfile dataset --freq --out freq_report
```

## PLINK 2.0 Examples

```bash
# Import VCF with PLINK 2
plink2 --vcf variants.vcf.gz --make-pgen --out dataset

# GWAS with linear regression
plink2 --pfile dataset --glm --covar covariates.txt --out gwas_results

# Allele frequency
plink2 --pfile dataset --freq --out freq
```

## File Formats

| Extension | Format | Description                   |
| --------- | ------ | ----------------------------- |
| `.bed`    | Binary | Genotype matrix (binary)      |
| `.bim`    | Text   | Variant information           |
| `.fam`    | Text   | Sample information            |
| `.pgen`   | Binary | PLINK 2 genotype (compressed) |
| `.pvar`   | Text   | PLINK 2 variant info          |
| `.psam`   | Text   | PLINK 2 sample info           |

## Key Options

| Option           | Description             |
| ---------------- | ----------------------- |
| `--bfile PREFIX` | Input BED/BIM/FAM       |
| `--vcf FILE`     | Input VCF               |
| `--make-bed`     | Output BED/BIM/FAM      |
| `--maf FLOAT`    | Min allele frequency    |
| `--geno FLOAT`   | Max missing per variant |
| `--mind FLOAT`   | Max missing per sample  |
| `--hwe FLOAT`    | HWE p-value threshold   |
| `--out PREFIX`   | Output prefix           |

## See Also

- [vcftools](vcftools.md) — VCF filtering and pop-gen stats
- [bcftools](bcftools.md) — VCF manipulation
- [VCF format](../formats/vcf.md)
