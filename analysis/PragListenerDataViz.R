# Require packages
library(tidyverse)      # Data wrangling
library(wesanderson)    # Colors
source("../helpers.R")  # Confidence Intervals

L1_data_file <- "~/Desktop/PragListener.csv"
L1data <- read_csv(L1_data_file)
#PFdata = read.table(data_file,header=T,sep=",",quote="")

# Number of participants
nrow(unique(L1data[,"worker_id"]))
nrow(L1data[,"worker_id"])/22

excluded_hi = L1data %>%
  filter(scale == "training1") %>%
  filter(degree == 'hi2') %>%
  filter(judgment < 4) %>%
  select(worker_id)

excluded_low = L1data %>%
  filter(scale == "training1") %>%
  filter(degree == 'low1') %>%
  filter(judgment >2) %>%
  select(worker_id)

table(L1data[,"native_language"])/22
excluded_lang = L1data %>%
  filter(native_language == 'Vietnamese') %>%
  select(worker_id) %>%
  unique()

excluded = full_join(excluded_hi,excluded_low) %>%
  full_join(excluded_lang) %>%
  select(worker_id)

# AQ scores by participant
## 0-50 per Baron-Cohen et al 2001
aq_scores = unique(L1data[,c("baroncohen_aq","austin_aq","not_answered","worker_id")]) %>%
  filter(not_answered == 0) %>%
  filter(!worker_id %in% excluded) %>%
  mutate(BC_AQ=as.numeric(as.character(baroncohen_aq))) %>%
  mutate(A_AQ=(as.numeric(as.character(austin_aq))-50)/3) # Transform the 50-200 A_AQ data to 0-50 like BC_AQ

h_aq = aq_scores %>%
  filter(BC_AQ >= 32)
l_aq = aq_scores %>%
  filter(BC_AQ < 32)

nrow(aq_scores) # Should equal number of participants

# Set ggplot theme
theme_set(theme_bw())

# Plot histogram of AQ scores
ggplot(aq_scores, aes(position="identity"),binwidth=5) +
  geom_density(aes(x=BC_AQ,fill="blue"),alpha=.8) +
  geom_density(aes(x=A_AQ,fill="red"),alpha=.8) +
  scale_fill_discrete(name="Scoring Method",
                      breaks=c("blue","red"),
                      labels=c("Austin (2005)","Baron-Cohen, et al. (2001)")) +
  xlim(0,50) +
  xlab("AQ score") + 
  ylab("Density")

# Thanks to Masoud Jasbi for a bunch of this
means = L1data %>%
  filter(scale != "training1") %>%
  filter(!worker_id %in% excluded$worker_id) %>%
  mutate(AQ_bin=cut_width(as.numeric(baroncohen_aq),25,12.5)) %>%
  #mutate(AQ_bin=cut_number(as.numeric(baroncohen_aq),n=3)) %>%
  #mutate(AQ_bin=cut_number(as.numeric(baroncohen_aq),n=1)) %>%
  group_by(AQ_bin) %>%
  mutate(n_participants_in_group = length(unique(worker_id))) %>%
  group_by(judgment,AQ_bin,word) %>%
  mutate(freq_of_response = n(),propResp=freq_of_response/n_participants_in_group) %>%
  ungroup() %>%
  mutate(word=fct_relevel(word,"none","some","most","all")) %>%
  mutate(word=fct_relevel(word,"disgusting","gross","palatable","delicious")) %>%
  mutate(word=fct_relevel(word,"hated","disliked","liked","loved")) %>%
  mutate(word=fct_relevel(word,"forgettable","bland","memorable","unforgettable")) %>%
  mutate(word=fct_relevel(word,"terrible","bad","good","excellent")) %>%
  select(worker_id,scale,degree,judgment,word,AQ_bin,propResp)
  #mutate(YMin=ProportionYes-CILow,YMax=ProportionYes+CIHigh)

means_table.l1 = unique(means[,c("propResp","word","judgment","AQ_bin")])

for (w in unique(means_table.l1$word)) {
  for (b in unique(means_table.l1$AQ_bin)) {
    t = means_table.l1 %>%
      filter(word == w) %>%
      filter(AQ_bin == b)
    for (i in 1:5) {
      if (!i %in% t$judgment) {
        means_table.l1 = means_table.l1 %>%
          add_row(propResp = 0, word = w, judgment = i, AQ_bin = b)
      }
    }
  }
}

means_wide = select(means,worker_id,judgment,word,AQ_bin) %>% 
  spread(word,judgment)

group_by(means_wide,AQ_bin) %>%
  mean(good)

ggplot(means_table.l1, aes(position="identity", color=AQ_bin)) +
  geom_line(aes(x=judgment,y=propResp)) +
  geom_point(aes(x=judgment,y=propResp)) +
  #geom_smooth(aes(x=judgment,y=propResp)) +
  facet_wrap(~word,ncol=4) +
  labs(x="Number of Stars", y="Proportion of responses") +
  scale_color_discrete(name = "Group",
                       breaks=c("(25,50]","[0,25]"),
                       labels=c("High AQ","Low AQ"))

# Plot means with facets by word and color denoting high or low AQ group
ggplot(means_table.l1, aes(x=judgment,y=propResp,fill=AQ_bin)) +
  scale_fill_manual(values = wes_palette("FantasticFox1")[-c(1,2)])+
  geom_bar(position=position_dodge(), stat="identity") +
  #geom_errorbar(aes(ymin=YMin,ymax=YMax),width=0) +
  facet_wrap(~word,nrow=5,ncol=4) +
  labs(x="Number of Stars given", y="Probability of response")

# Get number in each group
n_low_aq = nrow(filter(unique(means[c("worker_id","AQ_bin")]),AQ_bin=="[0,25]"))
n_high_aq = nrow(unique(means[c("worker_id")])) - n_low_aq

# To Do
#     1. Confidence intervals.
#     2. Fix the bar plot so that the bars don't expand when there are empty values.
#     3. Maybe do it as lines rather than bars?.