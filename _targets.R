library(targets)
source("R/functions.R")

targets::tar_option_set(
  packages = c("geckor", "tidyverse", "tsibble", "slider", "modeltime"))

list(
  targets::tar_target(data, bitcoin_data()),
  targets::tar_target(splits, initial_split(data)),
  targets::tar_target(models, model_frame(splits)),
  targets::tar_target(calibration, model_calibration(splits, models)),
  targets::tar_target(forecast_plot, visualize_forecast(calibration, splits, data))
)
