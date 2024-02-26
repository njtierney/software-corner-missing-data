library(tidyverse)
library(janitor)

rodents_raw <- read_csv(
  "data-raw/CSM081.csv",
  name_repair = make_clean_names
)

# from http://lter.konza.ksu.edu/content/csm08-small-mammal-host-parasite-sampling-data-16-linear-trapping-transects-located-8-lter

species_txt <- "PMMA=Peromyscus maniculatus; PMLE=Peromyscus leucopus; REME=Reithrodontomys megalotis; REMO=Reithrodontomys montanus; NEFL=Neotoma floridana; MIOC=Microtus ochrogaster; MIPI=Microtus pinetorum; SIHI=Sigmodon hispidus; CHHI=Chaetodipus hispidus; BLHA=Blarina hylophaga; CRPA=Cryptotis parva; SYFL=Sylvalagus floridanus; DIVI=Didelphis virginiana; ZAHU=Zapus hudsonius; ICTR=Ictidomys tridecemlineatus"

species_split <- str_split_1(species_txt, pattern = ";") %>% 
  str_trim() 
  
species_lookup <- tibble(species = species_split) %>% 
  tidyr::separate_wider_delim(
    cols = everything(),
    delim = "=",
    names = c("shortcode", "scientific_name")
    ) %>% 
  mutate(
    # found by googleing
    common_name = case_when(
      shortcode == "PMMA" ~ "deer mouse",
      shortcode == "PMLE" ~ "white footed mouse",
      shortcode == "REME" ~ "western harvest mouse",
      shortcode == "REMO" ~ "plains harvest mouse",
      shortcode == "NEFL" ~ "eastern woodrat",
      shortcode == "MIOC" ~ "prairie vole",
      shortcode == "MIPI" ~ "woodland vole",
      shortcode == "SIHI" ~ "hispid cotton rat",
      shortcode == "CHHI" ~ "hispid pocket mouse",
      shortcode == "BLHA" ~ "elliots short-tailed shrew",
      shortcode == "CRPA" ~ "north American least shrew",
      shortcode == "SYFL" ~ "eastern cottontail",
      shortcode == "DIVI" ~ "virginia opossum",
      shortcode == "ZAHU" ~ "meadow jumping mouse",
      shortcode == "ICTR" ~ "thirteen-lined ground squirrel",
      
    )
  )

species_lookup

rodents_clean <- rodents_raw %>%
  select(
    date,
    species,
    total_length,
    tail_length,
    hf_length,
    ear_length,
    weight,
    sex,
    age
  ) %>% 
  left_join(
    species_lookup,
    by = join_by(species == shortcode)
  ) %>% 
  select(
    -species,
    -scientific_name
  ) %>% 
  relocate(
    common_name,
    .after = date
    ) %>% 
  mutate(
    date = mdy(date)
  ) %>% 
  rename(
    hind_foot_length = hf_length,
    species = common_name
  )

rodents_clean %>% count(species)
# rodents_clean %>% vis_miss(facet = common_name)
# choose four most common

rodents <- rodents_clean %>% 
  filter(
    species %in% c(
      "eastern woodrat",
      "prairie vole",
      "western harvest mouse",
      "deer mouse"
    )
  ) %>% 
  mutate(
    across(
      c(
        species,
        sex,
        age
      ),
      as_factor
    )
  )

dir_create("data")
write_csv(
  x = rodents,
  "data/rodents.csv"
  )
