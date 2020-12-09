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
  exists_flag = 0
  functions.list  <-  RcppDeepState::deepstate_get_function_body(path)
  fun_names <- unique(functions.list$funName)
  for(f in fun_names){
    honggfuzz.fun.path <- file.path(test_path,f,paste0("HonggFuzz_",f))
    honggfuzz.harness.path <- file.path(honggfuzz.fun.path,paste0(f,"_DeepState_TestHarness"))
    input_dir <- file.path(honggfuzz.fun.path,"honggfuzz_inputs")
    inputs.list <- Sys.glob(file.path(input_dir,"*"))
    if(!dir.exists(honggfuzz.fun.path)){
      exists_flag = 1
      dir.create(honggfuzz.fun.path,showWarnings = FALSE)
    }
    function.path <- file.path(test_path,f)
    harness.path <-  file.path(function.path,paste0(f,"_DeepState_TestHarness.cpp"))
    makefile.path <- file.path(function.path,"Makefile")
    if(file.exists(harness.path) && file.exists(makefile.path) ){
      executable <- gsub(".cpp$","",harness.path)
      object <- gsub(".cpp$",".o",harness.path)
      o.logfile <- file.path(honggfuzz.fun.path,paste0("/",f,"_log"))
      logfile <-  file.path(honggfuzz.fun.path,paste0("/honggfuzz_",f,"_log"))
      output_dir <- file.path(honggfuzz.fun.path,paste0("/honggfuzz_",f,"_output"))
      if(!dir.exists(output_dir)) {
        dir.create(output_dir,showWarnings = FALSE)
      }
      if(!dir.exists(input_dir)) {
        dir.create(input_dir,showWarnings = FALSE)
      }

      harness_lines <- readLines(harness.path,warn=FALSE)
      harness_lines <- gsub("#include <fstream>","#include <fstream>\n#include <ctime>",harness_lines,fixed=TRUE)
      harness_lines <- gsub("RInside R;","RInside R;\n  std::time_t t = std::time(0);",harness_lines,fixed=TRUE)
      k <- nc::capture_all_str(harness_lines,
                               "qs::c_qsave","\\(",
                               save=".*",",\"",l=".*","\"")
      for(i in seq_along(k$l)){
        harness_lines <- gsub(paste0("\"",k$l[i],"\""),paste0(gsub(".qs","",basename(k$l[i])),"_t"),harness_lines,fixed=TRUE)
        harness_lines <- gsub(paste0("qs::c_qsave(",gsub(".qs","",basename(k$l[i]))),paste0("std::string ",gsub(".qs","",basename(k$l[i])),"_t = ","\"",dirname(dirname(k$l[i])),
                                                                                            "/",basename(honggfuzz.fun.path),"/honggfuzz_inputs/\" + std::to_string(t) + \"_",basename(k$l[i]),"\"",";\n  qs::c_qsave(",gsub(".qs","",basename(k$l[i]))),harness_lines,fixed=TRUE)
      }
      #print(honggfuzz..fun.path)
      harness.honggfuzz <- file.path(honggfuzz.fun.path,basename(harness.path))
      file.create(harness.honggfuzz,recursive=TRUE)
      cat(harness_lines, file=harness.honggfuzz, sep="\n")
     #makefile update
      makefile_lines <- readLines(makefile.path,warn=FALSE)
      makefile_lines <- gsub(paste0("clang++ -g -o ",honggfuzz.fun.path,basename(executable)),paste0("clang++ -g -o ",honggfuzz.harness.path,".honggfuzz"),makefile_lines,fixed=TRUE)
      makefile_lines <- gsub("clang++","$(CXX)",makefile_lines,fixed=TRUE)
      makefile_lines <- gsub("-ldeepstate","-ldeepstate_HFUZZ",makefile_lines,fixed=TRUE)
     makefile_lines <- gsub("deepstate-master/build","deepstate-master/build_honggfuzz",makefile_lines,fixed=TRUE)
      HONGGFUZZ_HOME = file.path(deepstate,"honggfuzz")
      Sys.setenv(HONGGFUZZ_HOME=HONGGFUZZ_HOME)
      makefile_lines <- gsub("R_HOME=",paste0("export HONGGFUZZ_HOME=",HONGGFUZZ_HOME,"\nCXX = ${HONGGFUZZ_HOME}/hfuzz_cc/hfuzz-clang++\nHONGG_FUZZ=${HONGGFUZZ_HOME}/honggfuzz \nR_HOME="),makefile_lines,fixed=TRUE)
      makefile_lines <- gsub(o.logfile,logfile,makefile_lines,fixed=TRUE)
     makefile_lines <- gsub(".hongg.cpp",".cpp",makefile_lines,fixed=TRUE)
      makefile_lines <- gsub(function.path,honggfuzz.fun.path,makefile_lines,fixed=TRUE)
     input_dir <- file.path(function.path,"inputs")
      makefile.hongg<- file.path(honggfuzz.fun.path,"Makefile")

      file.create(makefile.hongg,recursive=TRUE)
      cat(makefile_lines, file=makefile.hongg, sep="\n")
      compile_line <-paste0("cd ",honggfuzz.fun.path," && rm -f *.o && make")
      execution_line <- paste0("cd ",honggfuzz.fun.path," && ${HONGGFUZZ_HOME}/honggfuzz -t 2000 -i ",input_dir," -o ",output_dir," -- ",basename(executable)," ___FILE___")
      if(exists_flag == 1){
        print(compile_line)
        print(execution_line)
        system(compile_line)
        system(execution_line)
      }
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
