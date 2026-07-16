# Project examples Makefile
# Stage D: Embed Lua in C

.PHONY: all clean embed_lua

LUA_PKG ?= $(shell pkg-config --cflags --libs lua5.4 2>/dev/null || pkg-config --cflags --libs lua 2>/dev/null || echo "-llua -lm")

all: embed_lua

embed_lua: 05-embed-lua.c
	gcc -Wall -o $@ $< $(LUA_PKG)

clean:
	rm -f embed_lua
