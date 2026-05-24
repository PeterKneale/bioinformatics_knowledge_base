#!/usr/bin/env bash
#
# RNA-seq Processing Pipeline
# ============================
# Concatenate multi-lane FASTQs → FastQC (pre-trim) → Trimmomatic →
# FastQC (post-trim) → STAR alignment → Sort → Index
#
# Usage:
#   ./rnaseq-pipeline.sh <sample_id> <raw_data_dir> <output_dir>
#
# Example:
#   ./rnaseq-pipeline.sh sample1 /data/raw /data/processed
#
# Assumptions:
#   - Paired-end Illumina data
#   - Multi-lane FASTQs named: <sample>_L00{1,2,3,4}_R{1,2}_001.fastq.gz
#   - STAR index and adapter files already exist (paths below)
#   - Tools installed: fastqc, trimmomatic, STAR, samtools

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# ==============================================================================
# Configuration
# ==============================================================================

SAMPLE="${1:?Usage: $0 <sample_id> <raw_data_dir> <output_dir>}"
RAW_DIR="${2:?Usage: $0 <sample_id> <raw_data_dir> <output_dir>}"
OUT_DIR="${3:?Usage: $0 <sample_id> <raw_data_dir> <output_dir>}"

# Tool resources (adjust paths for your environment)
STAR_INDEX="/ref/star_index"
ADAPTERS="/ref/adapters/TruSeq3-PE-2.fa"
THREADS=8

# Create output directory structure
mkdir -p "${OUT_DIR}"/{concat,fastqc_pretrim,trimmed,fastqc_posttrim,aligned}

# ==============================================================================
# Step 1: Concatenate Multi-Lane FASTQs
# ==============================================================================
# Illumina sequencers split samples across lanes for load balancing.
# Lanes are independent observations of the same library — concatenation
# is a simple append (order doesn't matter, reads are independent).

echo "[$(date '+%H:%M:%S')] Concatenating lanes for ${SAMPLE}..."

R1_CONCAT="${OUT_DIR}/concat/${SAMPLE}_R1.fastq.gz"
R2_CONCAT="${OUT_DIR}/concat/${SAMPLE}_R2.fastq.gz"

# cat works on gzipped files because gzip streams are concatenable
# (the result is a valid gzip file containing all reads sequentially)
cat "${RAW_DIR}"/${SAMPLE}_L00*_R1_001.fastq.gz > "${R1_CONCAT}"
cat "${RAW_DIR}"/${SAMPLE}_L00*_R2_001.fastq.gz > "${R2_CONCAT}"

echo "[$(date '+%H:%M:%S')] Concatenated $(zcat "${R1_CONCAT}" | wc -l | awk '{print $1/4}') read pairs"

# ==============================================================================
# Step 2: FastQC — Pre-Trimming
# ==============================================================================
# Establishes baseline quality. Look for:
#   - Adapter contamination (Adapter Content module)
#   - Quality drop-off at read ends (Per Base Quality)
#   - Library complexity (Duplication Levels)
#   - Contamination (GC Content, Overrepresented Sequences)

echo "[$(date '+%H:%M:%S')] Running FastQC (pre-trim)..."

fastqc \
  --outdir "${OUT_DIR}/fastqc_pretrim" \
  --threads "${THREADS}" \
  --noextract \
  "${R1_CONCAT}" "${R2_CONCAT}"

# ==============================================================================
# Step 3: Trimmomatic — Adapter Removal & Quality Trimming
# ==============================================================================
# Step order matters:
#   1. ILLUMINACLIP - remove adapters first (they affect quality assessment)
#   2. LEADING/TRAILING - trim obvious low-quality ends
#   3. SLIDINGWINDOW - adaptive quality trim (4bp window, mean Q20)
#   4. MINLEN - drop reads too short to align reliably

echo "[$(date '+%H:%M:%S')] Running Trimmomatic..."

TRIM_R1="${OUT_DIR}/trimmed/${SAMPLE}_R1_paired.fastq.gz"
TRIM_R2="${OUT_DIR}/trimmed/${SAMPLE}_R2_paired.fastq.gz"
UNPAIRED_R1="${OUT_DIR}/trimmed/${SAMPLE}_R1_unpaired.fastq.gz"
UNPAIRED_R2="${OUT_DIR}/trimmed/${SAMPLE}_R2_unpaired.fastq.gz"

trimmomatic PE \
  -threads "${THREADS}" \
  -phred33 \
  "${R1_CONCAT}" "${R2_CONCAT}" \
  "${TRIM_R1}" "${UNPAIRED_R1}" \
  "${TRIM_R2}" "${UNPAIRED_R2}" \
  ILLUMINACLIP:"${ADAPTERS}":2:30:10:2:True \
  LEADING:3 \
  TRAILING:3 \
  SLIDINGWINDOW:4:20 \
  MINLEN:36 \
  2>&1 | tee "${OUT_DIR}/trimmed/${SAMPLE}_trimmomatic.log"

# ==============================================================================
# Step 4: FastQC — Post-Trimming
# ==============================================================================
# Verify trimming resolved the issues identified in Step 2.
# Compare pre/post reports (or aggregate with MultiQC).

echo "[$(date '+%H:%M:%S')] Running FastQC (post-trim)..."

fastqc \
  --outdir "${OUT_DIR}/fastqc_posttrim" \
  --threads "${THREADS}" \
  --noextract \
  "${TRIM_R1}" "${TRIM_R2}"

# ==============================================================================
# Step 5: STAR Alignment
# ==============================================================================
# Two-pass mode: discovers novel splice junctions in pass 1, then re-aligns
# using discovered junctions in pass 2. More sensitive for novel isoforms.
#
# Key settings:
#   --outSAMtype BAM SortedByCoordinate  → STAR sorts internally (saves a step)
#   --quantMode GeneCounts               → Gene-level counts (like featureCounts)
#   --outSAMattributes                   → Tags needed for downstream tools

echo "[$(date '+%H:%M:%S')] Running STAR alignment..."

STAR_OUT="${OUT_DIR}/aligned/${SAMPLE}_"

STAR \
  --genomeDir "${STAR_INDEX}" \
  --readFilesIn "${TRIM_R1}" "${TRIM_R2}" \
  --readFilesCommand zcat \
  --runThreadN "${THREADS}" \
  --outSAMtype BAM SortedByCoordinate \
  --outSAMattributes NH HI AS NM MD nM \
  --twopassMode Basic \
  --quantMode GeneCounts \
  --outFileNamePrefix "${STAR_OUT}"

# STAR outputs: ${STAR_OUT}Aligned.sortedByCoord.out.bam (already coordinate-sorted)

# ==============================================================================
# Step 6: Index the BAM
# ==============================================================================
# BAM indexing creates a .bai file enabling O(log n) region queries.
# Required by: IGV, GATK, samtools view <region>, deepTools, etc.
# Prerequisite: BAM must be coordinate-sorted (STAR did this for us).

echo "[$(date '+%H:%M:%S')] Indexing BAM..."

FINAL_BAM="${STAR_OUT}Aligned.sortedByCoord.out.bam"

samtools index -@ "${THREADS}" "${FINAL_BAM}"

# ==============================================================================
# Step 7: Quick QC Summary
# ==============================================================================
# flagstat provides a fast sanity check of the alignment.

echo "[$(date '+%H:%M:%S')] Generating alignment statistics..."

samtools flagstat "${FINAL_BAM}" > "${OUT_DIR}/aligned/${SAMPLE}_flagstat.txt"
samtools idxstats "${FINAL_BAM}" > "${OUT_DIR}/aligned/${SAMPLE}_idxstats.txt"

# ==============================================================================
# Summary
# ==============================================================================

echo ""
echo "========================================"
echo "Pipeline complete for: ${SAMPLE}"
echo "========================================"
echo ""
echo "Outputs:"
echo "  Concatenated FASTQs:   ${OUT_DIR}/concat/"
echo "  Pre-trim QC:           ${OUT_DIR}/fastqc_pretrim/"
echo "  Trimmed reads:         ${OUT_DIR}/trimmed/"
echo "  Post-trim QC:          ${OUT_DIR}/fastqc_posttrim/"
echo "  Aligned BAM:           ${FINAL_BAM}"
echo "  BAM index:             ${FINAL_BAM}.bai"
echo "  Gene counts:           ${STAR_OUT}ReadsPerGene.out.tab"
echo "  Splice junctions:      ${STAR_OUT}SJ.out.tab"
echo "  STAR log:              ${STAR_OUT}Log.final.out"
echo "  Alignment stats:       ${OUT_DIR}/aligned/${SAMPLE}_flagstat.txt"
echo ""
echo "Next steps:"
echo "  - Aggregate QC with: multiqc ${OUT_DIR}"
echo "  - DE analysis with ReadsPerGene.out.tab (column 4 for dUTP libraries)"
echo "  - Or run featureCounts on the BAM for more control"
