library(dplyr)
library(lubridate)
library(ggplot2)
library(tidyverse)
restaurants <- read_csv("DOHMH_New_York_City_Restaurant_Inspection_Results.csv",
                        col_types = cols(CAMIS = col_character()))

emb <- read_csv("name_embeddings_unique_camis.csv",
                col_types = cols(CAMIS = col_character()))
cleaned <- restaurants %>%
  filter(!is.na(`CUISINE DESCRIPTION`)) %>%
  mutate(`INSPECTION DATE` = mdy(`INSPECTION DATE`))

open_df <- cleaned %>%
  group_by(CAMIS) %>%
  summarise(
    Cuisine = first(`CUISINE DESCRIPTION`),
    First_Inspection = min(`INSPECTION DATE`, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    Open_Month = floor_date(First_Inspection, unit = "month") 
  ) %>%
  filter(Open_Month >= ymd("2000-01-01"))   

trend_df <- open_df %>%
  group_by(Open_Month, Cuisine) %>%
  summarise(New_Count = n(), .groups = "drop")

top10 <- trend_df %>%
  group_by(Cuisine) %>%
  summarise(total = sum(New_Count), .groups = "drop") %>%
  slice_max(total, n = 10) %>%
  pull(Cuisine)

trend_df2 <- trend_df %>%
  mutate(Cuisine2 = if_else(Cuisine %in% top10, Cuisine, "Other")) %>%
  group_by(Open_Month, Cuisine2) %>%
  summarise(New_Count = sum(New_Count), .groups = "drop")

ggplot(trend_df2,
       aes(x = Open_Month, y = New_Count, color = Cuisine2)) +
  geom_line(linewidth = 1) +
  labs(
    title = "Trend of Detected Restaurants by Cuisine (Monthly, NYC)",
    x = "Month",
    y = "Number of Opened Restaurants",
    color = "Cuisine"
  ) +
  theme_minimal()

ggsave("figures/trends.png",plot=last_plot())

