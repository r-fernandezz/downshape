library(targets)

targets::tar_source()

list(

    # Project parameters
    tar_target(experiments, c("historical", "ssp126", "ssp245", "ssp370", "ssp534-over", "ssp585"))
    ,tar_target(vars, c("sos", "tos", "zos", "uo", "vo", "chlos")) # variable 2D
    #,tar_target(vars, c("so", "thetao", "chl")) # variable 3D
    ,tar_target(freq, "mon")
    #,tar_target(freq, "day")
    ,tar_target(time_span, list(start = "1982-01-01T00:00:00Z", end = "2100-12-31T23:59:59Z"))

    # Esgf dataset search & select
    ,tar_target(available_dataset, search_and_parse(experiments, freq, vars, time_span))


)