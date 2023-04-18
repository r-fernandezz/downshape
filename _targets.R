library(targets)

Sys.setenv(TAR_WARN = "false")

targets::tar_source()

list(

    ################################# EDIT ME !! Project parameters #################################
    tar_target(experiments, c("piControl","historical", "ssp126", "ssp245", "ssp370", "ssp534-over", "ssp585"))
    ,tar_target(vars, c("so", "zos", "uo", "vo", "thetao", "chl", "uas", "vas", "sfcWind"))
    ,tar_target(freq, "mon")
    ,tar_target(time_span, list(start = "1982-01-01T00:00:00Z", end = "2100-12-31T23:59:59Z"))
    ,tar_target(historical_period, list(start = "1850-01-01T00:00:00", end = "2014-12-01T00:00:00"))
    ,tar_target(futur_period, list(start = "2015-01-01T00:00:00", end = "2100-12-01T00:00:00"))

    ,tar_target(current_period, list(start = "2018-01-01T00:00:00", end = "2019-12-31T23:59:59"))
    ,tar_target(spat_reso, "180x90")
    ,tar_target(deep_level, list(start = c(0, 50), end = c(50, 100)))
    ,tar_target(vars_speed, list(compo1 = c("uvo", "eastward_wind"), compo2 = c("vgo", "northward_wind"), name = "CURRENT", "WIND"))

    ################################# CMIP data process #################################

    # Esgf dataset search & select
    ,tar_target(available_dataset_json, search_esgf(experiments, freq, vars, time_span))
    ,tar_target(available_dataset_df, cmip_parse_search(available_dataset_json))
    ,tar_target(select_dataset, select_dataset(available_dataset_df), format = "file")

    # Download and remapped esgf data selected (CMIP6)
    ,tar_target(cmip_data, download_cmip_data(select_dataset, time_span), format = "file")
    #,tar_target(cmip_data, list.files(here::here("output", "data_cmip6"), pattern = ".nc$", recursive = TRUE, full.names = TRUE))
    ,tar_target(concatenate_cmip, concatenate_cmip(cmip_data), format = "file")
    ,tar_target(remapCDO_cmip, remapCDO_cmip(concatenate_cmip), format = "file")
    ,tar_target(speedCompo_cmip2, speedCompo_cmip(remapCDO_cmip, vars_speed, remove = FALSE), format = "file")
    
    ################################# Copernicus data process #################################

    # Download and remmaped copernicus data (observed)
    ,tar_target(tab_parameters, here::here("data", "copernicus_parameters.csv"), format = "file")
    ,tar_target(obs_data, copernicus_download_api(tab_parameters), format = "file")
    ,tar_target(remapCDO_copernicus, remapCDO_copernicus(obs_data), format = "file")
    ,tar_target(speedCompo_copernicus, speedCompo_copernicus(remapCDO_copernicus, vars_speed, remove = FALSE), format = "file")

)