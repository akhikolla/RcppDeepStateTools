##' @title  creates Eclipser specific make files for given functions in package
##' @param path to the package to test
##' @export
deepstate_pkg_create_Eclipser<-function(path){
  path <- normalizePath(path,mustWork=TRUE)
  insts.path <- normalizePath("~",mustWork=TRUE)
  deepstate <- file.path(insts.path,".RcppDeepState")
  deepstate.path <- file.path(deepstate,"deepstate-master")
  inst_path <- file.path(path, "inst")
  test_path <- file.path(inst_path,"testfiles")
  if(!(file.exists(file.path(insts.path,".RcppDeepState/deepstate-master/build/libdeepstate32.a")) &&
       file.exists(file.path(insts.path,"/.RcppDeepState/deepstate-master/build/libdeepstate.a")))){
    RcppDeepState::deepstate_make_run()
  }
  dll <- file.path(deepstate,"Eclipser/build/Eclipser.dll")
  if(!file.exists(dll)){
    deepstate_make_eclipser()
  }
  functions.list  <-  RcppDeepState::deepstate_get_function_body(path)
  fun_names <- unique(functions.list$funName)
  for(f in fun_names){
    function.path <- file.path(test_path,f)
    harness.path <-  file.path(function.path,paste0(f,"_DeepState_TestHarness.cpp"))
    makefile.path <- file.path(function.path,"Makefile")
    executable <- gsub(".cpp$","",harness.path)
    object <- gsub(".cpp$",".o",harness.path)
    o.logfile <- paste0(function.path,"/",f,"_log")
    logfile <-  paste0(function.path,"/eclipser_",f,"_log")
    if(file.exists(harness.path) && file.exists(makefile.path) && file.exists(executable)){
      eclipser_out <- file.path(function.path,"eclipser_out")
      dir.create(eclipser_out,showWarnings = FALSE)
      #compile_line <- paste0("cd ",function.path," && deepstate-eclipser ./",basename(executable)," -o eclipser_out --timeout 30")
      executable <- gsub(".cpp$","",harness.path)
      object <- gsub(".cpp$",".o",harness.path)
      o.logfile <- paste0(function.path,"/",f,"_log")
      makefile_lines <- readLines(makefile.path,warn=FALSE)
      makefile_lines <- gsub("R_HOME=",paste0("export ECLIPSER_HOME=",insts.path,"/.RcppDeepState/Eclipser/build\nR_HOME="),makefile_lines,fixed=TRUE)
      makefile_lines <- gsub(o.logfile,logfile,makefile_lines,fixed=TRUE)
      makefile_lines <- gsub("--output_test_dir.*> /dev/null","",makefile_lines)
      makefile_lines <- gsub("valgrind.* ./","./",makefile_lines)
      makefile_lines <- gsub(paste0("./",basename(executable)," --fuzz"),paste0("deepstate-eclipser ./",basename(executable)," -o eclipser_out --timeout 30"),makefile_lines,fixed=TRUE)
      makefile.eclipser <- file.path(dirname(makefile.path),"Eclipser.Makefile")
      file.create(makefile.eclipser,recursive=TRUE)
      cat(makefile_lines, file=makefile.eclipser, sep="\n")
      compile_line <-paste0("rm -f *.o && make -f ",makefile.eclipser)
      print(compile_line)
      system(compile_line)
    }
  }
}



##' @title  creates Eclipser fuzzer for given functions in package
##' @export
deepstate_make_eclipser <- function(){
  insts.path <- normalizePath("~",mustWork=TRUE)
  deepstate.path <- paste0(insts.path,"/.RcppDeepState")
  master <- file.path(deepstate.path,"deepstate-master")
  system(paste0("cd ", deepstate.path, " ; ","git clone https://github.com/SoftSec-KAIST/Eclipser && cd Eclipser && make"))
  ECLIPSER_HOME = file.path(deepstate.path,"Eclipser/build")
  Sys.setenv(ECLIPSER_HOME=ECLIPSER_HOME)
}
