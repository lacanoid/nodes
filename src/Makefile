all: install

run: netty-login
	./netty-login

install: netty-login
	install netty-login ../bin

netty-login: netty-login.c
	cc netty-login.c -o netty-login

