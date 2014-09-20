; Xbox_Account uses the xbox live xuid to look up info, below using Major Nelson's xuid
my_account := new Xbox_Account("2584878536129841")
msgbox % "Gamertag: " my_account.Gamertag
my_account.Display_Friends()
my_account.Display_FriendsV1()
my_account.Display_Profile()
my_account.Display_ProfileV1()()
