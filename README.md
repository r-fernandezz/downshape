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

``` mermaid
graph LR
  subgraph Graph
    direction LR
    x3f5ab24ee8d242b4(["select_dataset"]):::outdated --> xba5d8678b6176d68(["download_cmip_data"]):::outdated
    x2c0118dd07b06ac8(["time_span"]):::outdated --> xba5d8678b6176d68(["download_cmip_data"]):::outdated
    x6fcf9b0e7fc429ff(["available_dataset_json"]):::outdated --> xe895740a9b7896f7(["available_dataset_df"]):::outdated
    x96804873c73726bd(["concatenate_data"]):::outdated --> x160e3ae24bfccc51(["remap_cmip_data"]):::outdated
    xbce5cad1cf7e7103(["futur_period"]):::outdated --> x160e3ae24bfccc51(["remap_cmip_data"]):::outdated
    x57dd1d5e854c11b6(["historical_period"]):::outdated --> x160e3ae24bfccc51(["remap_cmip_data"]):::outdated
    xe73cbbcc20086ecd(["spat_reso"]):::outdated --> x160e3ae24bfccc51(["remap_cmip_data"]):::outdated
    xac02e5e58926353b(["experiments"]):::outdated --> x6fcf9b0e7fc429ff(["available_dataset_json"]):::outdated
    x906e78a8df9f52cb(["freq"]):::outdated --> x6fcf9b0e7fc429ff(["available_dataset_json"]):::outdated
    x2c0118dd07b06ac8(["time_span"]):::outdated --> x6fcf9b0e7fc429ff(["available_dataset_json"]):::outdated
    x8f15ec77b8dbd81a(["vars"]):::outdated --> x6fcf9b0e7fc429ff(["available_dataset_json"]):::outdated
    xe895740a9b7896f7(["available_dataset_df"]):::outdated --> x3f5ab24ee8d242b4(["select_dataset"]):::outdated
    x084994fb0e480676(["current_period"]):::outdated --> x8bfa010e2da6177f(["remap_copernicus_data"]):::outdated
    xd7bca5ba4e5f539d(["obs_data"]):::outdated --> x8bfa010e2da6177f(["remap_copernicus_data"]):::outdated
    xe73cbbcc20086ecd(["spat_reso"]):::outdated --> x8bfa010e2da6177f(["remap_copernicus_data"]):::outdated
    xba5d8678b6176d68(["download_cmip_data"]):::outdated --> x96804873c73726bd(["concatenate_data"]):::outdated
    x4301c707c2ab0cdc(["tab_parameters"]):::outdated --> xd7bca5ba4e5f539d(["obs_data"]):::outdated
    x625f066a5f205ec8(["deep_level"]):::outdated --> x625f066a5f205ec8(["deep_level"]):::outdated
  end
```

# :point_right: Step by step

- :one: Import files necessary into data folder
- :two: Edit targets of “\_targets.R” file.
- :three: Run pipeline launching *make.R* script

# :heavy_check_mark: Input Informations

## Data folder

:heavy_check_mark: **\[copernicus_parameters.csv\]** : csv file.
Parameters of data we want dto download. Check table structuration on
github.

:heavy_check_mark: **\[Mask_PA_variable.shp\]** : Shapefile. Mask of
study area to crop environmental rasters with CDO. This shapefile will
be convert to NETCDF file with *gdal* before being used by CDO.

## Targets script

:heavy_check_mark: **\[experiments\]** : To select ssp scenario
downloaded (check on esgf website menu)

:heavy_check_mark: **\[vars\]** : To select variables downloaded (check
on esgf website menu).

:heavy_check_mark: **\[freq\]** : To select frequence of variables
downloaded (check on esgf website menu).

:heavy_check_mark: **\[time_span\]** : To select min and max time of
variables downloaded (format example:“1982-01-01T00:00:00Z”).

:heavy_check_mark: **\[historical_period\]** : List start and end time.
To define min and max time of historical period (cdo format:
“YYYY-MM-DDThh:mm:ss”).

:heavy_check_mark: **\[future_period\]** : List start and end time. To
define min and max time of future period (cdo format:
“YYYY-MM-DDThh:mm:ss”).

:heavy_check_mark: **\[spat_reso\]** : To remap variables with CDO
swoftware by bilinear method allowing change spatial resolution (cdo
command format: “180x90” correspond to 2°x2°, “360x180” correspond to
1°x1°).

:heavy_check_mark: **\[deep_level\]** : List start and end deep level by
file created. To split variable to several files by deep level. First
(or n) element of “start” vector correspond to first (or n) element of
“end” vector.

# :key: Dependencies

To download Copernicus data it’s necessary to install
[python3](https://www.python.org/downloads/) and motuclient (Ubuntu
command: *python3 -m pip install motuclient==1.8.4 –no-cache-dir*).

To formate cmip data it’s necessary to install
[gdal](https://gdal.org/download.html),
[cdo](https://code.mpimet.mpg.de/projects/cdo/embedded/index.html#x1-30001.1),
[nco](https://command-not-found.com/ncrename).

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
  - :open_file_folder: cmip6_data_remapped *–\[remap_cmip_data()\]–*
    - :open_file_folder: Model_name_download *–\[remap_cmip_data()\]–*
      - :page_facing_up: Vars1.nc *–\[remap_cmip_data()\]–*
      - :page_facing_up: Vars2.nc *–\[remap_cmip_data()\]–*
      - :page_facing_up: VarsX.nc *–\[remap_cmip_data()\]–*
