# BCF Format (Binary Call Format)

**Extension:** `.bcf`  
**Type:** Binary (BGZF-compressed)  
**Specification:** [BCF2 Format](https://samtools.github.io/hts-specs/BCFv2_qref.pdf)

## Purpose

Binary representation of VCF data. Provides faster I/O and smaller file sizes compared to text VCF, while containing identical information. Analogous to the BAM-SAM relationship. Particularly beneficial for large multi-sample VCF files.

## Structure

BCF is a binary encoding of the VCF data model:
- Same header as VCF
- Records stored as typed binary values
- BGZF block compression
- Supports random access via CSI index

## Indexing

### CSI Index (`.csi`)

```bash
# Index a BCF file
bcftools index variants.bcf       # → variants.bcf.csi

# Query a region
bcftools view variants.bcf chr1:1000000-2000000
```

## Creating BCF

```bash
# Convert VCF to BCF
bcftools view -Ob variants.vcf.gz -o variants.bcf
bcftools index variants.bcf

# Call variants directly to BCF
bcftools mpileup -f ref.fa sorted.bam | bcftools call -mv -Ob -o variants.bcf

# Any bcftools command with -Ob outputs BCF
bcftools filter -i 'QUAL>=20' variants.vcf.gz -Ob -o filtered.bcf
```

## Reading BCF

```bash
# View BCF as VCF text
bcftools view variants.bcf

# Convert BCF to compressed VCF
bcftools view -Oz variants.bcf -o variants.vcf.gz

# Query region
bcftools view variants.bcf chr1:1000000-2000000

# All bcftools operations work transparently on BCF
bcftools stats variants.bcf
bcftools query -f '%CHROM\t%POS\t%REF\t%ALT\n' variants.bcf
```

## Output Format Flags (bcftools)

| Flag  | Format                        |
| ----- | ----------------------------- |
| `-Ov` | Uncompressed VCF              |
| `-Oz` | Compressed VCF (.vcf.gz)      |
| `-Ob` | BCF                           |
| `-Ou` | Uncompressed BCF (for piping) |

## BCF vs VCF Comparison

| Property       | VCF (.vcf.gz)         | BCF                          |
| -------------- | --------------------- | ---------------------------- |
| Size           | Larger                | ~10-20% smaller              |
| Read speed     | Slower (text parsing) | Faster (binary)              |
| Index          | .tbi or .csi          | .csi                         |
| Human-readable | Yes (with zless)      | No                           |
| Tool support   | Universal             | bcftools, GATK, htslib-based |

## Tools That Create This Format

| Tool                             | Context                |
| -------------------------------- | ---------------------- |
| [bcftools](../tools/bcftools.md) | Any command with `-Ob` |

## Tools That Read This Format

| Tool                             | Purpose                     |
| -------------------------------- | --------------------------- |
| [bcftools](../tools/bcftools.md) | All VCF/BCF operations      |
| [GATK](../tools/gatk.md)         | Variant analysis            |
| Any htslib-based tool            | Transparent VCF/BCF support |

## When to Use BCF

- Large multi-sample call sets (1000+ samples)
- Pipelines with many bcftools operations (faster I/O)
- When piping between bcftools commands (`-Ou` for uncompressed BCF)

## See Also

- [VCF](vcf.md) — text version
- [BAM](bam.md) — similar binary concept for alignments
