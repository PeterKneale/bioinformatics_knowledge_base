# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a bioinformatics knowledge base repository containing reference documentation for command-line tools and file formats used in next-generation sequencing (NGS) analysis. The repository is structured into two main sections:

1. **CLI Tools** (`tools/` directory) - Documentation for bioinformatics command-line tools including alignment, variant calling, quantification, and visualization
2. **File Formats** (`formats/` directory) - Documentation for bioinformatics file formats and their indexing strategies

## Key Directories and Files

- `tools/` - Contains reference documentation for bioinformatics CLI tools in individual markdown files
- `tools/INDEX.md` - Index of all tools organized by category
- `formats/` - Contains reference documentation for bioinformatics file formats
- `formats/INDEX.md` - Index of all file formats organized by category

## Common Tasks

### Adding New Tool Documentation
When adding documentation for a new bioinformatics tool:
1. Create a new markdown file in the `tools/` directory
2. Follow the existing format with sections for Source, License, Category, Purpose, Installation, Key Commands, Usage Examples, and Related Tools
3. Update `tools/INDEX.md` to include the new tool in the appropriate category

### Adding New File Format Documentation
When adding documentation for a new bioinformatics file format:
1. Create a new markdown file in the `formats/` directory
2. Follow the existing format with sections for Description, Indexing, Coordinate Systems, and Format Conversion Paths
3. Update `formats/INDEX.md` to include the new format

### Updating Existing Documentation
- All documentation is in markdown format
- Follow existing conventions for formatting and structure
- Ensure examples are complete and runnable commands
- Keep installation instructions up to date with current package managers (conda, brew)

## Development Workflow

This is a documentation-only repository focused on reference materials. No code compilation or testing is required. Documentation is maintained as markdown files that serve as reference materials for bioinformatics practitioners.

## Tools and Formats Reference

The repository provides comprehensive reference materials for:
- Short-read alignment tools (BWA, Bowtie2, minimap2)
- RNA-seq alignment tools (STAR, HISAT2)
- Variant calling tools (GATK, bcftools, FreeBayes)
- Quantification tools (featureCounts, HTSeq-count, Kallisto, Salmon)
- Alignment processing tools (samtools, Picard)
- Coverage and visualization tools (deepTools, bedtools)
- Sequence search and alignment tools (BLAST, HMMER, MUSCLE, MAFFT)
- File formats and indexing strategies (FASTQ, FASTA, SAM, BAM, VCF, BED, BigWig, etc.)

## Index Structure

The repository uses a consistent index structure:
- Tools are organized by category in `tools/INDEX.md`
- File formats are organized by category in `formats/INDEX.md`
- Each tool/format has its own dedicated markdown file with comprehensive documentation