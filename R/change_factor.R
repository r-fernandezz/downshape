#' climato_cmip
#'
#' @description To create climatology for all variables by experiments and by models. Remove months not choosen before to mean.
#'
#' @param speedCompo_cmip Target. Allow to connect target. Check README documentation.
#' @param climato_period Target. Check README documentation.
#' 
#' @return List of files created
#'
#' @export .grd files meaned without months not choosen
#' 

climato_cmip <- function(speedCompo_cmip, climato_period){

    # Create stockage folder
    path_output_cf <- paste0(here::here("output", "data_cmip6_change_factor"))
    if(file.exists(path_output_cf)) fs::dir_delete(path_output_cf)
    dir.create(path_output_cf, showWarnings = FALSE)

    path_output <- paste0(here::here("output", "data_cmip6_change_factor", "climatology"))
    if(file.exists(path_output)) fs::dir_delete(path_output)
    dir.create(path_output, showWarnings = FALSE)

    model <- list.files(here::here("output", "data_cmip6_remapped"))
    ssp <- list.files(here::here("output", "data_cmip6_remapped", model[1])) #same ssp for all models
    ssp <- ssp[!(ssp %in% "historical")] #remove historical, to create climatology on all other ssp
    vars <- unlist(lapply(list.files(here::here("output", "data_cmip6_remapped", model[1], ssp[1]), pattern = ".nc$"), function(list) unique(strsplit(list, "_")[[1]][1])))

    stock_climato_files <- c()

    for(c in 1:length(climato_period$name)){

        climato_files <- unlist(lapply(model, function(m){
                            unlist(lapply(ssp, function(s){
                                unlist(lapply(vars, function(v){
                                        # m = "CanESM5"; s = "ssp126" ; v = "SSTcmip"
                                        message("Create climatology ", climato_period$name[c], " with CDO for ", m, "|", s, "|", v)

                                        # Create output folders
                                        path_output_c <- paste0(path_output, "/", climato_period$name[c])
                                        dir.create(path_output_c, showWarnings = FALSE)
                                        path_output_m <- paste0(path_output, "/", climato_period$name[c], "/", m)
                                        dir.create(path_output_m, showWarnings = FALSE)
                                        path_output_s <- paste0(path_output, "/", climato_period$name[c], "/", m, "/", s)
                                        dir.create(path_output_s, showWarnings = FALSE)
                                        
                                        # Create input and output file name for CDO command
                                        in_mean <- grep(paste0(v, "_"),
                                                        list.files(here::here("output", "data_cmip6_remapped", m, s), pattern = ".nc$", full.names = TRUE),
                                                        value = TRUE)
                                        out_mean <- gsub("data_cmip6_remapped", paste0("data_cmip6_change_factor/climatology/", climato_period$name[c]), in_mean)
                                        out_mean <- gsub("[0-9]{1,10}-[0-9]{1,10}", paste0("climato", climato_period$name[c]), out_mean)

                                        # Mean time to create climatology with CDO
                                        comd <- paste0("cdo seldate,", climato_period$start[c], ",", climato_period$end[c], " ", in_mean, " ", out_mean)
                                        system(comd)

                                        # Mean climatology, remove month not used and convert to raster format
                                        climatoMean <- mean_month(  month = climato_period$month_choose, 
                                                                    path_variable = out_mean, 
                                                                    type_output = "StackRaster")

                                        # Export climatology meaned in .grd
                                        raster::writeRaster(climatoMean, 
                                                            filename = gsub(".nc", ".grd", out_mean), 
                                                            overwrite = TRUE)
                                        ifelse( file.exists(gsub(".nc", ".grd", out_mean)),
                                                unlink(out_mean),
                                                stop(paste0("Climatology not created : ", c, "|", m, "|", s, "|", v))) 

                                        return(gsub(".nc", ".grd", out_mean))

                                }))
                            }))
                        }))
        
        stock_climato_files <- c(climato_files, stock_climato_files)

    }

    return(stock_climato_files)

}

#' mergeHistorical_cmip
#'
#' @description Convert historical variable to raster and merge time period (historical + ssp) if necessary.
#'
#'
#' @param speedCompo_cmip Target. Allow to connect target. Check README documentation.
#' @param historical_period Target. Check README documentation.
#' @param baseline_period Target. Check README documentation.
#' @param futur_period Target. Check README documentation.
#' @param climato_period Target. Check README documentation.
#'
#' @return Name Variable
#'
#' @export 
#' 

mergeHistorical_cmip <- function(speedCompo_cmip, historical_period, baseline_period, futur_period, climato_period){

    # Control error into targets time
    if(as.Date(historical_period$end) > as.Date(baseline_period$end)) stop("Check README documentation, 'historical_period$end' target more older than 'baseline_period$end' target")
    if(as.Date(historical_period$start) != as.Date(baseline_period$start)) stop("Check README documentation, not same date for'historical_period$start' target and 'baseline_period$start' target")
    if(as.Date(futur_period$start) - as.Date(historical_period$end) > 31) stop("Check README documentation, 'futur_period' target not begining juste after 'historical_period' target")
    message("Check ready, so we can merged historical and ssp periods")

    if(!(historical_period$start == baseline_period$start & historical_period$end == baseline_period$end)){

        message("WARNING : We admit 'historical_period' target is more small than 'baseline_period' target, so we merge time of historical and ssp period")

        # Create stockage folder
        path_output <- paste0(here::here("output", "data_cmip6_change_factor", "historical_ssp_merged"))
        if(file.exists(path_output)) fs::dir_delete(path_output)
        dir.create(path_output, showWarnings = FALSE)

        model <- list.files(here::here("output", "data_cmip6_remapped"))
        ssp <- list.files(here::here("output", "data_cmip6_remapped", model[1])) #same ssp for all models
        ssp <-  ssp[!(ssp %in% "historical")]
        vars <- unlist(lapply(list.files(here::here("output", "data_cmip6_remapped", model[1], ssp[1]), pattern = ".nc$"), function(list) strsplit(list, "_")[[1]][1]))

        histoMerge_files <- unlist(lapply(model, function(m){
                                dir.create(paste0(path_output, "/", m), showWarnings = FALSE)

                                unlist(lapply(ssp, function(s){
                                    dir.create(paste0(path_output, "/", m, "/", s), showWarnings = FALSE)

                                    unlist(lapply(vars, function(v){
                                        # m = "CanESM5"; s = "ssp126" ; v = "SSTcmip"

                                        # Select input names files for CDO command
                                        historical <- list.files(here::here("output", "data_cmip6_remapped", m, "historical"), pattern = paste0(v, "_"), full.name = TRUE)
                                        ssp <- list.files(here::here("output", "data_cmip6_remapped", m, s), pattern = paste0(v, "_"), full.name = TRUE)

                                        # Create output name for CDO command
                                        out_select <- paste0(path_output, "/", m, "/", s, "/", basename(historical))
                                        format_date <- gsub("-", "", strsplit(baseline_period$end, "T")[[1]][1])
                                        out_select <- gsub("-[0-9]{1,10}", paste0("-", format_date), out_select )
                                        out_select <- gsub("_historical_", paste0("_historical+", s, "_"), out_select)

                                        # Select and merge ssp time period with all historical period
                                        out_name <- paste0(dirname(out_select), "/ssp_period_merged_to_historical_TEMPO_file.nc")
                                        comd_sel <- paste0("cdo seldate,", historical_period$end, ",", baseline_period$end, " ", ssp, " ", out_name)
                                        system(comd_sel)

                                        comd_merge <- paste0("cdo mergetime ", historical, " ", out_name, " ", out_select)
                                        system(comd_merge)
                                        ifelse( file.exists(out_select),
                                                unlink(out_name),
                                                stop(paste0("Historical period not merge or ssp period not selected for : ", m, "|", s, "|", v)))

                                        # Mean historical period, remove month not used and export to raster format
                                        historicalMean <- mean_month(   month = climato_period$month_choose, 
                                                                        path_variable = out_select, 
                                                                        type_output = "StackRaster")

                                        # Export climatology meaned in .grd
                                        raster::writeRaster(historicalMean, 
                                                            filename = gsub(".nc", ".grd", out_select), 
                                                            overwrite = TRUE)
                                        ifelse( file.exists(gsub(".nc", ".grd", out_select)),
                                                unlink(out_select),
                                                stop(paste0("New historical merged with ssp not created : ", m, "|", s, "|", v))) 

                                        return(gsub(".nc", ".grd", out_select))
                                        

                                    }))
                                }))
                            }))
    
    return(histoMerge_files)

    }else(message("WARNING : 'historical_period' target and 'baseline_period' target can't to be used in 'mergeHistorical_cmip' function beacause they have same period"))

}

#' deltaCF
#'
#' @description Allow to calculate delto between historical modified (with mergeHistorical_cmip) and baseline. 
#' Remove months not choosen to create climatology of baseline 
#'
#'
#' @param Variable Type. Explication.
#' @param Variable Type. Explication.
#'
#' @return Name Variable
#'
#' @export 
#' 

deltaCF <- function(climato_cmip, mergeHistorical_cmip, match_name, grad_copernicus){
    
    # Create output folder
    path_output <- here::here("output", "data_cmip6_change_factor")
    path_output_dir <- paste0(path_output, "/variables_bias-corrected")
    if(file.exists(path_output_dir)) fs::dir_delete(path_output_dir)
    dir.create(path_output_dir, showWarnings = FALSE)

    # Lapply arguments
    climato <- list.files(paste0(path_output, "/climatology"))
    model <- list.files(here::here("output", "data_cmip6_remapped"))
    ssp <- list.files(here::here("output", "data_cmip6_remapped", model[1])) #same ssp for all models
    ssp <-  ssp[!(ssp %in% "historical")]
    vars <- unlist(lapply(list.files(here::here("output", "data_cmip6_remapped", model[1], ssp[1]), pattern = ".nc$"), function(list) strsplit(list, "_")[[1]][1]))


    histoMerge_files <- unlist(lapply(climato, function(c){
                        dir.create(paste0(path_output_dir, "/", c), showWarnings = FALSE)
                            unlist(lapply(model, function(m){
                            dir.create(paste0(path_output_dir, "/", c, "/", m), showWarnings = FALSE)

                                unlist(lapply(ssp, function(s){
                                    dir.create(paste0(path_output_dir, "/", c, "/", m, "/", s), showWarnings = FALSE)

                                    unlist(lapply(vars, function(v){

                                        # c = "2030" ; m = "CanESM5"; s = "ssp126" ; v = "SSTcmip"

                                        historical <- list.files(paste0(path_output, "/historical_ssp_merged/", m, "/", s), pattern = paste0(v, "_"), full.name = TRUE)
                                        historical <- grep(".grd$", historical, value = TRUE)

                                        ssp <- list.files(paste0(path_output, "/climatology/", c, "/", m, "/", s), pattern = paste0(v, "_"), full.name = TRUE)
                                        ssp <- grep(".grd$", ssp, value = TRUE)

                                        r_hist <- raster::stack(historical)
                                        r_ssp <- raster::stack(ssp)

                                        # Choose calcul of delta
                                        delta_absolute <- grep(v, c("SST", "SSTcmip", "CHL", "CHLcmip", "BATHY", "BATHYcmip",
                                                            "GSST", "GSSTcmip", "GCHL", "GCHLcmip", "GBATHY", "GBATHYcmip")) # absolute delta can be calculate on these variables
                                        delta_absolute <- ifelse(   length(delta_absolute) > 0,
                                                                    TRUE,
                                                                    FALSE)

                                        if(delta_absolute == TRUE){
                                            message("Absolute difference (delta) must to be calculated for this variable (Navarro_Racines et al. 2020, page 3)")
                                            delta <- r_ssp - r_hist

                                        }else{
                                            message("Relative change (delta) must to be calculated for this variable (Navarro_Racines et al. 2020, page 3)")
                                            delta <- (r_ssp - r_hist)/r_hist
                                        
                                        }

                                        # Select baseline variable (copernicus) correspond to cmip variable processing (v)
                                        position <- grep(paste0(v, "$"), match_name$cmip)
                                        v_copernicus <- match_name$copernicus[position]
                                        baseline <- list.files(here::here("output", "data_copernicus_remapped", "baseline", "GRD"), pattern = paste0(v_copernicus, "_"), full.name = TRUE)
                                        baseline <- grep(".grd$", baseline, value = TRUE)

                                        # Remove months don't used to create climatology with baseline
                                        baseline <- mean_month( month = climato_period$month_choose, 
                                                                path_variable = baseline, 
                                                                type_output = "StackRaster")

                                        # Calcul new variable bias-corrected
                                        if(delta_absolute == TRUE){

                                            vars <- baseline + delta

                                        }else{

                                            vars <- baseline * (1 + delta)
                                        
                                        }

                                        raster::writeRaster(vars, 
                                                            filename = paste0(path_output_dir, "/", c, "/", m, "/", s, "/", "Bias-corrected_variable__", v, ".grd"), 
                                                            overwrite = TRUE)

                                    }))
                                }))
                            }))
                        }))

}
