#' climato_cmip
#'
#' @description To create climatology. Mean and remove months not choosen for all variables by experiments and by models.
#'
#' @param speedCompo_cmip Target. Allow to connect target. Check README documentation.
#' @param climato_period List. "name" is the climatology name (folder output name), "start" and "end" are borns of climatology would you want (cdo format: "YYYY-MM-DDThh:mm:ss").
#' @param month_choose Vector. Month conserved into the climatology mean calcul. Argument of "mean_month" function.
#' 
#' @return List of files created
#'
#' @export .grd files meaned without months not choosen
#' 

climato_cmip <- function(   speedCompo_cmip, 
                            climato_period = list(  name = c("2030", "2050", "2070"), 
                                                    start = c("2020-01-01T00:00:00", "2040-01-01T00:00:00", "2060-01-01T00:00:00"), 
                                                    end = c("2040-12-30T23:59:59", "2060-12-30T23:59:59", "2080-12-30T23:59:59")),
                            month_choose = c(2, 3, 4, 5, 6, 7, 8, 9)){

    # Create stockage folder
    path_output <- paste0(here::here("output", "data_cmip6_change_factor", "climatology"))
    if(file.exists(path_output)) fs::dir_delete(path_output)
    dir.create(path_output, showWarnings = FALSE)

    model <- list.files(here::here("output", "data_cmip6"))
    ssp <- list.files(here::here("output", "data_cmip6", model[1])) #same ssp for all models
    ssp <- ssp[!(ssp %in% "historical")] #remove historical, to create climatology on all other ssp
    vars <- unlist(lapply(list.files(here::here("output", "data_cmip6", model[1], ssp[1]), pattern = ".nc$"), function(list) strsplit(list, "_")[[1]][1]))

    climato_files <- unlist(lapply(model, function(m){
                        unlist(lapply(ssp, function(s){
                            unlist(lapply(vars, function(v){
                                
                                for(c in 1:length(climato_period)){
                                    
                                    # m = "CanESM5"; s = "ssp126" ; v = "SSTcmip"

                                    message("Create climatology ", c, " with CDO for ", m, "|", s, "|", v)

                                    # Create output folders
                                    path_output_c <- paste0(path_output, "/", climato_period$name[c])
                                    dir.create(path_output_c, showWarnings = FALSE)
                                    path_output_m <- paste0(path_output, "/", climato_period$name[c], "/", m)
                                    dir.create(path_output_m, showWarnings = FALSE)
                                    path_output_s <- paste0(path_output, "/", climato_period$name[c], "/", m, "/", s)
                                    dir.create(path_output_s, showWarnings = FALSE)
                                    
                                    # Create input and output file name for CDO command
                                    in_mean <- grep(paste0(v, "_"),
                                                    list.files(here::here("output", "data_cmip6", m, s), pattern = ".nc$", full.names = TRUE),
                                                    value = TRUE)
                                    out_mean <- gsub("data_cmip6", paste0("data_cmip6_change_factor/", climato_period$name[c]), in_mean)

                                    # Mean time to create climatology with CDO
                                    comd <- paste0("cdo seldate,", climato_period$start[c], ",", climato_period$end[c], " ", in_mean, " ", out_mean)

                                    # Mean climatology, convert to raster format and remove month not used
                                    climatoMean <- mean_month(  month = month_choose, 
                                                                path_variable = out_mean, 
                                                                type_output = "StackRaster")

                                    # Export climatology meaned in .grd
                                    raster::writeRaster(climatoMean, gsub(".nc", ".grd", out_mean), format = "raster")
                                    ifelse( file.exists(gsub(".nc", ".grd", out_mean)),
                                            unlink(out_mean),
                                            stop(paste0("Climatology not created : ", c, "|", m, "|", s, "|", v))) 

                                    return(gsub(".nc", ".grd", out_mean))
                                }

                            }))
                        }))
                    }))

    return(climato_files)

}

#' mergeHistorical_cmip
#'
#' @description Convert historical variable to raster and merge time period (historical + ssp) if necessary.
#'
#'
#' @param Variable Type. Explication.
#' @param Variable Type. Explication.
#'
#' @return Name Variable
#'
#' @export 
#' 

mergeHistorical_cmip <- function(){

    if( all(historical_period$start == baseline_period$start & historical_period$end != baseline_period$end) == TRUE){

        message("WARNING : We admit 'historical_period' target is more small than 'baseline_period' target, so we merge time of historical and ssp period")

        # Create stockage folder
        path_output <- paste0(here::here("output", "data_cmip6_change_factor", "historical_ssp_merged"))
        if(file.exists(path_output)) fs::dir_delete(path_output)
        dir.create(path_output, showWarnings = FALSE)

        model <- list.files(here::here("output", "data_cmip6"))
        ssp <- list.files(here::here("output", "data_cmip6", model[1])) #same ssp for all models
        ssp <-  ssp[!(ssp %in% "historical")]
        vars <- unlist(lapply(list.files(here::here("output", "data_cmip6", model[1], ssp[1]), pattern = ".nc$"), function(list) strsplit(list, "_")[[1]][1]))

        histoMerge_files <- unlist(lapply(model, function(m){
                                unlist(lapply(ssp, function(s){
                                    unlist(lapply(vars, function(v){


                                    }))
                                }))
                            }))

    }else(message("WARNING : 'historical_period' target and 'baseline_period' target can't to be used in 'mergeHistorical_cmip' function"))

}