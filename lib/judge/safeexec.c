/*
 safeexec
 Executar um comando num ambiente protegido
 pbv, 1999-2000
 alterado por cassio@ime.usp.br 2003-2008

 esse programa precisa estar instalado setuid root
 $ gcc -Wall -march=i386 -o safeexec safeexec.c
 $ chown root.root safeexec
 $ chmod 4555 safeexec
*/
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <sys/resource.h>
#include <signal.h>
#include <time.h>

#include <string.h>
#include <errno.h>

/* tempo de erro entre o sinal e o estouro no caso de time-limit */
#define EPSILON 0.01

#define MBYTE  (1024*1024)

int child_pid;          /* pid of the child process */

struct rlimit cpu_timeout = {5,5};    		/* max cpu time (seconds) */
struct rlimit max_nofile = {64,64};    		/* max number of open files */
struct rlimit max_fsize = {64*MBYTE,64*MBYTE};    /* max filesize */

struct rlimit max_stack = {128*MBYTE, 128*MBYTE};     /* max stack size */
struct rlimit max_data  = {128*MBYTE, 128*MBYTE};     /* max data segment size */
struct rlimit max_core  = {0, 0};                 /* max core file size */
struct rlimit max_rss   = {128*MBYTE, 128*MBYTE};     /* max resident set size */

struct rlimit max_processes = {64,64}; /* max number of processes */


int real_timeout = 30;                 /* max real time (seconds) */

int dochroot = 1, st=1;

#define BUFFSIZE 256
char rootdir[BUFFSIZE], saida[BUFFSIZE], entrada[BUFFSIZE], erro[BUFFSIZE];

/* alarm handler */
void handle_alarm(int sig) {
  fprintf(stderr, "timed-out (realtime) after %d seconds\n", real_timeout);
  fflush(stderr);
//  fprintf(stdout, "timed-out (realtime) after %d seconds\n", real_timeout);
//  fflush(stdout);
  kill(child_pid,9);   /* kill child */
  exit(3);
}

int user, group;
const char vers[] = "1.3.1";

void usage(int argc, char **argv) {
  fprintf(stderr, "safeexec version %s\nusage: %s [ options ] cmd [ arg1 arg2 ... ]\n", vers, argv[0]);
  fprintf(stderr, "available options are:\n");
  fprintf(stderr, "\t-c <max core file size> (default: %d)\n", 
	  (int) max_core.rlim_max);
  fprintf(stderr, "\t-f <max file size> (default: %d)\n", 
	  (int) max_fsize.rlim_max);
  fprintf(stderr, "\t-F <max number of files> (default: %d)\n", 
	  (int) max_nofile.rlim_max);
  fprintf(stderr, "\t-d <max process DATA segment> (default: %d bytes)\n",
	  (int) max_data.rlim_max);
  fprintf(stderr, "\t-s <max process STACK segment> (default: %d bytes)\n",
	  (int) max_stack.rlim_max);
  fprintf(stderr, "\t-m <max process RSS> (default: %d bytes)\n",
	  (int) max_rss.rlim_max);
  fprintf(stderr, "\t-u <max number of child procs> (default: %d)\n",
	  (int) max_processes.rlim_max);
  fprintf(stderr, "\t-t <max cpu time> (default: %d secs)\n",
	  (int) cpu_timeout.rlim_max);
  fprintf(stderr, "\t-T <max real time> (default: %d secs)\n",
	  (int) real_timeout);
  fprintf(stderr, "\t-R <root directory> (default: cwd)\n");
  fprintf(stderr, "\t-n <chroot it?> (default: %d)\n", dochroot);
  fprintf(stderr, "\t-i <standard input file> (default: not defined)\n");
  fprintf(stderr, "\t-o <standard output file> (default: not defined)\n");
  fprintf(stderr, "\t-e <standard error file> (default: not defined)\n");
  fprintf(stderr, "\t-U <user id> (default: %d)\n", user);
  fprintf(stderr, "\t-G <group id> (default: %d)\n", group);
  fprintf(stderr, "\t-p <show spent time?> (default: %d)\n", st);
/*******Note that currently Linux does not support memory usage limits********/
}

int main(int argc, char **argv) { 
  int status, opt, ret;
  time_t ini;
  struct stat sstat;
  double dt;

  entrada[0] = saida[0] = erro[0] = rootdir[0] = 0;

  if(argc>1 && !strcmp("--help", argv[1])) {
    usage(argc,argv);
    exit(5);
  }

  user = group = 65534;

  /* parse command-line options */
  getcwd(rootdir, BUFFSIZE);  /* default: use cwd as rootdir */
  while( (opt=getopt(argc,argv,"c:d:m:f:F:s:t:T:u:n:i:o:e:R:G:U:p")) != -1 ) {
    switch(opt) {
    case 'c': max_core.rlim_max = max_core.rlim_cur = atoi(optarg);
      break;
    case 'f': max_fsize.rlim_max = max_fsize.rlim_cur = atoi(optarg);
      break;
    case 'F': max_nofile.rlim_max = max_nofile.rlim_cur = atoi(optarg);
      break;
    case 'd': max_data.rlim_max = max_data.rlim_cur = atoi(optarg);
      break;
    case 'm': max_rss.rlim_max = max_rss.rlim_cur = atoi(optarg);
      break;
    case 's': max_stack.rlim_max = max_stack.rlim_cur = atoi(optarg);
      break;
    case 't': cpu_timeout.rlim_max = cpu_timeout.rlim_cur = atoi(optarg);
      break;
    case 'T': real_timeout = atoi(optarg);
      break;
    case 'u': max_processes.rlim_max = max_processes.rlim_cur = atoi(optarg);
      break;
    case 'U': user = atoi(optarg);
      break;
    case 'G': group = atoi(optarg);
      break;
    case 'R': strncpy(rootdir, optarg, 255);  /* root directory */
              rootdir[255]=0;
      break;
    case 'i': strncpy(entrada, optarg, 255);
              rootdir[255]=0;
      break;
    case 'o': strncpy(saida, optarg, 255);
              rootdir[255]=0;
      break;
    case 'e': strncpy(erro, optarg, 255);
              rootdir[255]=0;
      break;
    case 'n': dochroot = atoi(optarg);
      break;
    case 'p': st = atoi(optarg);
      break;
    case '?': usage(argc,argv);
      exit(5);
    }
  }

  if(optind >= argc) {  /* no more arguments */
    usage(argc,argv);
    exit(5);
  }

  /* change the root directory (ZP: and working dir, in not root)*/
  if(rootdir[0] && chdir(rootdir)) { 
    fprintf(stderr,"%s\n",strerror(errno));
    fprintf(stderr,"%s: unable to change directory to %s\n",
	    argv[0], rootdir); 
    exit(4); 
  } 

  if(dochroot && chroot(rootdir)) { 
    fprintf(stderr,"%s\n",strerror(errno));
    fprintf(stderr,"%s: unable to change root directory to %s\n",
	    argv[0], rootdir); 
    exit(4); 
  } 

  stat(".", &sstat);
  if(user == -1)
    user = (int) sstat.st_uid;
  if(group == -1)
    group = (int) sstat.st_gid;  
  if(user == 0 || group == 0) {
    fprintf(stderr, "I cannot execute safeexec as unprivileged root or in a directory with root as owner (or group)\n");
    exit(4);
  }

  /* change the group id to 'nobody' */
  if(setgid(group)<0) {
    fprintf(stderr,"%s\n",strerror(errno));
    fprintf(stderr, "%s: unable to change gid to %d\n", argv[0], group);
    exit(4);
  }
  /* change the user id to 'nobody' */
  if(setuid(user)<0) {
    fprintf(stderr,"%s\n",strerror(errno));
    fprintf(stderr, "%s: unable to change uid to %d\n", argv[0], user);
    exit(4);
  }
  
  time(&ini);
  if((child_pid=fork())) { 
    struct rusage uso;
    /* ------------------- parent process ----------------------------- */
    /* set this limit also for parent */
    setrlimit(RLIMIT_CORE, &max_core);

    if(real_timeout > 0) {
      alarm(real_timeout);   /* set alarm and wait for child execution */
      signal(SIGALRM, handle_alarm);
    }
    wait(&status);

    getrusage(RUSAGE_CHILDREN, &uso);
    dt = uso.ru_utime.tv_sec+(double)uso.ru_utime.tv_usec/1000000.0+
         uso.ru_stime.tv_sec+(double)uso.ru_stime.tv_usec/1000000.0;
//    printf("user runnning time: %.4lf\n",uso.ru_utime.tv_sec+(double)uso.ru_utime.tv_usec/1000000.0); 
//    printf("system runnning time: %.4lf\n",uso.ru_stime.tv_sec+(double)uso.ru_stime.tv_usec/1000000.0); 
//    printf("total runnning time: %.4lf\n",dt); 

    if (dt + EPSILON >= cpu_timeout.rlim_max) {
//      printf ("utsec=%d utusec=%d stsec=%d stusec=%d\n", uso.ru_utime.tv_sec, uso.ru_utime.tv_usec, uso.ru_stime.tv_sec, uso.ru_stime.tv_usec);
      fprintf(stderr, "timed-out (cputime) after %d seconds\n", (int) cpu_timeout.rlim_max);
      fflush(stderr);
//      fprintf(stdout, "timed-out (cputime) after %d seconds\n", (int) cpu_timeout.rlim_max);
//      fflush(stdout);
      exit(3);
    }

    // check if child got an uncaught signal error & reproduce it in parent
    if(WIFSIGNALED(status))  {
      fprintf (stderr, "safeexec: RUN-TIME SIGNAL REPORTED BY THE PROGRAM %s: %d\n", argv[optind], WTERMSIG(status));
      fflush(stderr);
//      raise(WTERMSIG(status));
      exit(2);
    }

    if(WIFEXITED(status)) {
      if(WEXITSTATUS(status)) {
	ret = WEXITSTATUS(status)+10;
	fprintf (stderr, "safeexec: PROGRAM EXITED WITH NONZERO CODE %s: %d\n",
		 argv[optind], ret-10);
      } else ret = 0;
    } else {
      fprintf (stderr, "safeexec: PROGRAM TERMINATED ABNORMALLY %s\n",
	       argv[optind]);
      ret = 9;
    }

    // otherwise just report the exit code:
    if (st) fprintf (stderr, "safeexec: TOTAL TIME RUNNING %s: %us\n", argv[optind], (unsigned int) (time(NULL)-ini));
    exit(ret);
  } else {
    /* ------------------- child process ------------------------------ */
    if (saida[0]) freopen(saida, "w", stdout);
    if (erro[0]) freopen(erro, "w", stderr);
    if (entrada[0]) freopen(entrada, "r", stdin);

    /* attempt to change the hard limits */
    /*******Note that currently Linux does not support memory usage limits********/
    if( setrlimit(RLIMIT_CPU, &cpu_timeout) /*|| 
	setrlimit(RLIMIT_DATA, &max_data) ||
	setrlimit(RLIMIT_STACK, &max_stack) ||
	setrlimit(RLIMIT_CORE, &max_core) ||
	setrlimit(RLIMIT_RSS, &max_rss) ||
	setrlimit(RLIMIT_FSIZE, &max_fsize) ||
	setrlimit(RLIMIT_NOFILE, &max_nofile) ||
	setrlimit(RLIMIT_NPROC, &max_processes)*/) {
      fprintf(stderr,"%s\n",strerror(errno));
      fprintf(stderr, "%s: can't set hard limits\n", argv[0]);
      exit(6);
    }

    /* attempt to exec the child process */
    if(execv(argv[optind],&argv[optind]) < 0) {
      fprintf(stderr,"%s\n",strerror(errno));
      fprintf(stderr, "%s: unable to exec %s\n", argv[0], argv[optind]);
      exit(6);
    } 
  }
  return 0;
}
