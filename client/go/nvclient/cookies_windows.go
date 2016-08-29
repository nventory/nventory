package nvclient

import "path"

func getCookieFilename() string {
	home := "C:\\yp"
	return path.Join(home, ".opsdb_cookie")
}
