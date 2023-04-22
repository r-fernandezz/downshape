#' renameVar
#'
#' @description Rename variable with rename target vector. 
#'
#' @param data Target. Data download by copernicus_download_api() and download_cmip_data() function.
#' @param type_data Character, "cmip6" or "copernicus". Data type used, to find valid path.
#' @param skip Logical. Default FALSE. If you want skip (TRUE) or not (FALSE) this function into the pipeline to conserve target valid into target_visnetwork visual.
#' @param renameVar List. Old name and correspondance to new name you want into output file name.
#' 
#' @return NULL
#'
#' @export Overwrite old file (.nc)

renameVar <- function(data, type_data, skip = FALSE, renameVar = targets::tar_read("renameVar")){

    if(skip == FALSE){

        if(length(targets::tar_read("renameVar")) >= 1){

            path <- switch(type_data,
                            copernicus = here::here("output", "data_copernicus"),
                            cmip6 = here::here("output", "data_cmip6"))

            files <- list.files(path, recursive = TRUE, full.names = TRUE)

            for(i in 1:length(renameVar$oldname)){

                file_path <- grep(paste0(renameVar$oldname[i], "_"), files, value = TRUE)

                if(length(file_path) >= 1){

                    for(f in 1:length(file_path)){

                        f_out <- gsub(".nc", "_TEMPO.nc", file_path[f])

                        com_rename <- paste0("cdo chname,", renameVar$oldname[i], ",", renameVar$newname[i], " ", file_path[f], " ", f_out)
                        message("### Running CDO command to rename variable :  \n", "--->", com_rename)
                        system(com_rename)

                        unlink(file_path[f])
                        file_rename <- strsplit(basename(file_path[f]), "_")[[1]]
                        file_rename[1] <- renameVar$newname[i]
                        file_rename <- paste(dirname(file_path[f]), paste0(file_rename, collapse = "_"), sep = "/")
                        file.rename(f_out, file_rename)

                    }
                }else(stop(paste0("Not any variables with the oldname", " '", renameVar$oldname[i], "' ", "give into 'renameVar' target is found")))
            }

            

        }else(message("Not any variables renamed"))

        return(list.files(path, recursive = TRUE, full.names = TRUE))

    }else{

        message("Skip manually 'renameVar' target (renameVar function)")

        path <- switch(type_data,
                copernicus = here::here("output", "data_copernicus"),
                cmip6 = here::here("output", "data_cmip6"))
        return(list.files(path, recursive = TRUE, full.names = TRUE))

    }

}


#' concatenate
#'
#' @description Merge cmip6 datasets by source x experiment x var for all datasets. Sorted by date and time. 
#' Used into concatenate_experiment() function.
#'
#' @param source Model downloaded
#' @param experiment Experiment downloaded
#' @param var Variable downloaded
#' @param type_data Character. Type of data you want process, "cmip6" or "copernicus". Default "cmip6".
#'
#' @return path to the output file merged
#'
#' @export file merged (.nc)
#'

concatenate <- function(source = NULL, 
                        experiment = NULL, 
                        var, 
                        type_data = "cmpi6") {

    if(type_data == "cmip6"){
        path_switch <- here::here("output", "data_cmip6", source, experiment)
    }

    if(type_data == "copernicus"){
        path_switch <- here::here("output", "data_copernicus")
    }

    exp_files_full <- sort(list.files(path = path_switch,
                                    pattern = paste0(var, "_"),
                                    full.names = TRUE))

    exp_files <- basename(exp_files_full)
    
    #if only one file then do nothing
    if (length(exp_files) == 1){
        message("### WARNING: Only one file, impossible to merge files")
        return(paste0(path_switch, "/", exp_files))
    } 

    # Output file name
    h1 <- exp_files[1]
    h2 <- exp_files[length(exp_files)]
    f_out <- paste0(path_switch, "/", substr(h1, 1, nchar(h1) - 9),
                    substr(h2, nchar(h2) - 8, nchar(h2)-3),
                    ".nc")

    f_in <- paste(exp_files_full, collapse = " ")
    com <- paste0("cdo mergetime ", f_in, " ", f_out)
    message("### Running CDO command to merge:  \n", "--->", com)
    system(com)
    Sys.sleep(5)
    unlink(exp_files_full)

    return(f_out)

}


#' concatenate_cmip
#'
#' @description Apply concatenate() function at all cmip6 datasets.
#'
#' @param renameVar_cmip Target. Data we want to merge.
#'
#' @return Same of concatenate() function
#'
#' @export Same of concatenate() function

concatenate_cmip <- function(renameVar_cmip){

    # download_data <- targets::tar_read("download_cmip_data")
    message("# Concatenating data files for each source * experiment * variable")

    data_sets <- strsplit(download_data, "cmip6/")
    data_sets <- unlist(lapply(data_sets, "[[", 2))

    data_sets <- do.call(rbind, lapply(strsplit(data_sets, "/"), function(x){

        d <- data.frame(t(unlist(x)))
        names(d) <- c("source_id", "experiment_id", "file")
        d$variable_id <- strsplit(d$file, "_|[.]")[[1]][1]
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
                            concatenate(source = s, experiment = e, var = v)
                        }))
                    }))
                }))
    
    # Remove files don't run with CDO (NA.nc). If "sources" and "experiment" don't have same "variable"
    select <- grep("NA.nc", basename(res_files))
    res_files <- res_files[-select]

    return(res_files)

}


#' concatenated_copernicus
#'
#' @description Apply concatenate() function at all copernicus datasets.
#'
#' @param obs_data Path list. List of variable path download by copernicus_download_api function
#'
#' @return Same of concatenate() function
#'
#' @export Same of concatenate() function
#' 

concatenate_copernicus <- function(obs_data){

    tab <- read.csv2(here::here("output", "data_copernicus", "copernicus_parameters_modified.csv"))
    
    v <- unique(sapply(strsplit(list.files(here::here("output", "data_copernicus"), pattern = ".nc$"), "_"), "[[", 1))

    vars <- unlist(lapply(v, function(v){

        message("Concatenate variable : ", v)

        concatenate(var = v, type_data = "copernicus")

    }))
    
    return(vars)
    
}


#' remapCDO
#'
#' @description To formate cmip6 and copernicus data download with CDO swofware. This function create and run CDO commands to shaping data.
#' If file final exists, the file will not be formatted again.
#'
#' @param file_path Path. File path of variable you want process.
#' @param type_data Character. Type of data you want process, "cmip6" or "copernicus".
#' @param period Character. "current" or "historical". Correspond to current_period historical_period target (check readme informations). Else it's not "historical_period" or "current_period", automatically function extract born of futur period.
#' @param spat_reso Character. spat_reso targets (check readme informations).
#' @param pat_output path. Folder where you want export variable processed.
#' @param monthWeek Logical. "month" or "week". Default "month". If you want mean data by week or month.
#' 
#' @return File path of the variable processed
#'
#' @export File (.nc) of the variable processed


remapCDO <- function(   file_path, 
                        type_data = "cmip6", 
                        period, 
                        spat_reso, 
                        path_output,
                        monthWeek = "month"){

    # Remove file stoped during process
    pattern <- paste0(path_output, "/", basename(file_path))
    pattern <- strsplit(pattern, "_")[[1]]
    pattern <- paste0(pattern[1:as.numeric(length(pattern)-1)], collapse = "_")
    process <- grep(pattern, list.files(path_output, full.name = TRUE), value = TRUE)
    if(length(process) >=1) remove(process)

    #################### Filter by time, treatment of the period we would like
    period <- switch(period,
                    current = targets::tar_read("current_period"),
                    historical = targets::tar_read("historical_period"),
                    targets::tar_read("futur_period"))

    f_seltime <- gsub(".nc", "_seltime.nc", file_path)
    f_seltime <- paste0(path_output, "/", basename(f_seltime))
    com_time <- paste0("cdo seldate,", period$start, ",", period$end, " ", file_path, " ", f_seltime)
    message("### Running CDO command to seltime :  \n", "--->", com_time)
    system(com_time)

    # Change date in file name
    split <- strsplit(f_seltime, "_")[[1]]
    place <- grep("[0-9]{6}-[0-9]{6}", split) #select date
    date <- lapply(period, function(x){
                st <- sapply(strsplit(x, "T"), "[[", 1 )
                st <- strsplit(st, "-")[[1]]
                st <- paste0(st, collapse = "")
            })
    split[place] <- paste(date$start, date$end, sep = "-")
    new_name <- paste(split, collapse = "_")
    file.rename(f_seltime, new_name)
    f_seltime <- new_name

    #################### Regrid
    f_regrid <- gsub(".nc", "_regrid.nc", f_seltime)
    com_regrid <- paste0("cdo remapdis,r", spat_reso, " ", f_seltime, " ", f_regrid)
    message("### Running CDO command to regrid :  \n", "--->", com_regrid)	      
    system(com_regrid)
    Sys.sleep(5)
    unlink(f_seltime)

    #################### Fill missing values
    f_miss <- gsub(".nc", "_miss.nc", f_regrid)
    com_miss <- paste0("cdo fillmiss ", f_regrid, " ", f_miss)
    message("### Running CDO command to fill missinf values :  \n", "--->", com_miss)
    system(com_miss)
    Sys.sleep(5)
    unlink(f_regrid)

    #################### Create, regrid, replicated and apply mask only to conserve study area
    mask_PA <- here::here("data", "mask_PA_variable.shp")
    mask_PA_out <- here::here("output", "mask_PA_variable.nc")
    system(paste0("gdal_rasterize -of netCDF -burn 1 -tr 0.01 0.01 ", "-a_srs EPSG:4326 ", mask_PA, " ", mask_PA_out)) # convert shp to nc

    ## Regrid mask
    f_maskRegrid <- gsub(".nc", "_regrid.nc", mask_PA_out)
    com_maskRegrid <- paste0("cdo -remapbil,r", spat_reso, " ", mask_PA_out, " ", f_maskRegrid)
    system(com_maskRegrid)
    Sys.sleep(5)
    unlink(mask_PA_out)

    ## Apply mask at several time series
    f_maskArea <- gsub(".nc", "_maskArea.nc", f_miss)
    com_maskArea <- paste0("cdo ifthen ", f_maskRegrid, " ", f_miss, " ", f_maskArea)
    message("### Running CDO command to apply mask :  \n", "--->", com_maskArea)
    system(com_maskArea)
    Sys.sleep(5)
    unlink(f_miss)

    #################### Change temporal resolution
    if(monthWeek == "month"){
        f_tempReso <- gsub(".nc", "_tempReso.nc", f_maskArea)
        com_tempReso <- paste0("cdo monmean ", f_maskArea, " ", f_tempReso)
        message("### Running CDO command to change temporal resolution :  \n", "--->", com_tempReso)
        system(com_tempReso)
        Sys.sleep(5)
        unlink(f_maskArea)
    }

    if(monthWeek == "week"){

        # f_maskArea <- "/home/romain/Documents/data_copernicus_beforeRename/zo_MULTIOBS_GLO_PHY_TSUV_3D_MYNRT_015_012-TDS_20180101-20191231.nc"
        # resotempo = list(vars = c("so", "to", "ugouvo", "zo", "WIND" ), reso = c("week", "week", "week", "week", "hour6"))

        resotempo <- targets::tar_read("resotempo")
        v <- strsplit(basename(f_maskArea), "_")[[1]][1]
        reso <- resotempo$reso[grep(v, resotempo$vars)]

        if(reso == "day"){}
            f_tempReso <- gsub(".nc", "_tempReso.nc", f_maskArea)
            com_tempReso <- paste0("cdo timselmean,7 ", f_maskArea, " ", f_tempReso)
            message("### Running CDO command to change temporal resolution :  \n", "--->", com_tempReso)
            system(com_tempReso)
            Sys.sleep(5)
            unlink(f_maskArea)

        if(reso == "hour1"){
            f_tempReso <- gsub(".nc", "_tempReso.nc", f_maskArea)
            com_tempReso <- paste0("cdo timselmean,168 ", f_maskArea, " ", f_tempReso)
            message("### Running CDO command to change temporal resolution :  \n", "--->", com_tempReso)
            system(com_tempReso)
            Sys.sleep(5)
            unlink(f_maskArea)
        }

        if(reso == "hour6"){
            f_tempReso <- gsub(".nc", "_tempReso.nc", f_maskArea)
            com_tempReso <- paste0("cdo timselmean,28 ", f_maskArea, " ", f_tempReso)
            message("### Running CDO command to change temporal resolution :  \n", "--->", com_tempReso)
            system(com_tempReso)
            Sys.sleep(5)
            unlink(f_maskArea)
        }

        if(reso == "week"){
            f_tempReso <- gsub(".nc", "_tempReso.nc", f_maskArea)
            file.rename(from = f_maskArea, to = f_tempReso)
            unlink(f_maskArea)
        }

        if(reso == "month"){stop("Time mean by week impossible beacause of file have a time unit in week")}
    }

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
        message("### Running CDO command to change dimension names :  \n", "--->", com_dimName)
        system(com_dimName)
        Sys.sleep(5)
        unlink(f_tempReso)

    } else {
        message("### -> Dimension names don't change. File rename")
        f_dimName <- gsub(".nc", "_dimName.nc", f_tempReso)
        file.rename(f_tempReso, f_dimName)
        Sys.sleep(5)
    }

    #################### Extract depth levels
    ncdf_file <- stars::read_ncdf(f_dimName)
    dim <- names(stars::st_dimensions(ncdf_file))

    boleen <- "lev" %in% dim

    if(boleen == TRUE){ # if file have a "lev" dimension

        # Mean all depth layers
        f_deep_tot <- gsub(".nc", "_deep.nc", f_dimName)
        com_deep_tot <- paste0("cdo vertmean ", f_dimName, " ", f_deep_tot)
        message("### Running CDO command to mean all depth levels :  \n", "--->", com_deep_tot)
        system(com_deep_tot)

        if(length(targets::tar_read(deep_level)$start) != 0){ #if deep_level target isn't empty

            # Loop initialisation
            deep_level <- targets::tar_read(deep_level)
            returnTOT <- c() #stock path return

            for(d in 1:length(deep_level$start)){

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
                message("### Running CDO command to extract depth levels between two values :  \n", "--->", com_deep)
                system(com_deep)
                Sys.sleep(5)
                unlink(f_deepTEMPO)

                returnTOT <- c(returnTOT, f_deep)

            }
            Sys.sleep(5)
            unlink(f_dimName)
            return(c(f_deep_tot, returnTOT))

        }else(return(f_deep_tot))

    } else {
        f_deep <- gsub(".nc", "_deep.nc", f_dimName)
        message(paste0("No depth levels for this variable: ", f_dimName))
        file.rename(f_dimName, f_deep)
        return(f_deep)
    }

}


#' remapCDO_cmip
#'
#' @description Apply remapCDO function to all cmip6 variables
#'
#' @param concatenate_cmip Path. Path of the cmip file you want formatted with CDO.
#'
#' @return Vector with paths of processed variables
#'
#' @export Processed files (.nc)
#' 

remapCDO_cmip <- function(concatenate_cmip){

    mods <- list.files(here::here("output", "data_cmip6")) # tructure file give all models downloaded

    # Remove folder and creat a folder empty
    if(file.exists(here::here("output", "data_cmip6_remapped"))) fs::dir_delete(here::here("output", "data_cmip6_remapped"))
    dir.create(here::here("output", "data_cmip6_remapped"))

    message("We have ", length(mods), " models: ", paste(mods, collapse = " | "))

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
        runs <- unique(unlist(sapply(vars, function(x){
            fs <- grep(x, basename(files), value = TRUE)
            fs <- setNames(lapply(splits[fs], '[', 4), NULL)
        })))

        # Apply CDO function at all files
        unlist(parallel::mclapply(runs, function(r) {
            #r = "piControl" ; r = "historical"
            unlist(parallel::mclapply(vars, function(v){
            #v  = "chl"

                # Remove path files don't exist. If "sources" () and "experiment" don't have same "variable"
                file <- paste0(here::here("output", "data_cmip6"), "/", m, "/", r, "/", grep(v, basename(files), value = TRUE))
                file <- paste0(here::here("output", "data_cmip6"), "/", m, "/", r, "/", grep(r, basename(file), value = TRUE))
                
                if(length(grep(".nc", file)) != 0){
                    
                    message("Processing for: ", m, " / ", r, " / ", v)

                    file_form <- remapCDO(  file_path = file, 
                                            type_data = "cmip6", 
                                            period = r, 
                                            spat_reso = targets::tar_read("spat_reso"), 
                                            path_output = path_output)

                    return(file_form)

                }

            }, mc.cores = 1)) # bug with mc.cores > 1

        }, mc.cores = 1)) # bug with mc.cores > 1

    }))

}

#' remapCDO_copernicus
#'
#' @description Apply remapCDO function to all copernicus variables
#'
#'
#' @param concatenate_copernicus Path list. Path of the copernicus file you want formatted with CDO.
#'
#' @return Vector with paths of processed variables
#'
#' @export Processed files (.nc)

remapCDO_copernicus <- function(concatenate_copernicus) {
    
    path_output <- here::here("output", "data_copernicus_remapped")
    
    ####### Remove folder and creat a folder empty
    if(file.exists(path_output)) fs::dir_delete(path_output)
    dir.create(path_output, showWarnings = FALSE)

    list_file <- list.files(here::here("output", "data_copernicus"), full.name = TRUE)
    
    ####### Monthly mean
    message("Mean by month")

    # Remove folder and creat a folder empty
    path_output_m <- paste0(path_output, "/", "month")
    if(file.exists(path_output_m)) fs::dir_delete(path_output_m)
    dir.create(path_output_m, showWarnings = FALSE)

    parallel::mclapply(list_file, function(f){
        
        message("Treatment of files :", list_file)

        remapCDO(   file_path = f, 
                    type_data = "copernicus", 
                    period = "current", 
                    spat_reso = targets::tar_read("spat_reso"), 
                    path_output = path_output_m)

        }, mc.cores = length(list_file))

    ####### Weekly mean
    message("Mean by week")

    # Remove folder and creat a folder empty
    path_output_w <- paste0(path_output, "/", "week")
    if(file.exists(path_output_w)) fs::dir_delete(path_output_w)
    dir.create(path_output_w, showWarnings = FALSE)

    parallel::mclapply(list_file, function(f){
        
        message("Treatment of files :", f)

        remapCDO(   file_path = f, 
                    type_data = "copernicus", 
                    period = "current", 
                    spat_reso = targets::tar_read("spat_reso"), 
                    path_output = path_output_w,
                    monthWeek = "week")

        }, mc.cores = length(list_file))

    return(list.files(path_output, recursive = TRUE, full.names = TRUE))

}


#' speedCompo
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
#' @param remove Logical. If TRUE remove files (uo, vo) used to create speed file. If TRUE tar_visnetwork invalid previous steps.
#'
#' @return Path of processed variable
#'
#' @export Processed file (.nc)

speedCompo <- function( path_compo1, 
                        path_compo2, 
                        name_compo1, 
                        name_compo2,
                        name_speed,
                        remove){

    # Create output file name
    split_name <- strsplit(basename(path_compo1), "_")[[1]] # create name of output file
    path_output <- dirname(path_compo1)
    f_merge <- paste0(path_output, "/", paste0(name_speed, "_", paste(split_name[2:length(split_name)], collapse = "_")))

    # Merge with CDO
    f_mergeTEMPO <- gsub(".nc", "_TEMPO.nc", f_merge)
    com_mergeTEMPO <- paste0("cdo merge ", path_compo1, " ", path_compo2, " ", f_mergeTEMPO)
    system(com_mergeTEMPO)

    # remove depth name (ex: chl50-100 -> chl) to apply cdo command on true variable name
    new_name <- lapply(list(name_compo1 = name_compo1, 
                            name_compo2 = name_compo2, 
                            name_speed = name_speed ), 
                        function(x) gsub("[0-9]{0,6}-[0-9]{0,6}", "", x))

    f_merge <- gsub("_TEMPO.nc", "_speedCompo.nc", f_mergeTEMPO)
    com_merge <- paste0("cdo expr,", "'", new_name$name_speed, "=", 
                        "sqrt(", new_name$name_compo1, "*", new_name$name_compo1, "+", new_name$name_compo2, "*", new_name$name_compo2, ")", "' ", 
                        f_mergeTEMPO, " ", f_merge)
    message("### Running CDO command to calcule speed :  \n", "--->", com_merge)
    system(com_merge)

    if(file.exists(f_merge) == TRUE){
        unlink(f_mergeTEMPO)

        if(remove == TRUE){ #if remove, tar_visnetwork invalid previous steps
            unlink(path_compo1) 
            unlink(path_compo2) 
        }

    } else(stop("Calcul with components failed"))

    return(f_merge)

}


#' speedCompo_cmip
#'
#' @description To apply speedCompo() function at cmip6 data
#'
#'
#' @param file_path Path. File paths of cmip6 variables you want process.
#' @param vars_speed List. vars_speed targets (check readme informations).
#' @param remove Logical. Argument of speedCompo function. If TRUE remove files used to create speed file (uo, vo). If TRUE tar_visnetwork invalid previous steps.
#'
#' @return Vector with paths of processed variables
#'
#' @export Processed files (.nc)
#'

speedCompo_cmip <- function(file_path = remapCDO_cmip, 
                            vars_speed, 
                            remove = FALSE) {

    # file_path <- list.files(here::here("output", "data_cmip6_remapped"), recursive = TRUE, full.name = TRUE)
    # vars_speed <- targets::tar_read("vars_speed")

    model <- list.files(here::here("output", "data_cmip6_remapped"))

    for(i in 1:length(model)){

        file_path2 <- grep(model, file_path, value = TRUE)

        # Integrate depth variables (U0-50, chl50-100, etc...) in vars_speed targets
        vsplit <- sapply(strsplit(basename(file_path2), "_"), "[[", 1)
        vsplit_compo1 <- unique(grep(paste0(vars_speed$compo1, collapse = "|"), vsplit, value = TRUE))
        vsplit_compo2 <- unique(grep(paste0(vars_speed$compo2, collapse = "|"), vsplit, value = TRUE))
        boleen <- sort(vsplit_compo1) == sort(vars_speed$compo1)
        if(FALSE %in% boleen){
            vars_speed$compo1 <- vsplit_compo1
            vars_speed$compo2 <- vsplit_compo2
            vars_speed$name <- paste0(gsub("[0-9]{1,10}-[0-9]{1,10}", "", vars_speed$compo1), vars_speed$compo2)
        }

        # Conserve path root of the file
        path_root <- unique(dirname(file_path2))

        for(i in 1:length(vars_speed$compo1)){

            # Select variable with two coponents
            grep_var <- grep(basename(file_path2), pattern = paste0("^(", vars_speed$compo1[i], "_", ")", "|", "^(", vars_speed$compo2[i], "_", ")"), value = TRUE)

            if(length(grep_var) >= 2){ #if pattern "grep_var" object correspond to copernicus variable names, length = 0

                run <- unique(sapply(strsplit(grep_var, "_"), "[", 4))

                unlist(lapply(run, function(run){

                    #run = "historical"

                    grep_run <- grep(basename(grep_var), pattern = run, value = TRUE)
                    
                    message(paste0("#### Launch speedCompo function for : \n"), paste0(grep_run, collapse = "\n"))

                    if(length(grep_run) > 2) stop("More than one file found to calculate speed!" )

                    compo <- speedCompo(path_compo1 = paste(path_root, grep_run[1], sep = "/"), 
                                        path_compo2 = paste(path_root, grep_run[2], sep = "/"), 
                                        name_compo1 = vars_speed$compo1[i], 
                                        name_compo2 = vars_speed$compo2[i],
                                        name_speed = vars_speed$name[i],
                                        remove = remove
                                        )

                }))

            }

        }

    }

    # Return all file of after this step - all file after previous step = only file create during this step
    all <- list.files(here::here("output", "data_cmip6_remapped"), recursive = TRUE, full.name = TRUE)
    previous <- file_path
    place <- grep(paste0(previous, collapse = "|"), all)
    return <- all[-place]

    return(return)

}


#' speedCompo_copernicus
#'
#' @description To apply speedCompo() function at copernicus data
#'
#'
#' @param file_path Path. File paths of copernicus variables you want process.
#' @param vars_speed List. vars_speed targets (check readme informations).
#' @param remove Logical. Argument of speedCompo function. If TRUE remove files used to create speed file (uo, vo). If TRUE tar_visnetwork invalid previous steps.

#' @return Vector with paths of processed variables
#'
#' @export Processed files (.nc)
#'

speedCompo_copernicus <- function(file_path = remapCDO_copernicus, 
                                    vars_speed,
                                    remove = FALSE) {

    # Extract path for monthly and weekly data 
    path_root <- unique(dirname(file_path))
    temp_folder <- strsplit(path_root, "/")
    temp_folder <- sapply(temp_folder, "[[", length(temp_folder[[1]]))

    # Integrate depth variables (U0-50, chl50-100, etc...) in vars_speed targets
    vsplit <- sapply(strsplit(basename(file_path), "_"), "[[", 1)
    vsplit_compo1 <- unique(grep(paste0(vars_speed$compo1, collapse = "|"), vsplit, value = TRUE))
    vsplit_compo2 <- unique(grep(paste0(vars_speed$compo2, collapse = "|"), vsplit, value = TRUE))
    boleen <- sort(vsplit_compo1) == sort(vars_speed$compo1)
    if(FALSE %in% boleen){
        vars_speed$compo1 <- vsplit_compo1
        vars_speed$compo2 <- vsplit_compo2
        vars_speed$name <- paste0(gsub("[0-9]{1,10}-[0-9]{1,10}", "", vars_speed$compo1), vars_speed$compo2)
    }

    # Speed calcul
    for(f in 1:length(temp_folder)){ #filter by monthly and weekly data

        for(i in 1:length(vars_speed$compo1)){

            grep_var <- grep(file_path, pattern = temp_folder[f], value = TRUE)

            # Select variable with two coponents
            grep_var <- grep(basename(grep_var), pattern = paste0("^(", vars_speed$compo1[i], "_)", "|", "^(", vars_speed$compo2[i], "_)"), value = TRUE)
            if(length(grep_var) > 2) stop("Error: more than one file found to calculate speed!" )

            if(length(grep_var) == 2){ # if pattern "fs" object correspond to cmip6 variable names, length = 0
                    
                    message("Calcul speed with variables", " (",temp_folder[f], ") : \n", paste0(grep_var, collapse = "\n"))

                    compo <- speedCompo(path_compo1 = paste(path_root[f], grep_var[1], sep = "/"), 
                                        path_compo2 = paste(path_root[f], grep_var[2], sep = "/"), 
                                        name_compo1 = vars_speed$compo1[i], 
                                        name_compo2 = vars_speed$compo2[i],
                                        name_speed = vars_speed$name[i],
                                        remove = remove
                                                        )

            }

        }
    }

    # Return all file of after this step - all file after previous step = only file create during this step
    all <- list.files(here::here("output", "data_copernicus_remapped"), recursive = TRUE, full.name = TRUE)
    previous <- file_path
    place <- grep(paste0(previous, collapse = "|"), all)
    return <- all[-place]

    return(return)


}
