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

    , tar_target(resotempo, list(vars = c("so", "to", "ugouvo", "zo", "WIND" ), 
                                reso = c("week", "week", "week", "week", "hour6"))) 
    ,tar_target(http_vars, list(http = c(),
                                name = c()))
    ,tar_target(current_period, list(start = "2018-01-01T00:00:00", end = "2019-12-31T23:59:59"))
    ,tar_target(spat_reso, "180x90")
    ,tar_target(deep_level, list(start = c(0, 50), end = c(50, 100)))
    ,tar_target(renameVar, list(oldname = c("so", "to", "ugo", "vgo", "zo", "chl"), newname = c("SSS", "SST", "CURRENTug", "CURRENTvg", "SSH", "CHLA")))
    ,tar_target(vars_speed, list(compo1 = c("CURRENTug"), compo2 = c("CURRENTvg"), name = c("CURRENT", "WIND")))

    ################################# CMIP data process #################################

    # Esgf dataset search & select
    ,tar_target(available_dataset_json, search_esgf(experiments, freq, vars, time_span))
    ,tar_target(available_dataset_df, cmip_parse_search(available_dataset_json))
    ,tar_target(select_dataset, select_dataset(available_dataset_df), format = "file")

    # Download and remapped esgf data selected (CMIP6)
    ,tar_target(cmip_data, download_cmip_data(select_dataset, time_span), format = "file")
    #,tar_target(cmip_data, list.files(here::here("output", "data_cmip6"), pattern = ".nc$", recursive = TRUE, full.names = TRUE))
    , tar_target(renameVar_cmip, renameVar(data = cmip_data, type_data = "cmip6", skip = TRUE), format = "file")
    ,tar_target(concatenate_cmip, concatenate_cmip(renameVar_cmip), format = "file")
    ,tar_target(remapCDO_cmip, remapCDO_cmip(concatenate_cmip), format = "file")
    ,tar_target(speedCompo_cmip, speedCompo_cmip(remapCDO_cmip, vars_speed, remove = FALSE), format = "file")
    
    ################################# Copernicus data process #################################

    # Download and remmaped copernicus data (observed)
    ,tar_target(tab_parameters, here::here("data", "copernicus_parameters.csv"), format = "file")
    ,tar_target(obs_data, copernicus_download_api(tab_parameters, skip = TRUE), format = "file")
    ,tar_target(http_data, http_download(http_vars, path_output = here::here("output", "data_copernicus"), skip = TRUE))
    ,tar_target(renameVar_copernicus, renameVar(data = c(obs_data, http_data), type_data = "copernicus", skip = FALSE), format = "file")
    ,tar_target(concatenate_copernicus, concatenate_copernicus(renameVar_copernicus), format = "file")
    ,tar_target(remapCDO_copernicus, remapCDO_copernicus(concatenate_copernicus), format = "file")
    ,tar_target(speedCompo_copernicus, speedCompo_copernicus(remapCDO_copernicus, vars_speed, remove = FALSE), format = "file")
    
    ################################# To connect downshape and modeloTrack pipeline #################################
    ,tar_target(connectPip, connectPip(speedCompo_copernicus, speedCompo_cmip))
)