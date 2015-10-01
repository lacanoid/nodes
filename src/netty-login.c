#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <sys/types.h>
#include <pwd.h>
#include <grp.h>

#define NODEJS "nodejs"
#define NODE_PATH "/usr/share/nodes/node_modules"

int main(int argc,char **argv);
void showHelp();
void showError(char *err);

////////////////////////////////////////////////////////////////////////////////

int main(int argc,char **argv) {
  if(argc<2) {
    showHelp(); exit(1);
  };

  char *username = argv[1];
  if(!username || strnlen(username,32)==0) {
    showError("Username must not be blank"); exit(1);
  }

  struct passwd *pw;

  errno = 0;
  int uid = getuid();
  pw = getpwnam(username);
  if(errno) { showError("getpwnam()"); exit(1); }
  if(!pw) {
    showError("Unknown user"); exit(1);
  }
  if(setgid(pw->pw_gid)) {
    showError("Failed to set gid"); exit(1);
  }
  if(initgroups(username,0)) {
    // showError("Failed to initialize groups");
  }
  if(setuid(pw->pw_uid)) {
    showError("Failed to set uid"); exit(1);
  }

  setpgrp(); // create new process group

  // set environment
  setenv("USER",username,1);
  setenv("HOME",pw->pw_dir,1);

  // execute shell
  //  execlp("env","env",0);
  if(uid) {
    // normal user
    execlp(NODEJS,NODEJS,"bin/nodex",NULL);
  } else {
    // superuser
    if(chdir(pw->pw_dir)) { showError("chdir()"); exit(1); }
    setenv("NODE_PATH",NODE_PATH,1);
    execlp(NODEJS,NODEJS,"/usr/sbin/nodex",NULL);
  }
  //execlp(NODEJS,NODEJS,"-e","console.log('Hello, world!')",NULL);
  showError("exec()");
}

void showHelp() {
  showError("Usage: netty-login username");
}

void showError(char *errmsg) {
  if(errno) perror(NULL);
  if(errmsg) fprintf(stderr, "%s\n", errmsg);
}
