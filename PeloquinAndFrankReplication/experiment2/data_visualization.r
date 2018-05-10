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

data_file <- "Desktop/PeloquinAndFrankReplicationData_Pilot.csv"
PFdata <- read_csv(data_file)
PFdata = read.table(data_file,header=T,sep=",",quote="")
og_data_file <- "/home/cj/Desktop/scalar_implicature/production-results/e12-anonymized-results/OGData.csv"
OGdata <- read_csv(og_data_file)

####
# No longer needed
# data_organizer.py creates separate column for number not answered
####
# Split the AQ data into two rows, one with the score and the other the number of questions not answered
#PFdata2 = PFdata %>%
#  separate(baroncohen_aq,c("BC_AQ","NumNotAnswered"),sep="\\.")

# AQ scores by participant
aq_scores = unique(PFdata[,c("baroncohen_aq","worker_id")]) %>%
  mutate(BC_AQ=as.numeric(as.character(baroncohen_aq)))
nrow(aq_scores) # Should equal number of participants

# Set ggplot theme
theme_set(theme_bw())

# Plot histogram of AQ scores
ggplot(aq_scores, aes(x=BC_AQ)) +
  geom_histogram(binwidth = 2)

# Filter those who failed training trials
PFexcluded = PFdata %>%
  filter(scale == "training1") %>%
  filter(judgment == 0) %>%
  select(worker_id)

# Judith wrote most of this, it organizes the data into a format ggplot can handle
#   Study it and figure it out
means = PFdata %>%
  filter(scale != "training1") %>%
  filter(!worker_id %in% PFexcluded) %>%
  mutate(AQ_bin=cut_width(as.numeric(baroncohen_aq),25,12.5)) %>%
  #mutate(AQ_bin=cut_number(as.numeric(BC_AQ),2)) %>%
  group_by(manipulation,word,scale,AQ_bin) %>%
  summarize(ProportionYes=mean(judgment),CILow=ci.low(judgment),CIHigh=ci.high(judgment)) %>%
  ungroup() %>%
  mutate(word=fct_relevel(word,"none","little","some","most","all")) %>%
  mutate(word=fct_relevel(word,"disgusting","gross","mediocre","palatable","delicious")) %>%
  mutate(word=fct_relevel(word,"hated","disliked","indifferent","liked","loved")) %>%
  mutate(word=fct_relevel(word,"forgettable","bland","ordinary","memorable","unforgettable")) %>%
  mutate(word=fct_relevel(word,"terrible","bad","okay","good","excellent")) %>%
  mutate(YMin=ProportionYes-CILow,YMax=ProportionYes+CIHigh)

# Plot means with facets by word and color denoting high or low AQ group
ggplot(means, aes(x=manipulation/20,y=ProportionYes,color=AQ_bin)) +
  #scale_color_manual(values = wes_palette("BottleRocket2"))+
  geom_point() +
  geom_errorbar(aes(ymin=YMin,ymax=YMax),width=0) +
  geom_line() +
  facet_wrap(~word,nrow=5,ncol=5) +
  labs(x="Number of Stars", y="Proportion of 'yes' responses")

par(mfrow=c(5,5))
for (s in unique(PFdata$scale)) {
  for (d in c('low2','low1','mid','hi2','hi1')) {
    if (s == 'training1') {
      next
    }
    word_data <- subset(PFdata,scale == s & degree == d)
    og_word_data <- subset(OGdata,scale == s & degree == d)
    y = c(
      mean(subset(word_data,manipulation == 20)$judgment),
      mean(subset(word_data,manipulation == 40)$judgment),
      mean(subset(word_data,manipulation == 60)$judgment),
      mean(subset(word_data,manipulation == 80)$judgment),
      mean(subset(word_data,manipulation == 100)$judgment)
    )
    og_y = c(
      mean(subset(og_word_data,manipulation == 20)$judgment),
      mean(subset(og_word_data,manipulation == 40)$judgment),
      mean(subset(og_word_data,manipulation == 60)$judgment),
      mean(subset(og_word_data,manipulation == 80)$judgment),
      mean(subset(og_word_data,manipulation == 100)$judgment)
    )
    stars = c(1,2,3,4,5)
    plot(stars,y,type='l',main=unique(word_data$word),xlab='Stars',ylab='Mean judgement',ylim=c(0,1))
    lines(stars,og_y,type = 'l',col="blue",lty=2)
  }
}
