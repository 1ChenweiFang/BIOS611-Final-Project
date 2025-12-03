library(dplyr)
library(ggplot2)
library(tidyverse)

restaurants <- read_csv("DOHMH_New_York_City_Restaurant_Inspection_Results.csv",
                        col_types = cols(CAMIS = col_character()))

emb <- read_csv("name_embeddings_unique_camis.csv",
                col_types = cols(CAMIS = col_character()))
boro_viol <- restaurants %>%
  group_by(BORO) %>%
  summarise(
    n_viol        = n(),                  
    n_restaurants = n_distinct(CAMIS),     
    viol_per_rest = n_viol / n_restaurants,
    .groups = "drop"
  ) %>%
  arrange(desc(viol_per_rest))


ggplot(boro_viol,
       aes(x = reorder(BORO, viol_per_rest),
           y = viol_per_rest)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(
    title = "Average Number of Violations per Restaurant by Borough",
    x = "Borough",
    y = "Average Violations per Restaurant"
  ) +
  theme_minimal()

ggsave("figures/avg_vio.png",plot=last_plot())