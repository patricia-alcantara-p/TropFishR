#' @title Restructuring of length frequency data
#'
#' @description First step of the Electronic LEngth Frequency ANalysis (ELEFAN),
#' which is restructuring length-frequency data (lfq).
#' This is done according to a certain protocol, described by many authors (see
#' Details or References for more information).
#'
#' @param param a list consisting of following parameters:
#' \itemize{
#'   \item \strong{midLengths} midpoints of the length classes
#'   \item \strong{dates} dates of sampling times (class Date)
#'   \item \strong{catch} matrix with catches/counts per length class (row) and
#'   sampling date (column)
#' }
#' @param MA number indicating over how many length classes the moving average
#' should be performed (default: 5)
#' @param addl.sqrt additional squareroot transformation of positive values
#' according to Brey et al. (1988) (default: FALSE).
#' Particularly useful if many observations have a low frequency (<10)
#'
#' @examples
#' # data and plot of catch frequencies
#' data(synLFQ4)
#' plot(synLFQ4, Fname="catch")
#'
#' # restructuring and calculation of ASP
#' synLFQ4 <- lfqRestructure(synLFQ4, MA=11)
#' synLFQ4$ASP
#'
#' # plot of restructured scores and fit of soVBGF growth curves
#' plot(synLFQ4)
#' lfqFitCurves(synLFQ4,
#'  par=list(Linf=80, K=0.5, t_anchor=0.25, C=0.75, ts=0),
#'  draw=TRUE
#' )$fASP
#'
#'
#' @details This function is used prior to fitting of growth curves (e.g. in
#' \code{\link{ELEFAN}}, \code{\link{ELEFAN_SA}} functions). It restructures a length
#' frequency data set according to a list of steps to emphasise cohorts in the data.
#' The steps can be found in various publications, see e.g. Brey et al. (1988) or
#'  Pauly and David (1981). Here, the most recent steps documented in Gayanilo (1997)
#'  are followed.
#'
#' @return A list with the input parameters and following list objects:
#' \itemize{
#'   \item \strong{rcounts}: restructured frequencies,
#'   \item \strong{peaks_mat}: matrix with uniquely numbered positive peaks,
#'   \item \strong{ASP}: available sum of peaks, sum of posititve peaks which
#'   could be potential be hit by growth curves. This is calculated as the sum of
#'   maximum values from each run of posive restructured scores,
#'   \item \strong{MA}: moving average used for restructuring.
#' }
#'
#'
#' @references
#' Brey, T., Soriano, M., and Pauly, D. 1988. Electronic length frequency analysis:
#' a revised and expanded user's guide to ELEFAN 0, 1 and 2.
#'
#' Gayanilo, Felimon C. FAO-ICLARM stock assessment tools: reference manual.
#' No. 8. Food & Agriculture Org., 1997.
#'
#' Pauly, D. 1981. The relationship between gill surface area and growth performance in fish:
#' a generalization of von Bertalanffy's theory of growth. \emph{Meeresforsch}. 28:205-211
#'
#' Pauly, D. and N. David, 1981. ELEFAN I, a BASIC program for the objective extraction of
#' growth parameters from length-frequency data. \emph{Meeresforschung}, 28(4):205-211
#'
#' Pauly, D., 1985. On improving operation and use of ELEFAN programs. Part I: Avoiding
#' "drift" of K towards low values. \emph{ICLARM Conf. Proc.}, 13-14
#'
#' Pauly, D., 1987. A review of the ELEFAN system for analysis of length-frequency data in
#' fish and aquatic invertebrates. \emph{ICLARM Conf. Proc.}, (13):7-34
#'
#' Pauly, D. and G. R. Morgan (Eds.), 1987. Length-based methods in fisheries research.
#' (No. 13). WorldFish
#'
#' Pauly, D. and G. Gaschuetz. 1979. A simple method for fitting oscillating length
#' growth data, with a program for pocket calculators. I.C.E.S. CM 1979/6:24.
#' Demersal Fish Cttee, 26 p.
#'
#' Pauly, D. 1984. Fish population dynamics in tropical waters: a manual for use
#' with programmable calculators (Vol. 8). WorldFish.
#'
#' Quenouille, M. H., 1956. Notes on bias in estimation. \emph{Biometrika}, 43:353-360
#'
#' Somers, I. F., 1988. On a seasonally oscillating growth function.
#' ICLARM Fishbyte 6(1): 8-11.
#'
#' Sparre, P., Venema, S.C., 1998. Introduction to tropical fish stock assessment.
#' Part 1. Manual. \emph{FAO Fisheries Technical Paper}, (306.1, Rev. 2): 407 p.
#'
#' Tukey, J., 1958. Bias and confidence in not quite large samples.
#' \emph{Annals of Mathematical Statistics}, 29: 614
#'
#' Tukey, J., 1986. The future of processes of data analysis. In L. V. Jones (Eds.),
#' The Collected Works of John W. Tukey-philosophy and principles of data analysis:
#' 1965-1986 (Vol. 4, pp. 517-549). Monterey, CA, USA: Wadsworth & Brooks/Cole
#'
#' @export

lfqRestructure <- function(param, MA=5, addl.sqrt=FALSE){

  lfq <- param
  if(MA%%2 == 0) stop("MA must be an odd integer")

  # Steps refer to Gayanilo (1997) FAO-ICLARM stock assessment tools: reference manual
  rcounts <- NaN*lfq$catch
  for(i in seq(ncol(lfq$catch))){
    pm <- (MA-1)/2 # plus minus
    n <- length(lfq$catch[,i])
    AF <- NaN*seq(lfq$catch[,i])
    nz <- NaN*seq(lfq$catch[,i])

    # Step A & B
    for(j in seq(lfq$catch[,i])){
      idx <- (j-pm):(j+pm)
      idx <- idx[which(idx %in% seq(lfq$catch[,i]))]
      idxn <- idx[-which(idx==j)] # neighbors only
      nz[j] <- sum(lfq$catch[idxn,i] == 0) + (MA-length(idx)) # number of adjacent zeros
      MA.j <- sum(lfq$catch[idx,i])/MA
      # print(MA)
      AF[j] <- lfq$catch[j,i]/MA.j
    }
    # intermediate step to remove Inf an NA
    AF <- replace(AF, which(AF==Inf | is.na(AF)), 0)

    # Step C
    Fs <- AF/mean(AF, na.rm=TRUE)-1 # restructured frequencies

    # Steps D & E - Adjust for zero frequency
    posFs <- which(Fs > 0)
    if(length(posFs)>0) {Fs[posFs] <- (Fs * 1/2^nz)[posFs]}
    # replace ultimate length bin with zero if negative
    if(sign(Fs[length(Fs)]) == -1){Fs[length(Fs)] <- 0}
    # divide penultimate length bin by 2 if negative
    if(sign(Fs[length(Fs)-1]) == -1){Fs[length(Fs)-1] <- Fs[length(Fs)-1]/2}

    # Step F - Adjust for Fi
    SPV <- sum(Fs[which(Fs > 0)])
    SNV <- sum(Fs[which(Fs < 0)])
    # set -1 to 0
    minus1 <- which((1+Fs) < 1e-8 | is.na(Fs))
    if(length(minus1)>0) {Fs[minus1] <- 0}
    # adjust negative numbers
    isneg <- which(Fs < 0)
    Fs[isneg] <- Fs[isneg] * (SPV/-SNV)

    # optional square-root adjustment to emphasize larger length bins with lower counts
    if(addl.sqrt){
      posFs <- which(Fs > 0)
      if(length(posFs)>0) {Fs[posFs] <- Fs[posFs] / sqrt(1+2/lfq$catch[posFs,i])} #Fs[posFs] / sqrt(1+2/Fs[posFs])}
    }

    rcounts[,i] <- Fs
  }
  lfq$rcounts <- rcounts

  # create peak matrix
  prep_mat <- lfq$rcounts
  prep_mat <- ifelse(prep_mat > 0,1,0)
  peaks_mat <- NA*prep_mat
  for(i in seq(ncol(peaks_mat))){
    vec_peaki <- prep_mat[,i]
    runs <- rle(vec_peaki)
    rle_val <- runs$values
    rle_val[which(rle_val == 1)] <- 1:length(rle_val[which(rle_val == 1)])
    peaks_mat[,i] <- rep(rle_val, runs$lengths)
  }
  maxn.peaks <- max(peaks_mat, na.rm=TRUE)
  peaks_mat <- peaks_mat + (prep_mat * maxn.peaks * col(peaks_mat))
  lfq$peaks_mat <- peaks_mat

  # ASP calc
  sampASP <- NaN*seq(ncol(rcounts))
  for(i in seq(ncol(rcounts))){
    # lfq.i <- lfq[i,]
    tmp <- rle(sign(rcounts[,i]))
    start.idx <- c(1, cumsum(tmp$lengths[-length(tmp$lengths)])+1)
    end.idx <- cumsum(tmp$lengths)
    posrun <- which(tmp$values == 1)
    peakval <- NaN*posrun
    for(p in seq(length(posrun))){
      peakval[p] <- max(rcounts[start.idx[posrun[p]]:end.idx[posrun[p]], i ])
    }
    sampASP[i] <- sum(peakval)
  }
  ASP <- sum(sampASP)
  lfq$ASP <- ASP
  lfq$MA <- MA

  class(lfq) <- "lfq"
  return(lfq)
}
