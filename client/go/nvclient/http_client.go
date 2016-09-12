package nvclient

import (
	"crypto/tls"
	"github.com/atclate/go-logger"
	"errors"
	"fmt"
	"net/url"
	"net/http"
	"os"
	"bufio"
	"regexp"
	"strings"
	"net/http/cookiejar"
	"time"
	"golang.org/x/net/publicsuffix"
)

func NewHttpClient() *HttpClient {
	return &HttpClient{httpClientMap: make(map[string]*http.Client, 0)}
}

type HttpClient struct {
	server        string
	httpClientMap map[string]*http.Client
}

func (c *HttpClient) GetServer() string {
	return c.server
}

func (c *HttpClient) SetServer(server string) {
	c.server = server
}

func passwordCallback(username string) string {
	if username == autoreg {
		return autoreg_password
	} else {
		_, p, _ := PromptUserLogin(username, bufio.NewReader(os.Stdin))
		return p
	}
}

func (c *HttpClient) newHttpClientFor(username string, passwordCallback func(username string) string) (*http.Client, error) {

	// Create new blank http client
	httpClient := createBlankHttpClient()
	// load cookies for user
	loadCookiesIntoClient(username, httpClient)

	cookiesList := make([]*http.Cookie, 0)

	redirflag := false

	httpClient.CheckRedirect = NoRedirectFunc

	// check if we're able to log in
	resp, err := c.isLoggedIn(c.GetServer(), httpClient)
	if err != nil {
		return nil, err
	}
	host := c.GetServer()

	responseCode := resp.StatusCode

	if isRedirect(responseCode) {
		// Not SSO redirect.
		urlStr := getHeaderLocation(resp)
		var isSSO = regexp.MustCompile(`^https:\/\/sso.*`)
		var isAuthorized = regexp.MustCompile(`^(http|https):\/\/(sso.*)\/session\/tokens`)
		if username != autoreg {
			cookieLocation := urlStr
			if location := getHeaderLocation(resp); isRedirectResponse(resp) && isSSO.MatchString(location) {
				logger.Debug.Printf("POST to %v/accounts.xml was redirected, authenticating to SSO\n", host)
				redirflag = true
				numRedirects := 1

				passwd := passwordCallback(username)

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
					logger.Error.Printf("Error when parsing URL %v: %v\n", urlStr, err)
				}
				urlObj.Scheme = "https"
				urlStr = urlObj.String()
				logger.Debug.Println(fmt.Sprintf("Authenticating to %v", urlStr))
				passwd := autoreg_password

				v := url.Values{}
				v.Set("login", username)
				v.Set("password", passwd)
				httpClient.CheckRedirect = RedirectFunc
				resp, err = httpClient.PostForm(urlStr, v)
				cookiesList = append(cookiesList, resp.Cookies()...)
				if err != nil {
					logger.Error.Printf("Error when posting to %v: %v\n", urlStr, err)
					os.Exit(1)
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

func (c *HttpClient) isLoggedIn(host string, httpClient *http.Client) (*http.Response, error) {
	redirFunc := httpClient.CheckRedirect
	httpClient.CheckRedirect = NoRedirectFunc

	vFoo := url.Values{}
	vFoo.Set("foo", "bar")

	// post to host/accounts.xml and inspect the response.
	// if it redirects to sso location, client is not authenticated.
	// if it responds without redirect, assume it is authenticated.
	urlStr := fmt.Sprintf("%v/accounts.xml", host)
	logger.Debug.Printf("posting to (%v)", urlStr)
	resp, err := httpClient.Post(urlStr, "application/x-www-form-urlencoded", strings.NewReader(vFoo.Encode()))
	if err == nil {
		respStr, err := readResponseBody(resp.Body)
		if err == nil {
			if isRedirectResponse(resp) {
				logger.Debug.Printf("response %v redirected to %v", urlStr, getHeaderLocation(resp))
				var isSSO = regexp.MustCompile(`^https:\/\/sso.*`)
				// Follow all redirects for nginx cause POST doesn't
				for isRedirectResponse(resp) && !isSSO.MatchString(getHeaderLocation(resp)) {
					u, err := url.Parse(getHeaderLocation(resp))
					if err == nil {
						c.SetServer(fmt.Sprintf("%v://%v", u.Scheme, u.Host))
					}
					if u.Scheme == "" {
						u.Scheme = "http"
					}
					c.SetServer(fmt.Sprintf("%v://%v", u.Scheme, u.Host))
					urlStr = u.String()

					logger.Debug.Printf("Posting to: %v\n", urlStr)
					resp, err = httpClient.Post(urlStr, "application/x-www-form-urlencoded", strings.NewReader(url.Values{"foo": []string{"bar"}}.Encode()))
				}
			} else {
				logger.Debug.Printf("response from %v:\n%v", urlStr, respStr)
				httpClient.CheckRedirect = redirFunc
				return resp, err
			}
		} else {
			logger.Debug.Printf("error from %v:\n%v", urlStr, err)
		}
	} else if handleResponseError(err) != nil {
		logger.Error.Print(fmt.Sprintf("err: %v", err))
		return resp, err
	}
	httpClient.CheckRedirect = redirFunc
	return resp, err
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
		// File already exists.
		// Read all cookies from file
		existing_cookies, err := loadCookiesFromFile(filename)
		// Save non-existing cookies
		f, err := os.OpenFile(filename, os.O_APPEND|os.O_WRONLY, 0600)
		defer f.Close()
		if err == nil {
			for _, c := range cookies {
				if !existing_cookies.cookieExists(c) {
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
			}
		} else {
			logger.Error.Printf("Error openning cookie file (%v): %v\n", filename, err)
		}
	}
}

type CookieList []*http.Cookie

func (cl CookieList) cookieExists(c *http.Cookie) bool {
	for _, cookie := range cl {
		if cookie.Raw == c.Raw {
			return true
		}
	}
	return false
}

func loadCookiesFromFile(filename string) (CookieList, error) {
	cookies := make([]*http.Cookie, 0)

	// TODO: Check if previous cookie is already there
	_, err := os.Stat(filename)
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
					cookies = append(cookies, cookie)
				}
				line, _ = readLine(reader)
			}
			return cookies, err
		}
	}
	return nil, err
}

func loadCookiesIntoClient(username string, client *http.Client) {
	filename := getCookieFilename(username)

	cookies, err := loadCookiesFromFile(filename)

	// check cookies, load if exists
	if err == nil && len(cookies) > 0 {
		logger.Debug.Printf("Loading %v cookie(s) from file (%v)", len(cookies), filename)
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
			client.Jar.SetCookies(&k, c)
		}
	}
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
