
##' dispersion spectrum
##'
##' dispersion spectrum
##' @title dispersion_spectrum
##' @param cluster list describing a cluster
##' @param angles of incident field in radians
##' @param axis of incident field rotation character vector from ('x', 'y', 'z')
##' @param material list
##' @param medium medium refractive index
##' @param polarisation linear or circular polarisation
##' @param progress logical, display progress bar
##' @return data.frame
##' @export
##' @family user_level cda
##' @author baptiste Auguie
dispersion_spectrum <- function (cluster, material, medium = 1.33,
                                 angles, axis='z', 
                                 polarisation=c("linear", "circular"), 
                                 progress = FALSE) 
{
  k0 <- 2 * pi/material[['wavelength']]
  kn <- k0 * medium
  polarisation <- match.arg(polarisation)
  
  polarisation <- if(polarisation == "linear") 0L else if(polarisation == "circular") 1L 
  
  Beta <- inverse_polarizability(cluster, material, 
                                 polarizability_fun = polarizability_ellipsoid, 
                                 medium = medium, kuwata = TRUE)
  Nwavelengths <- length(k0)
  Nparticles <- nrow(cluster$r)
  Nangles <- length(angles)
  
  if(length(axis) == 1) axis <- rep(axis, length.out=Nangles)
  axeso <- axis # original codes
  axis <- as.integer(factor(axis, levels=c('x','y','z')))-1L
  stopifnot(all(axis %in% c(0L, 1L, 2L)), !any(is.na(axis)))

  stopifnot(Nangles == length(axis))
  stopifnot(is.matrix(Beta), is.vector(angles), 
            is.matrix(cluster$r), 
            is.matrix(cluster$angles))
  
  stopifnot(nrow(Beta)/3 == Nparticles, 
            ncol(Beta) == Nwavelengths)
  
  res <- dispersion$dispersion_spectrum(kn, Beta, cluster$r, 
                                        cluster$angles, angles, axis, 
                                        polarisation, progress)
  
  angles <- angles[rep(seq.int(Nangles), Nwavelengths)]
  axis <- axeso[rep(seq.int(Nangles), Nwavelengths)]
  wavelength <- rep(material$wavelength, each = Nangles)
  
  results <- 
    rbind(data.frame(wavelength = wavelength, angles = angles,
                     axis=axis,
                     value = c(res[, 1, , drop = TRUE]),
                     type = "extinction", polarisation = "1"),
          data.frame(wavelength = wavelength, angles = angles,
                     axis=axis,
                     value = c(res[, 2, , drop = TRUE]),
                     type = "absorption", polarisation = "1"),
          data.frame(wavelength = wavelength, angles = angles,
                     axis=axis,
                     value = c(res[, 3, , drop = TRUE]),
                     type = "scattering", polarisation = "1"),
          data.frame(wavelength = wavelength, angles = angles,
                     axis=axis,
                     value = c(res[, 4, , drop = TRUE]),
                     type = "extinction", polarisation = "2"),
          data.frame(wavelength = wavelength, angles = angles,
                     axis=axis,
                     value = c(res[, 5, , drop = TRUE]),
                     type = "absorption", polarisation = "2"),
          data.frame(wavelength = wavelength, angles = angles,
                     axis=axis,
                     value = c(res[, 6, , drop = TRUE]),
                    type = "scattering", polarisation = "2"))
  
  if(polarisation == 0L)
    results$polarisation <- factor(results$polarisation, labels = c("p", "s"))
  
  if(polarisation == 1L){
    
    results$polarisation <- factor(results$polarisation, labels = c("R", "L"))
    results <- rbind(results,  data.frame(wavelength = wavelength, angles = angles, axis=axis,
                                          value = c(res[, 4, , drop = TRUE]  - res[, 1, , drop = TRUE]),
                                          type = "extinction", polarisation = "CD"))
  }
  
  invisible(results)
}
