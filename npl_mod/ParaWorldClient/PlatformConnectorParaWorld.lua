--[[
Title: PlatformConnectorParaworld
Author(s): Cellfy, refactored by LiXizhi
Date Created: Aug 27, 2018
Date Updated: Dev 4, 2018
Desc: 
Usage:
------------------------------------------------------------
local PlatformConnectorParaworld = NPL.load("./PlatformConnectorParaworld.lua")
------------------------------------------------------------
]]

local NetworkClient = NPL.load("./NetworkClient.lua");
local PlatformConnectorBase = NPL.load("./PlatformConnectorBase.lua");
local PlatformConnectorParaworld = commonlib.inherit(PlatformConnectorBase, NPL.export());

function PlatformConnectorParaworld:ctor()
    self.identity = "PlatformConnectorParaworld";
    
    self.remote_ip = "127.0.0.1";
    self.remote_port = "8098";
    self.remote_address = "script/paraworld/network/GameMessageHandler.lua";
    self.nid = nil;
end

function PlatformConnectorParaworld:Init()
    PlatformConnectorParaworld._super.Init(self);

    LOG.std(nil, "debug", "truckstar", "initing paraworld connecter");

    self.nid =  NetworkClient.connect(self.remote_ip,
                                      self.remote_port,
                                      function()
                                          LOG.std(nil, "debug", "truckstar", "paraworld connection failed");
                                      end,
                                      self.remote_address);
    NPL.AddPublicFile("script/Truck/Network/ParaWorldMessageHandler.lua", 601);
    
    self.inited = true;
    
    NetworkClient.send(self.nid, {command="dummpy_message"}, true);
end

function PlatformConnectorParaworld:SendMessage(msg)
    if self.inited and msg and msg.command then
        NetworkClient.send(self.nid, msg, true);
    end
end
