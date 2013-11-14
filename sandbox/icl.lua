local icl = {}

local function pony_dns_wrapper(domain, optional)
  local result, err = pony.dns(optional.record_type,
                               domain,
                               { resolver = optional.resolver,
                                 tcp = optional.tcp,
                                 timeout = optional.timeout_seconds,
                                 recursive = optional.recusrive,
                               })
  if err ~= nil then
    return nil, err
  end
  return {
    A = result.A1,
    AAAA = result.AAAA,
    MX = result.MX,
    TXT = result.TXT,
    NS = result.NS,
    CNAME = result.CNAME,
    SOA = result.SOA,
  }, nil
end

local function ldns_wrapper(domain, optional)
  local result, err = dns_lookup(domain, optional.resolver)
  if err ~= nil then
    return nil, err
  end
  return {
    A = result,
  }, nil
end

local dns_implementations = {
  pony = pony_dns_wrapper,
  ldns = ldns_wrapper,
}

-- Perform a DNS query.
--
-- Required arguments:
-- - domain is the domain name to resolve.
--
-- Optional arguments:
-- - record_type is one of DNS's record types (e.g., A, AAAA, MX, etc.)
--   If omitted, use A.
-- - resolver is the IP address of the DNS resolver to query.
--   If omitted, use the system's default nameserver.
-- - timeout_seconds is how long to wait before terminating the lookup.
--   If omitted, wait for 5 seconds.
-- - recursive is a boolean telling whether to resolve the query recursively.
--   If omitted, resolve recursively.
-- - tcp is a boolean telling whether to use TCP for resolution.
--   If omitted, don't use TCP.
-- - implementation is the name of the underyling primitive function to use.
--   If omitted, choose an implementation based on what's available.
--
-- Returns a table with the following fields:
-- - A, a list of IPv4 addresses in the order they were recevied.
-- - AAAA, a lit of IPv4 addresses in the order they were received.
-- - MX, a list of domains used for handling mail.
-- - TXT, a list of text records.
-- - NS, a list of nameservers.
-- - CNAME, a list of canonical names.
-- - SOA, a list of SOA records.
-- - implementation, a string identifying the underlying DNS implementation
--   (e.g., "ldns", "libevent", "pony", etc.)
function icl.dns(domain, optional)
  if optional == nil then
    optional = {}
  end

  -- Fill in default arguments.
  if optional.record_type == nil then
    optional.record_type = "A"
  end
  if optional.timeout_seconds == nil then
    optional.timeout_seconds = 5
  end
  if optional.recursive == nil then
    optional.recursive = true
  end
  if optional.tcp == nil then
    optional.tcp = false
  end
  if optional.implementation == nil then
    if dns_implementations.pony then
      optional.implementation = "pony"
    elseif dns_implementations.ldns then
      optional.implementation = "ldns"
    end
  end

  local wrapper_func = dns_implementations[optional.implementation]
  if wrapper_func == nil then
    return nil, "could not find implementation"
  end
  result, err = wrapper_func(domain, optional)
  if result ~= nil then
    result.implementation = optional.implementation
  end
  return result, err
end

local function pony_http_get_wrapper(scheme, domain, path, host, optional)
  local result, err = pony.gethttp("",
                                   scheme,
                                   domain,
                                   path,
                                   host,
                                   {
                                     timeout = optional.timeout_seconds,
                                     headers = table.concat(optional.headers),
                                   })
  if err ~= nil then
    return nil, err
  end
  return {
    status = result.httpstatus,
    content = result.httpcontent,
    headers = result.httpheaders,
  }, nil
end

local http_get_implementations = {
  pony = pony_http_get_wrapper,
}

-- Fetch a URL over HTTP.
--
-- Required arguments:
-- - url is an http or https URL to fetch.
-- Optional arguments:
-- - timeout_seconds is how long to wait before terminating the fetch.
--   If omitted, wait for 5 seconds.
-- - headers is an array of headers to append to the request.
-- - implementation, a string identifying the underlying HTTP GET implementation
--   (e.g., "pony", "libevent", "libcurl", etc.)
--
-- Returns a table with the following fields:
-- - status, the HTTP status code (e.g., 200, 404, etc.)
-- - content, the content of the page fetched.
-- - headers, an array of response headers.
function icl.http_get(scheme, domain, path, host, optional)
  if optional == nil then
    optional = {}
  end

  -- Fill in default arguments.
  if optional.timeout_seconds == nil then
    optional.timeout_seconds = 5
  end
  if optional.headers == nil then
    optional.headers = {}
  end
  if optional.implementation == nil then
    if http_get_implementations.pony then
      optional.implementation = "pony"
    end
  end

  local wrapper_func = http_get_implementations[optional.implementation]
  if wrapper_func == nil then
    return nil, "could not find implementation"
  end
  result, err = wrapper_func(scheme, domain, path, host, optional)
  if result ~= nil then
    result.implementation = optional.implementation
  end
  return result, err
end

return icl
