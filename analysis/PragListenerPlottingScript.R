# Require packages
library(tidyverse)      # Data wrangling
library(wesanderson)    # Colors
source("../helpers.R")  # Confidence Intervals

#Load data
L1_data_file <- "~/Desktop/PragListener.csv"
L1data <- read_csv(L1_data_file)

# Number of participants
nrow(unique(L1data[,"worker_id"]))
nrow(L1data[,"worker_id"])/22

# Data Exclusions
## Exclude those who said a high rating was <= 3 stars
excluded_hi = L1data %>%
  filter(scale == "training1") %>%
  filter(degree == 'hi2') %>%
  filter(judgment < 4) %>%
  select(worker_id)

## Exclude those who said a low rating was >= 3 stars
excluded_low = L1data %>%
  filter(scale == "training1") %>%
  filter(degree == 'low1') %>%
  filter(judgment >2) %>%
  select(worker_id)

## See responses to native language question
table(L1data[,"native_language"])/22
## Exclude those whose native language is not English
excluded_lang = L1data %>%
  filter(native_language != 'English') %>%
  select(worker_id) %>%
  unique()

excluded = full_join(excluded_hi,excluded_low) %>%
  full_join(excluded_lang) %>%
  select(worker_id)

means_test = L1data %>%
  filter(scale != "training1") %>%
  filter(!worker_id %in% excluded$worker_id) %>%
  mutate(AQ_bin=cut_width(as.numeric(baroncohen_aq),25,12.5)) %>%
  select(worker_id,judgment,word,AQ_bin) %>%
  rename(stars = judgment) %>%
  add_column(judgment = 1,.before=3)

# This takes a while to run, only do so if necessary
#   But really, it takes almost 2 minutes
for (p in unique(means_test$worker_id)) { 
  for (w in unique(means_test$word)) {
    t = means_test %>%
      filter(word == w) %>%
      filter(worker_id == p)
    b = t$AQ_bin
    for (i in 1:5) {
      if (!i %in% t$stars) {
        print(paste(p,w,i,b))
        means_test = means_test %>%
          add_row(worker_id = p, word = w, stars = i, judgment = 0, AQ_bin=b)
      }
    }
  }
}

mt_plot = means_test %>%
  group_by(word,stars,AQ_bin) %>%
  summarize(Proportion=mean(judgment),CILow=ci.low(judgment),CIHigh=ci.high(judgment)) %>%
  ungroup() %>%
  mutate(word=fct_relevel(word,"none","some","most","all")) %>%
  mutate(word=fct_relevel(word,"disgusting","gross","palatable","delicious")) %>%
  mutate(word=fct_relevel(word,"hated","disliked","liked","loved")) %>%
  mutate(word=fct_relevel(word,"forgettable","bland","memorable","unforgettable")) %>%
  mutate(word=fct_relevel(word,"terrible","bad","good","excellent")) %>%
  mutate(YMin=Proportion-CILow,YMax=Proportion+CIHigh)

n_low_aq = nrow(filter(unique(means_test[c("worker_id","AQ_bin")]),AQ_bin=="[0,25]"))
n_high_aq = nrow(unique(means_test[c("worker_id")])) - n_low_aq

ggplot(mt_plot, aes(x=stars,y=Proportion,position="identity", color=AQ_bin)) +
  geom_line() +
  geom_point() +
  geom_errorbar(aes(ymin=YMin,ymax=YMax),width=0) +
  facet_wrap(~word,ncol=4) +
  labs(x="Number of Stars", y="Proportion of responses") +
  scale_color_discrete(name = "Group",
                       breaks=c("(25,50]","[0,25]"),
                       labels=c("High AQ","Low AQ"))
