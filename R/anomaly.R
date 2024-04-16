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
                    if(TRUE %in% c(dim(v) != dim(clim))) stop(paste0(  "Variable and climatology dimension are different", "\n",
                                                                        "--> variable : ", list_file_full[i], "\n",
                                                                        "--> climatology : ", clim_list, "\n"))

                    # Anomaly calculation anomaly 
                    message("Anomaly calculation processing...")
                    anomaly <- v - clim
                    names(anomaly) <- names(v)
                    message("Anomaly calculation processing ---> DONE")

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