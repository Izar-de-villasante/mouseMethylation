#
# Author: Raúl Sanz
#
# Description: Script to plot the methylation and the detected DMRs in a defined range of the genome.
#

# PACKAGES INSTALLATION

# BiocManager::install("Gviz")
# install.packages("dplyr")
# BiocManager::install("coMET")
# BiocManager::install("GenomicFeatures")
# BiocManager::install("org.Hs.eg.db")
# BiocManager::install("org.Mm.eg.db")
# BiocManager::install("TxDb.Hsapiens.UCSC.hg19.knownGene")
# BiocManager::install("TxDb.Mmusculus.UCSC.mm39.refGene")

# REQUIRED PACKAGES

library(Gviz)
library(dplyr)
library(coMET)
library(GenomicFeatures)
library(org.Hs.eg.db)
# library(org.Mm.eg.db)
library(TxDb.Hsapiens.UCSC.hg19.knownGene)
# library(TxDb.Mmusculus.UCSC.mm39.refGene)

# FUNCTION

plot.DMR <- function(genome, chr, start, end, CpGs, DMRs, enhancers, feature){
  # genomic coordinates
  gtrack <- GenomeAxisTrack()
  
  # representation of the chromosome
  itrack <- IdeogramTrack(genome=genome, chromosome=chr)
  
  # gene model
  txdb_hg19 <- TxDb.Hsapiens.UCSC.hg19.knownGene # human model
  ### *mouse*: txdb_mm39 <- TxDb.Mmusculus.UCSC.mm39.refGene
  gene_model <- GeneRegionTrack(txdb_hg19, genome=genome, chromosome=chr, showId=TRUE, geneSymbol=TRUE, name="UCSC")
  ## show symbol ID instead of transcript ID
  symbols <- unlist(mapIds(org.Hs.eg.db, gene(gene_model), "SYMBOL", "ENTREZID", multiVals="first"))
  ### *mouse*: symbols <- unlist(mapIds(org.Mm.eg.db, gene(gene_model), "SYMBOL", "ENTREZID", multiVals="first"))
  symbol(gene_model) <- symbols[gene(gene_model)]
  
  # enhancers
  enh <- AnnotationTrack(start=c(enhancers$start), end=c(enhancers$end), chromosome=chr, name="enh", fill="darkgreen", col="darkgreen")
  
  # detected DMRs
  DMR_track <- AnnotationTrack(start=c(DMRs$start), end=c(DMRs$end), chromosome=chr, name="DMRs", col="purple4", fill="purple4")
  
  # heatmap of the methylation values at every CpG site
  heatmap <- DataTrack(CpGs, name=" ",chromosome = chr, type="heatmap", showSampleNames=T, cex.sampleNames=0.7, 
                      gradient=c(colorRampPalette(c("blue", "white", "red"))(n = 299)), separator=2)
  
  # average methylation level per group
  if(missing(feature)){ # if feature to group is not specified
    methylation <- DataTrack(CpGs, name="Methylation", chromosome=chr, type="a", groups=colnames(CpGs@elementMetadata))
  } else{
    methylation <- DataTrack(CpGs, name="Methylation", chromosome=chr, type="a", groups=feature)
  }
  
  plotTracks(list(itrack, gtrack, gene_model, enh, DMR_track, heatmap, methylation), from=start, to=end, 
             extend.left=0.1, extend.right=0.1, sizes=c(2,2,5,2,2,10,5))
}

# USAGE

# reference genome of the specie to plot
genome <- "hg19"
# chromosome to represent
chr <- "chr3"
# range to plot (first and last position)
start <- 37493945
end <- 37498950

# annotated enhancers from FANTOM5 project
enh_FANTOM <- DNaseI_FANTOM(gen=genome, chr=chr, start=start, end=end, bedFilePath="data/enhancers_human.bed",
                           featureDisplay='enhancer', stacking_type="full")
enh_FANTOM.df <- as.data.frame(enh_FANTOM@range@ranges)
enhancers <- enh_FANTOM.df

# GenomicRanges object including the position of the CpG site and its beta values associated
CpGs <- gmSet@rowRanges
values(CpGs) <- beta_values

# data frame containing the detected DMRs with the human_methylation.R script 
DMRs <- read.csv("results/human//DMR_list.csv") 

# feature to group the samples (optional)
## read metadata...
feature <- metadata$Condition

plot.DMR(genome, chr, start, end, CpGs, DMRs, enhancers, feature)