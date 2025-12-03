library(ggplot2)
library(dplyr)
library(tidyverse)

restaurants <- read_csv("DOHMH_New_York_City_Restaurant_Inspection_Results.csv",
                        col_types = cols(CAMIS = col_character()))

emb <- read_csv("name_embeddings_unique_camis.csv",
                col_types = cols(CAMIS = col_character()))

cuisine_viol <- restaurants %>%
  filter(!is.na(`CUISINE DESCRIPTION`)) %>%
  group_by(`CUISINE DESCRIPTION`) %>%
  summarise(
    n_viol = n(),
    n_restaurants = n_distinct(CAMIS),
    avg_viol_per_rest = n_viol / n_restaurants,
    .groups = "drop"
  ) %>%
  arrange(desc(avg_viol_per_rest)) %>%
  dplyr::slice(1:15)

ggplot(cuisine_viol,
       aes(x = reorder(`CUISINE DESCRIPTION`, avg_viol_per_rest),
           y = avg_viol_per_rest)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(
    title = "Top 15 Cuisine Types by Average Violations per Restaurant",
    x = "Cuisine Type",
    y = "Average Violations per Restaurant"
  ) +
  theme_minimal()

ggsave("figures/violation_frequency.png",plot=last_plot())