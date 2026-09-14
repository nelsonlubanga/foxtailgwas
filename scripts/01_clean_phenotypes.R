#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tidyr)
  library(ggplot2)
})

raw_file <- "data/raw/Field trail data Foxtail millet for PIs.xlsx"
processed_dir <- "data/processed"
qc_dir <- "data/processed/qc"
figure_dir <- "figures/qc"

dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(qc_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

clean_text <- function(x) {
  x <- str_squish(as.character(x))
  na_if(x, "")
}

clean_id <- function(x) {
  n <- str_extract(clean_text(x), "[0-9]+")
  if_else(is.na(n), NA_character_, paste0("Fm", as.integer(n)))
}

number_or_na <- function(x) {
  suppressWarnings(parse_number(clean_text(x), na = c("", "NA", "n/a", "*")))
}

is_special_missing <- function(x) clean_text(x) %in% c("*", "n/a")

safe_stat <- function(x, fun) {
  if (all(is.na(x))) return(NA_real_)
  fun(x, na.rm = TRUE)
}

# 2023: one management regime and three plot replicates per genotype.
p23_raw <- read_excel(raw_file, sheet = "Field23", col_types = "text") |>
  mutate(across(everything(), clean_text))

p23 <- p23_raw |>
  transmute(
    year = 2023L,
    genotype = clean_id(Genotype),
    origin = `Place of origin`,
    genetic_cluster = na_if(`Visual Genetic Cluster`, "*"),
    genetic_cluster_raw = `Visual Genetic Cluster`,
    treatment = "None",
    nitrogen_level = NA_real_,
    treatment_inferred = FALSE,
    block = as.integer(number_or_na(Rep)),
    dtf_raw = DtF,
    dtf = if_else(number_or_na(DtF) > 0, number_or_na(DtF), NA_real_),
    flowering_event = case_when(
      number_or_na(DtF) > 0 ~ 1L,
      TRUE ~ NA_integer_
    ),
    flowering_code = case_when(
      DtF == "0" ~ "zero_code",
      DtF == "*" ~ "star_code",
      is.na(DtF) ~ "missing",
      TRUE ~ "observed"
    ),
    height_cm_raw = `Plant Height (cm)`,
    height_cm = if_else(number_or_na(`Plant Height (cm)`) > 0,
                        number_or_na(`Plant Height (cm)`), NA_real_),
    height_zero_flag = number_or_na(`Plant Height (cm)`) == 0,
    plants_m2_raw = `plt/m2 (Agnes)`,
    plants_m2 = number_or_na(`plt/m2 (Agnes)`),
    plants_m2_zero_flag = number_or_na(`plt/m2 (Agnes)`) == 0,
    number_of_tillers = NA_real_,
    days_to_harvest = NA_real_,
    normalized_difference_vegetation_index = NA_real_,
    fluorescence = NA_real_,
    thousand_seed_weight_g = number_or_na(`1000 seed weight (gr) (Agnes)`),
    protein_pct = number_or_na(`% Protein (Charlotte)`),
    fat_pct = number_or_na(`fat (%) (Louise)`),
    thousand_seed_protein = number_or_na(`1000 seed Protein`),
    thousand_seed_fat = number_or_na(`1000 seed Fat`),
    panicle_length_cm = number_or_na(`Panicle length cm (Luis and Millie)`),
    pedicel_length_cm = number_or_na(`Pedecile length cm (Luis and Millie)`)
  )

# 2024: two nitrogen treatments and three blocks per genotype. Columns named
# Ave/Std are genotype-treatment summaries repeated on plot rows and are
# deliberately excluded to avoid pseudoreplication.
p24_raw <- read_excel(raw_file, sheet = "Field24", col_types = "text") |>
  mutate(across(everything(), clean_text)) |>
  rename(origin = `...2`, genetic_cluster_raw = `...3`)

# One treatment cell is '*'. The balanced design makes it recoverable: within
# a genotype-block pair, the missing treatment must be the other of 40/120.
p24_raw <- p24_raw |>
  mutate(
    genotype_clean = clean_id(Geno),
    block_clean = as.integer(number_or_na(Block)),
    treatment_original = Treatment
  ) |>
  group_by(genotype_clean, block_clean) |>
  mutate(
    treatment_inferred = Treatment == "*",
    Treatment = case_when(
      Treatment != "*" ~ Treatment,
      any(Treatment == "40", na.rm = TRUE) ~ "120",
      any(Treatment == "120", na.rm = TRUE) ~ "40",
      TRUE ~ NA_character_
    )
  ) |>
  ungroup()

p24 <- p24_raw |>
  transmute(
    year = 2024L,
    genotype = genotype_clean,
    origin,
    genetic_cluster = na_if(genetic_cluster_raw, "*"),
    genetic_cluster_raw,
    treatment = paste0("N", Treatment),
    nitrogen_level = number_or_na(Treatment),
    treatment_inferred,
    block = block_clean,
    dtf_raw = DtF,
    dtf = if_else(number_or_na(DtF) > 0, number_or_na(DtF), NA_real_),
    flowering_event = case_when(
      number_or_na(DtF) > 0 ~ 1L,
      TRUE ~ NA_integer_
    ),
    flowering_code = case_when(
      DtF == "0" ~ "zero_code",
      DtF == "*" ~ "star_code",
      is.na(DtF) ~ "missing",
      TRUE ~ "observed"
    ),
    height_cm_raw = Height,
    height_cm = if_else(number_or_na(Height) > 0, number_or_na(Height), NA_real_),
    height_zero_flag = number_or_na(Height) == 0,
    plants_m2_raw = `Plants/m2`,
    plants_m2 = number_or_na(`Plants/m2`),
    plants_m2_zero_flag = number_or_na(`Plants/m2`) == 0,
    number_of_tillers = number_or_na(Tillers),
    days_to_harvest = number_or_na(`Days to Harvest`),
    normalized_difference_vegetation_index = number_or_na(NVDI),
    fluorescence = number_or_na(Flourescence),
    thousand_seed_weight_g = NA_real_,
    protein_pct = number_or_na(`%Protein`),
    fat_pct = NA_real_,
    thousand_seed_protein = NA_real_,
    thousand_seed_fat = NA_real_,
    panicle_length_cm = NA_real_,
    pedicel_length_cm = NA_real_
  )

phenotypes <- bind_rows(p23, p24) |>
  arrange(year, genotype, treatment, block) |>
  mutate(plot_id = paste(year, genotype, treatment, block, sep = "_"), .before = 1)

if (anyDuplicated(phenotypes$plot_id)) stop("Duplicate plot IDs detected")
if (any(is.na(phenotypes$genotype))) stop("Unparseable genotype IDs detected")
if (any(is.na(phenotypes$block))) stop("Unparseable block values detected")
if (any(is.na(p24$nitrogen_level))) stop("Unresolved 2024 treatment values detected")

write_csv(phenotypes, file.path(processed_dir, "phenotypes_plot_clean.csv"), na = "")

trait_names <- c(
  "dtf", "height_cm", "plants_m2", "number_of_tillers", "days_to_harvest",
  "normalized_difference_vegetation_index", "fluorescence", "thousand_seed_weight_g", "protein_pct",
  "fat_pct", "thousand_seed_protein", "thousand_seed_fat",
  "panicle_length_cm", "pedicel_length_cm"
)

qc_summary <- phenotypes |>
  select(year, treatment, all_of(trait_names)) |>
  pivot_longer(all_of(trait_names), names_to = "trait", values_to = "value") |>
  group_by(year, treatment, trait) |>
  summarise(
    n_rows = n(),
    n_observed = sum(!is.na(value)),
    n_missing = sum(is.na(value)),
    minimum = safe_stat(value, min),
    median = safe_stat(value, median),
    mean = safe_stat(value, mean),
    maximum = safe_stat(value, max),
    .groups = "drop"
  )
write_csv(qc_summary, file.path(qc_dir, "trait_summary.csv"), na = "")

design_summary <- phenotypes |>
  group_by(year, treatment) |>
  summarise(
    n_plots = n(),
    n_genotypes = n_distinct(genotype),
    n_blocks = n_distinct(block),
    n_origins = n_distinct(origin),
    .groups = "drop"
  )
write_csv(design_summary, file.path(qc_dir, "design_summary.csv"), na = "")

issues <- bind_rows(
  phenotypes |> filter(treatment_inferred) |>
    transmute(plot_id, issue = "treatment_inferred", raw_value = "*", action = treatment),
  phenotypes |> filter(flowering_code != "observed") |>
    transmute(plot_id, issue = paste0("dtf_", flowering_code), raw_value = dtf_raw,
              action = "dtf and flowering_event set missing; raw code retained"),
  phenotypes |> filter(height_zero_flag %in% TRUE) |>
    transmute(plot_id, issue = "height_zero", raw_value = height_cm_raw,
              action = "height_cm set missing; raw value retained"),
  phenotypes |> filter(plants_m2_zero_flag %in% TRUE) |>
    transmute(plot_id, issue = "plants_m2_zero", raw_value = plants_m2_raw,
              action = "zero retained; review as possible establishment failure")
)
write_csv(issues, file.path(qc_dir, "flagged_observations.csv"), na = "")

combined_raw <- read_excel(raw_file, sheet = "Field 23-24", col_types = "text")
combined_2024_ids <- combined_raw |>
  filter(as.integer(Year) == 2024L) |>
  transmute(genotype = clean_id(Genotype)) |>
  distinct() |>
  pull(genotype)
omitted_2024_ids <- setdiff(unique(p24$genotype), combined_2024_ids)

# Audit the manually combined sheet. In its 2024 rows, the three shared trait
# headings are shifted: the column labelled DtF contains Plants/m2, the column
# labelled Plant Height contains DtF, and the column labelled plt/m2 contains
# Height. Record match rates so this is detected reproducibly.
combined_2024 <- combined_raw |>
  filter(as.integer(Year) == 2024L) |>
  transmute(
    genotype = clean_id(Genotype), treatment = as.character(Treatment),
    block = as.integer(number_or_na(Rep)), combined_dtf = as.character(DtF),
    combined_height = as.character(`Plant Height (cm)`),
    combined_plants_m2 = as.character(`plt/m2`)
  )
raw_2024_compare <- p24_raw |>
  transmute(
    genotype = genotype_clean, treatment = Treatment, block = block_clean,
    raw_plants_m2 = as.character(`Plants/m2`), raw_dtf = as.character(DtF),
    raw_height = as.character(Height)
  )
sheet_audit <- inner_join(
  raw_2024_compare, combined_2024,
  by = c("genotype", "treatment", "block")
)
sheet_mapping <- tibble(
  combined_heading = c("DtF", "Plant Height (cm)", "plt/m2"),
  matching_raw_field = c("Plants/m2", "DtF", "Height"),
  n_compared = nrow(sheet_audit),
  n_exact_matches = c(
    sum(coalesce(sheet_audit$combined_dtf, "__NA__") ==
          coalesce(sheet_audit$raw_plants_m2, "__NA__")),
    sum(coalesce(sheet_audit$combined_height, "__NA__") ==
          coalesce(sheet_audit$raw_dtf, "__NA__")),
    sum(coalesce(sheet_audit$combined_plants_m2, "__NA__") ==
          coalesce(sheet_audit$raw_height, "__NA__"))
  )
) |>
  mutate(match_fraction = n_exact_matches / n_compared)
write_csv(sheet_mapping, file.path(qc_dir, "combined_sheet_2024_mapping_audit.csv"))

workbook_comparison <- tibble(
  item = c(
    "Field23 raw rows", "Field24 raw rows", "Clean rows",
    "Field24 genotypes", "Combined-sheet 2024 genotypes",
    "Field24 genotypes absent from combined sheet"
  ),
  value = c(
    nrow(p23_raw), nrow(p24_raw), nrow(phenotypes),
    n_distinct(p24$genotype),
    length(combined_2024_ids),
    length(omitted_2024_ids)
  ),
  note = c(
    "", "", "Built from raw year sheets, not the combined sheet",
    "", "Calculated from the combined sheet", paste(omitted_2024_ids, collapse = "; ")
  )
)
write_csv(workbook_comparison, file.path(qc_dir, "workbook_comparison.csv"), na = "")

p <- phenotypes |>
  filter(!is.na(dtf)) |>
  ggplot(aes(x = interaction(year, treatment, sep = " / "), y = dtf)) +
  geom_boxplot(outlier.alpha = 0.35) +
  labs(x = "Year / treatment", y = "Days to flowering",
       title = "Days to flowering after conservative cleaning") +
  theme_bw(base_size = 11)
ggsave(file.path(figure_dir, "dtf_by_year_treatment.png"), p,
       width = 7, height = 4.5, dpi = 180)

message("Wrote ", nrow(phenotypes), " cleaned plot records")
message("Review data/processed/qc/flagged_observations.csv before phenotype modelling")
