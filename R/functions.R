
bitcoin_data <- function() {
  
  geckor::coin_history('bitcoin', days = 180) %>%
    dplyr::select(timestamp, price) %>%
    dplyr::filter(!is.na(timestamp))
  
}

initial_split <- function(data) {
  
  rsample::initial_time_split(data, prop = .9)
  
}

model_frame <- function(splits) {
  
  model_fit_prophet <- modeltime::prophet_reg() %>%
    parsnip::set_engine(engine = "prophet") %>%
    recipes::step_naomit(timestamp) %>%
    recipes::step_date(timestamp, feature = 'month', ordinal = FALSE) %>%
    parsnip::fit(price ~ timestamp, data = rsample::training(splits))
  
  modeltime::modeltime_table(model_fit_prophet)
  
}

model_calibration <- function(splits, models) {
  
  models %>%
    modeltime::modeltime_calibrate(
      new_data = rsample::testing(splits),
      quiet = FALSE)
  
}

visualize_forecast <- function(model_calibration, splits, data) {
  
  model_calibration %>%
    modeltime::modeltime_forecast(
      new_data = rsample::testing(splits),
      actual_data = data) %>%
    modeltime::plot_modeltime_forecast()
  
}


