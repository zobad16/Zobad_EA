pollutantmean<- function(dir,pol, ID)
{
    directory<-list.files(path=dir, full.names = TRUE)[ID]
    #
    #length(directory)
    dat <- data.frame()
   
    for(i in 1:length(directory)) {
     dat<- rbind(dat,read.csv(directory[i]))
   } 
    r_data<-dat
    r_data2 <- r_data[pol]
    #r_pol <- is.na(r_data2)
    #noNa  <- r_data2[!r_pol]
    #noNa[pol]
    #sumP <- sum(noNa)
    #n<- length(r_data2[!r_pol])
    #meanP<-sumP/n
    mean(r_data$pol,na.rm=TRUE)
   #}
    #r_data2 <- r_data[pol]
    #r_pol <- is.na(r_data2)
    #noNa  <- r_data2[!r_pol]
    #noNa[pol]
    #sumP <- sum(noNa)
    #n<- length(r_data2[!r_pol])
    #meanP<-sumP/n
}