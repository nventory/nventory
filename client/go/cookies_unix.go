package main

import (
	"os"
	"path"
)

func getCookieFilename(login string) string {
	home := os.Getenv("HOME")
	filename := ".opsdb_cookie"
	if login == autoreg {
		filename += "_" + login
	}
	return path.Join(home, filename)
}
