#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(data.table))

project_dir <- normalizePath(getwd())
gwas_dir <- file.path(project_dir, "results", "gwas")
summary_dir <- file.path(gwas_dir, "summary")
dir.create(summary_dir, recursive = TRUE, showWarnings = FALSE)

alpha <- 0.05
datasets <- c("2023", "2024_N40", "2024_N120")
files <- unlist(lapply(datasets, function(dataset) {
  list.files(
    file.path(gwas_dir, dataset),
    pattern = "^GAPIT\\.Association\\.GWAS_Results.*\\(NYC\\)\\.csv$",
    recursive = TRUE,
    full.names = TRUE
  )
}), use.names = FALSE)

if (length(files) != 72L) {
  stop(sprintf("Expected 72 primary GWAS tables, found %d", length(files)))
}

analysis_summary <- vector("list", length(files))
significant_hits <- vector("list", length(files))

for (i in seq_along(files)) {
  file <- files[[i]]
  relative <- sub(paste0("^", gwas_dir, "/"), "", file)
  parts <- strsplit(relative, "/", fixed = TRUE)[[1]]
  dataset <- parts[[1]]
  trait <- parts[[2]]
  model <- parts[[3]]

  header <- names(fread(file, nrows = 0L))
  effect_column <- intersect(c("Effect", "effect"), header)
  wanted <- intersect(c("SNP", "Chr", "Pos", "P.value", "MAF", "nobs", effect_column), header)
  result <- fread(file, select = wanted)
  setnames(result, effect_column, "Effect", skip_absent = TRUE)

  tested <- sum(is.finite(result$P.value) & !is.na(result$P.value))
  threshold <- alpha / tested
  hit <- result[is.finite(P.value) & P.value <= threshold]
  if (nrow(hit)) {
    hit[, `:=`(
      dataset = dataset,
      trait = trait,
      model = model,
      markers_tested = tested,
      bonferroni_threshold = threshold,
      minus_log10_p = -log10(P.value)
    )]
    setcolorder(
      hit,
      c("dataset", "trait", "model", "SNP", "Chr", "Pos", "P.value",
        "minus_log10_p", "bonferroni_threshold", "markers_tested",
        setdiff(names(hit), c("dataset", "trait", "model", "SNP", "Chr", "Pos",
                              "P.value", "minus_log10_p", "bonferroni_threshold",
                              "markers_tested")))
    )
  }

  finite_p <- result$P.value[is.finite(result$P.value)]
  analysis_summary[[i]] <- data.table(
    dataset = dataset,
    trait = trait,
    model = model,
    markers_tested = tested,
    bonferroni_threshold = threshold,
    minus_log10_threshold = -log10(threshold),
    significant_associations = nrow(hit),
    minimum_p = if (length(finite_p)) min(finite_p) else NA_real_,
    top_snp = if (length(finite_p)) result$SNP[which.min(result$P.value)] else NA_character_
  )
  significant_hits[[i]] <- hit
  message(sprintf("%d/72 %s / %s / %s: %d hits", i, dataset, trait, model, nrow(hit)))
}

analysis_summary <- rbindlist(analysis_summary, fill = TRUE)
significant_hits <- rbindlist(significant_hits, fill = TRUE)
setorder(analysis_summary, dataset, trait, model)
if (nrow(significant_hits)) setorder(significant_hits, dataset, trait, model, P.value)

fwrite(analysis_summary, file.path(summary_dir, "bonferroni_summary_by_analysis.csv"))
fwrite(significant_hits, file.path(summary_dir, "bonferroni_significant_associations.csv"))

trait_summary <- analysis_summary[, .(
  significant_associations = sum(significant_associations),
  models_with_hits = sum(significant_associations > 0L),
  minimum_p = min(minimum_p, na.rm = TRUE)
), by = .(dataset, trait)]
setorder(trait_summary, dataset, trait)
fwrite(trait_summary, file.path(summary_dir, "bonferroni_summary_by_trait.csv"))

if (nrow(significant_hits)) {
  recurrent <- significant_hits[, .(
    association_count = .N,
    datasets = paste(sort(unique(dataset)), collapse = ";"),
    traits = paste(sort(unique(trait)), collapse = ";"),
    models = paste(sort(unique(model)), collapse = ";"),
    minimum_p = min(P.value),
    Chr = first(Chr),
    Pos = first(Pos)
  ), by = SNP]
  setorder(recurrent, -association_count, minimum_p)
  fwrite(recurrent, file.path(summary_dir, "bonferroni_recurrent_snps.csv"))
}

cat(sprintf(
  "Completed %d analyses; %d significant associations involving %d unique SNPs.\n",
  nrow(analysis_summary), nrow(significant_hits), uniqueN(significant_hits$SNP)
))
