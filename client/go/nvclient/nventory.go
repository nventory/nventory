package nvclient

import (
	"crypto/tls"
	"errors"
	"fmt"
	"log"
	"net/http"
	"net/http/cookiejar"
	"net/url"
	"os/user"
	"regexp"
	"strings"
	"time"

	"golang.org/x/net/publicsuffix"

	logger "github.com/atclate/go-logger"

	"bufio"
	"os"
)

const autoreg = "autoreg"

var autoreg_password = "REPLACE_ME_WITH_AUTOREG_PASSWORD"

type NventoryDriver struct {
	Server        string
	Input         *bufio.Reader
	httpClientMap map[string]*http.Client
}

func (d NventoryDriver) GetServer() string {
	return d.Server
}

func getSetFromFlags(sc *SetCommands) map[string]string {
	fs := make(map[string]string, 0)
	for _, ss := range sc.setValueFlags.value {
		for _, s := range strings.Split(ss, ",") {
			splits := strings.Split(s, "=")
			if len(splits) == 2 {
				fs[splits[0]] = splits[1]
			} else {
				log.Fatalf("= required in set flags. (%v doesn't contain '='", s)
			}
		}
	}
	return fs
}

func (f *NventoryDriver) passwordCallback(username string) *http.Client {
	if f.httpClientMap == nil {
		f.httpClientMap = make(map[string]*http.Client, 0)
	}
	// Check if client is already initialized.
	httpClient := f.httpClientMap[username]

	if httpClient != nil {
		return httpClient
	}
	httpClient, err := f.GetHttpClientFor(username, func(username string) string {
		if username == autoreg {
			return autoreg_password
		} else {
			_, p, _ := PromptUserLogin(username, bufio.NewReader(os.Stdin))
			return p
		}
	})
	if err != nil {
		log.Fatal("Unable to initialize HTTP Client")
	}
	f.httpClientMap[username] = httpClient
	return httpClient
}

func (f *NventoryDriver) Search(object_type string, conditions map[string][]string, includes map[string][]string, fields []string) (Result, error) {
	logger.Debug.Println("searching in nventory for node with search subcommand ", searchCommand.destFlags.ToString())
	nv := NewNvClient(f.GetServer(), autoreg, f.passwordCallback, f.Input)
	return nv.GetObjects(object_type, conditions, includes)
}

func (f *NventoryDriver) Set(object_type string, conditions map[string][]string, includes map[string][]string, set map[string]string) (string, error) {
	logger.Debug.Println("setting in nventory for node with search subcommand ", searchCommand.destFlags.ToString())
	nv := NewNvClient(f.GetServer(), autoreg, f.passwordCallback, f.Input)
	u, _ := user.Current()
	return nv.SetObjects("nodes", conditions, includes, set, u.Username)
}

func (f *NventoryDriver) GetAllSubsystemNames(objectType string) ([]string, error) {
	logger.Debug.Println("searching in nventory for all subsystemnames with search subcommand ", objectType)
	nv := NewNvClient(f.GetServer(), autoreg, f.passwordCallback, f.Input)
	return nv.GetAllSubsystemNames(objectType)
}

func (f *NventoryDriver) GetAllFields(object_type string, command map[string][]string, includes map[string][]string, flags []string) (Result, error) {

	client, err := f.GetHttpClientFor(autoreg, func(username string) string {
		if username == autoreg {
			return autoreg_password
		} else {
			_, p, _ := PromptUserLogin(username, bufio.NewReader(os.Stdin))
			return p
		}
	})

	fields, err := f.GetAllSubsystemNames(object_type)
	if err != nil {
		return nil, err
	}
	m := make(map[string][]string, 0)
	m["include"] = fields
	u := getSearchUrl(f.GetServer(), object_type, command, includes)

	resp, _ := client.Get(u)

	logger.Debug.Println(fmt.Sprintf("URL: %v", u))

	responseStr, err := readResponseBody(resp.Body)
	if err != nil {
		log.Fatal("Unable to read response body.")
	}

	return GetResultsFromResponse(responseStr)
}

func intersection(allSubsystemNames []string, fields []string) []string {
	result := make([]string, 0)
	for _, name := range allSubsystemNames {
		for _, inc := range fields {
			if strings.Contains(name, inc) || strings.Contains(inc, name) {
				result = append(result, inc)
			}
		}
	}
	return result
}

func getSearchUrl(hostname string, object_type string, searchCommand map[string][]string, includes map[string][]string) string {
	// start organizing commands issued
	values := url.Values{}
	for k, v := range searchCommand {
		values = mergeMapOfStringArrays(values, Separate(v, k))
	}

	for k, v := range includes {
		m := make(map[string][]string, 0)
		for _, f := range v {

			var fieldsRegex = regexp.MustCompile(`([^[]+)\[.+\]`)
			if fieldsRegex.MatchString(f) {
				// field[subfield]
				fieldName := fieldsRegex.FindAllStringSubmatch(f, -1)
				val := []string{""}
				if strings.Contains(f, "[tags]") {
					val = append(val, "tags")
				}
				m[k+"["+fieldName[0][1]+"]"] = val
			} else {
				// field
				m[k+"["+f+"]"] = []string{""}
			}
		}
		values = mergeMapOfStringArrays(values, m)
	}

	return fmt.Sprintf("%v/%v.xml?%v", hostname, object_type, values.Encode())
}

func mergeMapOfStringArrays(a map[string][]string, b map[string][]string) map[string][]string {
	result := make(map[string][]string)
	for k, v := range a {
		result[k] = v
	}
	for k, v := range b {
		result[k] = append(result[k], v...)
	}
	return result
}

func Separate(hashStrings []string, prefix string) map[string][]string {
	hash := make(map[string][]string)
	// name[key]=value1,map[key]=value2
	for _, val := range hashStrings {
		values := strings.Split(val, ",")
		// name[key]=value
		for _, value := range values {
			pair := strings.Split(value, "=")
			key := ""
			value := ""
			if len(pair) == 2 {
				key = fmt.Sprintf("%v%v", prefix, search_shortcuts.Replace(pair[0]))
				value = pair[1]
			} else if len(pair) == 1 {
				key = "name"
				value = pair[0]
			} else {
				break
			}

			hash[key] = []string{value}
		}
	}
	return hash
}

func (f *NventoryDriver) GetHttpClientFor(login string, passwordCallback func(username string) string) (*http.Client, error) {
	// Load from cookie file
	cookie_file := getCookieFilename(login)

	var httpClient *http.Client
	cookies, err := loadCookies(cookie_file)
	if err == nil && len(cookies) > 0 {
		logger.Debug.Printf("Loading %v cookie(s) from file (%v)", len(cookies), cookie_file)
		httpClient = createBlankHttpClient()
		cookiesMap := make(map[url.URL][]*http.Cookie, 0)
		for _, c := range cookies {
			u := url.URL{
				Scheme: "http",
				Host:   c.Domain,
			}
			cookieList := cookiesMap[u]
			if cookieList == nil {
				cookieList = make([]*http.Cookie, 0)
			}
			cookieList = append(cookieList, c)
			cookiesMap[u] = cookieList
		}
		for k, c := range cookiesMap {
			logger.Debug.Printf("cookie host: %v\n", k.Host)
			httpClient.Jar.SetCookies(&k, c)
		}
		resp, err := checkLoggedIn(f.Server, httpClient)
		if !isRedirectResponse(resp) {
			return httpClient, err
		}
		//return nil, errors.New("Cookie not logged in.")
	}
	httpClient, err = createHttpClientFor(f.Server, login, passwordCallback(login), httpClient)
	if err != nil {
		// Failed creating new http client.
		logger.Error.Printf("Failed creating http client. Error: %v", err)
		os.Exit(1)
	}

	if f.httpClientMap == nil {
		f.httpClientMap = make(map[string]*http.Client, 0)
	}

	f.httpClientMap[login] = httpClient

	return httpClient, err
}

func createBlankHttpClient() *http.Client {
	options := cookiejar.Options{
		PublicSuffixList: publicsuffix.List,
	}
	cookieJar, _ := cookiejar.New(&options)
	tr := &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
	}
	client := &http.Client{
		Jar:           cookieJar,
		Timeout:       time.Duration(0),
		CheckRedirect: RedirectFunc,
		Transport:     tr,
	}
	return client
}

func checkLoggedIn(host string, httpClient *http.Client) (*http.Response, error) {
	redirFunc := httpClient.CheckRedirect
	httpClient.CheckRedirect = NoRedirectFunc

	cookiesList := make([]*http.Cookie, 0)
	vFoo := url.Values{}
	vFoo.Set("foo", "bar")
	urlStr := fmt.Sprintf("%v/accounts.xml", host)
	logger.Debug.Printf("posting to (%v)", urlStr)
	resp, err := httpClient.Post(urlStr, "application/x-www-form-urlencoded", strings.NewReader(vFoo.Encode()))
	if err == nil {
		cookiesList = append(cookiesList, resp.Cookies()...)
		respStr, err := readResponseBody(resp.Body)
		if err == nil {
			if isRedirectResponse(resp) {
				logger.Debug.Printf("response %v redirected to %v", urlStr, getHeaderLocation(resp))
			} else {
				logger.Debug.Printf("response from %v:\n%v", urlStr, respStr)
				httpClient.CheckRedirect = redirFunc
				return resp, err
			}
		} else {
			logger.Debug.Printf("error from %v:\n%v", urlStr, err)
		}
	} else if handleResponseError(err) != nil {
		log.Print(fmt.Sprintf("err: %v", err))
		return resp, err
	}
	httpClient.CheckRedirect = redirFunc
	return resp, err
}

func createHttpClientFor(host, login, password string, httpClient *http.Client) (*http.Client, error) {
	if httpClient == nil {
		httpClient = createBlankHttpClient()
	}
	cookiesList := make([]*http.Cookie, 0)

	redirflag := false
	username := login
	passwd := password

	httpClient.CheckRedirect = NoRedirectFunc

	resp, err := checkLoggedIn(host, httpClient)
	responseCode := resp.StatusCode

	if isRedirect(responseCode) {
		urlStr := getHeaderLocation(resp)
		var isSSO = regexp.MustCompile(`^https:\/\/sso.*`)
		var isAuthorized = regexp.MustCompile(`^(http|https):\/\/(sso.*)\/session\/tokens`)
		if username != autoreg {
			// Follow all redirects for nginx cause POST doesn't
			for isRedirectResponse(resp) && !isSSO.MatchString(getHeaderLocation(resp)) {
				logger.Debug.Printf("Posting to: %v\n", urlStr)
				resp, err = httpClient.Post(urlStr, "application/x-www-form-urlencoded", strings.NewReader(url.Values{"foo": []string{"bar"}}.Encode()))
				cookiesList = append(cookiesList, resp.Cookies()...)
			}
			cookieLocation := urlStr
			if location := getHeaderLocation(resp); isRedirectResponse(resp) && isSSO.MatchString(location) {
				logger.Debug.Printf("POST to %v/accounts.xml was redirected, authenticating to SSO\n", host)
				redirflag = true
				numRedirects := 1

				logger.Debug.Printf("Login: %v\n", username)
				if passwd == "" {
					username, passwd, err = PromptUserLogin(username, bufio.NewReader(os.Stdin))
				}

				// is sso
				// TODO: if no password exists, use password callback (what is passed in)
				numRedirects = 0
				for redirflag && numRedirects < 7 {
					var sso_server string
					ssoServerUrl, err := url.Parse(location)
					if err == nil {
						sso_server = ssoServerUrl.Host
					}
					logger.Debug.Println(fmt.Sprintf("SSO_SERVER: %v\n", sso_server))

					v := url.Values{}
					v.Set("login", username)
					v.Set("password", passwd)
					urlStr = fmt.Sprintf("https://%v/login?noredirects=1", sso_server)
					fmt.Printf("Authenticating to %v...\n", urlStr)
					resp, err = httpClient.Post(urlStr, "application/x-www-form-urlencoded", strings.NewReader(v.Encode()))
					cookiesList = append(cookiesList, resp.Cookies()...)
					responseCode = resp.StatusCode
					logger.Debug.Printf("Response: %v", resp)
					location = getHeaderLocation(resp)
					if isRedirectResponse(resp) {
						logger.Debug.Printf("redirect location: %v", location)
					}

					if responseCode == 200 || (isRedirect(responseCode) && isAuthorized.MatchString(location)) {
						logger.Debug.Printf("Authentication Successful to %v\n", cookieLocation)
						urlObj, err := url.Parse(cookieLocation)
						if err == nil {
							cookie_file := getCookieFilename(username)
							logger.Debug.Printf("Saving to cookie file (%v)", cookie_file)
							saveCookie(cookiesList, urlObj.Host, cookie_file)
						}
						redirflag = false
					} else if isRedirect(responseCode) {
						logger.Debug.Println(fmt.Sprintf("Redirected to %v\n", getHeaderLocation(resp)))
					} else {
						var isCantConnect = regexp.MustCompile(`Can't connect .* Invalid argument`)
						responseStr, err := readResponseBody(resp.Body)
						if err != nil {
							logger.Debug.Println("Unable to read response body.")
							return nil, errors.New("Unable to read response body.")
						}
						if isCantConnect.MatchString(responseStr) {
							logger.Debug.Println("Looks like you're missing Crypt::SSLeay")
							return nil, errors.New("Cannot connect. Looks like you're missing Crypt::SSLeay")
						}
						return nil, errors.New(fmt.Sprintf("Authentication failed:\n%v", resp))
					}
					// scheme => https
					numRedirects++
				}
				if numRedirects == 7 {
					return nil, errors.New("SSO redirect loop")
				}
			}
			if isRedirectResponse(resp) && isAuthorized.MatchString(getHeaderLocation(resp)) {
				tr := &http.Transport{
					TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
				}
				getClient := http.Client{
					CheckRedirect: func(req *http.Request, via []*http.Request) error {
						if len(via) >= 2 {
							return errors.New("stopped after 2 redirects")
						}
						return nil
					},
					Jar:       httpClient.Jar,
					Transport: tr,
				}
				resp, err := getClient.Get(getHeaderLocation(resp))
				if handleResponseError(err) != nil {
					return nil, errors.New(fmt.Sprintf("fatal error: %v", err))
				}
				if resp.StatusCode != 422 {
					if resp.StatusCode == 200 {
						return nil, errors.New("Unable to get SSO session token.  Might be authentication failure or SSO problem\n")
					}
				}
			}
		} else {
			// is autoreg
			var isSSORedir = regexp.MustCompile(`^https:\/\/sso.*\/login\?url`)
			var isSSORedirSearch = regexp.MustCompile(`^https:\/\/(sso.*)\/login\?url`)

			var nonSSOLocation string

			for err == nil && isRedirectResponse(resp) && !isSSORedir.MatchString(getHeaderLocation(resp)) {
				urlStr = getHeaderLocation(resp)
				nonSSOLocation = urlStr
				urlObj, err := url.Parse(urlStr)
				if err == nil {
					host = urlObj.Scheme + "://" + urlObj.Host
				}
				resp, err = httpClient.Post(urlStr, "application/x-www-form-urlencoded", strings.NewReader(url.Values{"foo": []string{"bar"}}.Encode()))
				cookiesList = append(cookiesList, resp.Cookies()...)
				if err == nil {
					respStr, err := readResponseBody(resp.Body)
					if err == nil {
						if isRedirectResponse(resp) {
							logger.Debug.Printf("response %v redirected to %v", urlStr, getHeaderLocation(resp))
						} else {
							logger.Debug.Printf("response(%v) from %v:\n%v", resp.StatusCode, urlStr, respStr)
						}
					}

				}
			}

			if isSSORedirSearch.MatchString(getHeaderLocation(resp)) {
				logger.Debug.Println(fmt.Sprintf("POST to %v/accounts.xml ( ** for user 'autoreg' ** ) was redirected, authenticating to local login path: '/login/login'\n", host))

				var urlBase string
				if nonSSOLocation != "" {
					urlBaseObj, err := url.Parse(nonSSOLocation)
					if err == nil {
						urlBase = fmt.Sprintf("https://%v", urlBaseObj.Host)
					}
				} else {
					urlBase = host
				}
				urlStr = fmt.Sprintf("%v/login/login", urlBase)
				urlObj, err := url.Parse(urlStr)
				if err != nil {
					log.Fatal(fmt.Sprintf("Error when parsing URL %v: %v", urlStr, err))
				}
				urlObj.Scheme = "https"
				urlStr = urlObj.String()
				logger.Debug.Println(fmt.Sprintf("Authenticating to %v", urlStr))

				v := url.Values{}
				v.Set("login", username)
				v.Set("password", passwd)
				httpClient.CheckRedirect = RedirectFunc
				resp, err = httpClient.Post(urlStr, "application/x-www-form-urlencoded", strings.NewReader(v.Encode()))
				cookiesList = append(cookiesList, resp.Cookies()...)
				if err != nil {
					log.Fatal(fmt.Sprintf("Error when posting to %v: %v", urlStr, err))
				}

				cookie_file := getCookieFilename(username)
				logger.Debug.Printf("Saving to cookie file (%v)", cookie_file)
				saveCookie(cookiesList, urlObj.Host, cookie_file)

				_, _ = readResponseBody(resp.Body)
			} else {
				logger.Debug.Printf("Authentication successful.\n")
			}
		}
	}
	httpClient.CheckRedirect = RedirectFunc

	return httpClient, nil
}

func saveCookie(cookies []*http.Cookie, domain, filename string) {
	logger.Debug.Printf("cookie file: %v, cookies: %v, domain: %v", filename, cookies, domain)
	if len(cookies) < 1 {
		return
	}
	if _, err := os.Stat(filename); os.IsNotExist(err) {
		// File doesn't exist. Create.
		f, err := os.Create(filename)
		defer f.Close()
		if err == nil {
			for _, c := range cookies {
				if c.Path == "" {
					c.Path = "/"
				}
				if c.Domain == "" {
					c.Domain = domain
				}
				cJson, err := serializeJSON(c)
				if err == nil {
					logger.Debug.Printf("cookie json: %v", cJson)
					// Save to file
					res, err := f.WriteString(cJson + "\n")
					if err != nil {
						logger.Error.Printf("Error writing to cookie file (%v) [%v]: %v\n", filename, res, err)
					}
				}
			}
		} else {
			logger.Error.Printf("Error creating cookie file (%v): %v\n", filename, err)
		}
	} else {
		// File already exists. Just overwrite.
		f, err := os.OpenFile(filename, os.O_APPEND|os.O_WRONLY, 0600)
		defer f.Close()
		if err == nil {
			for _, c := range cookies {
				if c.Path == "" {
					c.Path = "/"
				}
				if c.Domain == "" {
					c.Domain = domain
				}
				cJson, err := serializeJSON(c)
				if err == nil {
					logger.Debug.Printf("writing cookie json: %v", cJson)
					// Save to file
					res, err := f.WriteString(cJson + "\n")
					if err != nil {
						logger.Error.Printf("Error writing to cookie file (%v) [%v]: %v\n", filename, res, err)
					}
				}
			}
		} else {
			logger.Error.Printf("Error openning cookie file (%v): %v\n", filename, err)
		}
	}
}

func loadCookies(filename string) (c []*http.Cookie, err error) {
	res := make([]*http.Cookie, 0)

	// TODO: Check if previous cookie is already there
	_, err = os.Stat(filename)
	if err == nil {
		// cookie file found
		//Read cookie

		f, err := os.Open(filename)
		if err == nil {
			defer f.Close()
			reader := bufio.NewReader(f)
			line, _ := readLine(reader)
			for line != "" {
				cookie := &http.Cookie{}
				err = deserializeJSONCookie(string(line), cookie)
				if err == nil {
					logger.Debug.Printf("Cookie Found at %v: %v=%v", filename, cookie.Name, cookie.Value)
					res = append(res, cookie)
				}
				line, _ = readLine(reader)
			}
		}
	}
	return res, err
}

func NoRedirectFunc(req *http.Request, via []*http.Request) error {
	return errors.New("No redirect.")
}

func RedirectFunc(req *http.Request, via []*http.Request) error {
	if len(via) >= 10 {
		return errors.New("stopped after 10 redirects")
	}
	return nil
}
