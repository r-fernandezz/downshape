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
    x9289bfb53112cf3b(["concatenate_copernicus"]):::outdated --> xec6283d15a25ed08(["remapCDO_copernicus"]):::outdated
    xd2508c5b4a2cb302(["renameVar_cmip6"]):::outdated --> x4fe875b2492d0106(["concatenate_cmip"]):::outdated
    x4fe875b2492d0106(["concatenate_cmip"]):::outdated --> xf4b49e2ba07661b1(["remapCDO_cmip"]):::outdated
    xe44467b2b079fc18(["renameVar_copernicus"]):::outdated --> x9289bfb53112cf3b(["concatenate_copernicus"]):::outdated
    xd7bca5ba4e5f539d(["obs_data"]):::outdated --> xe44467b2b079fc18(["renameVar_copernicus"]):::outdated
    xd15c82dcb79a7c2e(["renameVar"]):::outdated --> xe44467b2b079fc18(["renameVar_copernicus"]):::outdated
    xac02e5e58926353b(["experiments"]):::uptodate --> x6fcf9b0e7fc429ff(["available_dataset_json"]):::uptodate
    x906e78a8df9f52cb(["freq"]):::uptodate --> x6fcf9b0e7fc429ff(["available_dataset_json"]):::uptodate
    x2c0118dd07b06ac8(["time_span"]):::uptodate --> x6fcf9b0e7fc429ff(["available_dataset_json"]):::uptodate
    x8f15ec77b8dbd81a(["vars"]):::uptodate --> x6fcf9b0e7fc429ff(["available_dataset_json"]):::uptodate
    x4301c707c2ab0cdc(["tab_parameters"]):::uptodate --> xd7bca5ba4e5f539d(["obs_data"]):::outdated
    xf4b49e2ba07661b1(["remapCDO_cmip"]):::outdated --> x0a3d6e672db943e2(["speedCompo_cmip2"]):::outdated
    xca459201a27e8460(["vars_speed"]):::outdated --> x0a3d6e672db943e2(["speedCompo_cmip2"]):::outdated
    x6fcf9b0e7fc429ff(["available_dataset_json"]):::uptodate --> xe895740a9b7896f7(["available_dataset_df"]):::uptodate
    xec6283d15a25ed08(["remapCDO_copernicus"]):::outdated --> xfc6ed28680e5db72(["speedCompo_copernicus"]):::errored
    xca459201a27e8460(["vars_speed"]):::outdated --> xfc6ed28680e5db72(["speedCompo_copernicus"]):::errored
    xe895740a9b7896f7(["available_dataset_df"]):::uptodate --> x3f5ab24ee8d242b4(["select_dataset"]):::outdated
    xd8e5f2013a341013(["cmip_data"]):::outdated --> xd2508c5b4a2cb302(["renameVar_cmip6"]):::outdated
    xd15c82dcb79a7c2e(["renameVar"]):::outdated --> xd2508c5b4a2cb302(["renameVar_cmip6"]):::outdated
    x3f5ab24ee8d242b4(["select_dataset"]):::outdated --> xd8e5f2013a341013(["cmip_data"]):::outdated
    x2c0118dd07b06ac8(["time_span"]):::uptodate --> xd8e5f2013a341013(["cmip_data"]):::outdated
    x084994fb0e480676(["current_period"]):::uptodate --> x084994fb0e480676(["current_period"]):::uptodate
    x625f066a5f205ec8(["deep_level"]):::uptodate --> x625f066a5f205ec8(["deep_level"]):::uptodate
    xbce5cad1cf7e7103(["futur_period"]):::uptodate --> xbce5cad1cf7e7103(["futur_period"]):::uptodate
    x57dd1d5e854c11b6(["historical_period"]):::uptodate --> x57dd1d5e854c11b6(["historical_period"]):::uptodate
    xe73cbbcc20086ecd(["spat_reso"]):::uptodate --> xe73cbbcc20086ecd(["spat_reso"]):::uptodate
  end
```

# :point_right: Step by step

- :one: Import files necessary into data folder
- :two: Edit targets of “\_targets.R” file.
- :three: Run pipeline launching *make.R* script

# :heavy_check_mark: Input Informations

## Data folder

| Columns database |                                                                                                      Description                                                                                                      |
|:----------------:|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------:|
| my_variable_name |                                                                                       Your variable name (outside api command)                                                                                        |
|       motu       |                                                                                        Check API request on Copernicus website                                                                                        |
|    service_id    |                                                                                        Check API request on Copernicus website                                                                                        |
|    product_id    |                                                                                        Check API request on Copernicus website                                                                                        |
|  longitude_min   |                                                                                               Extend of map downloaded                                                                                                |
|  longitude_max   |                                                                                               Extend of map downloaded                                                                                                |
|   latitude_min   |                                                                                               Extend of map downloaded                                                                                                |
|   latitude_max   |                                                                                               Extend of map downloaded                                                                                                |
|     date_min     |                                                                       Date. Format *Year-Month-Day* hours:minutes:seconds (2017-11-25 12:20:00)                                                                       |
|     date_max     |                                                                       Date. Format *Year-Month-Day* hours:minutes:seconds (2017-11-25 12:20:00)                                                                       |
|    depth_min     | Numeric. Depth in meters. If you want to download one depth layer, same value for “depth_min” and “depth_max”. If it’s a 3D variable (with depth dimension) the depth must be provided otherwise leave the cell empty |
|    depth_max     | Numeric. Depth in meters. If you want to download one depth layer, same value for “depth_min” and “depth_max”. If it’s a 3D variable (with depth dimension) the depth must be provided otherwise leave the cell empty |
|     variable     |                                                      Short name of variable downloaded. If several variable by product create one line by variable in the table                                                       |
|       DOI        |                                                                                               Check Copernicus website                                                                                                |

heavy_check_mark: **\[copernicus_parameters.csv\]** : csv file.
Parameters of data we want to download with one row by variable
downloaded. Check table structuration asked bellow. If variable have big
size, Copernicus api can’t to download and it’s necessary to divided
variable in several small time periods (use “divide”, “subvar” and
“septime” argument of copernicus_download_api() function). If a
parameter into this table doesn’t exist for your product (example :
depth) just leave the cell empty. Columns “date_min” and “date_max” must
be larger than (or equal) *current_period* target (into \*\_targets.R
file\*). If variable name (column “variable”) have a name with “\_“,”-“,
?, rename with **rename** target to one word without specials characters
(otherwise CDO command doesn’t work).

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
cmip6 variables downloaded (format example:“1982-01-01T00:00:00Z”).

:heavy_check_mark: **\[historical_period\]** : List start and end time.
To define min and max time of cmip6 data historical period (cdo format:
“YYYY-MM-DDThh:mm:ss”).

:heavy_check_mark: **\[future_period\]** : List start and end time. To
define min and max time of cmip6 data future period (cdo format:
“YYYY-MM-DDThh:mm:ss”).

:heavy_check_mark: **\[current_period\]** : List start and end time. To
define min and max time of copernicus data current period (cdo format:
“YYYY-MM-DDThh:mm:ss”). This period must overlap periods downloaded into
**copernicus_parameters.csv**.

:heavy_check_mark: **\[spat_reso\]** : To remap variables with CDO
swoftware by bilinear method allowing change spatial resolution (cdo
command format: “180x90” correspond to 2°x2°, “360x180” correspond to
1°x1°).

:heavy_check_mark: **\[deep_level\]** : List start and end deep level by
file created. To split variable to several files by deep level. First
(or n) element of “start” vector correspond to first (or n) element of
“end” vector. vectors of the list can be empty.

:heavy_check_mark: **\[renameVar\]** : List with old name and new name.
First (or n) element of “oldname” vector correspond to first (or n)
element of “newname” vector. Allow to rename into NETCDF file the
variable downloaded. This vectors gathers all old and new variable names
used to rename cmip6 and copernicus data.

:heavy_check_mark: **\[vars_speed\]** : List first, second component and
variable name. To calcul variable speed with two components (name vector
are juste used into code but it’s not names of output files). First (or
n) element of “compo1” vector correspond to first (or n) element of
“compo2” vector. If one short names of variable is same to cmip6 and
copernicus data, write one time. WARNING !! : If two different variables
have same component name, bug in the code. This target will be modified
by speedCompo_cmip() and speedCompo_copernicus() function to integrate
depth variables created during the process (chl50-100, uo0-100, etc…).
For example, final name of the variable named “wind” in this target and
calculated with “uo” and “vo” components will be “uovo” (two component
names will be always pasted to give final name of speed file). In this
vector, given variable names after the rename step with renameVar()
function and **renameVar** target.

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
  - :open_file_folder: data_cmip6_remapped *–\[remapCDO_cmip()\]–*
    - :open_file_folder: Model_name_download *–\[remapCDO_cmip()\]–*
      - :page_facing_up: Vars1.nc *–\[remapCDO_cmip()\]–*
      - :page_facing_up: Vars2.nc *–\[remapCDO_cmip()\]–*
      - :page_facing_up: VarsX.nc *–\[remapCDO_cmip()\]–*
      - :page_facing_up: Vars_speed.nc *–\[speedCompo_cmip()\]–*
  - :open_file_folder: data_copernicus *–\[copernicus_download_api()\]–*
    - :page_facing_up: copernicus_parameters_modified.csv
      *–\[copernicus_download_api()\]–*
    - :page_facing_up: Vars1.nc *–\[copernicus_download_api()\]–*
    - :page_facing_up: Vars2.nc *–\[copernicus_download_api()\]–*
    - :page_facing_up: VarsX.nc … *–\[copernicus_download_api()\]–*
  - :open_file_folder: data_copernicus_remapped
    *–\[remapCDO_copernicus()\]–*
    - month
      - :page_facing_up: Vars1.nc *–\[remapCDO_copernicus()\]–*
      - :page_facing_up: Vars2.nc *–\[remapCDO_copernicus()\]–*
      - :page_facing_up: VarsX.nc *–\[remapCDO_copernicus()\]–*
      - :page_facing_up: Vars_speed.nc *–\[speedCompo_copernicus()\]–*
    - week
      - :page_facing_up: Vars1.nc *–\[remapCDO_copernicus()\]–*
      - :page_facing_up: Vars2.nc *–\[remapCDO_copernicus()\]–*
      - :page_facing_up: VarsX.nc *–\[remapCDO_copernicus()\]–*
      - :page_facing_up: Vars_speed.nc *–\[speedCompo_copernicus()\]–*
