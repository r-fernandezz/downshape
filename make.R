# renv ---------------------
# renv::install() ; renv::snapshot(prompt = FALSE)
renv::restore()

######### Move target folder into output
library(targets)
dir.create(here::here("output", "_targets"), showWarnings = FALSE)
targets::tar_config_set(store = here::here("output", "_targets"))

######### Run pipeline ------------
targets::tar_visnetwork(targets_only = TRUE)
targets::tar_make()
