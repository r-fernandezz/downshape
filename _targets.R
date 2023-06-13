library(targets)

Sys.setenv(TAR_WARN = "false")

targets::tar_source()

list(

    ################################# EDIT ME !! Project parameters ##############################################################################
    tar_target(experiments,         c("historical", "ssp126", "ssp370", "ssp534-over", "ssp585"))
    ,tar_target(vars,               c("thetao", "chl"))
    ,tar_target(freq,               "mon")
    ,tar_target(historical_period,  list(   start = "1999-01-01T00:00:00", end = "2014-12-01T00:00:00"))
    ,tar_target(futur_period,       list(   start = "2015-01-01T00:00:00", end = "2080-12-01T00:00:00"))
    ,tar_target(time_span,          list(   start = "1999-01-01T00:00:00Z", end = "2080-12-31T23:59:59Z"))
    ,tar_target(vars_speed_cmip,    list(   compo1 = c(), compo2 = c(), name = c()))
    ,tar_target(climato_period,     list(   name = c("2030", "2050", "2070"), 
                                            start = c("2020-01-01T00:00:00", "2040-01-01T00:00:00", "2060-01-01T00:00:00"), 
                                            end = c("2040-12-30T23:59:59", "2060-12-30T23:59:59", "2080-12-30T23:59:59"),
                                            month_choose = c(2, 3, 4, 5, 6, 7, 8, 9)))
    
    ,tar_target(resotempo,          list(   vars = c("SST",  "CHLA", "BATHY", "SSTcmip"), 
                                            reso = c("week", "week", "FIXE", "month"))) 
    ,tar_target(http_vars,          list(   http = c("https://www.ngdc.noaa.gov/mgg/global/relief/ETOPO2/ETOPO2v2-2006/ETOPO2v2g/netCDF/ETOPO2v2g_f4_netCDF.zip"),
                                            name = c("BATHY")))
    ,tar_target(current_period,     list(   start = "2018-01-03T00:00:00", end = "2019-10-30T23:59:59"))
    ,tar_target(baseline_period,    list(   start = "1999-01-01T00:00:00", end = "2019-12-01T00:00:00"))
    ,tar_target(match_name,         list(   copernicus = c("SST", "SST0x100"), cmip = c("SSTcmip", "SSTcmip0x100")))
    ,tar_target(spat_reso,          "180x90")
    ,tar_target(deep_level,         list(   start = c(0, 0), end = c(1, 100)))
    ,tar_target(renameVar,          list(   oldname = c("to", "chl", "topo", "thetao"), 
                                            newname = c("SST", "CHLA", "BATHY", "STTcmip")))
    ,tar_target(vars_speed,         list(   compo1 = c(), compo2 = c(), name = c()))
    ,tar_target(bathy_CDO,          TRUE)

    ################################# Part 1 : CMIP data process (commit all targets if you don't use this part) #################################

    # Esgf dataset search, select and download
    ,tar_target(available_dataset_json, search_esgf(experiments, freq, vars, time_span, skip = FALSE))
    ,tar_target(available_dataset_df, cmip_parse_search(available_dataset_json, skip = FALSE))
    ,tar_target(select_dataset, select_dataset(available_dataset_df, skip = FALSE), format = "file")
    ,tar_target(cmip_data, download_cmip_data(select_dataset, time_span, skip = FALSE), format = "file")

    # Shaping esgf data downloaded (CMIP6)
    ,tar_target(renameVar_cmip, renameVar(data = cmip_data, type_data = "cmip6", skip = TRUE), format = "file")
    ,tar_target(concatenate_cmip, concatenate_cmip(renameVar_cmip), format = "file")
    ,tar_target(remapCDO_cmip, remapCDO_cmip(concatenate_cmip), format = "file")
    ,tar_target(speedCompo_cmip, speedCompo_cmip(remapCDO_cmip, vars_speed_cmip, remove = FALSE), format = "file")
    ,tar_target(climato_cmip, climato_cmip(speedCompo_cmip, climato_period), format = "file")
    ,tar_target(mergeHistorical_cmip, mergeHistorical_cmip(speedCompo_cmip, historical_period, baseline_period, futur_period, climato_period), format = "file")
    ,tar_target(varsBiasCorrected, deltaCF(climato_cmip, mergeHistorical_cmip, grad_copernicus, match_name, climato_period), format = "file")
    ,tar_target(MeanModel, meanMod(varsBiasCorrected), format = "file")
    ,tar_target(grad_cmip, grad_cmip(MeanModel), format = "file")

    ################################# Part 2 : Copernicus data process (commit all targets if you don't use this part) ###########################

    # Download copernicus data (observed)
    ,tar_target(tab_parameters, here::here("data", "copernicus_parameters.csv"), format = "file")
    ,tar_target(obs_data, copernicus_download_api(tab_parameters, skip = TRUE), format = "file")
    ,tar_target(bathy_vars, downloadCDO_bathy(bathy_CDO, skip = TRUE), format = "file")
    ,tar_target(http_data, http_download(http_vars, path_output = here::here("output", "data_copernicus"), skip = TRUE))

    # Shaping copernicus data downloaded (observed)
    ,tar_target(renameVar_copernicus, renameVar(data = c(obs_data, http_data, bathy_vars), type_data = "copernicus", skip = FALSE), format = "file")
    ,tar_target(concatenate_copernicus, concatenate_copernicus(renameVar_copernicus), format = "file")
    ,tar_target(remapCDO_copernicus, remapCDO_copernicus(concatenate_copernicus), format = "file")
    ,tar_target(speedCompo_copernicus, speedCompo_copernicus(remapCDO_copernicus, vars_speed, remove = FALSE), format = "file")
    ,tar_target(connectPip_copernicus, connectPip(data = speedCompo_copernicus, type_data = "copernicus"), format = "file")
    ,tar_target(grad_copernicus, grad_copernicus(connectPip_copernicus), format = "file")

)