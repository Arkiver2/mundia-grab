local url_count = 0
local tries = 0


read_file = function(file)
  if file then
    local f = assert(io.open(file))
    local data = f:read("*all")
    f:close()
    return data
  else
    return ""
  end
end

-- wget.callbacks.download_child_p = function(urlpos, parent, depth, start_url_parsed, iri, verdict, reason)
--   local url = urlpos["url"]["url"]
--   
--   -- Don't download the favicon over and over again
--   if url == "http://wallbase.cc/fav.gif" then
--     return false
--   
--   else
--     return verdict
--   end
-- end

wget.callbacks.get_urls = function(file, url, is_css, iri)
  local urls = {}
  local html = nil
  local mundia_url = "http://www.mundia.com"
  --example url: http://www.mundia.com/us/Person/743375/6809259973
  --example url: http://www.mundia.com/us/Person/12748608/-190814136
  
  
  --example url: http://www.mundia.com/pk/Search/Results?surname=ABDULA&birthPlace=Verenigde%20Staten
  if string.match(url, "%.mundia%.com/[a-z]+/Search/Results?surname=[A-Z]+%&birthPlace=[.]+") then
    if not html then
      html = read_file(file)
    end
    
    --example string: <a href="/pk/Person/5586782/-1432906874" class="">Joseph Sadula Abdula</a>
    for person_url in string.gmatch(html, '<a href="(/[a-z]+/Person/[0-9]/[-]?[0-9]+)" class="">[a-z]+</a>') do
      --------------Multiple links possible as results probably - chfoo - help?-------------------
      table.insert(urls, { url=mundia_url..person_url })
    end
    
    --example string: <a class="tree" href="/pk/Tree/Family/5586782/-1432906874"><span class="view-tree">Stamboom tonen</span></a>
    for tree_url in string.gmatch(html, '<a class="[a-z]+" href="(/[a-z]+/Tree/Family/[0-9]/[-]?[0-9]+)"><span class="view-tree">[a-z]+</span></a>') do
      --------------Multiple links possible as results probably - chfoo - help?-------------------
      table.insert(urls, { url=mundia_url..tree_url })
    end
    
    --example string: <img src="http://mediasvc.ancestry.com/v2/image/namespaces/1093/media/11f96e77-c39c-4ca4-b659-32f67aa8d129.jpg?client=TreeService&MaxSide=96" width="68" alt="Foto" /></a>
    for person_image in string.gmatch(html, '<img src="(http://mediasvc%.ancestry%.com/v[0-9]+/image/namespaces/[0-9]+/media/[a-z0-9-]+%.jpg%?client=TreeService&MaxSide=[0-9]+)" width="[0-9]+" alt="Foto" /></a>') do
      --------------Multiple links possible as results probably - chfoo - help?-------------------
      table.insert(urls, { url=person_image })
      for person_image_big in string.gmatch(person_image, "(http://mediasvc%.ancestry%.com/v[0-9]+/image/namespaces/[0-9]+/media/[a-z0-9-]+%.jpg%?client=TreeService)&MaxSide=[0-9]+") do
        table.insert(urls, { url=person_image_big })
      end
    end
  end
  
  --example url: http://www.mundia.com/pk/Person/5586782/-1432906874
  if string.match(url, "%.mundia%.com/[a-z]+/Person/[0-9]+/[-]?[0-9]+") then
    if not html then
      html = read_file(file)
    end
    
    --example string: href="/pk/Messages?sendMessageTo=0120cac9-0003-0000-0000-000000000000&subject=Joseph%2BSadula%2BAbdula"
    for adding_user in string.gmatch(html, 'href="(/[a-z]+/Messages%?sendMessageTo=[0-9-]+&subject=[a-z%]+)"') do
    end
    
  end
  
end
  

wget.callbacks.httploop_result = function(url, err, http_stat)
  -- NEW for 2014: Slightly more verbose messages because people keep
  -- complaining that it's not moving or not working
  local status_code = http_stat["statcode"]
  
  url_count = url_count + 1
  io.stdout:write(url_count .. "=" .. status_code .. " " .. url["url"] .. ".  \r")
  io.stdout:flush()
  
  if status_code >= 500 or
    (status_code >= 400 and status_code ~= 404) then
    io.stdout:write("\nServer returned "..http_stat.statcode..". Sleeping.\n")
    io.stdout:flush()

    os.execute("sleep 10")

    tries = tries + 1

    if tries >= 5 then
      io.stdout:write("\nI give up...\n")
      io.stdout:flush()
      return wget.actions.ABORT
    else
      return wget.actions.CONTINUE
    end
  end

  tries = 0

  -- We're okay; sleep a bit (if we have to) and continue
  local sleep_time = 0.1 * (math.random(75, 1000) / 100.0)

  --  if string.match(url["host"], "cdn") or string.match(url["host"], "media") then
  --    -- We should be able to go fast on images since that's what a web browser does
  --    sleep_time = 0
  --  end

  if sleep_time > 0.001 then
    os.execute("sleep " .. sleep_time)
  end

  return wget.actions.NOTHING
end
