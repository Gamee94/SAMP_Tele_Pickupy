/*
	Dynamiczne PickUpy by Game/B.A.Baracus
	Wymagania:
	    Serwer SA:MP
	    Baza MySql
	    Pluginy:
	        mysql R5 - od BlueG
	        sscanf 2

*/
#include <a_samp>
#include <a_mysql>
#include <ZCMD>
#include <sscanf2>

//Ustawienia MySql
#define SQL_HOST         "127.0.0.1" // HOST
#define SQL_USER        "USER" // USER
#define SQL_PASS         "PASSWORD" // PASS
#define SQL_DB             "BAZA" // DB

//Ustawienia skryptu
#define MYSQL_ERROR //Daj to w komentarzu aby wy³¹czyæ logi MySql!
#define MAX_PICK 150 //Maksymalna liczba pickupów

enum _pickups
{
	id,Float:x,Float:y,Float:z,Float:tp_x,Float:tp_y,Float:tp_z,Float:tp_a,description[32]
}

enum _create
{
	Float:x,Float:y,Float:z,Float:tp_x,Float:tp_y,Float:tp_z,Float:tp_a,description[32],step
}

new pickup[MAX_PICK][_pickups];
new create[_create];

public OnFilterScriptInit()
{
    mysql_connect(SQL_HOST, SQL_USER, SQL_DB, SQL_PASS);
    #if defined MYSQL_ERROR
	    mysql_debug(1);
	#endif
    if(mysql_ping())
    {
        new load_pick = 0,
			buff[64],
			query[256];
			
    	print("[PICKUPY][MYSQL] Po³¹czono z baz¹ danych!");
    	print("[PICKUPY]Dynamiczne PickUpy By Game/B.A.Baracus za³adowane powodzeniem!");
    	print("[PICKUPY] Trwa ³adowanie Pickupów!");
		format(buff,64,"SELECT * FROM `pickups` LIMIT %i",MAX_PICK);
		mysql_query(buff);
		mysql_store_result();
		if(mysql_num_rows())
		{
		    while(mysql_fetch_row(query))
		    {
		        sscanf(query,"p<|>ifffffffs[32]",pickup[load_pick][id],pickup[load_pick][x],pickup[load_pick][y],pickup[load_pick][z],pickup[load_pick][tp_x],pickup[load_pick][tp_y],pickup[load_pick][tp_z],pickup[load_pick][tp_a],pickup[load_pick][description]);
		        Create3DTextLabel(pickup[load_pick][description], 0x008080FF, pickup[load_pick][x],pickup[load_pick][y],pickup[load_pick][z]+0.50, 100.0, 0, 0);
	         	pickup[load_pick][id] = CreatePickup(1318, 1,pickup[load_pick][x],pickup[load_pick][y],pickup[load_pick][z]);
		        load_pick++;
		    }
		    printf("[PICKUPY] Za³adowano: %i pickupów!",load_pick);
		}
		else
		    print("[PICKUPY] Brak dodanych pickupów do bazy!");

		mysql_free_result();
    	
    }
    else if(!mysql_ping())
    {
		print("[PICKUPY][MYSQL] Nie po³¹czono z baz¹ danych!");
		print("[PICKUPY]Dynamiczne PickUpy By Game/B.A.Baracus za³adowane niepowodzeniem!");
    }
	return 1;
}

public OnFilterScriptExit()
	return mysql_close();

public OnPlayerPickUpPickup(playerid, pickupid)
{
	for(new i; i < MAX_PICK; i++)
	{
	    if(pickupid == pickup[i][id])
	    {
			SetPlayerPos(playerid,pickup[i][tp_x],pickup[i][tp_y],pickup[i][tp_z]);
			SetPlayerFacingAngle(playerid,pickup[i][tp_a]);
	    }
	}
	return 1;
}

CMD:dodajtp(playerid,params[])
{
	if(!IsPlayerAdmin(playerid))
		return SendClientMessage(playerid,0xFF0000FF,"[PICKUPY] Brak dostêpu!");
	if(CountTeleports() >= (MAX_PICK-1))
		SendClientMessage(playerid,0xFF0000FF, "[PICKUPY] Limit teleportów zosta³ wyczerpany. Zwiêksz wartoœæ 'MAX_PICK' w skrypcie, ¿eby dodaæ kolejne teleporty.");
	if(create[step] > 0)
	    return SendClientMessage(playerid,0xFF0000FF,"[PICKUPY] Aktualnie dodawany jest teleport, poczekaj!");
	if(isnull(params))
		return SendClientMessage(playerid,0xFF0000FF,"[PICKUPY] Wpisz /dodajtp [OPIS TELEPORTU np San Fierro]. Nie poda³eœ opisu!");
	if(strlen(params) > 32)
		return SendClientMessage(playerid,0xFF0000FF,"[PICKUPY] Wpisz /dodajtp [OPIS TELEPORTU np San Fierro]. Za d³ugi opis!");

    mysql_real_escape_string(params,create[description]);
	GetPlayerPos(playerid,create[x],create[y],create[z]);
	create[step]++;
	SendClientMessage(playerid,0xFF8000FF,"[PICKUPY] IdŸ do miejsca gdzie ma teleportowaæ i wpisz /zatwierdz");
	return 1;
}

CMD:zatwierdz(playerid,params[])
{
	if(!IsPlayerAdmin(playerid))
		return SendClientMessage(playerid,0xFF0000FF,"[PICKUPY] Brak dostêpu!");
	if(create[step] ==0)
	    return SendClientMessage(playerid,0xFF0000FF,"[PICKUPY] Wpisz /dodajtp aby dodaæ teleport");
	    
	new buff[256];
	
	GetPlayerPos(playerid,create[tp_x],create[tp_y],create[tp_z]);
	GetPlayerFacingAngle(playerid,create[tp_a]);
	
 	
	format(buff,sizeof buff,"INSERT INTO `pickups`(`X`,`Y`,`Z`,`TP_X`,`TP_Y`,`TP_Z`,`TP_A`,`description`) VALUES ('%0.3f','%0.3f','%0.3f','%0.3f','%0.3f','%0.3f','%0.2f','%s')",create[x],create[y],create[z],create[tp_x],create[tp_y],create[tp_z],create[tp_a],create[description]);
	mysql_query(buff);
	
	pickup[id][x] = create[x];
	pickup[id][y] = create[y];
	pickup[id][z] = create[z];
	pickup[id][tp_x] = create[tp_x];
	pickup[id][tp_y] = create[tp_y];
	pickup[id][tp_z] = create[tp_z];
	pickup[id][tp_a] = create[tp_a];
 	Create3DTextLabel(create[description], 0x008080FF, pickup[id][x],pickup[id][y],pickup[id][z]+0.50, 100.0, 0, 0);
	pickup[id][id] = CreatePickup(1318, 1,pickup[id][x],pickup[id][y],pickup[id][z]);

	format(buff,sizeof buff,"[PICKUPY] Dodano teleport %s !",create[description]);
	SendClientMessage(playerid,0x008000FF,buff);
	create[step] = 0;
	return 1;
}

stock CountTeleports()
{
	mysql_query("SELECT COUNT(*) FROM `pickups`");
	mysql_store_result();
	new rows = mysql_fetch_int();
	mysql_free_result();
	return rows;
}
