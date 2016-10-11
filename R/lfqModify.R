#' @title Modify lfq data for further analysis
#'
#' @description Rearrange catch matrix in length frequency data (lfq class) to
#'    have one column per year. This is required for e.g. \code{\link{catchCurve}}.
#'    Add plus group to catch matrix.
#'
#' @param lfq lfq object with dates, midLengths, and catch
#' @param par growth parameter as resulting from e.g. \code{\link{ELEFAN}}
#' @param plus_group logical; should a plus group be created? If yes you will be
#'    asked to insert the length for the plus group in the console. (Default: FALSE)
#'
#' @keywords function lfq length-frequency
#'
#' @examples
#' data(synLFQ4)
#' newlfq <- lfqModify(synLFQ4, plus_group = TRUE)
#'
#' @return lfq object with rearranged catch matrix (yearly sums) and growth parameters
#'    if provided.
#'
#' @export
lfq= synLFQ4
lfqModify <- function(lfq, par = NULL, plus_group = FALSE){

  dates <- lfq$dates
  midLengths <- lfq$midLengths
  catch <- lfq$catch

  # sum numbers per year
  c_sum <- by(t(catch),format(dates,"%Y"), FUN = colSums)

  # rearrange in data frame
  c_list <- lapply(as.list(c_sum), c)
  c_dat <- as.data.frame(c_list)

  # get rid of 0 bins at both ends
  lowRow <- 1
  resi <- TRUE
  while(resi == TRUE){
    resi <- rowSums(c_dat)[lowRow] == 0
    lowRow <- lowRow + 1
  }

  upRow <- nrow(c_dat)
  resi <- TRUE
  while(resi == TRUE){
    resi <- rowSums(c_dat)[upRow] == 0
    upRow <- upRow - 1
  }
  upRow <- upRow + 1

  catch <- c_dat[lowRow:upRow,]
  midLengths <- midLengths[lowRow:upRow]

  # plus group
  if(plus_group){
    print(data.frame(midLengths = midLengths, frequency = rowSums(catch)))
    writeLines("Check the table above and insert the length of the plus group.")
    pg = -1
    while(pg > max(midLengths) | pg < min(midLengths)){
      pg <- readline(paste0("Enter a length group between ", min(midLengths)," and ",
                            max(midLengths),":"))
      if(!(pg %in% midLengths)){
        writeLines(paste0(pg, " is not an element of midLengths (see table)."))
        pg = -1
      }
      #pg <- ifelse(grepl("\\D",pg),-1,as.integer(pg))
      if(is.na(pg)){break}  # breaks when hit enter
    }
    midLengths <- midLengths[1:which(midLengths == pg)]
    addplus <- colSums(catch[(which(midLengths == pg):nrow(catch)),])
    catch <- catch[1:which(midLengths == pg),]
    catch[which(midLengths == pg),] <-
      catch[which(midLengths == pg),] + addplus
  }

  # combine results
  if(ncol(catch) == 1){
    catches <- as.vector(catch)
  }else catches <- as.matrix(catch)
  res <- list(dates = dates,
              midLengths = midLengths,
              catch = catches)

  # add growth parameter if knowm
  if(!is.null(par)){
    res$Linf <- par$Linf
    res$K <- par$K
    res$t_anchor <- par$t_anchor
  }

  return(res)
}
