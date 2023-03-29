downshape
================

Table of contents

- [Basic Overview](#basic-overview)
- [Step by step](#step-by-step)
- [Input Data Informations](#input-data-informations)
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

Warning message: Targets and globals must have unique names. Ignoring
global objects that conflict with target names: download_cmip_data,
select_dataset. Warnings like this one are important, but if you must
suppress them, you can do so with Sys.setenv(TAR_WARN = “false”).

``` mermaid
graph LR
  subgraph Graph
    direction LR
    x3f5ab24ee8d242b4(["select_dataset"]):::outdated --> xba5d8678b6176d68(["download_cmip_data"]):::outdated
    x2c0118dd07b06ac8(["time_span"]):::outdated --> xba5d8678b6176d68(["download_cmip_data"]):::outdated
    x6fcf9b0e7fc429ff(["available_dataset_json"]):::outdated --> xe895740a9b7896f7(["available_dataset_df"]):::outdated
    xac02e5e58926353b(["experiments"]):::outdated --> x6fcf9b0e7fc429ff(["available_dataset_json"]):::outdated
    x906e78a8df9f52cb(["freq"]):::outdated --> x6fcf9b0e7fc429ff(["available_dataset_json"]):::outdated
    x2c0118dd07b06ac8(["time_span"]):::outdated --> x6fcf9b0e7fc429ff(["available_dataset_json"]):::outdated
    x8f15ec77b8dbd81a(["vars"]):::outdated --> x6fcf9b0e7fc429ff(["available_dataset_json"]):::outdated
    xe895740a9b7896f7(["available_dataset_df"]):::outdated --> x3f5ab24ee8d242b4(["select_dataset"]):::outdated
    x4301c707c2ab0cdc(["tab_parameters"]):::outdated --> xd7bca5ba4e5f539d(["obs_data"]):::outdated
  end
```

# :point_right: Step by step

- :one: Edit experiments (ssp scenario), vars (variables), freq
  (frequence), time_span (min and max time) targets of “\_targets.R”
  file.
- :two: Run pipeline launching *make.R* script.

# :heavy_check_mark: Input Data Informations

:heavy_check_mark: **\[copernicus_parameters.csv\]** : csv file.
Parameters of data we want dto download. Check table structuration on
github.

# :key: Dependencies

To download Copernicus data it’s necessary to install
[python3](https://www.python.org/downloads/) and motuclient (with this
command: *python3 -m pip install motuclient==1.8.4 –no-cache-dir*)

This R research compendium using renv package to fixe package version.
Run renv::restore() to update your packages in your computer and
renv::status() to check if everything is ready.

# :pushpin: Output Folders Structuration Creation

- :open_file_folder: output *–\[make.r\]–*
  - :page_facing_up: dataset_found_before_filter.csv
    *–\[select_dataset()\]–*
  - :page_facing_up: selected_datasets.csv *–\[select_dataset()\]–*
  - :open_file_folder: data_copernicus *–\[copernicus_download_api()\]–*
    - :page_facing_up: Vars1.nc *–\[copernicus_download_api()\]–*
    - :page_facing_up: Vars2.nc *–\[copernicus_download_api()\]–*
    - :page_facing_up: VarsX.nc … *–\[copernicus_download_api()\]–*
  - :open_file_folder: data_cmip6 *–\[download_cmip_data()\]–*
    - :open_file_folder: Model_name_download
      *–\[download_cmip_data()\]–*
      - :open_file_folder: Experiment_name_download
        *–\[download_cmip_data()\]–*
        - :page_facing_up: ModelName_ExperimentName_VarsName.sh
          *–\[download_cmip_data()\]–*
        - :page_facing_up: Vars1.nc *–\[download_cmip_data()\]–*
        - :page_facing_up: Vars2.nc *–\[download_cmip_data()\]–*
        - :page_facing_up: VarsX.nc … *–\[download_cmip_data()\]–*
