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
#' If file final exists, the file will not be formatted again.
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

    f_final <- paste0(path_output, "/", gsub(".nc", "_seltime_regrid_miss_maskArea_tempReso_dimName_deep.nc", basename(file_path)))

    if (file.exists(f_final) == TRUE){

        return(f_final)

    } else{

        #################### Filter by time, treatment of the period we would like
        period <- switch(period,
                        current = targets::tar_read("current_period"),
                        historical = targets::tar_read("historical_period"),
                        targets::tar_read("futur_period"))

        #period = list(start = "1970-01-01T00:00:00", end = "1975-12-30T00:00:00")

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

        #################### Extract depth levels
        ncdf_file <- stars::read_ncdf(f_dimName)
        dim <- names(stars::st_dimensions(ncdf_file))

        boleen <- "lev" %in% dim

        if(boleen == TRUE){ # if file have a "lev" dimension

            for(d in 1:length(deep_level$start)){

                # deep_level <- list(start = c(10, 50), end = c(100, 100))

                # Depth filter values
                start <- deep_level$start[d]
                end <- deep_level$end[d]

                ##### Mean layers between two borders
                depth_values <- stars::st_dimensions(ncdf_file)$lev$values
                depth_values <- depth_values[depth_values < end]
                depth_values <- depth_values[depth_values > start]

                f_deepTEMPO <- gsub(".nc", "_deepTEMPO.nc", f_dimName)
                com_deepTEMPO <- paste0("cdo select,level=", paste(depth_values, collapse = ","), " ", f_dimName, " ", f_deepTEMPO)
                system(com_deepTEMPO)

                # Mean depth layer
                message(paste0("Create file for the deep ", start, "m", " to ", end, "m"))
                split_name <- strsplit(basename(f_dimName), "_")[[1]] # create name of output file
                f_deep <- here::here(path_output, paste0(split_name[1], start, "-", end, "_", paste(split_name[2:length(split_name)], collapse = "_")))
                f_deep <- gsub(".nc", "_deep.nc", f_deep)

                com_deep <- paste0("cdo vertmean ", f_deepTEMPO, " ", f_deep)
                system(com_deep)
                unlink(f_deepTEMPO)

                # Mean all depth layers
                f_deep_tot <- gsub(".nc", "_deep.nc", f_dimName)
                com_deep_tot <- paste0("cdo vertmean ", f_dimName, " ", f_deep_tot)
                system(com_deep_tot)

            }

            unlink(f_dimName)

        } else {
            f_deep <- gsub(".nc", "_deep.nc", f_dimName)
            message(paste0("No depth levels for this variable: ", f_dimName))
            file.rename(f_dimName, f_deep)
        }

        return(f_deep)

    }
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

    dir.create(here::here("output", "data_cmip6_remapped"))

    message("we have ", length(mods), " models: ", paste(mods, collapse = " | "))

    unlist(lapply(mods, function(m){
        
        #m = "CMCC-ESM2"
        
        # Select files and variable names
        message(paste0("### Treatment of ", m))
        path_output <- here::here("output", "data_cmip6_remapped", m)
        dir.create(path_output)
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
                                                spat_reso = targets::tar_read("spat_reso"), 
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

    cat("Treatment of files: ", list_file, sep = "\n")

    parallel::mclapply(list_file, function(f){

        cdo_format_command( file_path = f, 
                            type_data = "copernicus", 
                            period = "current", 
                            spat_reso = targets::tar_read("spat_reso"), 
                            path_output = path_output)

        }, mc.cores = length(list_file))

    return(list.files(path_output, full.names = TRUE))
}


#' cpeed_compo
#'
#' @description To calculate speed with two components with CDO. 
#' In first, temporal file created to merge U and V variables and speed will be calculated on this file and exported into new file.
#'
#'
#' @param path_compo1 Path. Path of first component.
#' @param path_compo2 Path. Path of second component.
#' @param name_compo1 Character. Abbreviation of first name variable component. Into target vars_speed (check readme informations).
#' @param name_compo2 Character. Abbreviation of second name variable component. Into target vars_speed (check readme informations).
#' @param name_speed Character. Abbreviation of output name variable. Into target vars_speed (check readme informations).

#'
#' @return Path of processed variable
#'
#' @export Processed file (.nc)

speedCompo <- function( path_compo1, 
                        path_compo2, 
                        name_compo1, 
                        name_compo2,
                        name_speed){

    # Create output file name
    split_name <- strsplit(basename(path_compo1), "_")[[1]] # create name of output file
    path_output <- strsplit(path_compo1, "/")[[1]]
    path_output <- paste(path_output[1:as.numeric(length(path_output)-1)], collapse = "/")
    f_merge <- paste0(path_output, "/", paste0(name, "_", paste(split_name[2:length(split_name)], collapse = "_")))

    # Merge with CDO
    f_mergeTEMPO <- gsub(".nc", "_TEMPO.nc", f_merge)
    com_mergeTEMPO <- paste0("cdo merge ", path_compo1, " ", path_compo2, " ", f_mergeTEMPO)
    system(com_mergeTEMPO)
    
    f_merge <- gsub("_TEMPO.nc", "_speedCompo.nc", f_mergeTEMPO)
    com_merge <- paste0("cdo expr,", "'", name, "=", 
                        "sqrt(", name_compo1, "*", name_compo1, "+", name_compo2, "*", name_compo2, ")", "' ", 
                        f_mergeTEMPO, " ", f_merge)
    system(com_merge)

    if(file.exists(f_merge) == TRUE){
        unlink(f_mergeTEMPO)
        unlink(path_compo1)
        unlink(path_compo2)
    } else(stop("Calcul with components failed"))

    return(f_merge)

}


#' speed_compo_cmip
#'
#' @description To apply speedCompo() function at cmip6 data
#'
#'
#' @param file_path Path. File paths of cmip6 variables you want process.
#' @param vars_speed List. vars_speed targets (check readme informations).
#'
#' @return Vector with paths of processed variables
#'
#' @export Processed files (.nc)
#'

speedCompo_cmip <- function(file_path = remap_cmip_data, vars_speed ) {


    # Conserve path root of the file
    path_root <- strsplit(file_path[1], "/")[[1]]
    path_root <- paste(path_root[1:as.numeric(length(path_root)-1)], collapse = "/")

    return <- c()
    compo <- c() # if i = 1 empty

    for(i in 1:length(vars_speed$compo1)){

        # Select variable with two coponents
        grep_var <- grep(basename(file_path), pattern = paste0("^(", vars_speed$compo1[i], ")", "|", "^(", vars_speed$compo2[i], ")"), value = TRUE)

        if(length(grep_var) >= 2){ #if pattern "fs" object correspond to copernicus variable names, length = 0

            run <- unique(sapply(strsplit(grep_var, "_"), "[", 4))

            unlist(lapply(run, function(run){

                #run = "historical"

                grep_run <- grep(basename(grep_var), pattern = run, value = TRUE)

                if(length(grep_run) > 2) stop("More than one file found to calculate speed!" )

                compo <- speedCompo(path_compo1 = paste(path_root, grep_run[1], sep = "/"), 
                                    path_compo2 = paste(path_root, grep_run[2], sep = "/"), 
                                    name_compo1 = vars_speed$compo1[i], 
                                    name_compo2 = vars_speed$compo2[i],
                                    name_speed = vars_speed$name[i]
                                    )

            }))

        }

        return <- c(return, compo)

    }

    return(return)

}


#' speed_compo_copernicus
#'
#' @description To apply speedCompo() function at copernicus data
#'
#'
#' @param file_path Path. File paths of copernicus variables you want process.
#' @param vars_speed List. vars_speed targets (check readme informations).
#'
#' @return Vector with paths of processed variables
#'
#' @export Processed files (.nc)
#'

speedCompo_copernicus <- function(file_path = remap_copernicus_data, vars_speed) {
    
    # file_path = list.files(here::here("output", "data_copernicus_remapped"), full.name = TRUE)

    # Conserve path of the file
    path_root <- strsplit(file_path[1], "/")[[1]]
    path_root <- paste(path_root[1:as.numeric(length(path_root)-1)], collapse = "/")

    return <- c()
    compo <- c() # if i = 1 empty

    for(i in 1:length(vars_speed$compo1)){

        # Select variable with two coponents
        grep_var <- grep(basename(file_path), pattern = paste0("^(", vars_speed$compo1[i], ")", "|", "^(", vars_speed$compo2[i], ")"), value = TRUE)


        if(length(grep_var) > 2) stop("Error: more than one file found to calculate speed!" )

        if(length(grep_var) == 2){ # if pattern "fs" object correspond to cmip6 variable names, length = 0

            compo <- speedCompo(path_compo1 = paste(path_root, grep_var[1], sep = "/"), 
                                path_compo2 = paste(path_root, grep_var[2], sep = "/"), 
                                name_compo1 = vars_speed$compo1[i], 
                                name_compo2 = vars_speed$compo2[i],
                                name_speed = vars_speed$name[i]
                                )

        }

        return <- c(return, compo)

    }

    return(return)
}
