package.path = "../?.lua;" .. package.path

local redc = require "api.core.redis_client_cli"
local dtc = require "api.core.dtcoll"
local dt_red = require "api.core.dtree_redis"
local hfn = require "api.core.hlpfunc"

local json = require "api.core.json"


local red = redc.connect()
local dt = dt_red.new('CHINOOK',red)

local dataset = dt
: select{object="ARTIST", call = 
	function(art)
	
		local albums = dt:select_ix{object="ALBUM", index="IFK_AlbumArtistId", item=art.ArtistId}
		local tracks
		local all_t = 0
		dtc.new(albums):each(function(alb)
			tracks = dt:select_ix{object="TRACK", on="ALBUM", index="IFK_TrackAlbumId", item=alb.AlbumId}
			all_t = all_t + #tracks
		end)
		tracks = all_t
		albums = #albums
		if tracks > 0 then
			print(art.Name, tracks, albums)
			return art
		end
		return nil
	end
}

print(json.encode(dataset:content()))