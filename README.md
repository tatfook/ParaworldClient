# ParaworldClient

For each paraworld client app, call following code on startup. 
```
local ParaWorldClient = NPL.load("ParaWorldClient")
ParaWorldClient:Init()
```

This is based on cellify's code to connect with QQ hall.
Basically it connect to `127.0.0.1:8098` (the paraworld lobby process) to handle QQ hall message and heart beat. 

## TODO
we need to rewrite the script/*.* code into npl mod
