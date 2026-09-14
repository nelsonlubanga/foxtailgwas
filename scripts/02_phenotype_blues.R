#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
  library(asreml)
})

input_file <- "data/processed/phenotypes_plot_clean.csv"
output_dir <- "data/processed/blues"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

dat <- read_csv(input_file, show_col_types = FALSE) |>
  mutate(
    genotype = factor(genotype),
    block = factor(block),
    treatment = factor(treatment)
  )

traits_2023 <- c(
  "dtf", "height_cm", "plants_m2", "thousand_seed_weight_g",
  "protein_pct", "fat_pct", "panicle_length_cm", "pedicel_length_cm"
)

traits_2024 <- c(
  "dtf", "height_cm", "plants_m2", "number_of_tillers", "days_to_harvest",
  "normalized_difference_vegetation_index", "fluorescence", "protein_pct"
)

tidy_asreml_predictions <- function(fit, trait, year, scope) {
  fit$predictions$pvals |>
    as.data.frame() |>
    as_tibble() |>
    rename(blue = predicted.value, standard_error = std.error) |>
    mutate(
      year = year,
      trait = trait,
      scope = scope,
      estimable = status == "Estimable" & !is.na(blue),
      .before = 1
    ) |>
    select(year, trait, scope, everything())
}

fit_asreml_blue <- function(d, trait) {
  fit <- asreml(
    fixed = reformulate("genotype", response = trait),
    random = ~ block,
    residual = ~ idv(units),
    data = d,
    predict = predict.asreml(classify = "genotype"),
    maxit = 50,
    trace = FALSE
  )
  for (i in seq_len(5)) {
    if (isTRUE(fit$converge)) break
    fit <- update.asreml(fit)
  }
  fit
}

asreml_qc <- function(fit, d, trait, year, treatment = NA_character_) {
  vc <- summary(fit)$varcomp
  get_vc <- function(pattern) {
    hit <- grep(pattern, rownames(vc), value = TRUE)
    if (length(hit) == 0) return(NA_real_)
    vc[hit[1], "component"]
  }
  pred <- fit$predictions$pvals
  tibble(
    year = year, treatment = treatment, trait = trait,
    model = paste(trait, "~ genotype; random = ~ block"),
    n_observations = nrow(d), n_genotypes = n_distinct(d$genotype),
    converged = isTRUE(fit$converge), log_likelihood = fit$loglik,
    block_variance = get_vc("^block$"),
    residual_variance = get_vc("^units!units$"),
    n_estimable_blues = sum(pred$status == "Estimable", na.rm = TRUE),
    n_nonestimable_blues = sum(pred$status != "Estimable" | is.na(pred$predicted.value))
  )
}

fit_2023 <- function(trait) {
  d <- dat |>
    filter(year == 2023, !is.na(.data[[trait]])) |>
    droplevels()

  if (nrow(d) == 0 || n_distinct(d$genotype) < 2) return(NULL)

  fit <- fit_asreml_blue(d, trait)
  blue <- tidy_asreml_predictions(fit, trait, 2023L, "year")
  qc <- asreml_qc(fit, d, trait, 2023L)
  list(blue = blue, qc = qc)
}

fit_2024 <- function(trait) {
  d <- dat |>
    filter(year == 2024, !is.na(.data[[trait]])) |>
    droplevels()

  if (nrow(d) == 0 || n_distinct(d$genotype) < 2) return(NULL)

  # Nitrogen treatments occupied separate field halves. Fit each half as its
  # own randomized-block trial rather than estimating a treatment main effect.
  fitted_halves <- lapply(c("N40", "N120"), function(trt) {
    ds <- d |> filter(treatment == trt) |> droplevels()
    if (nrow(ds) == 0 || n_distinct(ds$genotype) < 2) return(NULL)
    fit <- fit_asreml_blue(ds, trait)
    blue <- tidy_asreml_predictions(fit, trait, 2024L, "treatment") |>
      mutate(treatment = trt, .after = scope)
    qc <- asreml_qc(fit, ds, trait, 2024L, trt)
    list(blue = blue, qc = qc)
  })

  by_treatment <- bind_rows(lapply(fitted_halves, `[[`, "blue"))
  qc <- bind_rows(lapply(fitted_halves, `[[`, "qc"))

  paired <- by_treatment |>
    select(genotype, treatment, blue, standard_error) |>
    pivot_wider(
      names_from = treatment,
      values_from = c(blue, standard_error)
    )

  # Treatments were in separate field halves, so covariance is taken as zero.
  # The contrast is useful as an exploratory plasticity phenotype, but it does
  # not support an unconfounded population-level test of nitrogen treatment.
  nitrogen_response <- paired |>
    transmute(
      year = 2024L, trait = trait, scope = "N120_minus_N40_exploratory",
      genotype,
      contrast = "N120 - N40",
      blue = blue_N120 - blue_N40,
      standard_error = sqrt(standard_error_N120^2 + standard_error_N40^2),
      estimable = !is.na(blue)
    )

  overall <- paired |>
    transmute(
      year = 2024L, trait = trait, scope = "year_descriptive",
      genotype,
      blue = (blue_N40 + blue_N120) / 2,
      standard_error = sqrt(standard_error_N40^2 + standard_error_N120^2) / 2,
      estimable = !is.na(blue)
    )

  list(by_treatment = by_treatment, overall = overall,
       nitrogen_response = nitrogen_response, qc = qc)
}

res23 <- lapply(traits_2023, fit_2023)
res24 <- lapply(traits_2024, fit_2024)

blue23_long <- bind_rows(lapply(res23, `[[`, "blue"))
blue24_treatment_long <- bind_rows(lapply(res24, `[[`, "by_treatment"))
blue24_overall_long <- bind_rows(lapply(res24, `[[`, "overall"))
blue24_response_long <- bind_rows(lapply(res24, `[[`, "nitrogen_response"))
model_qc <- bind_rows(
  lapply(res23, `[[`, "qc"),
  lapply(res24, `[[`, "qc")
)

write_csv(blue23_long, file.path(output_dir, "blue_2023_long.csv"), na = "")
write_csv(blue24_treatment_long,
          file.path(output_dir, "blue_2024_by_treatment_long.csv"), na = "")
write_csv(blue24_overall_long,
          file.path(output_dir, "blue_2024_overall_long.csv"), na = "")
write_csv(blue24_response_long,
          file.path(output_dir, "blue_2024_nitrogen_response_long.csv"), na = "")
write_csv(model_qc, file.path(output_dir, "blue_model_qc.csv"), na = "")

# Wide matrices are convenient phenotype inputs for GWAS software. Standard
# errors remain in the long files and are not discarded.
blue23_wide <- blue23_long |>
  select(genotype, trait, blue) |>
  pivot_wider(names_from = trait, values_from = blue)

blue24_overall_wide <- blue24_overall_long |>
  select(genotype, trait, blue) |>
  pivot_wider(names_from = trait, values_from = blue)

blue24_treatment_wide <- blue24_treatment_long |>
  mutate(trait_treatment = paste(trait, treatment, sep = "__")) |>
  select(genotype, trait_treatment, blue) |>
  pivot_wider(names_from = trait_treatment, values_from = blue)

blue24_n40_wide <- blue24_treatment_long |>
  filter(treatment == "N40") |>
  select(genotype, trait, blue) |>
  pivot_wider(names_from = trait, values_from = blue)

blue24_n120_wide <- blue24_treatment_long |>
  filter(treatment == "N120") |>
  select(genotype, trait, blue) |>
  pivot_wider(names_from = trait, values_from = blue)

blue24_response_wide <- blue24_response_long |>
  select(genotype, trait, blue) |>
  pivot_wider(names_from = trait, values_from = blue, names_prefix = "deltaN__")

write_csv(blue23_wide, file.path(output_dir, "gwas_phenotypes_2023.csv"), na = "")
write_csv(blue24_overall_wide,
          file.path(output_dir, "gwas_phenotypes_2024_overall.csv"), na = "")
write_csv(blue24_treatment_wide,
          file.path(output_dir, "gwas_phenotypes_2024_by_treatment.csv"), na = "")
write_csv(blue24_n40_wide,
          file.path(output_dir, "gwas_phenotypes_2024_N40.csv"), na = "")
write_csv(blue24_n120_wide,
          file.path(output_dir, "gwas_phenotypes_2024_N120.csv"), na = "")
write_csv(blue24_response_wide,
          file.path(output_dir, "gwas_phenotypes_2024_nitrogen_response.csv"), na = "")

message("2023: fitted ", length(res23), " traits for ",
        n_distinct(blue23_long$genotype), " genotypes")
message("2024: fitted ", length(res24), " traits for ",
        n_distinct(blue24_overall_long$genotype), " genotypes")
message("Primary 2024 GWAS inputs: gwas_phenotypes_2024_N40.csv and ",
        "gwas_phenotypes_2024_N120.csv")
message("Outputs written to ", output_dir)
