library(targets)

targets::tar_source()

list(

    ##### EDIT ME !! Project parameters
    tar_target(experiments, c("piControl","historical", "ssp126", "ssp245", "ssp370", "ssp534-over", "ssp585"))
    ,tar_target(vars, c("so", "zos", "uo", "vo", "thetao", "chl", "uas", "vas", "sfcWind"))
    ,tar_target(freq, "mon")
    ,tar_target(time_span, list(start = "1982-01-01T00:00:00Z", end = "2100-12-31T23:59:59Z"))

    # Esgf dataset search & select
    ,tar_target(available_dataset_json, search_esgf(experiments, freq, vars, time_span))
    ,tar_target(available_dataset_df, cmip_parse_search(available_dataset_json))
    ,tar_target(select_dataset, select_dataset(available_dataset_df), format = "file")

    # Download esgf dataset selected
    ,tar_target(download_cmip_data, download_cmip_data(select_dataset, time_span), format = "file")
    ,tar_target(concatenate_data, concatenate_data(download_cmip_data), format = "file")

    # Download environmentale variables observed 
    ,tar_target(tab_parameters, here::here("data", "copernicus_parameters.csv"), format = "file")
    ,tar_target(obs_data, copernicus_download_api(tab_parameters), format = "file")
)