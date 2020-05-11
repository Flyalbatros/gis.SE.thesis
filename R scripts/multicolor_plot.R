#plot with categoric colors, in the right order

with(subset(discussion_length, wiki == 'f'), plot(viewcount, total_score, pch=1, col=rgb(0,0,1), xlab='number of views', ylab='total score of thread', main='Total score of Q&As in function of the total number of views'))
with(subset(discussion_length, wiki == 't'), points(viewcount, total_score, pch=1, col=rgb(1,0,0)))
legend(1, 1300, legend=c("Red = wiki status", "Blue = no wiki status"))

with(subset(discussion_length, wiki == 'f'), plot(viewcount, comment_number/answer_number, pch=1, col=rgb(0,0,1), xlab='number of views', ylab='number of comments per answer', main='Comment ratio in function of views'))
with(subset(discussion_length, wiki == 't'), points(viewcount, comment_number/answer_number, pch=1, col=rgb(1,0,0)))
legend(1, 1300, legend=c("Red = wiki status", "Blue = no wiki status"))

with(subset(discussion_length, wiki == 'f'), plot(answer_number, comment_number/answer_number, pch=1, col=rgb(0,0,1), xlab='number of answers', ylab='number of comments per answer', main='Comment ratio in function of answer number'))
with(subset(discussion_length, wiki == 't'), points(answer_number, comment_number/answer_number, pch=1, col=rgb(1,0,0)))
legend(1, 1300, legend=c("Red = wiki status", "Blue = no wiki status"))

with(subset(discussion_length, wiki == 'f'), plot(answer_number, comment_number, pch=1, col=rgb(0,0,1), xlab='number of answers', ylab='number of comments', main='number of comments in function of answer number'))
with(subset(discussion_length, wiki == 't'), points(answer_number, comment_number, pch=1, col=rgb(1,0,0)))
legend(1, 1300, legend=c("Red = wiki status", "Blue = no wiki status"))

with(subset(time_diff, X1 < 3600*96), hist(X1/3600, breaks=96, freq=FALSE, axes=FALSE, main="Histogram of response time", xlab="Response time in days, each bin is an hour"))
axis(1,at=c(0,24,48,72,96), labels=c('0','1','2','3','4'))
axis(2,at=c(0,0.1,0.2,0.3,0.4,0.5))

with(subset(time_diff, X1 < 3600*96), hist(X1/3600, breaks=96, freq=FALSE, axes=FALSE, main="Histogram of response time", xlab="Response time in days, each bin is an hour", ylim=c(0,0.05)))
axis(1,at=c(0,24,48,72,96), labels=c('0','1','2','3','4'))
axis(2,at=c(0,0.05))