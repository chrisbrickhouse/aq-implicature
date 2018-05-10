# Load data

library(tidyverse)
library("wesanderson")
# Error bars
source("helpers.R")

data_file <- "~/Desktop/PragListener.csv"
PFdata = read.table(data_file,header=T,sep=",",quote="")

# AQ scores by participant
## 0-50 per Baron-Cohen et al 2001
bc_aq_scores = unique(PFdata[,c("baroncohen_aq","worker_id")]) %>%
  mutate(BC_AQ=as.numeric(as.character(baroncohen_aq)))
## 50 - 200 per Austin 2005
a_aq_scores = unique(PFdata[,c("austin_aq","worker_id")]) %>%
  mutate(A_AQ=as.numeric(as.character(austin_aq)))

nrow(aq_scores) # Should equal number of participants

# Set ggplot theme
theme_set(theme_bw())

# Plot histogram of AQ scores
ggplot(bc_aq_scores, aes(x=BC_AQ)) +
  geom_histogram(binwidth = 5)

# Thanks to Masoud Jasbi for a bunch of this
means = PFdata %>%
  filter(scale != "training1") %>%
  #filter(!worker_id %in% PFexcluded) %>%
  mutate(AQ_bin=cut_width(as.numeric(baroncohen_aq),25,12.5)) %>%
  #mutate(AQ_bin=cut_number(as.numeric(austin_aq),n=2)) %>%
  group_by(AQ_bin) %>%
  mutate(n_participants_in_group = length(unique(worker_id))) %>%
  group_by(judgment,AQ_bin,word) %>%
  mutate(freq_of_response = n(),propResp=freq_of_response/n_participants_in_group) %>%
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