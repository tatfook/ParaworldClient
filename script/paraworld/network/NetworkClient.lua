﻿--[[
NPL.load("(gl)script/paraworld/network/NetworkClient.lua");
local NetworkClient = commonlib.gettable("paraworld.network.NetworkClient");
]]

local NetworkClient = commonlib.gettable("paraworld.network.NetworkClient");

NPL.load("(gl)script/nplprotobuf/packets/PacketPb.lua");

local PacketPb = commonlib.gettable("nplprotobuf.packets.PacketPb");
local PacketPbHelper = commonlib.gettable("nplprotobuf.packets.PacketPbHelper");

--connection
local cons = {}

NPL.load("(gl)script/paraworld/network/Connection.lua");
local Connection = commonlib.gettable("paraworld.network.Connection");

--receive handler
local NetHandler = commonlib.inherit(nil, commonlib.gettable("paraworld.network.NetHandler"));

local isStarted = false;
function NetworkClient.start(ip, port)
	LOG.std(nil, "debug", "truckstar", "__msg__network_client--start");
	echo({ip,port})
	isStarted = true;
	if not (ip and port) then
		ip = "127.0.0.1";
		port = "8098";
	end
	PacketPbHelper.setMessageSender(NetworkClient.send);
	-- setting to 0.0.0.0 is allow to listen all local ips
	-- it will not listen any ports if port is "0"(just be a client)
        local att = NPL.GetAttributeObject();
        att:SetField("TCPKeepAlive", true);
        att:SetField("KeepAlive", true);
        att:SetField("IdleTimeoutPeriod", 24 * 60 * 60 * 1000);
	NPL.StartNetServer(ip, port)
	-- set receiving entry ( entry: activate() )
	NPL.AddPublicFile("script/paraworld/network/NetworkClient.lua", 201);
	
	NPL.load("(gl)script/paraworld/network/GameConnector.lua");
	local GameConnector = commonlib.gettable("paraworld.network.GameConnector");
	GameConnector.AddPublicFile();
end

function NetworkClient.stop()
	isStarted = false;
	NPL.StopNetServer();
end

function NetworkClient.connect(ip, port, errCallback, remote_file)
	LOG.std(nil, "debug", "truckstar", "__msg__network_client--connect: %s : %s", ip, port);
	if (not isStarted) then
		NetworkClient.start()
	end

	local nid = string.format("%s%s", ip, port);
	if cons[nid] then
		LOG.std(nil, "debug", "truckstar", "__msg__aa-nid: %d", nid);
		return nid;
	end

	local params = {host = tostring(ip), port = tostring(port), nid = nid};
	NPL.AddNPLRuntimeAddress(params);
	local handler = NetHandler:new()

	cons[nid] = Connection:new():init(nid, handler, remote_file);
	handler.errCallback = errCallback;
	--cons[nid]:connect()
	LOG.std(nil, "debug", "truckstar", "__msg__dd-nid: %s", nid);
	return nid;
end

--@param reason: reason for shutting down the connection: 10001: abandon on general purpose
--                                                        10002: not used yet
function NetworkClient.isReasonKnown(reason)
	return (reason>10000 and reason<10002);
end

--@param reason: same with NetworkClient.isReasonKnown
function NetworkClient.disconnect(nid, reason)
	local con = cons[nid];

	if (con and con:isConnected()) then
		con:disconnect(reason);
	end
	cons[nid] = nil
end

function NetworkClient.send(nid, packet, send_raw, remote_file)
	local con = cons[nid];
	if (not con) then
		-- commonlib.log("error: connection "..nid.." is not existed or closed when sending\n")
		return false;
	end
	local msg;
	if send_raw then
		msg = packet;
	else
		msg = packet:WritePacket();
		msg.id = packet.id;
	end
	return con:send(msg, remote_file)
end

function NetworkClient.handleError(nid, msg)
	local connection = cons[nid];
	if connection then 
		connection:onError("NPL_ConnectionDisconnected")
		echotable(msg);
	end
end


function NetHandler:handleMsg(msg)
	local pb = PacketPb:new();
	pb:unserialize(msg);

	PacketPbHelper.process(pb.headerRaw, pb.bodyRaw);

end

function NetHandler:handleErrorMessage(err,nid)
	NetworkClient.disconnect(nid)
	local reason = err:match("OnConnectionLost with reason = (%d+)");
	if not reason then
		commonlib.log("error: "..err.."\n")
		reason = -1;
	end
	if self.errCallback then
		self.errCallback(tonumber(reason));
	end

end

-- incoming msg entry
local function activate()
	local msg = msg;
	local id = msg.nid or msg.tid;
	if(id) then
		local connection = cons[id];
		if(connection) then
			connection:onReceive(msg);
		end
	end
end
NPL.this(activate);
