# Require packages
library(tidyverse)      # Data wrangling
library(wesanderson)    # Colors
source("../helpers.R")  # Confidence Intervals

# Load data
L0_data_file <- "/home/cj/Desktop/Linguistics/QP1/psycholing_results/PF_rep_l0_data_CS_scores.csv"
L0data <- read_csv(L0_data_file)
#PF2016_data_file <- "/home/cj/Desktop/scalar_implicature/production-results/e12-anonymized-results/OGData.csv"
#PF2016data <- read_csv(PF2016_data_file)

nrow(unique(L0data[,"worker_id"]))
nrow(L0data[,"worker_id"])/127

# Filter those whose first language isn't English
table(L0data[,"native_language"])
lang_excluded = L0data %>%
  filter(native_language == "spanish") %>%
  select(worker_id) %>%
  unique()

# Filter those who failed training trials
training_excluded = L0data %>%
  filter(scale == "training1") %>%
  filter(judgment == 0) %>%
  select(worker_id)

excluded = full_join(lang_excluded,training_excluded)


# AQ scores by participant
aq_scores = unique(L0data[,c("baroncohen_aq","austin_aq","not_answered","worker_id")]) %>%
  filter(not_answered == 0) %>%
  filter(!worker_id %in% excluded) %>%
  mutate(BC_AQ=as.numeric(as.character(baroncohen_aq))) #%>%
  #mutate(A_AQ=(as.numeric(as.character(austin_aq))-50)/3) # Transform the 50-200 A_AQ data to 0-50 like BC_AQ
nrow(aq_scores) # Should equal number of participants

# Set ggplot theme
theme_set(theme_bw())

# Plot histogram of AQ scores
ggplot(aq_scores, aes(x=BC_AQ)) +
  geom_histogram(binwidth = 1)

h_aq = unique(L0data[,c("baroncohen_aq","austin_aq","not_answered","worker_id")]) %>%
  filter(!worker_id %in% excluded$worker_id) %>%
  filter(baroncohen_aq > 3)

l_aq = unique(L0data[,c("baroncohen_aq","austin_aq","not_answered","worker_id")]) %>%
  filter(!worker_id %in% excluded$worker_id) %>%
  filter(baroncohen_aq <= 3)
nrow(h_aq)
nrow(l_aq)


# Judith wrote most of this, it organizes the data into a format ggplot can handle
#   Study it and figure it out
means = L0data %>%
  filter(scale != "training1") %>%
  filter(!worker_id %in% excluded$worker_id) %>%
  mutate(AQ_bin=cut_number(as.numeric(baroncohen_aq),2)) %>%
  group_by(manipulation,word,scale,AQ_bin) %>%
  summarize(ProportionYes=mean(judgment),CILow=ci.low(judgment),CIHigh=ci.high(judgment)) %>%
  ungroup() %>%
  mutate(word=fct_relevel(word,"none","little","some","most","all")) %>%
  mutate(word=fct_relevel(word,"disgusting","gross","mediocre","palatable","delicious")) %>%
  mutate(word=fct_relevel(word,"hated","disliked","indifferent","liked","loved")) %>%
  mutate(word=fct_relevel(word,"forgettable","bland","ordinary","memorable","unforgettable")) %>%
  mutate(word=fct_relevel(word,"terrible","bad","okay","good","excellent")) %>%
  mutate(YMin=ProportionYes-CILow,YMax=ProportionYes+CIHigh)

means["manipulation"] = means["manipulation"]/20
means_table.l0.single = unique(means[,c("ProportionYes","word","manipulation","AQ_bin")])

# Plot means with facets by word and color denoting high or low AQ group
ggplot(means, aes(x=manipulation/20,y=ProportionYes,color=AQ_bin)) +
  scale_color_manual(values = wes_palette("FantasticFox1")[-c(1,2)])+
  geom_point() +
  geom_errorbar(aes(ymin=YMin,ymax=YMax),width=0) +
  geom_line() +
  facet_wrap(~word,nrow=5,ncol=5) +
  labs(x="Number of Stars", y="Proportion of 'yes' responses") +
  scale_color_discrete(name = "Group",
                       breaks=c("(3,8]","[0,3]"),
                       labels=c("High AQ","Low AQ"))

#par(mfrow=c(5,5))
#for (s in unique(L0data$scale)) {
#  for (d in c('low2','low1','mid','hi2','hi1')) {
#    if (s == 'training1') {
#      next
#    }
#    word_data <- subset(L0data,scale == s & degree == d)
#    og_word_data <- subset(PF2016data,scale == s & degree == d)
#    y = c(
#      mean(subset(word_data,manipulation == 20)$judgment),
#      mean(subset(word_data,manipulation == 40)$judgment),
#      mean(subset(word_data,manipulation == 60)$judgment),
#      mean(subset(word_data,manipulation == 80)$judgment),
#      mean(subset(word_data,manipulation == 100)$judgment)
#    )
#    og_y = c(
#      mean(subset(og_word_data,manipulation == 20)$judgment),
#      mean(subset(og_word_data,manipulation == 40)$judgment),
#      mean(subset(og_word_data,manipulation == 60)$judgment),
#      mean(subset(og_word_data,manipulation == 80)$judgment),
#      mean(subset(og_word_data,manipulation == 100)$judgment)
#    )
#    stars = c(1,2,3,4,5)
#    plot(stars,y,type='l',main=unique(word_data$word),xlab='Stars',ylab='Mean judgement',ylim=c(0,1))
#    lines(stars,og_y,type = 'l',col="blue",lty=2)
#  }
#}
