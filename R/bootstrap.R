#' Parametric-bootstrap test of the constrained scale gradient
#'
#' Tests H0: gamma = 0 against H1: gamma > 0. The null lies on the boundary of
#' the constrained parameter space, so the likelihood-ratio statistic does not
#' have an asymptotic chi-square distribution and a parametric bootstrap is
#' used instead. Data are simulated from the fitted null model, in which
#' between-study heterogeneity is constant in the design-robustness index.
#'
#' @param object A constrained drmeta fit.
#' @param B Number of bootstrap samples.
#' @param seed Optional random seed.
#' @param parallel Logical; use mclapply on non-Windows platforms.
#' @param ncpus Number of cores when parallel is TRUE.
#' @return An object of class drmeta_bootstrap_gamma, a list with components
#'   \code{statistic} (observed likelihood-ratio statistic), \code{p.value},
#'   \code{B} (requested replicates), \code{B_used} (replicates in which both
#'   refits converged), \code{n_failed} (replicates discarded),
#'   \code{simulated} (the simulated statistics, with NA for failed
#'   replicates), \code{null} (the fitted null model), and \code{alternative}
#'   (the supplied fit).
#' @details Replicates in which either refit fails to converge are discarded
#'   rather than contributing a statistic computed at a non-optimal point. The
#'   p-value uses the number of usable replicates as its denominator, and the
#'   discarded count is returned so the loss is visible.
#'
#'   When \code{parallel = TRUE}, reproducibility across cores requires the
#'   L'Ecuyer-CMRG generator, which this function sets and restores when a
#'   seed is supplied.
#' @examples
#' path <- system.file("extdata", "bcg_design_robustness.csv", package = "drmeta")
#' bcg <- utils::read.csv(path)
#' fit <- drmeta(yi = bcg[["yi"]], vi = bcg[["vi"]], dr = bcg[["dr"]])
#' drmeta_bootstrap_gamma(fit, B = 100, seed = 1)
#' @export
drmeta_bootstrap_gamma <- function(object, B = 999, seed = NULL,
                                   parallel = FALSE, ncpus = 2L) {
  if (!inherits(object, "drmeta")) stop("object must be a drmeta fit.")
  if (!object$constrained) stop("Use a constrained fit for this test.")
  B <- as.integer(B)
  if (!is.finite(B) || B < 1L) stop("B must be a positive integer.")
  
  use_parallel <- isTRUE(parallel) && .Platform$OS.type != "windows"
  if (!is.null(seed)) {
    if (use_parallel) {
      old_kind <- RNGkind()[1]
      RNGkind("L'Ecuyer-CMRG")
      on.exit(RNGkind(old_kind), add = TRUE)
    }
    set.seed(seed)
  }
  
  null <- drmeta(object$yi, object$vi, object$dr,
                 mods = if (object$p > 1) object$X[, -1, drop = FALSE] else NULL,
                 method = object$method, constrained = TRUE, gamma_fixed = 0,
                 gamma_max = object$gamma_max, .quiet = TRUE)
  lr_obs <- max(0, 2 * (object$logLik - null$logLik))
  mu0 <- as.vector(null$X %*% null$beta)
  sd0 <- sqrt(null$vi + null$tau0sq)
  mods0 <- if (null$p > 1) null$X[, -1, drop = FALSE] else NULL
  
  one <- function(b) {
    yb <- stats::rnorm(null$k, mu0, sd0)
    res <- tryCatch({
      f0 <- drmeta(yb, null$vi, null$dr, mods = mods0,
                   method = null$method, constrained = TRUE, gamma_fixed = 0,
                   gamma_max = null$gamma_max, .quiet = TRUE)
      f1 <- drmeta(yb, null$vi, null$dr, mods = mods0,
                   method = null$method, constrained = TRUE,
                   gamma_max = null$gamma_max, .quiet = TRUE)
      # A statistic evaluated at a non-optimal point is not a draw from the
      # null distribution, so failed replicates are discarded rather than kept.
      if (!identical(f0$convergence, 0L) && f0$convergence != 0) return(NA_real_)
      if (!identical(f1$convergence, 0L) && f1$convergence != 0) return(NA_real_)
      max(0, 2 * (f1$logLik - f0$logLik))
    }, error = function(e) NA_real_)
    as.numeric(res)
  }
  
  if (use_parallel) {
    lr_sim <- as.numeric(unlist(parallel::mclapply(seq_len(B), one,
                                                   mc.cores = ncpus)))
  } else {
    lr_sim <- vapply(seq_len(B), one, numeric(1))
  }
  
  ok <- is.finite(lr_sim)
  B_used <- sum(ok)
  n_failed <- B - B_used
  if (B_used == 0L)
    stop("No bootstrap replicate converged; the null model may be misspecified.")
  if (n_failed > 0L)
    warning(sprintf("%d of %d bootstrap replicates failed to converge and were discarded.",
                    n_failed, B))
  
  structure(list(statistic = lr_obs,
                 p.value = (1 + sum(lr_sim[ok] >= lr_obs)) / (B_used + 1),
                 B = B, B_used = B_used, n_failed = n_failed,
                 simulated = lr_sim, null = null, alternative = object),
            class = "drmeta_bootstrap_gamma")
}

#' Print a parametric-bootstrap scale-gradient test
#'
#' @param x An object of class drmeta_bootstrap_gamma.
#' @param digits Number of significant digits.
#' @param ... Ignored.
#' @return Invisibly returns \code{x}. Called for its printed output.
#' @export
print.drmeta_bootstrap_gamma <- function(x, digits = max(3L, getOption("digits") - 3L), ...) {
  cat("Parametric-bootstrap test of the scale gradient\n\n")
  cat("H0: gamma = 0   vs   H1: gamma > 0   (boundary null)\n\n")
  cat("LR statistic:", format(x$statistic, digits = digits),
      "  p =", format(x$p.value, digits = digits), "\n")
  cat("Replicates:", x$B_used, "used of", x$B, "requested")
  if (x$n_failed > 0L) cat(" (", x$n_failed, " discarded)", sep = "")
  cat("\n\n")
  cat("gamma under H0:", format(x$null$gamma, digits = digits),
      "  gamma under H1:", format(x$alternative$gamma, digits = digits), "\n")
  cat("tau0^2 under H0:", format(x$null$tau0sq, digits = digits),
      "  tau0^2 under H1:", format(x$alternative$tau0sq, digits = digits), "\n")
  invisible(x)
}