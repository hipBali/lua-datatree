package.path = "../?.lua;" .. package.path

local redc = require "api.core.redis_client_cli"
local dtc = require "api.core.dtcoll"
local dt_red = require "api.core.dtree_redis"
local hfn = require "api.core.hlpfunc"

local json = require "api.core.json"


local red = redc.connect()
local dt = dt_red.new('CHINOOK',red)

local dataset = dt
: select{object="ARTIST"} 		
	: join{object="ALBUM", index="IFK_AlbumArtistId"} 
		: join{object="TRACK", on="ALBUM", index="IFK_TrackAlbumId"} 
			: join{object="GENRE", on="TRACK", merge=function(track,genre)
				track.Genre = genre[1].Name -- genre.Name as Genre
				genre = nil	-- remove merged object
			end }  
			: join{object="MEDIATYPE", on="TRACK", merge=function(track,medtype)
				track.MediaType = medtype[1].Name -- media_type.Name as MediaType
				medtype = nil	-- remove merged object
			end }  

print(json.encode(dataset:content()))