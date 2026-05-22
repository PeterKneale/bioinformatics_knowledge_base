# BigWig Format

**Extension:** `.bw`, `.bigwig`  
**Type:** Binary (indexed)  
**Specification:** [UCSC BigWig](https://genome.ucsc.edu/goldenPath/help/bigWig.html)

## Purpose

Binary indexed format for dense, continuous signal data across a genome. Stores numerical values (coverage, scores, signal intensity) at specific genomic positions or intervals. Enables fast display in genome browsers without loading entire datasets.

## Structure

BigWig is a compressed, indexed binary format that supports:
- Fast random access to any genomic region
- Multiple zoom levels for efficient display at different scales
- Both fixed-step and variable-step data
- Built-in summary statistics

## Indexing

BigWig files are **self-indexed** — no separate index file is needed. The R-tree index is embedded within the file, enabling instant random access to any region.

## Creating BigWig

### From BAM (most common)

```bash
# Using deepTools bamCoverage (recommended)
bamCoverage -b sorted.bam -o coverage.bw \
    --normalizeUsing RPKM --binSize 10 -p 8

# Using deepTools bamCompare (ChIP/input ratio)
bamCompare -b1 chip.bam -b2 input.bam -o log2ratio.bw -p 8

# Using deepTools with different normalisations
bamCoverage -b sorted.bam -o coverage.bw --normalizeUsing CPM
bamCoverage -b sorted.bam -o coverage.bw --normalizeUsing BPM
bamCoverage -b sorted.bam -o coverage.bw --normalizeUsing RPGC --effectiveGenomeSize 2913022398
```

### From BedGraph

```bash
# Convert BedGraph to BigWig (UCSC tools)
bedGraphToBigWig coverage.bedgraph chrom.sizes output.bw

# Generate chrom.sizes
samtools faidx reference.fa
cut -f1,2 reference.fa.fai > chrom.sizes
```

### From WIG

```bash
# Convert WIG to BigWig
wigToBigWig input.wig chrom.sizes output.bw
```

## Reading BigWig

```bash
# View signal in a region (UCSC bigWigSummary)
bigWigSummary coverage.bw chr1 1000000 2000000 10

# Extract to BedGraph
bigWigToBedGraph coverage.bw output.bedgraph

# Extract specific region
bigWigToBedGraph -chrom=chr1 -start=1000000 -end=2000000 coverage.bw region.bedgraph

# Using deepTools (compute matrix for plotting)
computeMatrix reference-point -S coverage.bw -R genes.bed -o matrix.gz
```

## Normalisation Methods (deepTools)

| Method | Description |
|--------|-------------|
| RPKM | Reads Per Kilobase per Million mapped reads |
| CPM | Counts Per Million mapped reads |
| BPM | Bins Per Million (like TPM for bins) |
| RPGC | Reads Per Genomic Content (1× coverage) |
| None | Raw read counts |

## Tools That Create This Format

| Tool | Context |
|------|---------|
| [deepTools bamCoverage](../tools/deeptools.md) | BAM → normalised BigWig |
| [deepTools bamCompare](../tools/deeptools.md) | Ratio BigWig |
| UCSC `bedGraphToBigWig` | BedGraph → BigWig |
| UCSC `wigToBigWig` | WIG → BigWig |

## Tools That Read This Format

| Tool | Purpose |
|------|---------|
| [deepTools computeMatrix](../tools/deeptools.md) | Signal matrices for heatmaps |
| [deepTools plotHeatmap/plotProfile](../tools/deeptools.md) | Visualisation |
| [IGV](https://igv.org/) | Genome browser display |
| UCSC Genome Browser | Track display |
| UCSC `bigWigSummary` | Summary statistics |
| UCSC `bigWigToBedGraph` | Convert back to text |

## BigWig vs BedGraph vs WIG

| Property | BigWig | BedGraph | WIG |
|----------|--------|----------|-----|
| Type | Binary | Text | Text |
| Indexed | Built-in | Via tabix | No |
| Random access | Fast | With tabix | No |
| File size | Small | Large | Large |
| Genome browser | Direct | Must convert | Must convert |
| Editability | No | Yes | Yes |

## See Also

- [BedGraph](bedgraph.md) — text-based coverage format
- [WIG](wig.md) — text wiggle format
- [BigBed](bigbed.md) — similar concept for interval data
- [BAM](bam.md) — source alignment data
