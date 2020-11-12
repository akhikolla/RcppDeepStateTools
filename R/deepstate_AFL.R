##' @title  creates afl fuzzer specific make for given functions in package
##' @param path to the package to test
##' @export
deepstate_pkg_create_AFL<-function(path){
  path <- normalizePath(path,mustWork=TRUE)
  #$AFL_HOME/afl-fuzz -i foo -o afl_Runlen -- ./Runlen_AFL --input_test_file @@ --no_fork --abort_on_fail
  insts.path <- normalizePath("~",mustWork=TRUE)
  deepstate <- file.path(insts.path,".RcppDeepState")
  deepstate.path <- file.path(deepstate,"deepstate-master")
  inst_path <- file.path(path, "inst")
  test_path <- file.path(inst_path,"testfiles")
  if(!(file.exists(file.path(insts.path,".RcppDeepState/deepstate-master/build/libdeepstate32.a")) &&
       file.exists(file.path(insts.path,".RcppDeepState/deepstate-master/build/libdeepstate.a")))){
    #RcppDeepState::deepstate_make_run()
  }
  AFL.a <- file.path(deepstate.path,"build_afl/libdeepstate_AFL.a")
  if(!file.exists(AFL.a)){
    #deepstate_make_afl()
  }
  functions.list  <-  RcppDeepState::deepstate_get_function_body(path)
  fun_names <- unique(functions.list$funName)
  for(f in fun_names){
    function.path <- file.path(test_path,f)
    afl.fun.path <- file.path(test_path,f,paste0("AFL_",f))
    afl.harness.path <- file.path(afl.fun.path,paste0(f,"_DeepState_TestHarness"))
    dir.create(afl.fun.path,showWarnings = FALSE)
    harness.path <-  file.path(function.path,paste0(f,"_DeepState_TestHarness.cpp"))
    makefile.path <- file.path(function.path,"Makefile")
    if(file.exists(harness.path) && file.exists(makefile.path) ){
      executable <- gsub(".cpp$","",harness.path)
      object <- gsub(".cpp$",".o",harness.path)
      o.logfile <- file.path(afl.fun.path,paste0(f,"_log"))
      logfile <-  file.path(afl.fun.path,paste0("afl_",f,"_log"))
      output_dir <- file.path(afl.fun.path,paste0("afl_",f,"_output"))
        dir.create(output_dir,showWarnings = FALSE)
      input_dir <- file.path(afl.fun.path,"afl_inputs")
      dir.create(input_dir,showWarnings = FALSE)
      #writing harness file
      harness_lines <- readLines(harness.path,warn=FALSE)
      harness_lines <- gsub("#include <fstream>","#include <fstream>\n#include <ctime>",harness_lines,fixed=TRUE)
      harness_lines <- gsub("RInside R;",paste0("RInside R;\n  std::time_t t = std::time(0);\n  std::string time =", "\"",
                            input_dir,"/","\""," + std::to_string(t)",";\n  mkdir(time.c_str(),S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH)")
                            ,harness_lines,fixed=TRUE)
      k <- nc::capture_all_str(harness_lines,
                               "qs::c_qsave","\\(",
                               save=".*",",\"",l=".*","\"")
      for(i in seq_along(k$l)){
        harness_lines <- gsub(paste0("\"",k$l[i],"\""),paste0(gsub(".qs","",basename(k$l[i])),"_t"),harness_lines,fixed=TRUE)
        harness_lines <- gsub(paste0("qs::c_qsave(",gsub(".qs","",basename(k$l[i]))),paste0("std::string ",gsub(".qs","",basename(k$l[i])),"_t = ","\"",dirname(dirname(k$l[i])),
                                                                                            "/",basename(afl.fun.path),"/afl_inputs/ \" + std::to_string(t) + \"/",basename(k$l[i]),"\"",";\n  qs::c_qsave(",gsub(".qs","",basename(k$l[i]))),harness_lines,fixed=TRUE)
      }
      print(afl.fun.path)
      ##makefileupdate
      harness.afl <- file.path(afl.fun.path,basename(harness.path))
      file.create(harness.afl,recursive=TRUE)
      cat(harness_lines, file=harness.afl, sep="\n")
      makefile_lines <- readLines(makefile.path,warn=FALSE)
      makefile_lines <- gsub(o.logfile,logfile,makefile_lines,fixed=TRUE)
      makefile_lines <- gsub(function.path,afl.fun.path,makefile_lines,fixed=TRUE)
      makefile_lines <- gsub(paste0("clang++ -g -o ",afl.fun.path,basename(executable)),paste0("clang++ -g -o ",afl.harness.path,".afl"),makefile_lines,fixed=TRUE)
      makefile_lines <- gsub("clang++","$(CXX)",makefile_lines,fixed=TRUE)
      makefile_lines <- gsub("-ldeepstate","-ldeepstate_AFL",makefile_lines,fixed=TRUE)
      makefile_lines <- gsub("deepstate-master/build","deepstate-master/build_afl",makefile_lines,fixed=TRUE)
      AFL_HOME = file.path(deepstate,"afl-2.52b")
      Sys.setenv(AFL_HOME=AFL_HOME)
      input_dir <- file.path(function.path,"inputs")
      makefile_lines <- gsub("R_HOME=",paste0("export AFL_HOME=",AFL_HOME,"\nCXX=${AFL_HOME}/afl-clang++\nAFL_FUZZ=${AFL_HOME}/afl-fuzz\nR_HOME="),makefile_lines,fixed=TRUE)
      #makefile_lines <- gsub(executable,paste0(executable,".afl"),makefile_lines,fixed=TRUE)
      #makefile_lines <- gsub(paste0("./",basename(executable)," --fuzz"),paste0("${AFL_HOME}/afl-fuzz -o ",output_dir," -m 150 -t 2000 -i ", input_dir," -- ",executable,".afl"),makefile_lines,fixed=TRUE)
      #makefile_lines <- gsub("--output_test_dir.*> /dev/null","",makefile_lines)
      makefile_lines <- gsub(".afl.cpp",".cpp",makefile_lines,fixed=TRUE)
      #makefile_lines <- gsub(paste0("./",executable),paste0("./",executable,".afl"),makefile_lines,fixed=TRUE)
      makefile.afl <- file.path(afl.fun.path,"Makefile")
      file.create(makefile.afl,recursive=TRUE)
      cat(makefile_lines, file=makefile.afl, sep="\n")
      #file.remove(object)
      #file.remove(executable)
      compile_line <-paste0("cd ",afl.fun.path," && rm -f *.o && make")
      print(compile_line)
      system(compile_line)
      execution_line <- paste0("cd ",afl.fun.path," && ${AFL_HOME}/afl-fuzz -i ", input_dir," -o ",output_dir," -m 150 -t 2000+ -- ./",basename(executable),
                               " --input_test_file @@ --no_fork")
      print(execution_line)
      system(execution_line)
      #deepstate_fuzz_fun(function.path)

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

