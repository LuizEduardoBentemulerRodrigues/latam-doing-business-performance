# ==============================================================================
# Data Collection via API (WDI) + Static Dataset (Doing Business)
# ==============================================================================
library(WDI)
library(readxl)
library(dplyr)
library(tidyr)
library(here)
library(writexl)

# 1. Define WDI indicator codes
indicator_wdi <- c(
  "NE.GDI.FTOT.ZS",      # Gross capital formation (% of GDP)
  "IP.PAT.RESD",         # Patent applications, residents
  "TX.VAL.TECH.MF.ZS",   # High-technology exports (% of manufactured exports)
  "SL.GDP.PCAP.EM.KD",   # GDP per person employed (constant 2017 PPP $)
  "SE.SEC.NENR",         # School enrollment, secondary (% net)
  "NE.TRD.GNFS.ZS",      # Trade (% of GDP)
  "GB.XPD.RSDV.GD.ZS",   # Research and development expenditure (% of GDP)
  "SP.POP.TOTL"          # Population, total
)

# 2. Get the list of Latin America & Caribbean countries
countries <- WDI_data$country %>% as_tibble()

countries_latam <- countries %>% 
  filter(region == "Latin America & Caribbean") %>% 
  pull(iso3c)

# 3. Extract WDI data for each Latin American country
indicators_data <- WDI(
  country = countries_latam, 
  indicator = indicator_wdi, 
  start = 2014, 
  end = 2020, 
  extra = TRUE          
) %>% 
  select(-iso2c)

# 4. Load Doing Business historical dataset
data_db <- here("data_db", "Historical-data---COMPLETE-dataset-with-scores (1).xlsx")
data_db <- read_excel(data_db, skip = 3, .name_repair = "unique") %>% 
  select(
    iso3c = contains("Code"),                           
    year = contains("DB Year") | contains("Year"),       
    Doing_Business_Score = contains("score (DB17-20")    
  ) %>% 
  select(iso3c = 1, year = 2, Doing_Business_Score = 3) %>% 
  mutate(
    year = as.numeric(year),
    iso3c = trimws(as.character(iso3c))
  ) %>% 
  filter(year >= 2014 & year <= 2020)

# 5. Merge datasets by country (iso3c) and year (year)
final_data <- indicators_data %>% 
  left_join(data_db, by = c("iso3c", "year"))

# 6. Export output dataset
write_xlsx(final_data, here("data_db", "Base_AML_DB_API.xlsx"))
message("Dataset successfully extracted and merged!")