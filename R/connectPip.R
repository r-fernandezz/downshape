#' connectPip
#'
#' @description All steps to integrate variables into modeloTrack pipeline
#'
#'
#' @param speedCompo_copernicus Target. All copernicus data processed.
#' @param speedCompo_cmip Target. All cmip6 data processed.
#'
#' @return NULL
#'
#' @export File (.grd)
#' 

connectPip <- function(speedCompo_copernicus, speedCompo_cmip){
    
    list_path <- list(  copernicus = here::here("output", "data_copernicus_remapped"),
                        cmip6 = here::here("output", "data_copernicus_remapped"))

    grd <- unlist(lapply(list_path, function(x){

        files <- list.files(x, recursive = TRUE, full.names = TRUE, pattern = ".nc$")

            if(length(files) > 0){ #if copernicus or cmip folder empty

                unlist(lapply(files, function(y){

                    nc <- terra::rast(y)

                    # Rename output files (with "__VARS" at final name file)
                    name <- sapply(strsplit(basename(y), "_"), "[[", 1)
                    newname <- paste0("__", name)
                    finalname <- gsub(paste0(name, "_"), "", y)
                    finalname <- gsub(".nc", paste0(newname, ".nc"), finalname)

                    # Remove hours intos name layer (date)
                    date <- as.Date(terra::time(nc), "%y.%m.%d")
                    date <- gsub("-", ".", date)
                    names(nc) <- date

                    # Export file
                    pathout <- paste0(dirname(finalname), "/GRD")
                    if(!file.exists(pathout)) dir.create(pathout)
                    terra::writeRaster(nc, 
                                        filename = paste0(pathout, "/", gsub(".nc", ".grd", basename(finalname))), 
                                        overwrite = TRUE)

                }))

            }
    }))

    return(grd)

}