local icl = import("icl")
local utils = import("utils")

local urls = import("iran_election_urls")

local function test_url(host, path)
  local out = {}

  out.dnslocal = icl.dns(host, {implementation="ldns"})
  out.dnsgoogle = icl.dns(host, {resolver="8.8.8.8", implementation="ldns"})

  if out.dnslocal.A == "10.10.34.34" then
    out.httpresult = icl.http_get("http://", out.dnsgoogle.A, path, host)
  else
    out.httpresult = icl.http_get("http://", out.dnslocal.A, path, host)
  end

  return out
end

for i, url in pairs(urls) do
  write_result(utils.serialize(test_url(url.host, url.path)))
end
