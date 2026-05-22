# tabix

**Purpose:** Indexes and queries tab-delimited genomic position files (VCF, BED, GFF). Enables fast random access to records overlapping a given genomic region. Part of HTSlib.

**Source:** [htslib.org](https://www.htslib.org/)  
**Citation:** Li H. (2011) *Bioinformatics* 27:718-719

## Installation

```bash
conda install -c bioconda htslib
```

## Usage Examples

```bash
# Compress a VCF with bgzip (required before indexing)
bgzip variants.vcf        # produces variants.vcf.gz

# Index a bgzipped VCF (creates .tbi)
tabix -p vcf variants.vcf.gz

# Index a bgzipped BED file
bgzip regions.bed
tabix -p bed regions.bed.gz

# Index a bgzipped GFF
bgzip annotation.gff
tabix -p gff annotation.gff.gz

# Query a region from indexed VCF
tabix variants.vcf.gz chr1:1000000-2000000

# Query multiple regions
tabix variants.vcf.gz chr1:100000-200000 chr2:300000-400000

# Query with header
tabix -h variants.vcf.gz chr1:1000000-2000000

# Query from a regions file (BED)
tabix -R regions.bed variants.vcf.gz

# List all chromosome names in index
tabix -l variants.vcf.gz

# Use CSI index for large chromosomes (>512Mb)
tabix --csi variants.vcf.gz
```

## Key Options

| Option      | Description                       |
| ----------- | --------------------------------- |
| `-p FORMAT` | Preset: vcf, bed, gff, sam        |
| `-h`        | Include header in output          |
| `-R FILE`   | Restrict to regions in BED file   |
| `-l`        | List sequence names               |
| `--csi`     | Use CSI index (for large genomes) |
| `-s INT`    | Column for sequence name          |
| `-b INT`    | Column for region start           |
| `-e INT`    | Column for region end             |
| `-S INT`    | Skip header lines                 |
| `-c CHAR`   | Comment character                 |

## bgzip

`bgzip` (block gzip) is required before indexing. It creates a `.gz` file that supports random access (unlike regular gzip).

```bash
# Compress
bgzip file.vcf

# Decompress
bgzip -d file.vcf.gz

# Reindex (keep both compressed and decompressed)
bgzip -c file.vcf > file.vcf.gz
```

## Index Types

| Index | Extension | Use Case                                            |
| ----- | --------- | --------------------------------------------------- |
| TBI   | `.tbi`    | Default tabix index                                 |
| CSI   | `.csi`    | Large chromosomes (>512Mb), supports deeper binning |

## Formats Indexed

| Format                       | Preset   |
| ---------------------------- | -------- |
| [VCF](../formats/vcf.md)     | `-p vcf` |
| [BED](../formats/bed.md)     | `-p bed` |
| [GFF](../formats/gff-gtf.md) | `-p gff` |
| [SAM](../formats/sam.md)     | `-p sam` |

## See Also

- [bcftools](bcftools.md) — uses tabix indices for VCF access
- [samtools](samtools.md) — BAM indexing (`.bai`)
- [VCF format](../formats/vcf.md) — primary use case
