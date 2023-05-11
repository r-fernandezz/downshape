#' connectPip
#'
#' @description All steps to integrate variables into modeloTrack pipeline. Convertion of NetCDF file to GRD and rename variable files.
#'
#'
#' @param date speedCompo_copernicus or speedCompo_cmip. Allow connection between targets
#' @param type_data Character. Type of data you want process, "cmip6" or "copernicus".

#' @return NULL
#'
#' @export File (.grd)
#' 

connectPip <- function(data, type_data){

    list_path <- switch(type_data,
                        copernicus = here::here("output", "data_copernicus_remapped"),
                        cmip6 = here::here("output", "data_cmip6_remapped"))

    grd <- unlist(lapply(list_path, function(x){

        message(paste0("Processing : ", x))

        files <- list.files(x, recursive = TRUE, full.names = TRUE, pattern = ".nc$")

            if(length(files) > 0){

                unlist(lapply(files, function(y){

                    message(paste0("Traitement of variable : ", basename(y)))

                    nc <- raster::brick(y)

                    # Rename output files (with "__VARS" at final name file)
                    name <- sapply(strsplit(basename(y), "_"), "[[", 1)
                    newname <- paste0("__", name)
                    finalname <- gsub(paste0(name, "_"), "", y)
                    finalname <- gsub(".nc", paste0(newname, ".nc"), finalname)

                    # Export file
                    pathout <- paste0(dirname(finalname), "/GRD")
                    if(!file.exists(pathout)) dir.create(pathout)
                    raster::writeRaster(nc, 
                                        filename = paste0(pathout, "/", gsub(".nc", ".grd", basename(finalname))), 
                                        overwrite = TRUE)

                    return(paste0(pathout, "/", gsub(".nc", ".grd", basename(finalname))))

                }))

            }else(stop("data_copernicus_remapped or data_cmip6_remapped folder empty"))
    }))

    return(grd)

}