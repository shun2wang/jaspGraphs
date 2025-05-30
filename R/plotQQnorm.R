#' @title Make a Q-Q plot

#' @param residuals Numeric vector, the residuals of the analysis.
#'
#' @param lower Numeric vector, lower confidence interval of each residual. If NULL, no error bars are drawn.
#' @param upper Numeric vector, lower confidence interval of each residual. If NULL, no error bars are drawn.
#' @param abline Logical, should an abline be drawn that best fits the points?
#' @param ablineOrigin  Logical, should an abline be drawn through the origin?
#' @param ablineColor String, color of the abline.
#' @param identicalAxes Logical, should the axes have the same range?
#' @param na.rm Logical, should NA's be removed from residuals?
#' @param xName String, name for the x-axis.
#' @param yName String, name for the y-axis.
#'
#' @details This function is equivalent to \code{qqnorm(residuals); qqline(residuals)}, but uses \code{ggplot2} and allows for confidence bands.
#'
#' @examples
#' x <- rnorm(100)
#' jaspGraphs::plotQQnorm(x)
#' # add a confidence interval for each point
#' lower <- x - .1
#' upper <- x + .1
#' jaspGraphs::plotQQnorm(x, lower, upper)
#'
#' @export
plotQQnorm <- function(residuals, lower = NULL, upper = NULL, abline = TRUE, ablineOrigin = FALSE, ablineColor = "red", identicalAxes = FALSE, na.rm = TRUE,
                       xName = gettext("Theoretical quantiles",domain="R-jaspGraphs"), yName = gettext("Observed quantiles",domain="R-jaspGraphs")) {

  n <- length(residuals)
  hasErrorbars <- !is.null(lower) && !is.null(upper)

  df <- data.frame(
    y = residuals,
    x = stats::qnorm(stats::ppoints(n))[order(order(residuals))]
  )
  if (hasErrorbars) {
    df$ymin <- lower
    df$ymax <- upper
  }

  if (isTRUE(na.rm)) {
    df <- df[!(is.na(residuals)), ]
  }

  # determine axes breaks
  if (identicalAxes) {
    xBreaks <- yBreaks <- getPrettyAxisBreaks(unlist(df))
  } else {
    xBreaks <- getPrettyAxisBreaks(df$x)
    yBreaks <- getPrettyAxisBreaks(c(df$y, df$ymin, df$ymax))
  }


  # from stats::qqline
  xvals <- stats::quantile(df$y, c(0.25, 0.75), names = FALSE)
  yvals <- stats::qnorm(c(0.25, 0.75))
  slope <- diff(xvals) / diff(yvals)
  int <- xvals[1L] - slope * yvals[1L]

  # initial guess for line range
  xvals <- range(xBreaks)
  yvals <- int + slope * xvals

  # TODO: if any y-values exceed the axes boundaries, recalculate line segment
  # if (yvals[1L] < yBreaks[1]) {
  # }
  # if (yvals[2L] > yBreaks[2L]) {
  # }

  # construct plot
  aes <- ggplot2::aes
  dfLine <- data.frame(x = xvals, y = yvals)
  g <- ggplot2::ggplot(data = df, aes(x = .data$x, y = .data$y))

  if (abline && ablineOrigin) {
    g <- g + ggplot2::geom_line(data = data.frame(x = c(min(xvals), max(xvals)), y = c(min(xvals), max(xvals))),
                                  mapping = ggplot2::aes(x = .data$x, y = .data$y),
                                  col = ablineColor,
                                  size = 1)
  } else if (abline) {
    g <- g + ggplot2::geom_line(mapping = aes(x = .data$x, y = .data$y), data = dfLine, inherit.aes = FALSE, color = ablineColor)
  }

  if (hasErrorbars)
    g <- g + ggplot2::geom_errorbar(aes(ymin = .data$ymin, ymax = .data$ymax))

  g <- g +
    geom_point() +
    scale_x_continuous(name = xName, breaks = xBreaks) +
    scale_y_continuous(name = yName, breaks = yBreaks)

  return(jaspGraphs::themeJasp(g))

}
