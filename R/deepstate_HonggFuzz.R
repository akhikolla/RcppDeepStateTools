##' @title  creates hongg fuzzer specific make for given functions in package
##' @param path to the package to test
##' @export
deepstate_pkg_create_HonggFuzz<-function(path){
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
  HF.a <- file.path(deepstate.path,"build_honggfuzz/libdeepstate_HFUZZ.a")
  if(!file.exists(HF.a)){
    deepstate_make__hongg()
  }
  functions.list  <-  RcppDeepState::deepstate_get_function_body(path)
  fun_names <- unique(functions.list$funName)
  for(f in fun_names){
    function.path <- file.path(test_path,f)
    harness.path <-  file.path(function.path,paste0(f,"_DeepState_TestHarness.cpp"))
    makefile.path <- file.path(function.path,"Makefile")
    if(file.exists(harness.path) && file.exists(makefile.path) ){
      executable <- gsub(".cpp$","",harness.path)
      object <- gsub(".cpp$",".o",harness.path)
      o.logfile <- paste0(function.path,"/",f,"_log")
      logfile <-  paste0(function.path,"/hongg_",f,"_log")
      output_dir <- paste0(function.path,"/hongg_",f,"_output")
      input_dir <- file.path(function.path,"inputs")
      #input_dir <- paste0(function.path,"/",f,"_output")
      makefile_lines <- readLines(makefile.path,warn=FALSE)
      makefile_lines <- gsub(paste0("clang++ -g -o",executable),paste0("clang++ -g -o",executable,".hongg"),makefile_lines,fixed=TRUE)
      makefile_lines <- gsub("clang++","$(CXX)",makefile_lines,fixed=TRUE)
      makefile_lines <- gsub("-ldeepstate","-ldeepstate_HFUZZ",makefile_lines,fixed=TRUE)
      makefile_lines <- gsub("deepstate-master/build","deepstate-master/build_honggfuzz",makefile_lines,fixed=TRUE)
      HONGGFUZZ_HOME = file.path(deepstate,"honggfuzz")
      Sys.setenv(HONGGFUZZ_HOME=HONGGFUZZ_HOME)
      makefile_lines <- gsub("R_HOME=",paste0("export HONGGFUZZ_HOME=",HONGGFUZZ_HOME,"\nCXX = ${HONGGFUZZ_HOME}/hfuzz_cc/hfuzz-clang++\nHONGG_FUZZ=${HONGGFUZZ_HOME}/honggfuzz \nR_HOME="),makefile_lines,fixed=TRUE)
      makefile_lines <- gsub(o.logfile,logfile,makefile_lines,fixed=TRUE)
      makefile_lines <- gsub(executable,paste0(executable,".hongg"),makefile_lines,fixed=TRUE)
      makefile_lines <- gsub(paste0("./",basename(executable)," --fuzz"),paste0("${HONGGFUZZ_HOME}/honggfuzz -t 2000 -i ",input_dir," -o ",output_dir," -x -- ",executable,".hongg"," ___FILE___"),makefile_lines,fixed=TRUE)
      makefile_lines <- gsub("--output_test_dir.*> /dev/null","",makefile_lines)
      makefile_lines <- gsub(paste0("./",executable),paste0("./",executable,".hongg"),makefile_lines,fixed=TRUE)
      makefile_lines <- gsub(".hongg.cpp",".cpp",makefile_lines,fixed=TRUE)
      makefile.hongg <- file.path(dirname(makefile.path),"Hongg.Makefile")
      file.create(makefile.hongg,recursive=TRUE)
      cat(makefile_lines, file=makefile.hongg, sep="\n")
      compile_line <-paste0("rm -f *.o && make -f ",makefile.hongg)
      print(compile_line)
      system(compile_line)
    }
  }
}

##' @title  creates Hongg fuzzer for given functions in package
##' @export
deepstate_make_hongg <- function(){
  insts.path <- normalizePath("~",mustWork=TRUE)
  deepstate.path <- file.path(insts.path,".RcppDeepState")
  master <- file.path(deepstate.path,"deepstate-master")
  build_honggfuzz <- file.path(master,"build_honggfuzz")
  dir.create(build_honggfuzz,showWarnings = FALSE)
  HONGGFUZZ_HOME = file.path(deepstate.path,"honggfuzz")
  if(!file.exists(HONGGFUZZ_HOME)){
  system(paste0("cd ", deepstate.path, " ; ","git clone https://github.com/google/honggfuzz && cd honggfuzz && make"))
  }
  Sys.setenv(HONGGFUZZ_HOME=HONGGFUZZ_HOME)
  system(paste0("cd ", build_honggfuzz," ; ","CXX=",HONGGFUZZ_HOME,"/hfuzz_cc/hfuzz-clang++",
                  " CC=",HONGGFUZZ_HOME,"/hfuzz_cc/hfuzz-clang cmake -DDEEPSTATE_HONGGFUZZ=ON ../"," ; ", "make"))
}
