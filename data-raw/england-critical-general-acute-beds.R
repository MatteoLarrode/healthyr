# ---- Load libs ----
library(tidyverse)
library(readxl)
library(devtools)
library(httr2)
library(lubridate)

# ---- Load internal sysdata.rda file with URL's ----
load_all(".")

# ---- Function to download and clean ----
scrape_data <- function(id, sheet, range, date) {
  # Download
  query_url <-
    query_urls |>
    filter(id == {{ id }}) |>
    pull(query)

  download <- tempfile(fileext = ".xlsx")

  request(query_url) |>
    req_perform(download)

  # Read
  raw_trusts <-
    read_excel(
      download,
      sheet = sheet,
      range = range
    )

  data <-
    raw_trusts |>
    select(
      nhs_trust22_code = "Code",
      general_acute_beds_available = "G&A beds available",
      general_acute_beds_occupied = "G&A beds occupied",
      general_acute_beds_occupancy_rate = "G&A occupancy rate",
      adult_general_acute_beds_available = "Adult G&A beds available",
      adult_general_acute_beds_occupied = "Adult G&A beds occupied",
      adult_general_acute_beds_occupancy_rate = "Adult G&A occupancy rate",
      paediatric_general_acute_beds_available = "Paediatric G&A beds available",
      paediatric_general_acute_beds_occupied = "Paediatric G&A beds occupied",
      paediatric_general_acute_beds_occupancy_rate = "Paediatric G&A occupancy rate",
      adult_critical_care_beds_available = "Adult critical care beds available",
      adult_critical_care_beds_occupied = "Adult critical care beds occupied",
      adult_critical_care_occupancy_rate = "Adult critical care occupancy rate",
      paediatric_intensive_cared_beds_available = "Paediatric intensive care beds available",
      paediatric_intensive_cared_beds_occupied = "Paediatric intensive care beds occupied",
      paediatric_intensive_cared_occupancy_rate = "Paediatric intensive care occupancy rate",
      neonatal_intensive_care_bed_avaialble = "Neonatal intensive care beds available",
      neonatal_intensive_care_bed_occupied = "Neonatal intensive care beds occupied",
      neonatal_intensive_care_occupancy_rate = "Neonatal intensive care occupancy rate"
    ) |>
    mutate(date = date) |>
    relocate(date, .after = nhs_trust22_code)

  return(data)
}

# ---- Iterate over all data sets and return as a dataframe ----
# Generate a dataframe with function arguments
# April 2023 does not have the "Code" column name
df <-
  tibble(
    id = query_urls |>
      filter(str_detect(id, "^nhs_critical_general_acute_beds")) |>
      filter(date != "April 2023") |>
      pull(id),
    sheet = rep(2, 15),
    range = c(rep("D26:V163", 7), rep("D26:AB163", 8)),
    date = c(
      "April 2022",
      "May 2022",
      "June 2022",
      "July 2022",
      "August 2022",
      "September 2022",
      "October 2022",
      "November 2022",
      "December 2022",
      "January 2023",
      "February 2023",
      "March 2023",
      "May 2023",
      "June 2023",
      "July 2023"
    )
  )

# Build dataframe with all months except April 2023
england_critical_general_acute_beds_incomplete <- pmap_dfr(df, scrape_data)

# ---- Handle the April 2023 exception ----
query_url_april23 <-
  query_urls |>
  filter(id == "nhs_critical_general_acute_beds_april_23") |>
  pull(query)

download <- tempfile(fileext = ".xlsx")

request(query_url_april23) |>
  req_perform(download)

raw_april23 <-
  read_excel(
    download,
    sheet = 2,
    range = "D26:AB163"
  )

data_april23 <-
  raw_april23 |>
  select(
    nhs_trust22_code = "...1",
    general_acute_beds_available = "G&A beds available",
    general_acute_beds_occupied = "G&A beds occupied",
    general_acute_beds_occupancy_rate = "G&A occupancy rate",
    adult_general_acute_beds_available = "Adult G&A beds available",
    adult_general_acute_beds_occupied = "Adult G&A beds occupied",
    adult_general_acute_beds_occupancy_rate = "Adult G&A occupancy rate",
    paediatric_general_acute_beds_available = "Paediatric G&A beds available",
    paediatric_general_acute_beds_occupied = "Paediatric G&A beds occupied",
    paediatric_general_acute_beds_occupancy_rate = "Paediatric G&A occupancy rate",
    adult_critical_care_beds_available = "Adult critical care beds available",
    adult_critical_care_beds_occupied = "Adult critical care beds occupied",
    adult_critical_care_occupancy_rate = "Adult critical care occupancy rate",
    paediatric_intensive_cared_beds_available = "Paediatric intensive care beds available",
    paediatric_intensive_cared_beds_occupied = "Paediatric intensive care beds occupied",
    paediatric_intensive_cared_occupancy_rate = "Paediatric intensive care occupancy rate",
    neonatal_intensive_care_bed_avaialble = "Neonatal intensive care beds available",
    neonatal_intensive_care_bed_occupied = "Neonatal intensive care beds occupied",
    neonatal_intensive_care_occupancy_rate = "Neonatal intensive care occupancy rate"
  ) |>
  mutate(date = "April 2023") |>
  relocate(date, .after = nhs_trust22_code)

england_critical_general_acute_beds <-
  bind_rows(
    england_critical_general_acute_beds_incomplete,
    data_april23
  )

# Save output to data/ folder
usethis::use_data(england_critical_general_acute_beds, overwrite = TRUE)
