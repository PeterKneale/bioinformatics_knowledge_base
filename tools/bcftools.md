# bcftools

**Source:** [samtools.github.io/bcftools](https://samtools.github.io/bcftools/)  
**License:** MIT  
**Category:** Variant calling & manipulation

## Purpose

Toolkit for variant calling and manipulating VCF/BCF files. Handles SNP/indel calling, filtering, annotation, consensus generation, file merging, and format conversion. Part of the HTSlib ecosystem alongside samtools.

## Installation

```bash
conda install -c bioconda bcftools
# or
brew install bcftools
```

## Key Commands

| Command | Description |
|---------|-------------|
| `mpileup` | Generate genotype likelihoods from BAM |
| `call` | SNP/indel calling from mpileup output |
| `filter` | Filter variants by expression |
| `view` | Subset, convert, filter VCF/BCF |
| `norm` | Left-align and normalise indels |
| `merge` | Merge multiple VCF/BCF files |
| `isec` | Intersect VCF files |
| `annotate` | Add annotations from another file |
| `consensus` | Apply variants to reference FASTA |
| `stats` | VCF statistics |
| `query` | Extract fields from VCF |
| `index` | Index VCF/BCF files |

## Usage Examples

```bash
# Variant calling pipeline (mpileup + call)
bcftools mpileup -f reference.fa aligned.sorted.bam | \
  bcftools call -mv -Oz -o variants.vcf.gz

# Index a compressed VCF
bcftools index variants.vcf.gz

# Filter variants: quality >= 20, depth >= 10
bcftools filter -i 'QUAL>=20 && DP>=10' variants.vcf.gz -Oz -o filtered.vcf.gz

# Extract only SNPs
bcftools view -v snps variants.vcf.gz -Oz -o snps.vcf.gz

# Normalise indels against reference
bcftools norm -f reference.fa variants.vcf.gz -Oz -o normalised.vcf.gz

# Generate consensus FASTA from VCF
bcftools consensus -f reference.fa variants.vcf.gz > consensus.fa

# Query specific fields
bcftools query -f '%CHROM\t%POS\t%REF\t%ALT\t%QUAL\n' variants.vcf.gz

# Intersect two VCF files (shared variants)
bcftools isec -p isec_output/ fileA.vcf.gz fileB.vcf.gz

# Statistics summary
bcftools stats variants.vcf.gz > stats.txt
```

## Produces

- `.vcf.gz` — Compressed variant calls
- `.bcf` — Binary VCF
- `.csi` — CSI index for VCF/BCF

## Related Tools

- [samtools](samtools.md) — Upstream BAM processing
- [gatk](gatk.md) — Alternative variant caller
- [vcftools](vcftools.md) — VCF manipulation and population genetics
- [tabix](tabix.md) — Alternative VCF indexing (.tbi)
