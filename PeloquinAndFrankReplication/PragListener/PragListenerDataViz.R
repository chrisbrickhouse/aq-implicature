# Load data

library(readr)
library(tidyr)
library(dplyr)
library(ggplot2)
library(magrittr)
library(forcats)
library("wesanderson")
# Error bars
source("helpers.R")
#library(tidyverse)

data_file <- "Desktop/PragListener.csv"
PFdata <- read_csv(data_file)
PFdata = read.table(data_file,header=T,sep=",",quote="")

# AQ scores by participant
aq_scores = unique(PFdata[,c("baroncohen_aq","worker_id")]) %>%
  mutate(BC_AQ=as.numeric(as.character(baroncohen_aq)))
nrow(aq_scores) # Should equal number of participants

# Set ggplot theme
theme_set(theme_bw())

# Plot histogram of AQ scores
ggplot(aq_scores, aes(x=BC_AQ)) +
  geom_histogram(binwidth = 2)

# Judith wrote most of this, it organizes the data into a format ggplot can handle
#   Study it and figure it out
means = PFdata %>%
  filter(scale != "training1") %>%
  #filter(!worker_id %in% PFexcluded) %>%
  mutate(AQ_bin=cut_width(as.numeric(baroncohen_aq),25,12.5)) %>%
  group_by(AQ_bin) %>%
  mutate(n_part = length(unique(worker_id))) %>%
  group_by(judgment,AQ_bin,word) %>%
  mutate(count_ppl = n(),propResp=count_ppl/n_part) %>%
  #mutate(AQ_bin=cut_number(as.numeric(BC_AQ),2)) %>%
  #group_by(judgment,word,scale,AQ_bin) %>%
  #summarize(numYes=n()) %>%
  ungroup() %>%
  mutate(word=fct_relevel(word,"none","little","some","most","all")) %>%
  mutate(word=fct_relevel(word,"disgusting","gross","palatable","delicious")) %>%
  mutate(word=fct_relevel(word,"hated","disliked","liked","loved")) %>%
  mutate(word=fct_relevel(word,"forgettable","bland","memorable","unforgettable")) %>%
  mutate(word=fct_relevel(word,"terrible","bad","good","excellent"))
  #mutate(YMin=ProportionYes-CILow,YMax=ProportionYes+CIHigh)

# Plot means with facets by word and color denoting high or low AQ group
ggplot(means, aes(x=judgment,y=propResp,fill=AQ_bin)) +
  #scale_color_manual(values = wes_palette("BottleRocket2"))+
  geom_bar(position=position_dodge(), stat="identity") +
  #geom_errorbar(aes(ymin=YMin,ymax=YMax),width=0) +
  #geom_line() +
  facet_wrap(~word,nrow=5,ncol=4) +
  labs(x="Number of Stars", y="Proportion of 'yes' responses")

# To Do
#     1. Confidence intervals.
#     2. Fix the bar plot so that the bars don't expand when there are empty values.
#     3. Maybe do it as lines rather than bars?.