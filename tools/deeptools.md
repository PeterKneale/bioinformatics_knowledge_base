# deepTools

**Source:** [deeptools.readthedocs.io](https://deeptools.readthedocs.io/)  
**License:** GPL-3.0  
**Category:** BAM/BigWig analysis & visualisation

## Purpose

Suite of tools for normalising, visualising, and quality-checking deep-sequencing data. Converts BAM to normalised coverage tracks (BigWig), generates heatmaps and profile plots around genomic features, and provides BAM-level QC (fingerprint plots, correlation matrices, PCA).

## Installation

```bash
conda install -c bioconda deeptools
# or
pip install deeptools
```

## Key Tools

| Tool | Description |
|------|-------------|
| `bamCoverage` | BAM → normalised BigWig |
| `bamCompare` | Log2 ratio of two BAM files (ChIP/input) |
| `computeMatrix` | Score matrix around features for plotting |
| `plotHeatmap` | Heatmap from computeMatrix output |
| `plotProfile` | Average profile plot from computeMatrix output |
| `multiBamSummary` | Genome-wide read count matrix |
| `plotCorrelation` | Sample correlation heatmap |
| `plotPCA` | PCA of samples |
| `plotFingerprint` | Assess ChIP enrichment |
| `alignmentSieve` | Filter BAM by fragment size, MAPQ |

## Usage Examples

```bash
# Convert BAM to normalised BigWig (RPKM)
bamCoverage -b aligned.sorted.bam \
  -o coverage.bw \
  --normalizeUsing RPKM \
  --binSize 10 \
  -p 8

# ChIP vs input log2 ratio BigWig
bamCompare -b1 chip.bam -b2 input.bam \
  -o log2ratio.bw \
  --normalizeUsing RPKM \
  -p 8

# Compute signal matrix around TSS
computeMatrix reference-point -S coverage.bw \
  -R genes.bed \
  --referencePoint TSS \
  -a 3000 -b 3000 \
  -o matrix.gz

# Plot heatmap
plotHeatmap -m matrix.gz -o heatmap.png

# Plot average profile
plotProfile -m matrix.gz -o profile.png

# Sample correlation
multiBamSummary bins --bamfiles s1.bam s2.bam s3.bam \
  -o results.npz -p 8
plotCorrelation -in results.npz --corMethod spearman \
  --whatToPlot heatmap -o correlation.png

# PCA of samples
plotPCA -in results.npz -o pca.png

# Fingerprint plot (ChIP enrichment QC)
plotFingerprint -b chip.bam input.bam -o fingerprint.png
```

## Produces

- `.bw` (BigWig) — Normalised coverage tracks
- `.gz` — Compressed matrices (computeMatrix)
- `.png` / `.pdf` — Plots and heatmaps
- `.npz` — NumPy summary arrays

## Related Tools

- [samtools](samtools.md) — BAM depth (unnormalised)
- [bedtools](bedtools.md) — BedGraph coverage (unnormalised)
- [igv](https://igv.org/) — Visualise BigWig tracks
