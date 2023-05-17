#' @title Gaussian smoothing of raster (spatialEco Package version < 2.0-0 using raster)
#' @description Applies a Gaussian smoothing kernel to smooth raster. 
#' 
#' @param x         raster object
#' @param type      The statistic to use in the smoothing operator 
#'                  (suggest mean or sd)
#' @param sigma     standard deviation (sigma) of kernel (default is 2)
#' @param n         Size of the focal matrix, single value (default is 
#'                  5 for 5x5 window) 
#' @param ...       Additional arguments passed to raster::focal 
#' 
#' @return raster class object of the local distributional moment
#'
#' @note
#'  This is a simple wrapper for the focal function, returning local 
#'  statistical moments 
#'
#' @author Jeffrey S. Evans  <jeffrey_evans@@tnc.org>
#'
#' @examples 
#'    library(raster)
#'    r <- raster(nrows=500, ncols=500, xmn=571823, xmx=616763, 
#'                ymn=4423540, ymx=4453690)
#'     crs(r) <- crs("+proj=utm +zone=12 +datum=NAD83 +units=m +no_defs")
#'    r[] <- runif(ncell(r), 1000, 2500)
#'    r <- focal(r, focalWeight(r, 150, "Gauss") )
#'  
#'  # Calculate Gaussian smoothing with sigma(s) = 1-4
#'  g1 <- raster.gaussian.smooth(r, sigma=1, nc=11)
#'  g2 <- raster.gaussian.smooth(r, sigma=2, nc=11)
#'  g3 <- raster.gaussian.smooth(r, sigma=3, nc=11)
#'  g4 <- raster.gaussian.smooth(r, sigma=4, nc=11)
#' 
#' opar <- par(no.readonly=TRUE)
#' par(mfrow=c(2,2)) 
#'   plot(g1, main="Gaussian smoothing sigma = 1") 
#'   plot(g2, main="Gaussian smoothing sigma = 2")
#'   plot(g3, main="Gaussian smoothing sigma = 3")
#'   plot(g4, main="Gaussian smoothing sigma = 4")
#' par(opar)
#'
#' @export

raster.gaussian.smooth <- function(x, sigma = 2, n = 5, type = mean, ...) {  
  if (!inherits(x, "RasterLayer")) stop("MUST BE RasterLayer OBJECT")
    gm <- gaussian.kernel(sigma=sigma, n=n)
	return( raster::focal(x, w = gm, fun = type, na.rm=TRUE, pad=FALSE, ...) )
}  


#' @title Gaussian Kernel (spatialEco Package version < 2.0-0 using raster)
#' @description Creates a Gaussian Kernel of specified size and sigma
#'
#' @param sigma  sigma (standard deviation) of kernel (defaults 2)
#' @param n      size of symmetrical kernel (defaults to 5x5)
#'
#' @return Symmetrical (NxN) matrix of a Gaussian distribution
#'
#' @author Jeffrey S. Evans  <jeffrey_evans@@tnc.org>
#'  
#' @examples 
#'   par(mfrow=c(2,2))
#'   persp(gaussian.kernel(sigma=1, n=27), theta = 135, 
#'         phi = 30, col = "grey", ltheta = -120, shade = 0.6, 
#'         border=NA )
#'   persp(gaussian.kernel(sigma=2, n=27), theta = 135, phi = 30, 
#'         col = "grey", ltheta = -120, shade = 0.6, border=NA )		
#'   persp(gaussian.kernel(sigma=3, n=27), theta = 135, phi = 30, 
#'         col = "grey", ltheta = -120, shade = 0.6, border=NA )				
#'   persp(gaussian.kernel(sigma=4, n=27), theta = 135, phi = 30,
#'         col = "grey", ltheta = -120, shade = 0.6, border=NA )					
#'			
#' @export

gaussian.kernel <- function(sigma=2, n=5) {
   m <- matrix(ncol=n, nrow=n)
     mcol <- rep(1:n, n)
     mrow <- rep(1:n, each=n)
       x <- mcol - ceiling(n/2)
       y <- mrow - ceiling(n/2)
     m[cbind(mrow, mcol)] <- 1/(2*pi*sigma^2) * exp(-(x^2+y^2)/(2*sigma^2))
   m / sum(m)
}

#' mean_month (adapted from modeloTrack pipeline)
#'
#' @description Environmental variable will be meaned only with month chosen. 
#'
#' @param month Numeric vector. Number of month chosen.
#' @param path_variable List. Path list of variable they will be meaned.
#' @param type_output Character ("SpatRaster", "StackRaster" or "stars"). Function return object class "SpatRaster", "StackRaster" or "stars"
#' 
#' @return SpatRaster or stars object
#'
#' @export 

mean_month <- function(month, path_variable, type_output = "StackRaster"){

    # Initialisation loop
    names_vec <- c()
    vars_mean <- switch(
                        type_output,
                        stars = list(),
                        SpatRaster = c(),
                        StackRaster = raster::stack())
    

    for (i in 1:length(path_variable)){
        

            stack_vars <- switch(
                                type_output,
                                stars = stars::read_stars(path_variable[i]),
                                SpatRaster = terra::rast(path_variable[i]),
                                StackRaster = raster::stack(path_variable[i])
                                )

            if(switch(
                    type_output, 
                    stars = length(dim(stack_vars)) > 2, 
                    SpatRaster = dim(stack_vars)[3] > 1,
                    StackRaster = dim(stack_vars)[[3]] > 1)){ # dimension x, y and band into stars object

                date <- switch(
                            type_output, # extract layer names (date have "X" bellow name)
                            stars = stars::st_dimensions(stack_vars)[[3]]$values,
                            SpatRaster = names(stack_vars),
                            StackRaster = names(stack_vars)
                            )

                date <- lapply(date, function(x) strsplit(x, "X")[[1]][2]) # remove X bellow name
                date <- as.Date(sapply(date, "[[", 1), format = "%Y.%m.%d") # date format
                date <-  as.numeric(format(date, format = "%m")) # extract month
                position <- which(date %in% month) # extract layer position of month we want to mean
                
                stack_vars <- switch(
                                type_output,
                                stars = stars::st_apply(stack_vars[, , , position], MARGIN = 1:2, FUN = mean),
                                SpatRaster = terra::app(stack_vars[[position]], mean),
                                StackRaster = raster::mean(stack_vars[[position]])
                                )

            }else(message("Varible with one dimension"))

            # initialisation (i=1) and stock layer
            if(i==1){vars_mean <- stack_vars}else(switch(type_output,
                                                        stars = vars_mean <- c(vars_mean, stack_vars),
                                                        SpatRaster = vars_mean <- c(vars_mean, stack_vars),
                                                        StackRaster = vars_mean <- raster::stack(vars_mean, stack_vars)))

            # Extract name of processing variable into file
            name <- basename(path_variable)
            names_vec[i] <- strsplit(name, "_")[[1]][1]

    } 

    names(vars_mean) <- names_vec    

    return(vars_mean)

}
