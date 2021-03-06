##' @title  run afl on all the packages
##' @param path to the package to test
##' @export
run_AFL<-function(){
  packages <- file.path(system.file("extdata",package="RcppDeepState"),"packages")
  cA.dir <- file.path(system.file("extdata",package="RcppDeepState"),"compileAttributes")
  root.path <- system.file("extdata",package="RcppDeepState")
  packages <- Sys.glob(file.path(cA.dir,"*"))
  for(pkg.i in seq_along(packages)){
    pkg.tar.gz <- packages[[pkg.i]]
  testfiles.vec <- Sys.glob(file.path(pkg.tar.gz,"inst/testfiles/*"))
  cat(sprintf("%4d - %s\n", pkg.i, pkg.tar.gz))
  if(length(testfiles.vec) > 0){
    deepstate_pkg_create_AFL(pkg.tar.gz)
  }
  }
}


valgrind_afl_test <- function(){
  cA.dir <- file.path(system.file("extdata",package="RcppDeepState"),"compileAttributes")
  cA.dir <-normalizePath(cA.dir, mustWork=TRUE)
  root.path <- system.file("extdata",package="RcppDeepState")
  packages <- Sys.glob(file.path(cA.dir,"*"))
  for(pkg.i in seq_along(packages)){
    pkg.tar.gz <- packages[[pkg.i]]
    testfiles.vec <- Sys.glob(file.path(pkg.tar.gz,"inst/testfiles/*"))
    test_path <- file.path(pkg.tar.gz,"inst/testfiles")
    functions.list <-  RcppDeepState::deepstate_get_function_body(pkg.tar.gz)
    cat(sprintf("%4d - %s\n", pkg.i, pkg.tar.gz))
    if(length(testfiles.vec) > 0){
      for(fun in testfiles.vec){
        afl.fun.path <- file.path(test_path,basename(fun),paste0("AFL_",basename(fun)))
        afl.inputs <- Sys.glob(file.path(afl.fun.path,"afl_inputs/*"))
        afl.inputs.path <- file.path(afl.fun.path,"afl_inputs")
        times <- unique(gsub("_.*","",basename(afl.inputs)))
        for(utime in times){
          run_line <- paste0("R -d \"valgrind --xml=yes --xml-file=",file.path(afl.inputs.path,paste0(utime,"_valgrind_log"))," --tool=memcheck --leak-check=yes\" --vanilla --args ",afl.inputs.path,"/",utime," < /home/akhila/RcppDeepStateTest/afl_valgrind_per_function.R")
          print(run_line)
          system(run_line)
          print("valgrind result")
          result = RcppDeepState::deepstate_read_valgrind_xml(file.path(afl.inputs.path,paste0(utime,"_valgrind_log")))
          print(result$logtable)
        }
      }
    }
  }
}


//analyze valgrind log
cA.dir <- file.path(system.file("extdata",package="RcppDeepState"),"compileAttributes")
root.path <- system.file("extdata",package="RcppDeepState")
packages <- Sys.glob(file.path(cA.dir,"*"))
package.afl.valgrind <- list()
for(pkg.i in seq_along(packages)){
  fun.afl.valgrind <- list()
  pkg.tar.gz <- packages[[pkg.i]]
  testfiles.vec <- Sys.glob(file.path(pkg.tar.gz,"inst/testfiles/*"))
  test_path <- file.path(pkg.tar.gz,"inst/testfiles")
  functions.list <-  RcppDeepState::deepstate_get_function_body(pkg.tar.gz)
  cat(sprintf("%4d - %s\n", pkg.i, pkg.tar.gz))
  if(length(testfiles.vec) > 0){
    for(fun in testfiles.vec){
    afl.fun.path <- file.path(test_path,basename(fun),paste0("AFL_",basename(fun)))
    afl.inputs.path <- file.path(afl.fun.path,"afl_inputs") 
    afl.inputs <- Sys.glob(file.path(afl.inputs.path,"*"))
    times <- unique(gsub("_.*","",basename(afl.inputs)))
    for(utime in times){
       log_file <- paste0(afl.inputs.path,"/",basename(utime),"_valgrind_log")
       if(file.exists(log_file)){
        RcppDeepState::deepstate_read_valgrind_xml(log_file) 
      }
     }
   }
  }
}
}
