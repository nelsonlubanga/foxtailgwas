#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(data.table)
  library(GAPIT)
})

project_dir <- normalizePath(getwd())
geno_dir <- file.path(project_dir, "data", "processed", "genotypes")
pheno_dir <- file.path(project_dir, "data", "processed", "blues")
output_root <- file.path(project_dir, "results", "gwas")
dir.create(output_root, recursive = TRUE, showWarnings = FALSE)

phenotype_sets <- list(
  `2023` = "gwas_phenotypes_2023.csv",
  `2024_N40` = "gwas_phenotypes_2024_N40.csv",
  `2024_N120` = "gwas_phenotypes_2024_N120.csv"
)
models <- c("MLM", "FarmCPU", "BLINK")

message("Reading marker map and compact genotype matrix")
GM <- fread(
  file.path(geno_dir, "Fox_geno.qc.012.pos"),
  col.names = c("scaffold", "Position")
)
GM[, Chromosome := as.integer(sub("^SCAFFOLD_", "", scaffold))]
GM[, SNP := paste0(scaffold, "_", Position)]
GM <- GM[, .(SNP, Chromosome, Position)]

taxa <- fread(
  file.path(geno_dir, "Fox_geno.qc.012.indv"),
  header = FALSE,
  col.names = "genotype"
)
taxa[, Taxa := .I]
fwrite(taxa[, .(Taxa, genotype)], file.path(output_root, "taxa_id_map.csv"))

expected_values <- nrow(taxa) * nrow(GM)
con <- file(file.path(geno_dir, "Fox_geno.qc.int8.bin"), open = "rb")
dosage <- readBin(con, integer(), n = expected_values, size = 1, signed = TRUE)
close(con)
if (length(dosage) != expected_values) stop("Binary genotype file has an unexpected size")
dosage[dosage == -1L] <- 1L
genotype_matrix <- matrix(dosage, nrow = nrow(taxa), ncol = nrow(GM), byrow = TRUE)
rm(dosage)
gc()

status_file <- file.path(output_root, "batch_status.csv")
record_status <- function(dataset, trait, model, n, status, started, detail = "") {
  row <- data.table(
    dataset = dataset,
    trait = trait,
    model = model,
    n = n,
    status = status,
    started = as.character(started),
    updated = as.character(Sys.time()),
    detail = detail
  )
  fwrite(row, status_file, append = file.exists(status_file), col.names = !file.exists(status_file))
}

for (dataset_name in names(phenotype_sets)) {
  phenotype <- fread(file.path(pheno_dir, phenotype_sets[[dataset_name]]))
  setnames(phenotype, 1L, "genotype")

  for (trait_name in names(phenotype)[-1L]) {
    usable <- phenotype[!is.na(get(trait_name)) & genotype %in% taxa$genotype]
    sample_rows <- match(usable$genotype, taxa$genotype)
    if (length(sample_rows) < 20L) {
      for (model_name in models) {
        record_status(dataset_name, trait_name, model_name, length(sample_rows), "skipped", Sys.time(), "fewer than 20 genotyped observations")
      }
      next
    }

    Y <- data.frame(
      Taxa = taxa$Taxa[sample_rows],
      value = usable[[trait_name]],
      check.names = FALSE
    )
    names(Y)[2L] <- trait_name
    GD <- cbind(Taxa = taxa$Taxa[sample_rows], genotype_matrix[sample_rows, , drop = FALSE])

    for (model_name in models) {
      model_dir <- file.path(output_root, dataset_name, trait_name, model_name)
      complete_file <- file.path(model_dir, ".complete")
      if (file.exists(complete_file)) next
      dir.create(model_dir, recursive = TRUE, showWarnings = FALSE)
      started <- Sys.time()
      # Reproducible model-specific stream for every environment-trait-model run.
      seed_key <- paste(dataset_name, trait_name, model_name, sep = "|")
      set.seed(20260908L + sum(utf8ToInt(seed_key) * seq_along(utf8ToInt(seed_key))))
      record_status(dataset_name, trait_name, model_name, nrow(Y), "started", started)
      message(sprintf("Starting %s / %s / %s (n=%d) at %s", dataset_name, trait_name, model_name, nrow(Y), started))

      old_dir <- setwd(model_dir)
      result <- tryCatch(
        capture.output(
          value <- GAPIT(
            Y = Y,
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
        ),
        error = function(e) e
      )
      setwd(old_dir)

      if (inherits(result, "error")) {
        record_status(dataset_name, trait_name, model_name, nrow(Y), "failed", started, conditionMessage(result))
        message(sprintf("FAILED %s / %s / %s: %s", dataset_name, trait_name, model_name, conditionMessage(result)))
      } else {
        saveRDS(value, file.path(model_dir, paste0("gapit_", model_name, "_result.rds")))
        writeLines(as.character(Sys.time()), complete_file)
        record_status(dataset_name, trait_name, model_name, nrow(Y), "completed", started)
        message(sprintf("Finished %s / %s / %s at %s", dataset_name, trait_name, model_name, Sys.time()))
      }
      if (exists("value", inherits = FALSE)) rm(value)
      rm(result)
      gc()
    }
    rm(Y, GD)
    gc()
  }
}

message("Complete GWAS batch finished")
