library(targets)
source("R/functions.R")
options(warning = FALSE)

targets::tar_option_set(
  packages = c("geckor", "tidyverse", "tsibble", "slider", "modeltime"))

list(
  targets::tar_target(data, bitcoin_data()),
  targets::tar_target(features, feature_enrichment(data)),
  targets::tar_target(return_histogram, viz_return_dist(features)),
  targets::tar_target(historic_prices, viz_historic_series(features)),
  targets::tar_target(cummulative_return, cummulative_return(features)),
  targets::tar_target(splits, initial_split(features)),
  targets::tar_target(models, model_frame(splits)),
  targets::tar_target(calibration, model_calibration(splits, models)),
  targets::tar_target(forecast_plot, visualize_forecast(calibration, splits, features))
)
