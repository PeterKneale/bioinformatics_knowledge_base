# WIG Format (Wiggle)

**Extension:** `.wig`  
**Type:** Text  
**Specification:** [UCSC Wiggle Format](https://genome.ucsc.edu/goldenPath/help/wiggle.html)

## Purpose

Text format for displaying dense, continuous data (coverage, conservation scores, GC content) as a track in genome browsers. Supports both fixed-step (uniform spacing) and variable-step (irregular positions) data.

## Structure

### Fixed-Step (uniform intervals)

```text
fixedStep chrom=chr1 start=1 step=10 span=10
0.5
0.8
1.2
0.9
```

All values are equally spaced. `step` = distance between values, `span` = size of each value.

### Variable-Step (irregular positions)

```text
variableStep chrom=chr1 span=10
1000    0.5
1050    0.8
1200    1.2
2000    0.9
```

Each line specifies position and value.

### Parameters

| Parameter | Description                         |
| --------- | ----------------------------------- |
| `chrom`   | Chromosome name                     |
| `start`   | Start position (1-based)            |
| `step`    | Distance between values (fixedStep) |
| `span`    | Size of each feature (default: 1)   |

## Indexing

WIG files are **not indexed**. For random access, convert to BigWig:

```bash
# Convert WIG to indexed BigWig
wigToBigWig input.wig chrom.sizes output.bw
```

## Tools That Create This Format

| Tool                   | Context                  |
| ---------------------- | ------------------------ |
| Various coverage tools | Legacy format output     |
| Conservation pipelines | PhyloP, PhastCons scores |

## Tools That Read This Format

| Tool                | Purpose                  |
| ------------------- | ------------------------ |
| UCSC `wigToBigWig`  | Convert to BigWig        |
| UCSC Genome Browser | Display (prefers BigWig) |

## Notes

- WIG is largely replaced by BigWig for most applications
- Convert to BigWig for efficient storage and access
- Use BedGraph instead if you need per-region (non-uniform) coverage

## See Also

- [BigWig](bigwig.md) — indexed binary version (preferred)
- [BedGraph](bedgraph.md) — alternative text coverage format
