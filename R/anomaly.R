#' anomaly
#'
#' @description Calculation variable anomaly with climatology available into data folder. 
#' This anomaly is calculated with weekly variables.
#'
#'
#' @param remapCDO_copernicus Type. Explication.
#' @param ano_vars Character. variable name (in the file name) would you like use to calcule anomaly. Set to NULL if not used.
#' @param skip Logical. Default FALSE. If you want skip (TRUE) or not (FALSE) this function into the pipeline to conserve target valid into target_visnetwork visual.
#' 
#' @return Name Variable
#'
#' @export 
#' 
#' 

anomaly <- function(connectPip_copernicus, ano_vars = NULL, skip = FALSE){

    if(skip == FALSE){

        if(!is.null(ano_vars)){

            return_names <- c()

            for(t in c("month", "week")){

                list_file <- list.files(here::here("output", "data_copernicus_remapped", t), pattern = "[.]nc$")
                list_file_full <- list.files(here::here("output", "data_copernicus_remapped", t), pattern = "[.]nc$", full.name = TRUE)
                vars_available <- unlist(lapply(strsplit(basename(list_file), "_"),"[[", 1))
                boolean <- ano_vars %in% gsub("[.]nc", "", vars_available)
                place <- grep(ano_vars, vars_available)
                
                ii <- 0 
                for(i in place){ #for all target variables in "ano_vars"

                    ii <- ii+1 #correspondance between ano_vars and list_file

                    message(paste0("--> Variable processing :", list_file_full[i]))
                    v <- raster::stack(list_file_full[i])

                    clim_list <- list.files(here::here("data"), pattern = paste0(ano_vars[ii], "_climatology"), full.names = TRUE) #all climatology
                    clim_list <- grep(paste0(t, "[.]"), clim_list, value = TRUE) #weekly or monthly climatology
                    clim_list <- grep(paste0("[.]grd$|[.]nc$"), clim_list, value = TRUE) #remove .grid files
                    if(length(clim_list) < 0) stop(paste0("Climatology not available for the variable : ", ano_vars[ii]))

                    message(paste0("--> Climatology processing :", clim_list))
                    clim <- raster::stack(clim_list)

                    # Check errors
                    if(TRUE %in% c(dim(v)[1:2] != dim(clim)[1:2])) stop(paste0(  "Variable and climatology dimension are different", "\n",
                                                                        "--> variable : ", list_file_full[i], "\n",
                                                                        "--> climatology : ", clim_list, "\n"))

                    # Anomaly calculation anomaly 
                    num_weekMonth <- function(raster, time){ #transforme layer date to week number
                        date_init <- gsub("X", "", names(raster))
                        date <- gsub("[.]", "-", date_init)

                        if(time == "week"){
                            date <- as.numeric(format(as.Date(date), "%U")) + 1 #betweeen 1 and 52 (not 0 and 51)
                            date <- paste0("Week_", date)
                            return(list(date_init, date))
                        }

                        if(time == "month"){
                            date <- format(as.Date(date), "%m")
                            date <- paste0("Month_", date)
                            return(list(date_init, date))
                        }

                    }

                    if(t == "week"){

                        num <- num_weekMonth(v, "week")
                        names(v) <- num[[2]]

                        message("Anomaly calculation processing...")
                        anomaly <- raster::stack()

                        for(l in 1:length(names(v))){
                            ll <- as.numeric(gsub("Week_", "", num[[2]]))
                            anomaly_sub <- raster::subset(v, l) - raster::subset(clim, ll[l])
                            anomaly <- raster::stack(anomaly, anomaly_sub)
                        }

                        message("Anomaly calculation processing ---> DONE")

                    }

                    if(t == "month"){

                        num <- num_weekMonth(v, "month")
                        names(v) <- num[[2]]

                        message("Anomaly calculation processing...")

                        anomaly <- raster::stack()

                        for(l in 1:length(names(v))){
                            ll <- as.numeric(gsub("Month_", "", num[[2]]))
                            anomaly_sub <- raster::subset(v, l) - raster::subset(clim, ll[l])
                            anomaly <- raster::stack(anomaly, anomaly_sub)
                        }

                        message("Anomaly calculation processing ---> DONE")

                    }

                    names(anomaly) <- num[[1]]

                    # Rename file name and export into folder "GRD"
                    name_path <- gsub("[.]nc", ".grd", list_file_full[i])
                    name_path <- paste0(dirname(name_path), "/GRD/", basename(name_path))
                    name_vars <- gsub(ano_vars[ii], paste0(ano_vars[ii], "ano"), basename(name_path))
                    name <- sapply(strsplit(basename(name_vars), "_"), "[[", 1)
                    newname <- paste0("__", name)
                    finalname <- gsub(paste0(name, "_"), "", name_vars)
                    finalname <- gsub("[.]grd", paste0(newname, ".grd"), finalname)
                    out_name <- paste0(dirname(name_path), "/", finalname)

                    raster::writeRaster(anomaly, 
                                        filename = out_name, 
                                        format = "raster",
                                        bylayer = FALSE, 
                                        overwrite = TRUE)
                    
                    message("Anomaly variable exportation ---> DONE")

                    return_names <- c(return_names, out_name)

                }
            }

            return(return_names)

        }else {
            message("The 'anomaly' target is empty")
            return(connectPip_copernicus)
        }

    }else{
        message("Skip manually 'anomaly' target")
        return(connectPip_copernicus)
    }

}