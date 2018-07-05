#include <amxmodx>
#include <amxmisc>

#define PLUGIN_VERSION "1.3"
#define MAX_MOTD_SIZE 1536
#define MAX_HEADER_SIZE 32
#define MAX_CMD_SIZE 32

new g_szMap[32]
new Trie:g_tMotds
new Trie:g_tHeaders
new const g_szSayStuff[2][] = { "say ", "say_team " }

public plugin_init()
{
	register_plugin("MOTD Commands", PLUGIN_VERSION, "OciXCrom")
	register_cvar("MOTDCommands", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	get_mapname(g_szMap, charsmax(g_szMap))
	g_tMotds = TrieCreate()
	g_tHeaders = TrieCreate()
	ReadFile()
}

public plugin_end()
{
	TrieDestroy(g_tMotds)
	TrieDestroy(g_tHeaders)
}
	
public Cmd_ShowMotd(id)
{
	new szCommand[MAX_CMD_SIZE * 2], szArgs[MAX_CMD_SIZE]
	read_argv(0, szCommand, charsmax(szCommand))
	
	if(equal(szCommand[0], g_szSayStuff[0], 3) || equal(szCommand[0], g_szSayStuff[1], 8))
	{
		read_argv(1, szArgs, charsmax(szArgs))
		remove_quotes(szArgs)
		
		static szMotd[MAX_MOTD_SIZE], szHeader[MAX_HEADER_SIZE]
		szHeader[0] = EOS
		
		TrieGetString(g_tMotds, szArgs, szMotd, charsmax(szMotd))
		TrieGetString(g_tHeaders, szArgs, szHeader, charsmax(szHeader))
		show_motd(id, szMotd, szHeader)
	}
	
	return PLUGIN_HANDLED
}

ReadFile()
{
	new szConfigsName[256], szFilename[256]
	get_configsdir(szConfigsName, charsmax(szConfigsName))
	formatex(szFilename, charsmax(szFilename), "%s/MotdCommands.ini", szConfigsName)
	new iFilePointer = fopen(szFilename, "rt")
	
	if(iFilePointer)
	{
		new szData[MAX_MOTD_SIZE + MAX_HEADER_SIZE + MAX_CMD_SIZE]
		new szMotd[MAX_MOTD_SIZE], szHeader[MAX_HEADER_SIZE], szCommand[MAX_CMD_SIZE], bool:bRead = true, iSize
		
		while(!feof(iFilePointer))
		{
			fgets(iFilePointer, szData, charsmax(szData))
			trim(szData)
			
			switch(szData[0])
			{
				case EOS, '#', ';': continue
				case '[':
				{
					iSize = strlen(szData)
					
					if(szData[iSize - 1] == ']')
					{
						szData[0] = ' '
						szData[iSize - 1] = ' '
						trim(szData)
						
						if(contain(szData, "*") != -1)
						{
							strtok(szData, szCommand, charsmax(szCommand), szMotd, charsmax(szMotd), '*')
							copy(szMotd, strlen(szCommand), g_szMap)
							bRead = equal(szMotd, szCommand) ? true : false
						}
						else
						{
							static const szAll[] = "#all"
							bRead = equal(szData, szAll) || equali(szData, g_szMap)
						}
					}
					else continue
				}
				default:
				{
					if(!bRead)
						continue
						
					strtok(szData, szCommand, charsmax(szCommand), szMotd, charsmax(szMotd), '=')
					trim(szCommand); trim(szMotd)
					szHeader[0] = EOS
					
					strtok(szCommand, szCommand, charsmax(szCommand), szHeader, charsmax(szHeader), ' ')
					TrieSetString(g_tMotds, szCommand, szMotd)
					TrieSetString(g_tHeaders, szCommand, szHeader)
					format(szCommand, charsmax(szCommand), "say %s", szCommand)
					register_clcmd(szCommand, "Cmd_ShowMotd")
					replace(szCommand, charsmax(szCommand), "say", "say_team")
					register_clcmd(szCommand, "Cmd_ShowMotd")
				}
			}
		}
		
		fclose(iFilePointer)
	}
}
