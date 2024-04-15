#' Copernicus_download_api
#'
#' @description To download data on Copernicus marine service website with Copernicus Marine Toolbox and csv table. 
#' Complete the CSV table column (copernicus_parameters.csv) with information from the Copernicus website.
#' This function checks the file names of the variables downloaded into the path to skip them if they already exist.
#' If the Copernicus Marine Toolbox is installed in a folder without full rights, it is necessary to run the "copernicusmarine login" command in the bash terminal and enter your username and password.
#' After this, when you run a request to download data, you won't have to enter your credentials again.
#'
#' @param path_tab_param Character. The path where the parameter table with variables information you want to download is located.
#' @param skip Logical. Default FALSE. If you want to skip (TRUE) or not (FALSE) this function in the pipeline to keep the target valid in the target_visnetwork visual.
#' @param path_copernicusmarine Character. The installation location of the Copernicus Marine Toolbox. You can find this path with the bash command "which copernicusmarine" (and use the provided output).
#' @param subvar Vector. Defaults to all variables in the table (targeted by the "path_tab_param" argument). A vector of variable names from the table to select which time variable must be divided by the "septime" argument.
#' @param septime Character. Divides time by "month" or "week" for variables selected in "subvar". 
#' The day number from "date_min" in the "path_tab_param" is used to create a vector with increments either by month or week, starting from the corresponding day of this date.
#' The "septime" argument must be adequate for the time period being downloaded.
#' @param divide Logical. If you want to use "subvar" and "septime" to divide the variable over time during downloading.
#' @param nb_retry Number. If the Copernicus API disconnects, you can set a retry number to attempt a new download before printing a download error.
#' @param user Character. The username used to log in to the Copernicus Marine Service website.
#' @param passwd Character. The password for logging in to the Copernicus Marine Service website.
#' 
#' @return Netcdf files paths
#'
#' @export Netcdf files downloaded

copernicus_download_api <- function(path_tab_param,
                                    skip = FALSE,
                                    path_copernicusmarine = "/home/romain/.local/bin/copernicusmarine",
                                    subvar = NULL,
                                    septime = "week",
                                    divide = FALSE,
                                    nb_retry = 100,
                                    user = read.table(here::here("data", "copernicus_logging.txt"))[1, 1],
                                    passwd = read.table(here::here("data", "copernicus_logging.txt"))[2, 1]) {
    
    #path_tab_param <- here::here("data", "copernicus_parameters.csv")

    if(skip == FALSE){

        # Remove folder and creat a folder empty
        path_output <- here::here("output", "data_copernicus")
        if(!file.exists(path_output)) dir.create(path_output, showWarnings = FALSE)

        # check encodage csv
        if(ncol(read.csv2(path_tab_param)) < 2){ 
            tab_param <- read.csv(path_tab_param)
        }else(tab_param <- read.csv2(path_tab_param))

        # Create subvar argument if you want
        if(length(subvar) > 0){message("Argument 'subvar' definied manually")}
        if(is.null(subvar)){
            subvar <- tab_param$my_variable_name
        }

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

                    if(septime == "month"){
                        vec <- seq(as.Date(date_deb), as.Date(date_fin), by = septime)
                    }

                    if(septime == "week"){
                        vec <- seq(as.Date(date_deb), as.Date(date_fin), by = septime)
                    }

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
                
            out_name <- sprintf("%s_%s_%s-%s.nc", 
                            tab_param[i, "my_variable_name"], 
                            tab_param[i, "dataset_id"], 
                            strsplit(gsub("-", "", tab_param[i, "date_min"]), " ")[[1]][1], 
                            strsplit(gsub("-", "", tab_param[i, "date_max"]), " ")[[1]][1])

            if(!file.exists(paste0(path_output, "/", out_name))){
                
                message(paste0("\n ########################### Traitement of ", tab_param[i, "my_variable_name"], " variable"))
                
                command <- paste0(path_copernicusmarine, " subset --force-download")

                if(!is.na(tab_param[i, "dataset_id"])){
                    command <- paste0(command, " --dataset-id ", tab_param[i, "dataset_id"])
                }else{stop("dataset_id parameter doesn't exist in the parameters table")}

                if(!is.na(tab_param[i, "dataset_version"])){
                    command <- paste0(command, " --dataset-version ", tab_param[i, "dataset_version"])
                }else{stop("dataset_version parameter doesn't exist in the parameters table")}

                if(!is.na(tab_param[i, "longitude_min"])){
                    command <- paste0(command, " --minimum-longitude ", tab_param[i, "longitude_min"])
                }else{stop("longitude_min parameter doesn't exist in the parameters table")} 

                if(!is.na(tab_param[i, "latitude_min"])){
                    command <- paste0(command, " --minimum-latitude ", tab_param[i, "latitude_min"])
                }else{stop("latitude_min parameter doesn't exist in the parameters table")}

                if(!is.na(tab_param[i, "longitude_max"])){
                    command <- paste0(command, " --maximum-longitude ", tab_param[i, "longitude_max"])
                }else{stop("longitude_max parameter doesn't exist in the parameters table")}

                if(!is.na(tab_param[i, "latitude_max"])){
                    command <- paste0(command, " --maximum-latitude ", tab_param[i, "latitude_max"])
                }else{stop("latitude_max parameter doesn't exist in the parameters table")}

                if(!is.na(tab_param[i, "date_min"])){
                    command <- paste0(command, " --start-datetime ", gsub(" ", "T", tab_param[i, "date_min"]))
                }else{stop("date_min parameter doesn't exist in the parameters table")}

                if(!is.na(tab_param[i, "date_max"])){
                    command <- paste0(command, " --end-datetime ", gsub(" ", "T", tab_param[i, "date_max"]))
                }else{stop("date_max parameter doesn't exist in the parameters table")}

                if(!is.na(tab_param[i, "depth_min"])){
                    command <- paste0(command, " --minimum-depth ", tab_param[i, "depth_min"])
                }else{message("depth_min parameter doesn't exist in the parameters table")}

                if(!is.na(tab_param[i, "depth_max"])){
                    command <- paste0(command, " --maximum-depth ", tab_param[i, "depth_max"])
                }else{message("depth_max parameter doesn't exist in the parameters table")}

                if(!is.na(tab_param[i, "variable"])){
                    
                    variables <- tab_param[i, "variable"]
                    variables <- unlist(strsplit(variables, split = "/"))
                    cmd_variable <- lapply(variables, function(x) paste0(" --variable ", x))
                    cmd_variable <- do.call("paste", cmd_variable)
                    command <- paste0(command, cmd_variable)

                }else{stop("variable parameter doesn't exist in the parameters table")}

                command <- paste0(command, " --output-directory ", path_output)

                command <- paste0(command, " --output-filename ", out_name)

                command <- paste0(command, " --username ", user)

                command <- paste0(command, " --password ", passwd)

                message("Downloading... Launch command : \n", "---> ", command, "\n")
                
                # Download and check file downloaded
                retry <- 0

                while(file.exists(paste0(path_output, "/", out_name)) == FALSE){
                    
                    # run python command
                    system(command, inter = TRUE)

                    if(retry == nb_retry){
                        stop(paste0("Variable ", tab_param[i, "my_variable_name"], " (", tab_param[i, "variable"], ")", " not downloaded! Number of tries exceeded..."))
                    }
                    
                    if(!file.exists(paste0(path_output, "/", out_name))){

                        retry <- retry + 1
                        message(paste0("retry ", retry, "/", nb_retry, " for ", tab_param[i, "my_variable_name"], " variable"))
                        
                        }else(message(paste0("\n", "---> Variable ", tab_param[i, "my_variable_name"], " (", tab_param[i, "variable"], ")", " downloaded successfully")))

                }

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

#' downloadCDO_bathy
#'
#' @description If you want download bathymetry variable with CDO.
#'
#' @param download Target. "bathy_CDO" target, check README documentation.
#'
#' @return NULL
#'
#' @export NetCDF file (.nc) of bathymetry come from CDO swoftware
#' 

downloadCDO_bathy <- function(  download = targets::tar_read("bathy_CDO"),
                                skip){
    
    if(skip == FALSE){

        if(download == TRUE){

            comd <- paste(paste0("cdo -f nc -topo"), here::here("output", "data_copernicus", "BATHY_cdo_NOAA_ETOPO2_2006_brut.nc"))
            system(comd)

            return(here::here("output", "data_copernicus", "BATHY_cdo_NOAA_ETOPO2_2006_brut.nc"))

        }else{
            message("Bathymetry doesn't downloaded")
            return(c())
        }

    }else(message("Skip manually 'bathy_vars' target (downloadCDO_bathy function)"))

}