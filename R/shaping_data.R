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

#' remap_data_cmip
#'
#' @description To formate cmip6 data download with CDO swofware. CDO commands created and run in this function. 
#' We regrid data with "spat_reso", we fill empty value, we crop data with a mask of area study.
#'
#'
#' @param concatenate_data List path. Path of concatenated files export by concatenate_data function.
#' @param spat_reso Character. Target "spat_reso". Variable spatial resolution applied.
#'
#' @return NULL
#'
#' @export Formated files (.nc)
#' 

remap_cmip_data <- function(concatenate_data, spat_reso){

    #spat_reso = "180x90"

    dir.create(here::here("output", "cmip6_data_remapped"), showWarnings = FALSE)

    mods <- read.csv2(here::here("output", "selected_datasets.csv"))
    mods <- unique(mods$source_id)

    message("we have ", length(mods), " models: ", paste(mods, collapse = " | "))

    unlist(lapply(mods, function(m){
        
        #m = "CMCC-ESM2"
        
        # Select files and variable names
        message(paste0("### Treatment of ", m))
        dir.create(here::here("output", "cmip6_data_remapped", m), showWarnings = FALSE)
        path  <- paste0(here::here("output", "data_cmip6"), "/", m)
        files <- list.files(path, recursive = TRUE, pattern = ".nc")
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

        # Apply CDO at all files
        unlist(parallel::mclapply(runs, function(r) {
            #r = "piControl" ; r = "historical"
            unlist(parallel::mclapply(vars, function(v){
            #v  = "chl"
                message("Processing for: ", m, " / ", r, " / ", v)
                
                file <- paste0("output/data_cmip6/", m, "/", r, "/", grep(v, files, value = TRUE))

                # if (substr(v, nchar(v)-1, nchar(v)) != "os") {
                # vf <- paste0(v, "os") } else { vf <- v }

                f_final <- gsub(paste0("output/data_cmip6/", m, "/", r, "/"), 
                                paste0("output/cmip6_data_remapped/", m, "/"), 
                                gsub(".nc", "_seltime_regrid_miss_maskArea_spatReso_dimName.nc", file))

                if (file.exists(f_final)) return(f_final)
                
                #################### Extract surface layer ?

                #   #extract first level if 3d file
                #   if (substr(v, nchar(v)-1, nchar(v)) != "os") {
                #     nv <- paste0(v, "os")
                #     lev <- system(paste0("cdo showlevel ", file), intern = TRUE)
                #     lev <- na.omit(as.numeric(strsplit(lev, " ")[[1]]))[1]
                #     com <- paste0("cdo sellevel,", lev)
                #     f_out <- gsub(v, nv, file)
                #         f_out <- gsub(paste0("data/", m), paste0("outputs/cmip6_data_remapped/", m), f_out)
                #   	comm <- paste(com, file, f_out)
                #   	system(comm)
                #   	file <- f_out
                #   }

                #################### Filter by time, treatment of the period we would like
                period <- switch(r,
                                historical = historical_period,
                                future_period)

                # period = list(start = "1970-01-01T00:00:00", end = "1980-01-01T00:00:00")

                f_seltime <- gsub(".nc", "_seltime.nc", file)
                f_seltime <- gsub(paste0("output/data_cmip6/", m, "/", r, "/"), paste0("output/cmip6_data_remapped/", m, "/"), f_seltime)
                com_time <- paste0("cdo seldate,", period$start, ",", period$end, " ", file, " ", f_seltime)
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
                f_tempReso <- gsub(".nc", "_spatReso.nc", f_maskArea)
                com_tempReso <- paste0("cdo monmean ", f_maskArea, " ", f_tempReso)
                system(com_tempReso)
                unlink(f_maskArea)

                #################### Change dimension names
                ncdf_file <- stars::read_ncdf(f_tempReso)
                dim <- names(stars::st_dimensions(ncdf_file))

                boleen <- dim != c("lon", "lat", "lev", "time")
                if(exists("com_dimName")) rm(com_dimName) #remove command if exist
                com_dimName <- paste0("ncrename") #first command part

                if(boleen[1] == TRUE){
                    com_dimName <- paste0(  com_dimName,
                                            " -d ", dim[1], ",long",
                                            " -v ", dim[1], ",long")
                }

                if(boleen[2] == TRUE){
                    com_dimName <- paste0(  com_dimName,
                                            " -d ", dim[2], ",latg",
                                            " -v ", dim[2], ",latg") 
                }

                if(boleen[3] == TRUE){
                    com_dimName <- paste0(  com_dimName,
                                            " -d ", dim[3], ",levg", 
                                            " -v ", dim[3], ",levg") 
                }

                if(boleen[4] == TRUE){
                    com_dimName <- paste0(  com_dimName,
                                            " -d ", dim[4], ",timeg", 
                                            " -v ", dim[4], ",timeg") 
                }

                if(com_dimName != "ncrename" ){
                    f_dimName <- gsub(".nc", "_dimName.nc", f_tempReso)
                    com_dimName <- paste0(  com_dimName,
                                            " ", f_tempReso,
                                            " ", f_dimName)
                    system(com_dimName)
                }else("Dimension names don't change")

                return(f_dimName)

            }, mc.cores = length(vars)))

        }, mc.cores = 2))

    }))

}

tr <- stars::read_ncdf("/home/romain/MyData/Doctorat/Analyses/downshape/output/cmip6_data_remapped/CMCC-ESM2/chl_Omon_CMCC-ESM2_piControl_r1i1p1f1_gn_197001-198912_seltime.nc")

org <- stars::read_ncdf("/home/romain/MyData/Doctorat/Analyses/downshape/output/cmip6_data_remapped/CMCC-ESM2/chl_Omon_CMCC-ESM2_piControl_r1i1p1f1_gn_197001-198912_seltime.nc")
