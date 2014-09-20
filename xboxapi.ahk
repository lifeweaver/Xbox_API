
class Xbox_Account extends Xbox_API
{
  __New(axuid,aparsed_profile:="")
  {
    base.__New()
    this.xuid := axuid
    
    if !aparsed_profile
      this.parsed_profile := Json2(this.Get_Profile(this.xuid))
    else
      this.parsed_profile := aparsed_profile
  }
  
  __Delete()
  {
    
  }
  
  ; This lets my_account.Gamertag return the gamertag
  __Get(aProperty)
  {
    return this.parsed_profile[aProperty]
  }
  
  ; Returns any xbox live messages
  Messages()
  {
    return this.Xbox_API_Request("messages")
  }
  
  Friends()
  {
    base_friends := Json2(this.Get_Friends(this.xuid))
	  
    parsed_friends := Object()
    Loop % base_friends.MaxIndex()
    {
      this_account := base_friends[A_Index]
      parsed_friends.Insert(new Xbox_Account(this_account["id"], this_account))
    }
    return parsed_friends
  }
  
  Display_Friends()
  {
    parsed_friends := this.Friends()
    friends_list := ""
    
    Loop % parsed_friends.MaxIndex()
      friends_list .= parsed_friends[A_Index]["Gamertag"] . "`n"
    
    Sort, friends_list
    msgbox % "Friends List(" . parsed_friends.MaxIndex() . "): `n" friends_list
  }
  
  Display_Profile()
  {
    profile_list := {}
    for key, value in this.parsed_profile
      profile_list .= key . ": " . value . "`n"
      
    Sort, profile_List
    msgbox % "Your Profile: " profile_list
  }
  
  Display_FriendsV1()
  {
    parsed_friends := Json2(this.Get_FriendsV1(this.xuid))["Friends"]

    online_list := ""
    offline_list := ""
    
    Loop % parsed_friends.MaxIndex()
    {
      this_friend := parsed_friends[A_Index]
	  if this_friend["isOnline"]
        online_list .= this_friend["Gamertag"] . "`n"
	  else
	    offline_list .= this_friend["Gamertag"] . "`n"
    }
    
    Sort, online_list
    Sort, offline_list
    msgbox % "Friends ListV1(" parsed_friends.MaxIndex() "): `n"
	      . "`n---Online Friends ---`n" online_list
		  . "`n`n---Offline Friends---`n" offline_list
  }
  
  Display_ProfileV1()
  {
    parsed_profile := Json2(this.Get_ProfileV1(this.xuid))["Player"]
	
	profile_list := {}
	for this_key, this_value in parsed_profile
	{
      profile_list .= this_key . ": " . this_value . "`n"
	  for key, value in parsed_profile[this_key]
	  {
        profile_list .= key . ": " . value . "`n"
		  for akey, avalue in parsed_profile[this_key][key]
		    profile_list .= akey . ": " . avalue . "`n"
	  }
	}

    Sort, profile_List
    msgbox % "Your ProfileV1: " profile_list
  }
}



class Xbox_API
{
  __New(api_key:="defalut_can_be_placed_here")
  {
    this.api_key := api_key
    this.base_urlv1 := "https://xboxapi.com/v1/" ;v1
    this.base_urlv2 := "https://xboxapi.com/v2/" ;v2
    this.WinHttpRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
  }

  __Delete()
  {
    ; this.WinHttpRequest.Open("GET", 
  }
  
  DoubleToHex(d)
  {
    form := A_FormatInteger
    SetFormat Integer, HEX
    v := DllCall("ntdll.dll\RtlLargeIntegerShiftLeft",Double,d, UChar,0, Int64)
    SetFormat Integer, %form%
    Return v
  }
  
  ; https://xboxapi.com/documentation
  Xbox_API_Request(request, xuid := "")
  {
    if xuid
      request_url := this.base_urlv2 . xuid . "/" . request
    else
      request_url := this.base_urlv2 . request
    
    try
    {
      this.WinHttpRequest.Open("GET", request_url)
      this.WinHttpRequest.SetRequestHeader("X-AUTH", this.api_key)
      this.WinHttpRequest.Send()
      this.WinHttpRequest.WaitForResponse(10)

      if this.WinHttpRequest.GetResponseHeader("X-RateLimit-Remaining") < 1
        msgbox % "Request limit reached, please wait minutes: " this.WinHttpRequest.GetResponseHeader("X-RateLimit-Reset") / 60
    }
	catch e
	{
	  Msgbox % "An exception was thrown: `nwhat: " e.what "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra
	  msgbox % this.WinHttpRequest.ResponseText
	  msgbox % this.WinHttpRequest.ResponseBody
	}
    return this.WinHttpRequest.ResponseText
  }
  
  ; https://xboxapi.com/v1/documentation
  ; Only have this for the Get_FriendsV1/Get_ProfileV1 since they returns the isOnline
  Xbox_API_RequestV1(request, xuid := "")
  {
    ; if xuid
      ; request_url := this.base_urlv1 . xuid . "/" . request
    ; else
      request_url := this.base_urlv1 . request
	  
    try
    {
      this.WinHttpRequest.Open("GET", request_url)
      this.WinHttpRequest.Send()
      this.WinHttpRequest.WaitForResponse(60)
	}
	catch e
	{
	  Msgbox % "An exception was thrown: `nwhat: " e.what "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra
	  msgbox % this.WinHttpRequest.ResponseText
	  msgbox % this.WinHttpRequest.ResponseBody
	}
	
	; Writes binary data then goes back to begining and Reads it as text
    if (this.WinHttpRequest.ResponseBody )
	{   
      ADO := ComObjCreate("ADODB.Stream")
      ADO.Type := 1        ; 1: binary 2: text
	  ADO.Mode := 3
      ADO.Open()
      ADO.Write(this.WinHttpRequest.ResponseBody)
	  
	  ; Part to read t he text
	  ADO.Position := 0
	  ADO.Type := 2 ; 1: binary 2: text
	  ADO.Charset:= "utf-8"
      return ADO.ReadText()
    }
	else
	  return this.WinHttpRequest.ResponseText
  }
  
  Get_GamerTag(xuid)
  {
    return this.Xbox_API_Request("gamertag/" . xuid)
  }
  
  Get_GamerTag_XUID(gamer_tag)
  {
    StringReplace, gamer_tag, gamer_tag, %A_Space%, +, ALL
    return this.Xbox_API_Request("xuid/" . gamer_tag)
  }
  
  Get_Profile(xuid)
  {
    return this.Xbox_API_Request("profile", xuid)
  }
  
  ; Only have it since it returns the isOnline
  Get_ProfileV1(xuid)
  {
    gamer_tag := this.Get_GamerTag(xuid)
    StringReplace, gamer_tag, gamer_tag, %A_Space%, +, ALL
    
    return this.Xbox_API_RequestV1("profile/" . gamer_tag, xuid)
  }
  
  Get_GamerCard(xuid)
  {
    return this.Xbox_API_Request("gamercard", xuid)
  }
  
  Get_Presence(xuid)
  {
    return this.Xbox_API_Request("presence", xuid)
  }
  
  Get_Activity(xuid)
  {
    return this.Xbox_API_Request("activity", xuid)
  }
  
  Get_Recent_Activity(xuid)
  {
    return this.Xbox_API_Request("activity/recent", xuid)
  }
  
  Get_Friends(xuid)
  {
    return this.Xbox_API_Request("friends", xuid)
  }
  
  ; Only have it since it returns the isOnline
  Get_FriendsV1(xuid)
  {
    gamer_tag := this.Get_GamerTag(xuid)
    StringReplace, gamer_tag, gamer_tag, %A_Space%, +, ALL
    
    return this.Xbox_API_RequestV1("friends/" . gamer_tag, xuid)
  }
  
  Get_Followers(xuid)
  {
    return this.Xbox_API_Request("followers", xuid)
  }
  
  Get_Recent_Players()
  {
    return this.Xbox_API_Request("recent-players")
  }
  
  Get_Game_Clips(xuid)
  {
    return this.Xbox_API_Request("game-clips", xuid)
  }
  
  Get_Saved_Game_Clips(xuid)
  {
    return this.Xbox_API_Request("game-clips/saved", xuid)
  }
  
  Get_Game_Stats(title_id, xuid)
  {
    return this.Xbox_API_Request("game-stats" . title_id, xuid)
  }
  
  Get_Xbox_360_Games(xuid)
  {
    return this.Xbox_API_Request("xbox360games", xuid)
  }
  
  Get_Xbox_One_Games(xuid)
  {
    return this.Xbox_API_Request("xboxonegames", xuid)
  }
  
  Get_Game_Achievements(title_id, xuid)
  {
    return this.Xbox_API_Request("achievements/" . title_id, xuid)
  }
  
  Xbox_Game_Information_Product_Id(product_id)
  {
    return this.Xbox_API_Request("game-details/" . product_id)
  }
  
  Xbox_Game_Information_Game_ID(game_id)
  {
    ; convert game_id to hex
    game_id := this.DoubleToHex(game_id)
    
    return this.Xbox_API_Request("game-details-hex/" . game_id)
  }
  
  
  
  
}
