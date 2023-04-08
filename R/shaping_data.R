#' concatenate_cmip6_data
#'
#' @description Merge cmip6 datasets by source x experiment x var for all datasets. Sorted by date and time. 
#' Used into concatenate_experiment() function.
#'
#' @param source Model downloaded
#' @param experiment Experiment downloaded
#' @param var Variable downloaded
#'
#' @return path to the output file merged
#'
#' @export file merged (.nc)
#'

concatenate_cmip6_data <- function(source, experiment, var) {

    #source = "CMCC-ESM2" ; experiment = "piControl" ; var= "chl"

    exp_files_full <- sort(list.files(path = file.path("output", "data_cmip6", source, experiment),
                                    pattern = paste0(var, "_"),
                                    full.names = TRUE))
    
    exp_files <- basename(exp_files_full)
    
    #if only one file then do nothing
    if (length(exp_files) == 1){
        message("### WARNING: Only one file, impossible to merge files")
        return(paste0("output/data_cmip6/", source, "/", experiment, "/",exp_files))
    } 

    h1 <- exp_files[1]
    h2 <- exp_files[length(exp_files)]
    f_out <- paste0("output/data_cmip6/", source, "/", experiment, "/", substr(h1, 1, nchar(h1) - 9),
                    substr(h2, nchar(h2) - 8, nchar(h2)-3),
                    ".nc")

    f_in <- paste0("output/data_cmip6/", source, "/", experiment, "/", substr(h1, 1, nchar(h1) - 16),"*nc")

    com <- paste0("cdo mergetime ", f_in, " ", f_out)
    message("### Running CDO command to merge:  \n", "--->", com)
    system(com)
    Sys.sleep(10)
    unlink(exp_files_full)

    return(f_out)

}


#' concatenate_data
#'
#' @description Apply concatenate_experiment() function at all datasets.
#'
#' @param download_data Downloaded data we want to merge.
#'
#' @return Same of concatenate_experiment() function
#'
#' @export Same of concatenate_experiment() function

concatenate_data <- function(download_data){

    #download_cmip_data <- targets::tar_load("download_cmip_data")
    #download_cmip_data <- list.files(here::here("output", "data_cmip6"), recursive = TRUE, full.names = TRUE)

    message("# Concatenating data files for each source * experiment * variable")

    data_sets <- strsplit(download_data, "cmip6/")
    data_sets <- unlist(lapply(data_sets, "[[", 2))

    data_sets <- do.call(rbind, lapply(strsplit(data_sets, "/"), function(x){

        d <- data.frame(t(unlist(x)))
        names(d) <- c("source_id", "experiment_id", "file")
        d$variable_id <- strsplit(d$file, "_|[.]")[[1]][3]
        return(d)

    }))

    sources     <- unique(data_sets$source_id)
    experiments <- unique(data_sets$experiment_id)
    variables   <- unique(data_sets$variable_id)
    message("---> ", length(sources)," source(s): ", paste(sources, collapse = " | "))

    res_files <- unlist(lapply(sources, function(s){
        unlist(lapply(experiments, function(e){
            unlist(lapply(variables, function(v){
                message(s, "|", e, "|", v)
                concatenate_cmip6_data(source = s, experiment = e, var = v)
            }))
        }))
    }))

    return(res_files)

}

#' cdo_format_command
#'
#' @description To formate cmip6 and copernicus data download with CDO swofware. This function create and run CDO commands to shaping data. 
#'
#' @param file_path Path. File path of variable you want process.
#' @param type_data Character. Type of data you want process, "cmip6" or "copernicus".
#' @param period Character. "current" or "historical". Correspond to current_period historical_period target (check readme informations). Else it's not "historical_period" or "current_period", automatically function extract born of futur period.
#' @param spat_reso Character. spat_reso targets (check readme informations).
#' 
#' @return File path of the variable processed
#'
#' @export File (.nc) of the variable processed


cdo_format_command <- function(file_path, 
                                type_data = "cmip6", 
                                period, 
                                spat_reso, 
                                path_output){
    #cmip
    #  period = list(start = "1970-01-01T00:00:00", end = "1980-01-01T00:00:00")
    # spat_reso = "180x90"
    # path_output = here::here("output", "data_cmip6_remapped", m)
    # deep_level = list(start = c(0, 50), end = c(50, 100))

    # copernicus
    # period = list(start = "2023-02-12T00:00:00", end = "2023-02-15T00:00:00")
    # spat_reso = "180x90"
    # path_output = here::here("output", "data_copernicus_remapped")
    # deep_level = list(start = c(0, 50), end = c(50, 100))

    f_final <- paste0(path_output, "/", gsub(".nc", "_seltime_regrid_miss_maskArea_spatReso_dimName.nc", basename(file_path)))

    if (file.exists(f_final)) return(f_final)

    #################### Filter by time, treatment of the period we would like
    period <- switch(period,
                    current = current_period,
                    historical = historical_period,
                    futur_period)

    f_seltime <- gsub(".nc", "_seltime.nc", file_path)
    f_seltime <- paste0(path_output, "/", basename(f_seltime))
    com_time <- paste0("cdo seldate,", period$start, ",", period$end, " ", file_path, " ", f_seltime)
    system(com_time)

    #################### Regrid
    f_regrid <- gsub(".nc", "_regrid.nc", f_seltime)
    com_regrid <- paste0("cdo remapdis,r", spat_reso, " ", f_seltime, " ", f_regrid)	      
    system(com_regrid)
    unlink(f_seltime)

    #################### Fill missing values
    f_miss <- gsub(".nc", "_miss.nc", f_regrid)
    com_miss <- paste0("cdo fillmiss ", f_regrid, " ", f_miss)
    system(com_miss)
    unlink(f_regrid)

    #################### Create, regrid, replicated and apply mask only to conserve study area
    mask_PA <- here::here("data", "mask_PA_variable.shp")
    mask_PA_out <- here::here("output", "mask_PA_variable.nc")
    system(paste0("gdal_rasterize -of netCDF -burn 1 -tr 0.01 0.01 ", "-a_srs EPSG:4326 ", mask_PA, " ", mask_PA_out)) # convert shp to nc

    ## Regrid mask
    f_maskRegrid <- gsub(".nc", "_regrid.nc", mask_PA_out)
    com_maskRegrid <- paste0("cdo -remapbil,r", spat_reso, " ", mask_PA_out, " ", f_maskRegrid)
    system(com_maskRegrid)
    unlink(mask_PA_out)

    ## Apply mask at several time series
    f_maskArea <- gsub(".nc", "_maskArea.nc", f_miss)
    com_maskArea <- paste0("cdo ifthen ", f_maskRegrid, " ", f_miss, " ", f_maskArea)
    system(com_maskArea)
    unlink(f_miss)

    #################### Change temporal resolution
    f_tempReso <- gsub(".nc", "_tempReso.nc", f_maskArea)
    com_tempReso <- paste0("cdo monmean ", f_maskArea, " ", f_tempReso)
    system(com_tempReso)
    unlink(f_maskArea)

    #################### Change dimension names
    ncdf_file <- stars::read_ncdf(f_tempReso)
    dim <- names(stars::st_dimensions(ncdf_file))

    boleen <- dim != c("lon", "lat", "lev", "time")
    if(exists("com_dimName") == TRUE) rm(com_dimName) #remove command if exist
    com_dimName <- paste0("ncrename") #first command part

    if(boleen[1] == TRUE){
        com_dimName <- paste0(  com_dimName,
                                " -d ", dim[1], ",lon",
                                " -v ", dim[1], ",lon")
    }

    if(boleen[2] == TRUE){
        com_dimName <- paste0(  com_dimName,
                                " -d ", dim[2], ",lat",
                                " -v ", dim[2], ",lat") 
    }

    if(boleen[3] == TRUE){
        com_dimName <- paste0(  com_dimName,
                                " -d ", dim[3], ",lev", 
                                " -v ", dim[3], ",lev") 
    }

    if(boleen[4] == TRUE){
        com_dimName <- paste0(  com_dimName,
                                " -d ", dim[4], ",time", 
                                " -v ", dim[4], ",time") 
    }

    if(com_dimName != "ncrename" ){
        f_dimName <- gsub(".nc", "_dimName.nc", f_tempReso)
        com_dimName <- paste0(  com_dimName,
                                " ", f_tempReso,
                                " ", f_dimName)
        system(com_dimName)
        unlink(f_tempReso)
    } else {
        message("### -> Dimension names don't change. File rename")
        f_dimName <- gsub(".nc", "_dimName.nc", f_tempReso)
        file.rename(f_tempReso, f_dimName)
    }

    #################### Extract deep levels
    # ncdf_file <- stars::read_ncdf(f_dimName)
    # dim <- names(stars::st_dimensions(ncdf_file))

    # boleen <- dim == c("lev", "lev", "lev", "lev")

    # if(TRUE %in% boleen == TRUE){ # if TRUE, file have a lev layer

    #     for(d in 1:length(deep_level$start)){

    #         start <- deep_level$start[d]
    #         end <- deep_level$end[d]

    #         message(paste0("Create file for the deep ", start, "m", " to ", end, "m"))
    #         f_deep <- gsub(".nc", paste0("_deep", start, "-", end, "m", ".nc"), f_dimName)
    #         com_deep <- paste0("cdo topvalue,", start, ",", end, " ", f_dimName, " ", f_deep)
    #         system(com_deep)

    #     }
        

    # } else {
    #     f_deep <- gsub(".nc", "_Nodeep.nc", f_dimName)
    #     file.rename(f_tempReso, f_dimName)


    # }

    # return(f_deep)

    return(f_dimName)

}


#' remap_data_cmip
#'
#' @description Apply cdo_format_command function to all cmip6 variables
#'
#' @param concatenate_data Path. Path of the file you want formatted with CDO.
#'
#' @return Vector with paths of processed variables
#'
#' @export Processed files (.nc)
#' 

remap_cmip_data <- function(concatenate_data){

    mods <- read.csv2(here::here("output", "selected_datasets.csv"))
    mods <- unique(mods$source_id)

    message("we have ", length(mods), " models: ", paste(mods, collapse = " | "))

    unlist(lapply(mods, function(m){
        
        #m = "CMCC-ESM2"
        
        # Select files and variable names
        message(paste0("### Treatment of ", m))
        path_output <- here::here("output", "data_cmip6_remapped", m)
        dir.create(path_output, showWarnings = FALSE)
        path  <- paste0(here::here("output", "data_cmip6"), "/", m)
        files <- list.files(path, recursive = TRUE, pattern = ".nc", full.names = TRUE)
        files <- basename(files)[!grepl("gr", files)] #remove regrid file
        splits <- sapply(basename(files), strsplit, "_")
        vars <- unique(sapply(splits, '[', 1))

        # Extract experiment name
        runs <- sapply(vars, function(x){
            fs <- grep(x, basename(files), value = TRUE)
            unique(unlist(setNames(lapply(splits[fs], '[', 4), NULL)))
        })

        # Create vector of experiment names from table with only one or several columns
        if(is.null(ncol(runs)) == TRUE){
            runs <- as.vector(runs)
        }else(runs <- runs[ ,1])

        # Apply CDO function at all files
        unlist(parallel::mclapply(runs, function(r) {
            #r = "piControl" ; r = "historical"
            unlist(parallel::mclapply(vars, function(v){
            #v  = "chl"
                message("Processing for: ", m, " / ", r, " / ", v)
                
                file <- paste0(here::here("output", "data_cmip6"), "/", m, "/", r, "/", grep(v, basename(files), value = TRUE))

                file_form <- cdo_format_command(file_path = file, 
                                                type_data = "cmip6", 
                                                period = r, 
                                                spat_reso = spat_reso, 
                                                path_output = path_output)

                return(file_form)

            }, mc.cores = length(vars)))

        }, mc.cores = 2))

    }))

}

#' remap_copernicus_data
#'
#' @description Apply cdo_format_command function to all copernicus variables
#'
#'
#' @param obs_data Path list. List of variable path download by copernicus_download_api function.
#'
#' @return Vector with paths of processed variables
#'
#' @export Processed files (.nc)

remap_copernicus_data <- function(obs_data) {
    
    path_output <- here::here("output", "data_copernicus_remapped")
    dir.create(path_output, showWarnings = FALSE)

    list_file <- list.files(here::here("output", "data_copernicus"), full.name = TRUE)

    unlist(parallel::mclapply(list_file, function(f){

            cdo_format_command( file_path = f, 
                                type_data = "copernicus", 
                                period = "current", 
                                spat_reso = spat_reso, 
                                path_output = path_output)

            }, mc.cores = length(list_file))
    )

    return(file_form)

}