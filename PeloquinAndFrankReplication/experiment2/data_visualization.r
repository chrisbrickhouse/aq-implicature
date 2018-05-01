# Load data

library(readr)
data_file <- "Desktop/PeloquinAndFrankReplicationData_Pilot.csv"
PFdata <- read_csv(data_file)

par(mfrow=c(5,5))
for (s in unique(PFdata$scale)) {
  for (d in c('low2','low1','mid','hi2','hi1')) {
    if (s == 'training1') {
      next
    }
    word_data <- subset(PFdata,scale == s & degree == d)
    y = c(
      mean(subset(word_data,manipulation == 20)$judgment),
      mean(subset(word_data,manipulation == 40)$judgment),
      mean(subset(word_data,manipulation == 60)$judgment),
      mean(subset(word_data,manipulation == 80)$judgment),
      mean(subset(word_data,manipulation == 100)$judgment)
    )
    stars = c(1,2,3,4,5)
    plot(stars,y,type='l',main=unique(word_data$word),xlab='Stars',ylab='Mean judgement',ylim=c(0,1))
  }
}