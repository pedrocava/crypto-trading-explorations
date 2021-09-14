
bitcoin_data <- function() {
  
  geckor::coin_history('bitcoin', days = 180) %>%
    dplyr::select(timestamp, price) %>%
    dplyr::filter(!is.na(timestamp))
  
}

feature_enrichment <- function(data) {
  
  data %>%
    dplyr::arrange(timestamp) %>%
    dplyr::mutate(
      return = (price - dplyr::lag(price)) / price,
      return_mvavg = slider::slide_dbl(
        .x = return,
        .f = mean,
        .before = 7),
      price_vol = slider::slide_dbl(
        .x = price,
        .f = sd,
        .before = 7),
      price_mvavg = slider::slide_dbl(
        .x = price,
        .f = mean,
        .before = 7))
  
}

cummulative_return <- function(features) {
  
  features %>%
    dplyr::select(timestamp, return) %>%
    tidyr::drop_na() %>%
    dplyr::mutate(cumreturn = purrr::accumulate(1 + return, `*`))
  
}



viz_return_dist <- function(features) {
  
  features %>%
    ggplot2::ggplot(ggplot2::aes(x = return)) + 
    ggplot2::geom_histogram(binwidth = .01, fill = 'light blue') +
    ggplot2::theme_minimal() + 
    ggplot2::labs(
      x = "Returns",
      y = "Count",
      title = "Histograma dos Retornos de BTC nos últimos 180 dias")
    
}

viz_historic_series <- function(features) {
  
  features %>%
    dplyr::select(timestamp, price_mvavg, price) %>%
    tidyr::pivot_longer(
      cols = c(price_mvavg, price),
      names_to = "series",
      values_to = "value") %>%
    ggplot2::ggplot(ggplot2::aes(x = timestamp, y = value, group = series)) +
    ggplot2::geom_line(size = 1.2, color = 'red') + 
    ggplot2::theme_minimal() + 
    ggplot2::labs(
      title = "Preços e média móvel semanal",
      x = "Tempo",
      y = "Valores",
      legend = "Séries")
  
}


initial_split <- function(data) {
  
  rsample::initial_time_split(data, prop = .9)
  
}

model_frame <- function(splits) {
  
  model_fit_prophet <- modeltime::prophet_reg() %>%
    parsnip::set_engine(engine = "prophet") %>%
    recipes::step_naomit(c(timestamp, return, price)) %>%
    recipes::step_date(
      timestamp,
      feature = 'month',
      ordinal = FALSE) %>%
    parsnip::fit(
      return ~ timestamp + log(price) + price_vol,
      data = rsample::training(splits))
  
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


