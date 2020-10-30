##' @title  creates afl fuzzer specific make for given functions in package
##' @param path to the package to test
##' @export
deepstate_pkg_create_AFL<-function(path){
  path <- normalizePath(path,mustWork=TRUE)
  insts.path <- normalizePath("~",mustWork=TRUE)
  deepstate <- file.path(insts.path,".RcppDeepState")
  deepstate.path <- file.path(deepstate,"deepstate-master")
  inst_path <- file.path(path, "inst")
  test_path <- file.path(inst_path,"testfiles")
  if(!(file.exists(file.path(insts.path,".RcppDeepState/deepstate-master/build/libdeepstate32.a")) &&
       file.exists(file.path(insts.path,".RcppDeepState/deepstate-master/build/libdeepstate.a")))){
    RcppDeepState::deepstate_make_run()
  }
  AFL.a <- file.path(deepstate.path,"build_afl/libdeepstate_AFL.a")
    if(!file.exists(AFL.a)){
      deepstate_make_afl()
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
        logfile <-  paste0(function.path,"/afl_",f,"_log")
        output_dir <- paste0(function.path,"/afl_",f,"_output")
        makefile_lines <- readLines(makefile.path,warn=FALSE)
        makefile_lines <- gsub(paste0("clang++ -g -o",executable),paste0("clang++ -g -o",executable,".afl"),makefile_lines,fixed=TRUE)
        makefile_lines <- gsub("clang++","$(CXX)",makefile_lines,fixed=TRUE)
        makefile_lines <- gsub("-ldeepstate","-ldeepstate_AFL",makefile_lines,fixed=TRUE)
        makefile_lines <- gsub("deepstate-master/build","deepstate-master/build_afl",makefile_lines,fixed=TRUE)
        AFL_HOME = file.path(deepstate,"afl-2.52b")
        Sys.setenv(AFL_HOME=AFL_HOME)
        makefile_lines <- gsub("R_HOME=",paste0("export AFL_HOME=",AFL_HOME,"\nCXX=${AFL_HOME}/afl-clang++\nAFL_FUZZ=${AFL_HOME}/afl-fuzz\nR_HOME="),makefile_lines,fixed=TRUE)
        makefile_lines <- gsub(o.logfile,logfile,makefile_lines,fixed=TRUE)
        #makefile_lines <- gsub(object,paste0(object,".afl"),makefile_lines,fixed=TRUE)
        makefile_lines <- gsub(executable,paste0(executable,".afl"),makefile_lines,fixed=TRUE)
        makefile_lines <- gsub(paste0("./",basename(executable)," --fuzz"),paste0("${AFL_HOME}/afl-fuzz -o ",output_dir," -m 150 -t 2000 -i ~/.RcppDeepState/deepstate-master/build_afl/ -- ",executable,".afl"),makefile_lines,fixed=TRUE)
        makefile_lines <- gsub("--output_test_dir.*> /dev/null","",makefile_lines)
        makefile_lines <- gsub(".afl.cpp",".cpp",makefile_lines,fixed=TRUE)
        makefile_lines <- gsub(paste0("./",executable),paste0("./",executable,".afl"),makefile_lines,fixed=TRUE)
        makefile.afl <- file.path(dirname(makefile.path),"AFL.Makefile")
        file.create(makefile.afl,recursive=TRUE)
        cat(makefile_lines, file=makefile.afl, sep="\n")
        #file.remove(object)
        #file.remove(executable)
        compile_line <-paste0("rm -f *.o && make -f ",makefile.afl)
        print(compile_line)
        system(compile_line)
      }
    }
  }


##' @title  creates afl fuzzer for given functions in package
##' @export
deepstate_make_afl<-function(){
  insts.path <- normalizePath("~",mustWork=TRUE)
  deepstate.path <- paste0(insts.path,"/.RcppDeepState")
  master <- file.path(deepstate.path,"deepstate-master")
  system(paste0("cd ", deepstate.path, " ; "," wget http://lcamtuf.coredump.cx/afl/releases/afl-latest.tgz && tar -xzvf afl-latest.tgz && rm -rf afl-latest.tgz && cd afl-2.52b",";", "make"))
  build_afl <- file.path(master,"build_afl")
  dir.create(build_afl,showWarnings = FALSE)
  AFL_HOME = file.path(deepstate.path,"afl-2.52b")
  Sys.setenv(AFL_HOME=AFL_HOME)
  system(paste0("cd ", build_afl," ; ","CXX=",AFL_HOME,"/afl-clang++ " ,"CC=", AFL_HOME,"/afl-clang cmake -DDEEPSTATE_AFL=ON ../"," ; ", "make -j4"))
}





