#This is function for module 1 of STAT628, the group members is Ashvini Fulpagar, Enze Wang, Mengkun Chen, Qingchuan Ji.
#The function name is just your_function
#The input is y_t, t, maxcap
#The output will be a number which is estimated time when y_t reach maxcap
#Our function is a linear regression based method which do not use lm()
#No package is required for our function
#In our function, we regard as the estimated slope must be positive (Or the y_t may never reach maxcap)
#Our function prefers to give a conservative and strict prediction.
#There is many parameters in our data, as mentioned by professor, there is no perfect algorithm, in fact we highly recomment if for further development, you can change any parameter you want to fit your data.
#There may some warning from our function when cleanning data. Just miss them. 

your_function<-function(y_t,t,maxcap){
  
  #Clean part:
  #Any clean part of function must pass the following example:
  #y_t=c('1',1,'-1',-1,Inf,'Inf','c',NA,NULL,NaN,'NA','NULL','NaN')
  
  y_t=as.numeric(y_t)
  t=as.numeric(t)
  Clean=which(is.infinite(y_t)|y_t<0|is.na(y_t))
  if(length(Clean)!=0){
    y_t=y_t[-Clean]
    t=t[-Clean]} 
  y_t=as.numeric(y_t)
  t=as.numeric(t)
  
  #Plot the y_t if you want
  #plot(y_t~t)
  
  #Calculate the max of y_t, max of t and length of data
  
  Maxy_t=max(y_t)
  EndTime=max(t)
  n=length(y_t)
  
  #Two special situations:
  #If the valid data length is less than 1, just give an alarm at the end of t, we regard the system is broken and nothing is recorded.
  #If the y_t in the end of time is larger than 98% of maxcap, just give an alarm at the end of t, we regard the system will break soon.
  
  if(n<=1){
    return(EndTime+1)
  }
  if(n>12){
    if(mean(y_t[(n-5):n])>0.98*maxcap){
      return(EndTime+1)
    }
  }
  
  #Our linear regression function:
  #In our function only slope is useful, but if you want to further development you can use intercept.
  
  LR<-function(X,Y){
    clean = !is.na(Y) 
    Y = as.numeric(Y[clean]);
    X = as.numeric(X[clean])
    Xmean=mean(X)
    Ymean=mean(Y)
    B=sum((X-Xmean)*(Y-Ymean))/sum((X-Xmean)^2)
    A=Ymean-B*Xmean
    return(c(B,A))
  }
  
  #If the valid point in our data is less than 20, it may not good to do advanced method to our data, we choose the simple linear regression.
  #We hold that the slope of our data should be positive or the y_t will never reach maxcap. So if the function found that the slope is non-positive, it will return the end of time directly.
  
  if(n<20){
    Result=LR(t,y_t)
    FinalSlope=Result[1]
    FinalIntercept=Result[2]
    if(FinalSlope>0){
      deadtime=(maxcap-FinalIntercept)/FinalSlope-2
      OUTPUT=max(deadtime,EndTime+1)
    }else{
      OUTPUT=EndTime+1
    }
  }else{
    #If our data is large enough for advanced method, use the following part.
    #The following loop is to find great jump of data, great jump is index where y_t drop from high level to low level sharply.
    #There is no perfect rule to find great jump, any rule will meet exceptions, therefore great jump is just an assist in our algorithm.
    
    GreatJump=c()
    Diffy_t=diff(y_t)
    m=n-1
    
    #DetectJumpDown will find y_t jumping from high level to low level sharply. DetectJumpUp will find y_t jumping from low level to high level sharply. 
    #In our function we will only use DetectJumpDown, the DetectJumpUp is for further development if you want. 
    #The rule of great jump is very strict, or some outliers will become great jump
    #The great jump is the method we design to deal with server down period, server maintenance period and server clean time. We ignore the DetectJumpUp because 1. It may belongs to valid data and contains some information we want; 2. Our following function can handle this kind of problem. 
    
    DetectJumpDown<-function(ind){
      #Two level of filter, one coarse and one fine filter, this will help this loop run very fast. 
      if(-Diffy_t[ind]>0.4*y_t[ind]){
        ForFive<-y_t[max(ind-5,1):ind]
        BackFive<-y_t[(ind+1):min(m,ind+5)]
        if(Diffy_t[ind]<0 & min(ForFive)>max(BackFive) & max(0.8*abs(Diffy_t[ind]),0.2*Maxy_t)<(mean(ForFive)-mean(BackFive))){
          return(ind)
        }
      }
      return(NA)
    }
    
    DetectJumpUp<-function(ind){
      if(Diffy_t[ind]>0.4*y_t[ind+1]){
        ForFive<-y_t[max(ind-5,1):ind]
        BackFive<-y_t[(ind+1):min(m,ind+5)]
        if(Diffy_t[ind]>0 & max(ForFive)<min(BackFive) & max(0.8*abs(Diffy_t[ind]),0.2*Maxy_t)<(-mean(ForFive)+mean(BackFive))){
          return(ind)
        }
      }
      return(NA)
    }
    
    #i where great jump happen will be saved in GreatJump
    detectret<-sapply(7:(m-7), FUN = DetectJumpDown)
    GreatJump<-detectret[!is.na(detectret)]
    
    #If you want to check GreatJump from our function, please run the following function:
    #plot(Diffy_t)
    #GreatJump
    #plot(y_t)
    #As we said before, subsection cut by great jump is only an assist for our prediction. In case that cutting by great jump will make our data piece too small. We run the following code:
    #We will check the length of every piece of data cutted by great jump point from the end, if the length is less than 10, we will ignore this cut. 
    #Any satisfactory great jump will be included into FinalCut.
    
    FinalCut=c(n)
    GreatJump=c(1,GreatJump)
    
    while(length(GreatJump)>0){
      lenJump=length(GreatJump)
      if(FinalCut[1]-GreatJump[lenJump]>=10){
        FinalCut=c(GreatJump[lenJump],FinalCut)
        GreatJump=GreatJump[-lenJump]
        n=FinalCut[1]
      }else{
        GreatJump=GreatJump[-lenJump]
      }
    }
    
    if(FinalCut[1]<=20){
      FinalCut[1]=1
    }else{
      FinalCut=c(1,FinalCut)
    }
    
    #In the following section we defind a function called PartLinearRegression.
    #For any long section (>30) cutted by FinalCut, we will cut any section into 4 equal part, and do linear regression [1/2,3/4], [3/4,1] first then choose the largest slope. If the slope is negative, use the [0,1/4], [1/4,1/2] then choose the largest slope.
    #This design is for exponential shape data or there is a piece of decreasing in our data.
    #As you can see, there is only a part of data from the end enter into linear regression calculation one by one, therefore we do not need to worry about the great increasing caused by server maintenance period.
    #The reason we choose the largest slope is that we want a conservative estimation of deadtime, any deadline larger than the real deadline will be very dangerous.
    #The work above is just PartLinearRegression does.
    
    PartLinearRegression<-function(t,y_t,index){
      #If the section is short, just do the linear regression, there is no need to do advanced method.
      if(length(index)<30){
        Y=y_t[Index]
        X=t[Index]
        Result=LR(X,Y)
        return(Result[1])
      }else{
        Y=y_t[Index]
        X=t[Index]
        n=length(Y)
        #Data Cut
        n1=round(1*n/4)
        n2=round(n/2)
        n3=round(3*n/4)
        Result3=LR(X[n3:n],Y[n3:n])
        Result2=LR(X[n2:n3],Y[n2:n3])
        Slope=c(Result3[1],Result2[1])
        #Choose the positive slope or return 0
        if(max(Slope)>0){
          index=which(Slope>0 & Slope<Inf)
          Slope=Slope[index]
          return(max(Slope))
        }else{
          Result1=LR(X[n1:n2],Y[n1:n2])
          Result0=LR(X[1:n1],Y[1:n1])
          Slope=c(Result1[1],Result0[1])
          if(max(Slope)>0){
            index=which(Slope>0 & Slope<Inf)
            Slope=Slope[index]
            return(max(Slope))
          }else{return(0)}
        }
      }
    }
    #It seems that this part contains many times of linear regression, but for most of situations, function will return output in the first two linear regression. 
    
    #The following loop do every PartLinearRegression on each section cutted by FinalCut from the end to start point. 
    #If there exists positive slope of the section from the end, then the loop will break, or it will return the first positive slope it found and break
    #No positive slope, the loop will return 0.
    
    lenCut=length(FinalCut)
    for(i in lenCut:2){
      Index=FinalCut[i-1]:FinalCut[i]
      FinalSlope=PartLinearRegression(t,y_t,Index)
      if(FinalSlope>0){
        break
      }else{
        FinalSlope=0
      }
    }
    
    #The FinalSlope is just we want.
    #For most of situations, the loop will break when i=lenCut, so we do not worry about the running time blow up unless there is special data. 
    #Different with the professor's example, after finding the slope we want, we will not use its corresponding intercept to calculate. 
    #Instead, we will use the y_t and t in the end of data to calculate the line, which avoid that the y_t is in low level at the end of time
    #It is not a good idea to calculate the mean of y_t at the end directly, in case there exist some NA among the last five elements.
    #The output will be the min of the five.
    #If the FinalSlope is non-positive, just return the end of time.
    
    n=length(y_t)
    Endt=t[n:min(n,max(n-5,1))]
    Endy_t=y_t[n:min(n,max(n-5,1))]
    
    if(FinalSlope>0){
      OUTPUT=(maxcap-Endy_t)/FinalSlope+Endt-2
      i=which.min(OUTPUT)
      OUTPUT=min(OUTPUT)
      Endy_t=Endy_t[i]
      Endt=Endt[i]
    }else{
      OUTPUT=EndTime+1
    }
    #As we mentioned before, this intercept is not slope's corresponding intercept.
    #The fitting line will start from the end of data. 
    #If you do not want to plot, just omit this line.
    FinalIntercept=Endy_t-Endt*FinalSlope
    
  }  
  #If you want to see how our function fit the data, how our prof's example function fit the data. Run the following code:
  #But it is time-consuming for ploting
  
  Example_function<-function(y_t,t,maxcap){
    y_t=as.numeric(y_t)
    t=as.numeric(t)
    Clean=which(toupper(y_t)==tolower(y_t)& y_t<Inf & y_t>0)
    y_t=y_t[Clean]
    t=t[Clean]
    y_t=as.numeric(y_t)
    t=as.numeric(t)
    OUTPUT=lm(y_t~t)
    Slope=OUTPUT$coefficients[2]
    Intercept=OUTPUT$coefficients[1]
    deadline=(maxcap-Slope)/Intercept-2
    return(c(deadline,Slope,Intercept))
  }
  ExampleOutput=Example_function(y_t,t,maxcap)
  ExampleSlope=ExampleOutput[2]
  ExampleIntercept=ExampleOutput[3]
  
  plot(y_t~t,xlim=c(0,1.5*EndTime),ylim=c(0,maxcap*1.1))
  abline(FinalIntercept, FinalSlope,col="red",lwd=3)
  abline(ExampleIntercept, ExampleSlope,col="green",lwd=3)
  abline(h = maxcap,col="blue",lwd=3)
  return(round(OUTPUT))
}

Example_function<-function(y_t,t,maxcap){
  y_t=as.numeric(y_t)
  t=as.numeric(t)
  Clean=which(toupper(y_t)==tolower(y_t)& y_t<Inf & y_t>0)
  y_t=y_t[Clean]
  t=t[Clean]
  y_t=as.numeric(y_t)
  t=as.numeric(t)
  OUTPUT=lm(y_t~t)
  Slope=OUTPUT$coefficients[2]
  Intercept=OUTPUT$coefficients[1]
  deadline=(maxcap-Slope)/Intercept-2
  return(deadline)
}


#Example 1
maxcap = 100*10^3;
out_data = read.csv("out_youtube.csv",header=TRUE)
plot(out_data$t,out_data$y_t,ylim=c(0,maxcap),xlim=c(0,1600),
     ylab="Youtube Traffic (Kb)",xlab="Time (sec)",main="Youtube Traffic Data")
abline(h = maxcap,col="red",lwd=2)

out_data_y_t=out_data$y_t
out_data_t=out_data$t


#Example 2
maxcap=100
box_data = read.csv("out_box.csv",header=TRUE)
plot(box_data$t,box_data$y_t,ylim=c(-10,maxcap),xlim=c(0,400),
     ylab="Box Traffic (kb) ",xlab="Time (sec)",main="Box Traffic Data")
abline(h = maxcap,col="red",lwd=2)

box_data_y_t=box_data$y_t
box_data_t=box_data$t


#Test

n=500
test_t=1:n
Error=c('1',1,'-1',-1,Inf,'Inf','c','你好',NA,NaN,'NA','NULL','NaN')

#Example 3
test_y_t1=rep(0,n)
m=round(n/5)
test_y_t1[1:m]=3*test_t[1:m]+rnorm(m, mean=0, sd=70)
test_y_t1[(m+1):(2*m)]=test_t[1:m]+1000+rnorm(m, mean=0, sd=70)
test_y_t1[(2*m+1):(3*m)]=6*test_t[1:m]+2000+rnorm(m, mean=0, sd=70)
test_y_t1[(3*m+1):(n-30)]=10*test_t[1:m]+3000+rnorm(m, mean=0, sd=70)
test_y_t1[(n-30):n]=test_t[1:m]+rnorm(m, mean=0, sd=70)
test_y_t1[round(0.5*n):(round(0.5*n)+30)]=0
test_y_t1[round(0.7*n):(round(0.7*n)+5)]=100
test_y_t1[sample(1:n, 13)]=Error
plot(test_y_t1~test_t)

#Example 4
test_y_t2=rep(0,n)
m=round(n/3)
test_y_t2[1:m]=3*test_t[1:m]-50+rnorm(m, mean=0, sd=70)
test_y_t2[(m+1):(2*m+1)]=4*test_t[1:m]-50+rnorm(m, mean=0, sd=70)
test_y_t2[(2*m+2):n]=10*test_t[1:m]-50+rnorm(m, mean=0, sd=70)
test_y_t2[round(0.5*n):(round(0.5*n)+30)]=0
test_y_t2[round(0.7*n):(round(0.7*n)+5)]=100
test_y_t2[sample(1:n, 13)]=Error
plot(test_y_t2~test_t)

#Example 5
test_y_t3=rep(0,n)
m=round(n/3)
test_y_t3[1:m]=10*test_t[1:m]-50+rnorm(m, mean=0, sd=70)
test_y_t3[(m+1):(2*m+1)]=5*test_t[1:m]-50+rnorm(m, mean=0, sd=70)
test_y_t3[(2*m+2):n]=1*test_t[1:m]-50+rnorm(m, mean=0, sd=70)
test_y_t3[sample(1:n, 13)]=Error
test_y_t3[round(0.5*n):(round(0.5*n)+30)]=0
test_y_t3[round(0.7*n):(round(0.7*n)+5)]=100
plot(test_y_t3~test_t)

#Example 6
m=round(4*n/5)
test_y_t4=rep(0,n)
test_y_t4[1:m]=rnorm(m, mean=100, sd=70)
test_y_t4[(m+1):n]=10*test_t[1:(n-m)]+rnorm(n-m, mean=0, sd=70)
test_y_t4[sample(1:n, 13)]=Error
test_y_t4[round(0.5*n):(round(0.5*n)+30)]=0
test_y_t4[round(0.7*n):(round(0.7*n)+5)]=100
plot(test_y_t4~test_t)

#Example 7
test_y_t5=100*log(test_t)+rnorm(n, mean=100, sd=70)
test_y_t5[sample(1:n, 13)]=Error
test_y_t5[round(0.5*n):(round(0.5*n)+30)]=0
test_y_t5[round(0.7*n):(round(0.7*n)+5)]=3
plot(test_y_t5~test_t)


#Example 8
test_y_t6=rep(0,n)
m=round(n/5)
test_y_t6[1:m]=3*test_t[1:m]+rnorm(m, mean=0, sd=70)
test_y_t6[(m+1):(2*m)]=test_t[1:m]+1000+rnorm(m, mean=0, sd=70)
test_y_t6[(2*m+1):(3*m)]=6*test_t[1:m]+2000+rnorm(m, mean=0, sd=70)
test_y_t6[(3*m+1):(4*m)]=10*test_t[1:m]+3000+rnorm(m, mean=0, sd=70)
test_y_t6[(4*m+1):(5*m)]=test_t[1:m]+rnorm(m, mean=0, sd=70)
test_y_t6[round(0.5*n):(round(0.5*n)+30)]=0
test_y_t6[round(0.7*n):(round(0.7*n)+5)]=100
test_y_t6[sample(1:n, 13)]=Error
plot(test_y_t6~test_t)

par(mfrow = c(2, 4))

your_function(out_data_y_t,out_data_t,100*10^3)
your_function(box_data_y_t,box_data_t,100)
your_function(test_y_t1,test_t,5000)
your_function(test_y_t2,test_t,2000)
your_function(test_y_t3,test_t,2000)
your_function(test_y_t4,test_t,1500)
your_function(test_y_t5,test_t,1000)
your_function(test_y_t6,test_t,5000)

##### What We'll Run for Grading #####
# The example data for y_t and t will change.

### Robustness/Error Tolerance ###
maxcap = 10; y_t = c(1:3,rep(NA,7)); t = 1:10; 
tryCatch(your_function(y_t,t,maxcap),error=function(e) "error")
maxcap = 10; y_t = c(1:3,sample(c(rep("a",5),rep(NA,5)),7)); t = 1:10; 
tryCatch(your_function(y_t,t,maxcap),error=function(e) "error")
# and other examples.

### Accuracy ###
maxcap = 15; y_t = 1:10; t = 1:10; trueTime = 14
# some loss function l(your_function(y_t,t,maxcap),trueTime)
# square-error loss:
(your_function(y_t,t,maxcap) - trueTime)^2
# non-symmetric square-error loss:
if(trueTime >= your_function(y_t,t,maxcap)) {
  (trueTime - your_function(y_t,t,maxcap))^2
} else {
  Inf
}  

### Speed ###
maxcap=2*10^5
y_t = 1:(10^5);  y_t[sample(1:10^5,10)] = NA; y_t[sample(1:10^5,10)] = 0; 
t = 1:(10^5);

codetime = rep(0,10)
Examplecodetime = rep(0,10)
for(i in 1:10) {
  start=Sys.time()
  output = your_function(y_t,t,maxcap) 
  end=Sys.time()
  codetime[i] = as.numeric(end-start)
  #start=Sys.time()
  #output = Example_function(y_t,t,maxcap) 
  #end=Sys.time()
  #Examplecodetime[i] = as.numeric(end-start)
  
}
mean(codetime)
0.1178642
mean(Examplecodetime)
0.2083678

#0.96s€
### Scalability  ###
codetime = 1:6; maxcap = 10^7; Exampletime = 1:6
for(i in 1:6) {
  start=Sys.time()
  y_t = 1:(10^i); t = 1:(10^i);
  output = your_function(y_t,t,maxcap) 
  end=Sys.time()
  codetime[i] = as.numeric(end-start)
  start=Sys.time()
  y_t = 1:(10^i); t = 1:(10^i);
  output = Example_function(y_t,t,maxcap) 
  end=Sys.time()
  Exampletime[i] = as.numeric(end-start)
}
plot(1:6,log(codetime,10),pch = 15,col='red', cex=2)
points(1:6,log(Exampletime,10),pch = 15,col='green', cex=2)
€