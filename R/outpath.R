#' outpath
#'
#' @description Allow to create folder structure given
#'
#'
#' @param output Character. The absolute path must be constructed. This path should begin with "/home" (for Linux and macOS) or "[A-Z]:/" for Windows OS.
#'
#' @return NULL
#'
#' @export Create folder structure
#' 
#' 

outpath <- function(output) {

    path <- strsplit(output, "/")

    #For linux and MacOS: if path begining by "/"
    if(path[[1]][1] == ""){
    
        for(i in 2:as.numeric(length(path[[1]])-1)){
            path2 <- path
            path_deb <- paste0("/", path[[1]][2]) 
            path2[[1]][2] <- path_deb
            path2 <- path2[[1]][-1]
            path_r <- paste0(paste0(path2[1:i], collapse = "/"))
            if(dir.exists(path_r) == FALSE){
            dir.create(path_r, showWarnings = FALSE)
            }
        }

    }

    # For windows
    if (grepl("[A-Z]:", path[[1]][1]) == TRUE) {

        for(i in 2:length(path[[1]])){
            path_r <- paste0(paste0(path[[1]][1:i], collapse = "/"))
            if(dir.exists(path_r) == FALSE){
            dir.create(path_r, showWarnings = FALSE)
            }
        }

    }

}
