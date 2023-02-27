# renv ---------------------
# renv::install() ; renv::snapshot(prompt = FALSE)
# renv::restore()

# run pipeline ------------
library(targets)
targets::tar_visnetwork(targets_only = TRUE)
dir.create("outputs")
tar_make()
