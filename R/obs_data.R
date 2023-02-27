#' Copernicus_download_api
#'
#' @description To download data on Copernicus marine service website with MOTU API and csv table. 
#' Complete column of csv table with MOTU API requeste output on Copernicus website (one row by product downloading).
#' If a parameter into csv table doesn't exist for your product (example : depth) just leave the box empty.
#'
#'
#' @param path_output Path. Path where netcdf data will be exported.
#' @param path_tab_param Path. Path where is the table with parameters of variables you would downloaded.
#' @param user Character. User used to connect you on Copernicus marine service website.
#' @param passwd Character. Password to connect you on Copernicus marine service website.
#' 
#' @return Netcdf files
#'
#' @export Netcdf files downloaded

copernicus_download_api <- function(path_tab_param,
                                    path_output = here::here("outputs"),
                                    folder_output = "copernicus",
                                    user = read.table(here::here("data", "copernicus_logging.txt"))[1, 1],
                                    passwd = read.table(here::here("data", "copernicus_logging.txt"))[2, 1]) {

    #path_tab_param <- tar_read(tab_parameters)

    dir.create(paste(path_output, folder_output, sep = "/"), showWarnings = FALSE)

    # check encodage csv
    if(ncol(read.csv2(path_tab_param)) < 2){ 
        tab_param <- read.csv(path_tab_param)
    }else(tab_param <- read.csv2(path_tab_param))

    # creat python command and download by table row
    for(i in 1:nrow(tab_param)){

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
                        " --out-dir ", paste0(path_output, "/", folder_output), 
                        " --out-name ", tab_param[i, "my_variable_name"], ".nc", 
                        " --user ", user,
                        " --pwd ", passwd)

    # run python command
    message("Downloading...")
    system(command, inter = TRUE)
    message(paste("Variable ", tab_param[i, "my_variable_name"], " downloaded successfully "))

    }

    return(list.files(here::here("output", "output", "copernicus")))

}

# copernicus_download_api()

# stars::read_stars(paste0(here::here("outputs", "copernicus"), "/DUV.nc"))
