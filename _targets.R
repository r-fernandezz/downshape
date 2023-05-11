library(targets)

Sys.setenv(TAR_WARN = "false")

targets::tar_source()

list(

    ################################# EDIT ME !! Project parameters #################################
    tar_target(experiments, c("historical", "ssp126", "ssp245", "ssp370", "ssp534-over", "ssp585"))
    ,tar_target(vars, c("thetao"))
    ,tar_target(freq, "mon")
    ,tar_target(time_span, list(start = "1982-01-01T00:00:00Z", end = "2100-12-31T23:59:59Z"))
    ,tar_target(historical_period, list(start = "1850-01-01T00:00:00", end = "2014-12-01T00:00:00"))
    ,tar_target(futur_period, list(start = "2015-01-01T00:00:00", end = "2100-12-01T00:00:00"))
    ,tar_target(vars_speed_cmip, list(compo1 = c(), compo2 = c(), name = c()))
    
    ,tar_target(resotempo, list(vars = c("SSS", "SST", "CURRENTug", "CURRENTvg", "SSH", "CHLA", "WIND", "BATHY"), 
                                reso = c("week", "week", "week", "week", "week", "week", "hour6", "FIXE"))) 
    ,tar_target(http_vars, list(http = c("https://www.ngdc.noaa.gov/mgg/global/relief/ETOPO2/ETOPO2v2-2006/ETOPO2v2g/netCDF/ETOPO2v2g_f4_netCDF.zip"),
                                name = c("BATHY")))
    ,tar_target(current_period, list(start = "2018-01-03T00:00:00", end = "2019-10-30T23:59:59"))
    ,tar_target(spat_reso, "180x90")
    ,tar_target(deep_level, list(start = c(0, 50), end = c(50, 100)))
    ,tar_target(renameVar, list(oldname = c("so", "to", "ugo", "vgo", "zo", "chl", "wind_speed", "topo", "thetao"), newname = c("SSS", "SST", "CURRENTug", "CURRENTvg", "SSH", "CHLA", "WIND", "BATHY", "SSTcmip")))
    ,tar_target(vars_speed, list(compo1 = c("CURRENTug"), compo2 = c("CURRENTvg"), name = c("CURRENT")))
    ,tar_target(bathy_CDO, TRUE)

    ################################# CMIP data process #################################

    # Esgf dataset search & select
    ,tar_target(available_dataset_json, search_esgf(experiments, freq, vars, time_span, skip = TRUE))
    ,tar_target(available_dataset_df, cmip_parse_search(available_dataset_json, skip = TRUE))
    ,tar_target(select_dataset, select_dataset(available_dataset_df, skip = TRUE), format = "file")

    # Download and remapped esgf data selected (CMIP6)
    ,tar_target(cmip_data, download_cmip_data(select_dataset, time_span, skip = TRUE), format = "file")
    ,tar_target(renameVar_cmip, renameVar(data = cmip_data, type_data = "cmip6", skip = TRUE), format = "file")
    ,tar_target(concatenate_cmip, concatenate_cmip(renameVar_cmip), format = "file")
    ,tar_target(remapCDO_cmip, remapCDO_cmip(concatenate_cmip), format = "file")
    ,tar_target(speedCompo_cmip, speedCompo_cmip(remapCDO_cmip, vars_speed_cmip, remove = FALSE), format = "file")
    
    ################################# Copernicus data process #################################

    # Download and remmaped copernicus data (observed)
    # ,tar_target(tab_parameters, here::here("data", "copernicus_parameters.csv"), format = "file")
    # ,tar_target(obs_data, copernicus_download_api(tab_parameters, skip = TRUE), format = "file")
    # ,tar_target(bathy_vars, downloadCDO_bathy(bathy_CDO, skip = FALSE), format = "file")
    # ,tar_target(http_data, http_download(http_vars, path_output = here::here("output", "data_copernicus"), skip = TRUE))
    
    # ,tar_target(renameVar_copernicus, renameVar(data = c(obs_data, http_data, bathy_vars), type_data = "copernicus", skip = FALSE), format = "file")
    # ,tar_target(concatenate_copernicus, concatenate_copernicus(renameVar_copernicus), format = "file")
    # ,tar_target(remapCDO_copernicus, remapCDO_copernicus(concatenate_copernicus), format = "file")
    # ,tar_target(speedCompo_copernicus, speedCompo_copernicus(remapCDO_copernicus, vars_speed, remove = FALSE), format = "file")
    # ,tar_target(grad_copernicus, grad_copernicus(connectPip), format = "file")

    ################################# To connect downshape and modeloTrack pipeline #################################
    ,tar_target(connectPip, connectPip(speedCompo_copernicus, speedCompo_cmip), format = "file")
)