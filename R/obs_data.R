#' Copernicus_download_api
#'
#' @description To download data on Copernicus marine service website with MOTU API and csv table. 
#' Complete csv table column (copernicus_parameters.csv) with MOTU API requeste output on Copernicus website.
#' This function check the file names of variables downloaded into the path to skip it if they exist.
#'
#' @param path_tab_param Path. Path where is the table with parameters of variables you would downloaded.
#' @param skip Logical. Default FALSE. If you want skip (TRUE) or not (FALSE) this function into the pipeline to conserve target valid into target_visnetwork visual.
#' @param user Character. User used to connect you on Copernicus marine service website.
#' @param passwd Character. Password to connect you on Copernicus marine service website.
#' @param divid Logical. If you want use "subvar" and "septime" to divided variable into the time during downloading.
#' @param subvar Vector. Name variable vector into table to choose time variable must to be divided by "septime" argument.
#' @param septime vector. Divide time (day) of variable sected in "subvar".
#' 
#' @return Netcdf files
#'
#' @export Netcdf files downloaded

copernicus_download_api <- function(path_tab_param,
                                    skip = FALSE,
                                    user = read.table(here::here("data", "copernicus_logging.txt"))[1, 1],
                                    passwd = read.table(here::here("data", "copernicus_logging.txt"))[2, 1],
                                    divide = TRUE,
                                    subvar = c("WIND_E", "WIND_N"),
                                    septime = c(7, 7)) {
    
    #path_tab_param <- here::here("data", "copernicus_parameters.csv")

    if(skip == FALSE){

        # Remove folder and creat a folder empty
        path_output <- here::here("output", "data_copernicus")
        if(!file.exists(path_output)) dir.create(path_output, showWarnings = FALSE)

        # check encodage csv
        if(ncol(read.csv2(path_tab_param)) < 2){ 
            tab_param <- read.csv(path_tab_param)
        }else(tab_param <- read.csv2(path_tab_param))

        # Check if motuclient is installed
        version <- system("python3 -m motuclient --version", inter = TRUE)
        version <- strsplit(version, split = " v")
        if(version[[1]][1] != "motuclient-python"){
        stop("Error: motuclient isn't installed")
        }

        # Divided time of varible with big size
        if(divide == TRUE){

            tab_modif <- NULL

            for(i in 1:nrow(tab_param)){

                boleen <- tab_param[i, "my_variable_name"] %in% subvar

                if(boleen == TRUE){
        
                    date_deb <- tab_param[i, "date_min"]
                    date_fin <- tab_param[i, "date_max"]

                    vec <- seq(as.Date(date_deb), as.Date(date_fin), by = septime[i])
                    tab_tempo <- tab_param[i, !(names(tab_param) %in% c("date_min", "date_max"))]
                    tab_tempo_var <- data.frame(tab_tempo, date_min = paste(vec[1], "00:00:00"), date_max = paste(vec[2], "23:59:59"))

                    for(v in 2:as.numeric(length(vec)-1)){

                        tab_tempo$date_min <- paste(vec[v]+1, "00:00:00")
                        tab_tempo$date_max <- paste(vec[v+1], "23:59:59")

                        tab_tempo_var <- rbind(tab_tempo_var, tab_tempo)

                    }

                }

                if(boleen == FALSE){

                    tab_tempo_var <- tab_param[i, ]

                }

                tab_modif <- rbind(tab_modif, tab_tempo_var)

            }

            write.csv2(tab_modif, file = here::here("output", "data_copernicus", "copernicus_parameters_modified.csv"), row.names = FALSE)
            tab_param <- tab_modif
        }

        # Creat python command and download by table row
        for(i in 1:nrow(tab_param)){

            if(!file.exists(paste0(path_output, "/", tab_param[i, "variable"], "_", tab_param[i, "service_id"], "_", 
                            strsplit(gsub("-", "", tab_param[i, "date_min"]), " ")[[1]][1], "-", 
                            strsplit(gsub("-", "", tab_param[i, "date_max"]), " ")[[1]][1], ".nc"))){
                
                message(paste0("Traitement of ", tab_param[i, "my_variable_name"], " variable"))

                command <- paste("python3 -m motuclient")

                if(!is.na(tab_param[i, "motu"])){
                    command <- paste0(command, " --motu ", tab_param[i, "motu"])
                }else("motu parameter doesn't exist")

                if(!is.na(tab_param[i, "service_id"])){
                    command <- paste0(command, " --service-id ", tab_param[i, "service_id"])
                }else("service_id parameter doesn't exist")

                if(!is.na(tab_param[i, "product_id"])){
                    command <- paste0(command, " --product-id ", tab_param[i, "product_id"])
                }else("product_id parameter doesn't exist")

                if(!is.na(tab_param[i, "longitude_min"])){
                    command <- paste0(command, " --longitude-min ", tab_param[i, "longitude_min"])
                }else("longitude_min parameter doesn't exist")

                if(!is.na(tab_param[i, "latitude_min"])){
                    command <- paste0(command, " --latitude-min ", tab_param[i, "latitude_min"])
                }else("latitude_min parameter doesn't exist")

                if(!is.na(tab_param[i, "longitude_max"])){
                    command <- paste0(command, " --longitude-max ", tab_param[i, "longitude_max"])
                }else("longitude_max parameter doesn't exist")

                if(!is.na(tab_param[i, "latitude_max"])){
                    command <- paste0(command, " --latitude-max ", tab_param[i, "latitude_max"])
                }else("latitude_max parameter doesn't exist")

                if(!is.na(tab_param[i, "date_min"])){
                    command <- paste0(command, " --date-min ", tab_param[i, "date_min"])
                }else("date_min parameter doesn't exist")

                if(!is.na(tab_param[i, "date_max"])){
                    command <- paste0(command, " --date-max ", tab_param[i, "date_max"])
                }else("date_max parameter doesn't exist")

                if(!is.na(tab_param[i, "depth_min"])){
                    command <- paste0(command, " --depth-min ", tab_param[i, "depth_min"])
                }else("depth_min parameter doesn't exist")

                if(!is.na(tab_param[i, "depth_max"])){
                    command <- paste0(command, " --depth-max ", tab_param[i, "depth_max"])
                }else("depth_max parameter doesn't exist")

                if(!is.na(tab_param[i, "variable"])){
                    
                    variables <- tab_param[i, "variable"]
                    variables <- unlist(strsplit(variables, split = "/"))
                    cmd_variable <- lapply(variables, function(x) paste0(" --variable ", x))
                    cmd_variable <- do.call("paste", cmd_variable)
                    command <- paste0(command, cmd_variable)

                }else("variable parameter doesn't exist")

                command <- paste0(command, 
                                    " --out-dir ", path_output, 
                                    " --out-name ", tab_param[i, "variable"], "_", tab_param[i, "service_id"], "_", 
                                                    strsplit(gsub("-", "", tab_param[i, "date_min"]), " ")[[1]][1], "-", 
                                                    strsplit(gsub("-", "", tab_param[i, "date_max"]), " ")[[1]][1], ".nc", 
                                    " --user ", user,
                                    " --pwd ", passwd)

                # run python command
                message("Downloading... Launch command : \n", "---> ", command)
                system(command, inter = TRUE)

                # Check if file is downloaded
                if(!file.exists(paste0(path_output, "/", tab_param[i, "variable"], "_", tab_param[i, "service_id"], "_", 
                            strsplit(gsub("-", "", tab_param[i, "date_min"]), " ")[[1]][1], "-", 
                            strsplit(gsub("-", "", tab_param[i, "date_max"]), " ")[[1]][1], ".nc"))){

                    stop(paste0("Variable ", tab_param[i, "my_variable_name"], " (", tab_param[i, "variable"], ")", " not downloaded! "))

                }else(message(paste0("Variable ", tab_param[i, "my_variable_name"], " (", tab_param[i, "variable"], ")", " downloaded successfully")))

            }else(message(paste0("Variable ", tab_param[i, "my_variable_name"], 
                                " (", tab_param[i, "variable"], ") ", 
                                "for the date ", strsplit(gsub("-", "", tab_param[i, "date_min"]), " ")[[1]][1], "-", strsplit(gsub("-", "", tab_param[i, "date_max"]), " ")[[1]][1],
                                " already downloaded!")))

        }

        return(list.files(here::here("output", "data_copernicus"), full.name = TRUE))

    }else{
        message("Skip manually 'obs_data' target (copernicus_download_api function)")
        return(list.files(here::here("output", "data_copernicus"), pattern = ".nc$", full.name = TRUE))
        }

}

#' http_download
#'
#' @description Download data outsite copernicus our esgf website.
#'
#' @param http_vars Target. "http_vars" target, check README documentation.
#' @param path_output Path. Output path where variable will be recorded.
#'
#' @return NULL
#'
#' @export NetCDF files (.nc)

http_download <- function(  http_vars = targets::tar_read("http_vars"), 
                            path_output,
                            skip = FALSE) {

    if(skip == FALSE){

    if(length(http_vars$http) >= 1){

        dir.create(path_output, showWarnings = FALSE)

        return_tot <- NULL

        for(i in 1:length(http_vars$http)){

            target_url <- http_vars$http[i]
            target_file <- paste0(path_output, "/", http_vars$name, "_", basename(target_file))

            if (file.exists(target_file)){
                return_tot <- c(return_tot, target_file)
            } else{
                download.file(target_url, target_file, method = "curl")
                return_tot <- c(return_tot, target_file)
            }

        }

        return(return_tot)

    }else{
        message("Not any outsite downloading")
        return(c())
        }

    }else(message("Skip manually 'http_data' target (http_download function)"))
}