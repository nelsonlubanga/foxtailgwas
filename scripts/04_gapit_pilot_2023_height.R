#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(data.table)
  library(GAPIT)
})

project_dir <- normalizePath(file.path(dirname(commandArgs(trailingOnly = FALSE)[1]), ".."), mustWork = FALSE)
if (!dir.exists(file.path(project_dir, "data"))) {
  project_dir <- getwd()
}

input_dir <- file.path(project_dir, "data", "processed", "gwas_inputs")
output_root <- file.path(project_dir, "results", "gwas", "pilot_2023_height")
dir.create(output_root, recursive = TRUE, showWarnings = FALSE)

message("Reading phenotype and marker map")
Y <- fread(file.path(input_dir, "2023_height_phenotype.csv"))
setnames(Y, c("Taxa", "height_cm"))

GM <- fread(
  file.path(input_dir, "2023_height.012.pos"),
  col.names = c("scaffold", "Position")
)
GM[, Chromosome := as.integer(sub("^SCAFFOLD_", "", scaffold))]
GM[, SNP := paste0(scaffold, "_", Position)]
GM <- GM[, .(SNP, Chromosome, Position)]

taxa <- fread(
  file.path(input_dir, "2023_height.012.indv"),
  header = FALSE,
  col.names = "Taxa"
)
if (!setequal(taxa$Taxa, Y$Taxa)) stop("Phenotype and genotype sample sets differ")
Y <- Y[match(taxa$Taxa, Y$Taxa)]
if (!identical(taxa$Taxa, Y$Taxa)) stop("Failed to align phenotype to genotype order")

message("Reading compact binary genotype matrix")
binary_file <- file.path(input_dir, "2023_height.int8.bin")
expected_values <- nrow(taxa) * nrow(GM)
con <- file(binary_file, open = "rb")
dosage <- readBin(con, integer(), n = expected_values, size = 1, signed = TRUE)
close(con)
if (length(dosage) != expected_values) stop("Binary genotype file has an unexpected size")
# Match GAPIT's SNP.impute = "Middle" rule for HapMap input.
dosage[dosage == -1L] <- 1L
GD <- matrix(dosage, nrow = nrow(taxa), ncol = nrow(GM), byrow = TRUE)
rm(dosage)
gc()

# Numeric IDs allow GAPIT to accept a matrix directly, avoiding a data frame
# with almost 900,000 columns. The original accession mapping is retained here.
taxa_map <- data.table(Taxa = seq_len(nrow(taxa)), genotype = taxa$Taxa)
fwrite(taxa_map, file.path(output_root, "taxa_id_map.csv"))
Y[, Taxa := taxa_map$Taxa]
GD <- cbind(Taxa = taxa_map$Taxa, GD)

models <- c("MLM", "FarmCPU", "BLINK")
for (model_name in models) {
  model_dir <- file.path(output_root, model_name)
  dir.create(model_dir, recursive = TRUE, showWarnings = FALSE)
  old_dir <- setwd(model_dir)
  on.exit(setwd(old_dir), add = TRUE)

  message(sprintf("Starting %s at %s", model_name, Sys.time()))
  capture.output(
    result <- GAPIT(
      Y = as.data.frame(Y),
      GD = GD,
      GM = as.data.frame(GM),
      model = model_name,
      PCA.total = 3,
      kinship.algorithm = "VanRaden",
      SNP.MAF = 0,
      SNP.impute = "Middle",
      Geno.View.output = FALSE,
      PCA.View.output = model_name == "MLM",
      Phenotype.View = model_name == "MLM",
      Inter.Plot = FALSE,
      file.output = TRUE
    ),
    file = file.path(model_dir, paste0("gapit_", model_name, ".log")),
    type = "output"
  )
  saveRDS(result, file.path(model_dir, paste0("gapit_", model_name, "_result.rds")))
  setwd(old_dir)
  message(sprintf("Finished %s at %s", model_name, Sys.time()))
}

message("All pilot models completed")
