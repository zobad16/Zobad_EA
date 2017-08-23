makeCacheMatrix<-function(x=matrix())
{
  i   <-  NULL
  set <-  function(y){
    x <<- y
    i <<-  NULL
  }
  get <- function() x
  setInverse <- function(inv) i <<- inv
  getInverse <- function()    i
  list(set = set , get = get,
       setInverse = setInverse,
       getInverse = getinverse)
}

cacheSolve <- function(x,...)
{
  i <- x$getInverse()
  if(!is.null(i) && x$getInverse()==x$get()){
    message("Retrieving Cached Data")
    return(i)
  }
  data <- x$get()
  i <- solve(data, ...)
  x$setInverse(i)
  
}