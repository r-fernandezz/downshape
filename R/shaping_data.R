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

}

