downshap
================

Table of contents

- [Basic Overview](#basic-overview)
- [Step by step](#step-by-step)
- [Dependencies](#dependencies)
- [Output Folders Structuration
  Creation](#output-folders-structuration-creation)

# :star: Basic Overview

:red_circle: *downshape* is an R research compendium exposing functions
to search, download, preprocess and bias-adjust CMIP6 data discovered
via the [ESGF Search RESTful
API](https://esgf.github.io/esg-search/ESGF_Search_RESTful_API.html).
This compendium allow to download observed data come from Copernicus
website.

``` mermaid
graph LR
  subgraph Graph
    direction LR
    x6fcf9b0e7fc429ff(["available_dataset_json"]):::uptodate --> xe895740a9b7896f7(["available_dataset_df"]):::uptodate
    xac02e5e58926353b(["experiments"]):::uptodate --> x6fcf9b0e7fc429ff(["available_dataset_json"]):::uptodate
    x906e78a8df9f52cb(["freq"]):::uptodate --> x6fcf9b0e7fc429ff(["available_dataset_json"]):::uptodate
    x2c0118dd07b06ac8(["time_span"]):::uptodate --> x6fcf9b0e7fc429ff(["available_dataset_json"]):::uptodate
    x8f15ec77b8dbd81a(["vars"]):::uptodate --> x6fcf9b0e7fc429ff(["available_dataset_json"]):::uptodate
    xe895740a9b7896f7(["available_dataset_df"]):::uptodate --> x3f5ab24ee8d242b4(["select_dataset"]):::uptodate
  end
```

# :point_right: Step by step

- :one: Edit experiments (ssp scenario), vars (variables), freq
  (frequence), time_span (min and max time) targets of “\_targets.R”
  file.
- :two: Run pipeline launching the first part of *makefile.R* script.

# :heavy_check_mark: Dependencies

No sowfware dependencies.

This R research compendium using renv package to fixe package version.
Run renv::restore() to update your packages in your computer and
renv::status() to check if everything is ready.

# :pushpin: Output Folders Structuration Creation

- :open_file_folder: output *–\[make.r\]–*
  - :page_facing_up: dataset_found_before_filter.csv
    *–\[select_dataset()\]–*
  - :page_facing_up: selected_datasets.csv *–\[select_dataset()\]–*
