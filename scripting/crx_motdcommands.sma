#include <amxmodx>
#include <amxmisc>

#define PLUGIN_VERSION "1.0"

new Trie:g_tMotds
new const g_szSayStuff[2][] = { "say ", "say_team " }

public plugin_init()
{
	register_plugin("MOTD Commands", PLUGIN_VERSION, "OciXCrom")
	register_cvar("@MOTDCommands", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	g_tMotds = TrieCreate()
	fileRead()
}

public plugin_end()
	TrieDestroy(g_tMotds)
	
public cmdMotd(id)
{
	new szCommand[64], szArgs[32]
	read_argv(0, szCommand, charsmax(szCommand))
	
	if(equal(szCommand[0], g_szSayStuff[0], 3) || equal(szCommand[0], g_szSayStuff[1], 8))
	{
		read_argv(1, szArgs, charsmax(szArgs))
		remove_quotes(szArgs)
		
		new szFile[128]
		TrieGetString(g_tMotds, szArgs, szFile, charsmax(szFile))
		show_motd(id, szFile)
	}
	
	return PLUGIN_HANDLED
}

fileRead()
{
	new szConfigsName[256], szFilename[256]
	get_configsdir(szConfigsName, charsmax(szConfigsName))
	formatex(szFilename, charsmax(szFilename), "%s/MotdCommands.ini", szConfigsName)
	new iFilePointer = fopen(szFilename, "rt")
	
	if(iFilePointer)
	{
		new szData[160], szFile[128], szCommand[32]
		
		while(!feof(iFilePointer))
		{
			fgets(iFilePointer, szData, charsmax(szData))
			trim(szData)
			
			if(szData[0] == EOS || szData[0] == ';')
				continue
				
			parse(szData, szCommand, charsmax(szCommand), szFile, charsmax(szFile))
			TrieSetString(g_tMotds, szCommand, szFile)
			format(szCommand, charsmax(szCommand), "say %s", szCommand)
			register_clcmd(szCommand, "cmdMotd")
			replace(szCommand, charsmax(szCommand), "say", "say_team")
			register_clcmd(szCommand, "cmdMotd")
		}
		
		fclose(iFilePointer)
	}
}
