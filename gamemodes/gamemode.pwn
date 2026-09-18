#include <a_samp>
#include <a_mysql>
#include <zcmd>
#include <sscanf2>

// Database Config
#define MYSQL_HOST "127.0.0.1"
#define MYSQL_USER "root"
#define MYSQL_PASSWORD ""
#define MYSQL_DATABASE "samprp_db"

#define MAX_ADMIN_LIMIT 5

new MySQL: g_SQL;

enum pInfo
{
    pID,
    pName[MAX_PLAYER_NAME],
    pPhone[15],
    pMoney,
    pBankMoney,
    pCoins,
    pAdmin,
    pFaction,
    pJob,
    pGangID,
    pGangRank,
    pCuffed
}
new PlayerInfo[MAX_PLAYERS][pInfo];

public OnGameModeInit()
{
    g_SQL = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE);
    if(mysql_errno(g_SQL) != 0)
    {
        printf("[MySQL Connection Failed] ከዳታቤዝ ጋር መገናኘት አልተቻለም!");
    }
    else
    {
        printf("[MySQL Connected] ከዳታቤዝ ጋር በተሳካ ሁኔታ ተገናኝቷል!");
    }

    SetGameModeText("Ethiopia RP v1.0");
    AddPlayerClass(0, 1758.0, -1898.0, 13.5, 0.0, 0, 0, 0, 0, 0, 0);
    
    // Payday Timer (በየ 60 ደቂቃው የሚሰራ)
    SetTimer("OnPlayerPaydayTimer", 3600000, true);
    return 1;
}

public OnGameModeExit()
{
    mysql_close(g_SQL);
    return 1;
}

public OnPlayerConnect(playerid)
{
    GetPlayerName(playerid, PlayerInfo[playerid][pName], MAX_PLAYER_NAME);
    PlayerInfo[playerid][pAdmin] = 0;
    PlayerInfo[playerid][pFaction] = 0;
    PlayerInfo[playerid][pJob] = 0;
    PlayerInfo[playerid][pGangID] = 0;
    PlayerInfo[playerid][pGangRank] = 0;
    PlayerInfo[playerid][pCoins] = 0;
    PlayerInfo[playerid][pCuffed] = 0;
    
    // የስልክ ቁጥር ማስገቢያ ዳያሎግ
    ShowPlayerDialog(playerid, 100, DIALOG_STYLE_INPUT, "የኢትዮጵያ ሰርቨር ምዝገባ", "እባክዎን የኢትዮጵያ ስልክ ቁጥርዎን ያስገቡ (+251..., 09... ወይም 07...):", "መዝግብ", "ውጣ");
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if(dialogid == 100)
    {
        if(!response) return Kick(playerid);
        
        if(strlen(inputtext) < 9 || (inputtext[0] != '0' && inputtext[0] != '+'))
        {
            SendClientMessage(playerid, 0xFF0000FF, "[ስህተት] እባክዎን ትክክለኛ የኢትዮጵያ ስልክ ቁጥር ያስገቡ!");
            ShowPlayerDialog(playerid, 100, DIALOG_STYLE_INPUT, "የኢትዮጵያ ሰርቨር ምዝገባ", "እባክዎን የኢትዮጵያ ስልክ ቁጥርዎን ያስገቡ (+251..., 09... ወይም 07...):", "መዝግብ", "ውጣ");
            return 1;
        }
        
        format(PlayerInfo[playerid][pPhone], 15, "%s", inputtext);
        SendClientMessage(playerid, 0x00FF00FF, "[SUCCESS] እንኳን ወደ ኢትዮጵያ ሰርቨር በደህና መጡ!");
        return 1;
    }
    return 0;
}

forward OnPlayerPaydayTimer();
public OnPlayerPaydayTimer()
{
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i) && PlayerInfo[i][pJob] > 0)
        {
            new salary = 1000;
            if(PlayerInfo[i][pJob] == 1) salary = 2500;
            else if(PlayerInfo[i][pJob] == 11) salary = 1800;
            else if(PlayerInfo[i][pJob] == 13) salary = 3000;
            else if(PlayerInfo[i][pJob] == 47) salary = 3500;

            PlayerInfo[i][pBankMoney] += salary;

            new string[128];
            format(string, sizeof(string), "[PAYDAY] የሰዓቱ ደመወዝ $%d ወደ ባንክ አካውንትዎ ገብቷል።", salary);
            SendClientMessage(i, 0x00FF00FF, string);
        }
    }
    return 1;
}

// -------------------------------------------------------------
// COMMANDS (ትእዛዞች)
// -------------------------------------------------------------

// /stats - ፕሮፋይል ማያ
CMD:stats(playerid, params[])
{
    new string[400];
    format(string, sizeof(string), "--- %s Stats ---\nስልክ: %s\nብር: $%d\nባንክ: $%d\nCoins: %d\nAdmin Level: %d\nFaction: %s\nJob ID: %d\nGang ID: %d (Rank %d)",
        PlayerInfo[playerid][pName],
        PlayerInfo[playerid][pPhone],
        PlayerInfo[playerid][pMoney],
        PlayerInfo[playerid][pBankMoney],
        PlayerInfo[playerid][pCoins],
        PlayerInfo[playerid][pAdmin],
        (PlayerInfo[playerid][pFaction] == 1) ? ("ፖሊስ (Police)") : ("ሲቪል (Civilian)"),
        PlayerInfo[playerid][pJob],
        PlayerInfo[playerid][pGangID],
        PlayerInfo[playerid][pGangRank]
    );
    ShowPlayerDialog(playerid, 1, DIALOG_STYLE_MSGBOX, "የተጫዋች መረጃ", string, "እሺ", "");
    return 1;
}

// /buycoins - 1 Coin = 500 Cash
CMD:buycoins(playerid, params[])
{
    new coins_to_buy;
    if(sscanf(params, "i", coins_to_buy)) return SendClientMessage(playerid, 0xFFFFFFFF, "አጠቃቀም: /buycoins [የ Coin መጠን]");
    if(coins_to_buy <= 0) return SendClientMessage(playerid, 0xFF0000FF, "[ስህተት] ትክክለኛ መጠን ያስገቡ!");
    if(PlayerInfo[playerid][pCoins] < coins_to_buy) return SendClientMessage(playerid, 0xFF0000FF, "[ስህተት] በቂ Coin የለዎትም!");

    new cash_amount = coins_to_buy * 500;
    PlayerInfo[playerid][pCoins] -= coins_to_buy;
    PlayerInfo[playerid][pMoney] += cash_amount;
    GivePlayerMoney(playerid, cash_amount);

    new string[128];
    format(string, sizeof(string), "[SHOP] %d Coins ቀይረው $%d የጌም ውስጥ ብር አግኝተዋል።", coins_to_buy, cash_amount);
    SendClientMessage(playerid, 0x00FF00FF, string);
    return 1;
}

// /makeadmin - Owner (Level 5) ብቻ ሌላ አድሚን መሾሚያ (MAX 5 Admins)
CMD:makeadmin(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 5) 
        return SendClientMessage(playerid, 0xFF0000FF, "[ስህተት] ዋና አድሚን (Owner) ብቻ ነው ሌላ አድሚን መሾም የሚችለው!");

    new targetid, level;
    if(sscanf(params, "ui", targetid, level)) 
        return SendClientMessage(playerid, 0xFFFFFFFF, "አጠቃቀም: /makeadmin [የተጫዋች ID] [Admin Level (1-5)]");

    if(!IsPlayerConnected(targetid)) 
        return SendClientMessage(playerid, 0xFF0000FF, "[ስህተት] ተጫዋቹ በሰርቨሩ ውስጥ የለም!");

    new current_admins = 0;
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i) && PlayerInfo[i][pAdmin] > 0) current_admins++;
    }

    if(current_admins >= MAX_ADMIN_LIMIT && level > 0)
        return SendClientMessage(playerid, 0xFF0000FF, "[ስህተት] የሰርቨሩ የአድሚኖች ብዛት ከ 5 መብለጥ አይችልም!");

    PlayerInfo[targetid][pAdmin] = level;
    new string[128], adminname[MAX_PLAYER_NAME], targetname[MAX_PLAYER_NAME];
    GetPlayerName(playerid, adminname, sizeof(adminname));
    GetPlayerName(targetid, targetname, sizeof(targetname));

    format(string, sizeof(string), "[ADMIN] ዋና አድሚን %s ተጫዋች %sን ደረጃ %d አድሚን አድርጎ ሾሟል።", adminname, targetname, level);
    SendClientMessageToAll(0x00FF00FF, string);
    return 1;
}

// /setfaction - አድሚን ብቻ ፖሊስ መሾሚያ
CMD:setfaction(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 1) 
        return SendClientMessage(playerid, 0xFF0000FF, "[ስህተት] አድሚኖች ብቻ ናቸው ፖሊስ መሾም የሚችሉት!");

    new targetid, factionid;
    if(sscanf(params, "ui", targetid, factionid)) 
        return SendClientMessage(playerid, 0xFFFFFFFF, "አጠቃቀም: /setfaction [የተጫዋች ID] [Faction ID (1: ፖሊስ, 0: ሲቪል)]");

    if(!IsPlayerConnected(targetid)) 
        return SendClientMessage(playerid, 0xFF0000FF, "[ስህተት] ተጫዋቹ በሰርቨሩ ውስጥ የለም!");

    PlayerInfo[targetid][pFaction] = factionid;
    new string[128], adminname[MAX_PLAYER_NAME], targetname[MAX_PLAYER_NAME];
    GetPlayerName(playerid, adminname, sizeof(adminname));
    GetPlayerName(targetid, targetname, sizeof(targetname));

    format(string, sizeof(string), "[ADMIN] አድሚን %s ተጫዋች %sን Faction %d አድርጎ ሾሟል።", adminname, targetname, factionid);
    SendClientMessageToAll(0x00FF00FF, string);
    return 1;
}

// /getjob - ከ 50 ስራዎች አንዱን መረጣ
CMD:getjob(playerid, params[])
{
    new jobid;
    if(sscanf(params, "i", jobid)) return SendClientMessage(playerid, 0xFFFFFFFF, "አጠቃቀም: /getjob [የስራ ID (1-50)]");
    if(jobid < 1 || jobid > 50) return SendClientMessage(playerid, 0xFF0000FF, "[ስህተት] የስራ ID ከ 1 እስከ 50 መሆን አለበት!");
    if(jobid <= 8 && PlayerInfo[playerid][pAdmin] < 1) return SendClientMessage(playerid, 0xFF0000FF, "[ስህተት] የመንግስት/የፖሊስ ስራዎች በአድሚን በኩል ብቻ ነው የሚሰጡት!");

    PlayerInfo[playerid][pJob] = jobid;
    new string[128];
    format(string, sizeof(string), "[JOB] በስራ ID %d ላይ በተሳካ ሁኔታ ተቀጥረዋል።", jobid);
    SendClientMessage(playerid, 0x00FF00FF, string);
    return 1;
}

// /cuff - ፖሊስ ወንጀለኛ ማሰሪያ
CMD:cuff(playerid, params[])
{
    if(PlayerInfo[playerid][pFaction] != 1) return SendClientMessage(playerid, 0xFF0000FF, "[ስህተት] ፖሊስ ብቻ ነው ካቴና ማሰር የሚችለው!");
    new targetid;
    if(sscanf(params, "u", targetid)) return SendClientMessage(playerid, 0xFFFFFFFF, "አጠቃቀም: /cuff [የተጫዋች ID]");
    if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid, 0xFF0000FF, "[ስህተት] ተጫዋቹ የለም!");

    TogglePlayerControllable(targetid, 0);
    SetPlayerSpecialAction(targetid, SPECIAL_ACTION_CUFFED);
    PlayerInfo[targetid][pCuffed] = 1;

    new string[128], name[MAX_PLAYER_NAME], targetname[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));
    GetPlayerName(targetid, targetname, sizeof(targetname));
    format(string, sizeof(string), "* ፖሊስ %s ተጫዋች %sን ካቴና አሰረው።", name, targetname);
    SendClientMessageToAll(0x33CCFFAA, string);
    return 1;
}

// /jail - ፖሊስ/አድሚን ማሰሪያ
CMD:jail(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < 1 && PlayerInfo[playerid][pFaction] != 1) return SendClientMessage(playerid, 0xFF0000FF, "[ስህተት] አድሚን ወይም ፖሊስ ብቻ ነው ማሰር የሚችለው!");
    new targetid, time;
    if(sscanf(params, "ui", targetid, time)) return SendClientMessage(playerid, 0xFFFFFFFF, "አጠቃቀም: /jail [የተጫዋች ID] [ደቂቃ]");

    SetPlayerPos(targetid, 264.14, 77.47, 1001.03);
    SetPlayerInterior(targetid, 6);

    new string[128], targetname[MAX_PLAYER_NAME];
    GetPlayerName(targetid, targetname, sizeof(targetname));
    format(string, sizeof(string), "[JAIL] ተጫዋች %s ለ %d ደቂቃ ታስሯል።", targetname, time);
    SendClientMessageToAll(0xFF0000FF, string);
    return 1;
}

// /lock - መኪና መቆለፊያ
CMD:lock(playerid, params[])
{
    new vehicleid = GetPlayerVehicleID(playerid);
    if(vehicleid == 0) return SendClientMessage(playerid, 0xFF0000FF, "[ስህተት] በመኪና ውስጥ መሆን አለብዎት!");

    new engine, lights, alarm, doors, bonnet, boot, objective;
    GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
    
    if(doors == 1) {
        SetVehicleParamsEx(vehicleid, engine, lights, alarm, 0, bonnet, boot, objective);
        SendClientMessage(playerid, 0x00FF00FF, "[CAR] መኪናዎ ተከፍቷል።");
    } else {
        SetVehicleParamsEx(vehicleid, engine, lights, alarm, 1, bonnet, boot, objective);
        SendClientMessage(playerid, 0xFF0000FF, "[CAR] መኪናዎ ተቆልፏል።");
    }
    return 1;
}

// /pay - ገንዘብ መስጫ
CMD:pay(playerid, params[])
{
    new targetid, amount;
    if(sscanf(params, "ui", targetid, amount)) return SendClientMessage(playerid, 0xFFFFFFFF, "አጠቃቀም: /pay [የተጫዋች ID] [መጠን]");
    if(amount <= 0 || PlayerInfo[playerid][pMoney] < amount) return SendClientMessage(playerid, 0xFF0000FF, "[ስህተት] የገንዘብ መጠን አይበቃም!");

    PlayerInfo[playerid][pMoney] -= amount;
    GivePlayerMoney(playerid, -amount);
    PlayerInfo[targetid][pMoney] += amount;
    GivePlayerMoney(targetid, amount);

    SendClientMessage(playerid, 0x00FF00FF, "[PAY] ገንዘብ በትክክል ተላልፏል።");
    return 1;
}

// /ginvite - የጋንግ አባል መጋበዝ
CMD:ginvite(playerid, params[])
{
    if(PlayerInfo[playerid][pGangRank] < 6) return SendClientMessage(playerid, 0xFF0000FF, "[ስህተት] የጋንግ መሪ ብቻ ነው መጋበዝ የሚችለው!");
    new targetid;
    if(sscanf(params, "u", targetid)) return SendClientMessage(playerid, 0xFFFFFFFF, "አጠቃቀም: /ginvite [የተጫዋች ID]");

    PlayerInfo[targetid][pGangID] = PlayerInfo[playerid][pGangID];
    PlayerInfo[targetid][pGangRank] = 1;
    SendClientMessage(targetid, 0x00FF00FF, "[GANG] ወደ ጋንግ ተቀላቅለዋል።");
    return 1;
}
